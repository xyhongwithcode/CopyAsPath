[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Path,

    [switch]$Copy,
    [switch]$Hotkey,
    [switch]$Install,
    [switch]$InstallMenu,
    [switch]$InstallHotkey,
    [switch]$Uninstall
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$appName = 'CopyAbsolutePath'
$installDir = Join-Path $env:LOCALAPPDATA 'CopyPath'
$installedScript = Join-Path $installDir 'CopyPath.ps1'
$menuLauncher = Join-Path $installDir 'CopyPathMenu.vbs'
$pidFile = Join-Path $installDir 'hotkey.pid'
$startupLink = Join-Path ([Environment]::GetFolderPath('Startup')) 'CopyAbsolutePath.lnk'
$powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$hotkeyId = 0x5245
$hotkeyModifiers = 0x0003
$hotkeyVirtualKey = 0x43
$wmHotkey = 0x0312
$explorerClasses = @('CabinetWClass', 'ExploreWClass', 'WorkerW', 'Progman')

$menuLauncherSource = @'
Option Explicit

Dim shell, fso, scriptPath, i, command
If WScript.Arguments.Count = 0 Then WScript.Quit 1

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "CopyPath.ps1")

command = Chr(34) & shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe" & Chr(34) & _
          " -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File " & Quote(scriptPath) & " -Copy"

For i = 0 To WScript.Arguments.Count - 1
    command = command & " " & Quote(WScript.Arguments(i))
Next

shell.Run command, 0, False

Function Quote(value)
    Dim result
    result = value
    If Len(result) > 0 Then
        If Right(result, 1) = "\" Then
            result = result & "\"
        End If
    End If
    Quote = Chr(34) & result & Chr(34)
End Function
'@

$nativeSource = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class CopyPathNative
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    private static extern bool PeekMessage(out NativeMessage lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax, uint wRemoveMsg);

    [StructLayout(LayoutKind.Sequential)]
    public struct NativeMessage
    {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pointX;
        public int pointY;
    }

    public static string ClassNameOf(IntPtr hwnd)
    {
        StringBuilder buffer = new StringBuilder(256);
        GetClassName(hwnd, buffer, buffer.Capacity);
        return buffer.ToString();
    }

    public static bool TryPeekMessage(out NativeMessage message)
    {
        return PeekMessage(out message, IntPtr.Zero, 0, 0, 1);
    }
}
'@

function Set-ClipboardText {
    param([Parameter(Mandatory = $true)][string]$Text)

    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        try {
            Set-Clipboard -Value $Text -ErrorAction Stop
            return
        } catch {
            Start-Sleep -Milliseconds 120
        }
    }
    throw '无法写入剪贴板。'
}

function Copy-PathText {
    param([string[]]$Paths)

    $items = foreach ($candidate in $Paths) {
        if ([string]::IsNullOrEmpty($candidate)) { continue }
        $value = $candidate
        if ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        if ($value) { $value }
    }
    $items = @($items | Select-Object -Unique)
    if ($items.Count -eq 0) { return }
    Set-ClipboardText (($items -join [Environment]::NewLine))
}

function Install-ScriptCopy {
    if (-not (Test-Path -LiteralPath $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    $source = [IO.Path]::GetFullPath($PSCommandPath)
    $target = [IO.Path]::GetFullPath($installedScript)
    if (-not [string]::Equals($source, $target, [StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
}

function Install-MenuLauncher {
    if (-not (Test-Path -LiteralPath $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    [IO.File]::WriteAllText($menuLauncher, $menuLauncherSource, [Text.Encoding]::Unicode)
}

function Get-MenuCommand {
    param([string]$Argument)
    $wscriptExe = Join-Path $env:SystemRoot 'System32\wscript.exe'
    return ('"{0}" //B //Nologo "{1}" "{2}"' -f $wscriptExe, $menuLauncher, $Argument)
}

function Install-ContextMenu {
    Install-MenuLauncher
    $targets = @(
        [pscustomobject]@{ Key = "Software\Classes\*\shell\$appName"; Argument = '%1'; SingleSelect = $true },
        [pscustomobject]@{ Key = "Software\Classes\Directory\shell\$appName"; Argument = '%1'; SingleSelect = $true },
        [pscustomobject]@{ Key = "Software\Classes\Directory\Background\shell\$appName"; Argument = '%V'; SingleSelect = $false },
        [pscustomobject]@{ Key = "Software\Classes\Drive\shell\$appName"; Argument = '%1'; SingleSelect = $false }
    )

    $root = [Microsoft.Win32.Registry]::CurrentUser
    foreach ($target in $targets) {
        $key = $root.CreateSubKey($target.Key)
        try {
            $key.SetValue('', '复制绝对路径', [Microsoft.Win32.RegistryValueKind]::String)
            $key.SetValue('Position', 'Top', [Microsoft.Win32.RegistryValueKind]::String)
            if ($target.SingleSelect) {
                $key.SetValue('MultiSelectModel', 'Single', [Microsoft.Win32.RegistryValueKind]::String)
            }
            $commandKey = $key.CreateSubKey('command')
            try {
                $commandKey.SetValue('', (Get-MenuCommand $target.Argument), [Microsoft.Win32.RegistryValueKind]::String)
            } finally {
                $commandKey.Dispose()
            }
        } finally {
            $key.Dispose()
        }
    }
}

function Uninstall-ContextMenu {
    $keys = @(
        "Software\Classes\*\shell\$appName",
        "Software\Classes\Directory\shell\$appName",
        "Software\Classes\Directory\Background\shell\$appName",
        "Software\Classes\Drive\shell\$appName"
    )
    foreach ($key in $keys) {
        try {
            [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($key, $false)
        } catch {
        }
    }
}

function Get-HotkeyProcess {
    if (-not (Test-Path -LiteralPath $pidFile)) { return $null }
    $text = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $text) { return $null }
    $savedProcessId = 0
    if (-not [int]::TryParse([string]$text, [ref]$savedProcessId)) { return $null }
    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $savedProcessId" -ErrorAction SilentlyContinue
    if (-not $process -or -not $process.CommandLine) { return $null }
    if ($process.CommandLine.IndexOf($installedScript, [StringComparison]::OrdinalIgnoreCase) -lt 0) { return $null }
    if ($process.CommandLine.IndexOf('-Hotkey', [StringComparison]::OrdinalIgnoreCase) -lt 0) { return $null }
    return $process
}

function Start-HotkeyHost {
    Install-ScriptCopy
    if (Get-HotkeyProcess) { return }
    $arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -Hotkey' -f $installedScript
    Start-Process -FilePath $powerShellExe -ArgumentList $arguments -WindowStyle Hidden | Out-Null
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        Start-Sleep -Milliseconds 200
        if (Get-HotkeyProcess) { return }
    }
    throw '快捷键后台进程启动失败。'
}

function Stop-HotkeyHost {
    $process = Get-HotkeyProcess
    if ($process) {
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 200
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

function Install-StartupShortcut {
    Install-ScriptCopy
    $wsh = New-Object -ComObject WScript.Shell
    try {
        $shortcut = $wsh.CreateShortcut($startupLink)
        $shortcut.TargetPath = $powerShellExe
        $shortcut.Arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -Hotkey' -f $installedScript
        $shortcut.WorkingDirectory = $installDir
        $shortcut.WindowStyle = 7
        $shortcut.Description = 'Ctrl+Alt+C copies selected explorer paths'
        $shortcut.Save()
    } finally {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($wsh)
    }
}

function Remove-StartupShortcut {
    Remove-Item -LiteralPath $startupLink -Force -ErrorAction SilentlyContinue
}

function Get-SelectedExplorerPaths {
    param(
        [IntPtr]$WindowHandle,
        [string]$WindowClass
    )

    $result = New-Object 'System.Collections.Generic.List[string]'
    $shell = New-Object -ComObject Shell.Application
    try {
        $windows = $shell.Windows()
        for ($index = 0; $index -lt $windows.Count; $index++) {
            $window = $windows.Item($index)
            $handle = [IntPtr]::Zero
            try { $handle = [IntPtr]([long]$window.HWND) } catch { }
            if ($handle -ne $WindowHandle) {
                if (-not (($WindowClass -eq 'WorkerW') -or ($WindowClass -eq 'Progman'))) { continue }
                $name = ''
                try { $name = [string]$window.Name } catch { }
                if ($name -ne 'Program Manager') { continue }
            }
            $selectedItems = $null
            try { $selectedItems = $window.Document.SelectedItems() } catch { }
            if ($null -eq $selectedItems) { continue }
            for ($itemIndex = 0; $itemIndex -lt $selectedItems.Count; $itemIndex++) {
                $item = $selectedItems.Item($itemIndex)
                $itemPath = ''
                try { $itemPath = [string]$item.Path } catch { }
                if ($itemPath) { $result.Add($itemPath) }
            }
            if ($result.Count -gt 0) { break }
        }
        if ($result.Count -eq 0) {
            for ($index = 0; $index -lt $windows.Count; $index++) {
                $window = $windows.Item($index)
                $handle = [IntPtr]::Zero
                try { $handle = [IntPtr]([long]$window.HWND) } catch { }
                if ($handle -ne $WindowHandle) { continue }
                $folderPath = ''
                try { $folderPath = [string]$window.Document.Folder.Self.Path } catch { }
                if ($folderPath) {
                    $result.Add($folderPath)
                    break
                }
            }
        }
    } finally {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
    return $result.ToArray()
}

function Invoke-HotkeyHost {
    Add-Type -TypeDefinition $nativeSource -Language CSharp

    if (-not (Test-Path -LiteralPath $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    $mutex = New-Object System.Threading.Mutex($false, 'Local\CopyAbsolutePath.Hotkey')
    $hasMutex = $false
    try {
        try {
            $hasMutex = $mutex.WaitOne(0)
        } catch [System.Threading.AbandonedMutexException] {
            $hasMutex = $true
        }
        if (-not $hasMutex) { return }

        Set-Content -LiteralPath $pidFile -Value $PID -Encoding ASCII
        $registered = $false
        $nextRegistrationAttempt = [DateTime]::MinValue
        try {
            while ($true) {
                $foreground = [CopyPathNative]::GetForegroundWindow()
                $windowClass = [CopyPathNative]::ClassNameOf($foreground)
                $isExplorer = $explorerClasses -contains $windowClass

                if ($isExplorer -and -not $registered -and [DateTime]::UtcNow -ge $nextRegistrationAttempt) {
                    $registered = [CopyPathNative]::RegisterHotKey([IntPtr]::Zero, $hotkeyId, $hotkeyModifiers, $hotkeyVirtualKey)
                    if (-not $registered) {
                        $nextRegistrationAttempt = [DateTime]::UtcNow.AddSeconds(2)
                    }
                } elseif (-not $isExplorer -and $registered) {
                    [void][CopyPathNative]::UnregisterHotKey([IntPtr]::Zero, $hotkeyId)
                    $registered = $false
                    $nextRegistrationAttempt = [DateTime]::MinValue
                }

                $message = New-Object 'CopyPathNative+NativeMessage'
                while ([CopyPathNative]::TryPeekMessage([ref]$message)) {
                    if (($message.message -eq $wmHotkey) -and ($message.wParam.ToInt32() -eq $hotkeyId)) {
                        $paths = @(Get-SelectedExplorerPaths -WindowHandle $foreground -WindowClass $windowClass)
                        if ($paths.Count -gt 0) {
                            Copy-PathText -Paths $paths
                        }
                    }
                    $message = New-Object 'CopyPathNative+NativeMessage'
                }
                Start-Sleep -Milliseconds 60
            }
        } finally {
            if ($registered) {
                [void][CopyPathNative]::UnregisterHotKey([IntPtr]::Zero, $hotkeyId)
            }
            Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        }
    } finally {
        if ($hasMutex) {
            try { $mutex.ReleaseMutex() } catch { }
        }
        $mutex.Dispose()
    }
}

if ($Copy) {
    Copy-PathText -Paths $Path
    return
}

if ($Hotkey) {
    Invoke-HotkeyHost
    return
}

if ($Uninstall) {
    Stop-HotkeyHost
    Remove-StartupShortcut
    Uninstall-ContextMenu
    Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output '已卸载：右键菜单、Ctrl+Alt+C 快捷键和开机启动项。'
    return
}

if ($Install -or $InstallMenu -or $InstallHotkey) {
    Install-ScriptCopy
    if ($Install -or $InstallMenu) {
        Install-ContextMenu
        Write-Output '已添加右键菜单“复制绝对路径”：文件、文件夹、文件夹空白处、驱动器。'
    }
    if ($Install -or $InstallHotkey) {
        Install-StartupShortcut
        Start-HotkeyHost
        Write-Output '已启用快捷键：在资源管理器中按 Ctrl+Alt+C 复制所选路径（无选中时复制当前文件夹路径）。'
    }
    if ($Install) {
        Write-Output 'Windows 11 的右键菜单需要点“显示更多选项”才能看到该条目。'
    }
    return
}

Write-Output '用法：'
Write-Output '  CopyPath.ps1 -Install          安装右键菜单和快捷键（含开机启动）'
Write-Output '  CopyPath.ps1 -InstallMenu      只安装右键菜单'
Write-Output '  CopyPath.ps1 -InstallHotkey    只安装快捷键和开机启动'
Write-Output '  CopyPath.ps1 -Uninstall        全部卸载'
Write-Output '  CopyPath.ps1 -Copy PATH        复制指定路径到剪贴板'
