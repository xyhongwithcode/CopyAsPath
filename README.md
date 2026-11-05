# CopyAsPath

Copy absolute file and folder paths from Windows File Explorer.

[中文说明](README.zh-CN.md)

## Features

- Adds **Copy absolute path** to the context menu for:
  - files
  - folders
  - empty space inside a folder (copies the current folder path)
  - drives (copies the drive root, for example `C:\`)
- Press `Ctrl+Alt+C` in File Explorer to copy the paths of all selected items.
- When nothing is selected in File Explorer, `Ctrl+Alt+C` copies the current folder path.
- Runs per user and does not require administrator rights.
- No network access, telemetry, or file-content reads.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 (included with Windows)
- Windows Script Host (`wscript.exe`, included with Windows)

## Install

1. Download this repository as a ZIP, or clone it.
2. Double-click `Install.cmd`.

The installer:

- copies the runtime files to `%LOCALAPPDATA%\CopyAsPath`
- adds per-user context-menu entries under `HKCU\Software\Classes`
- creates a startup shortcut and starts the `Ctrl+Alt+C` listener

No elevation prompt is expected. If Windows SmartScreen warns about the downloaded `.cmd` files, review the source and choose **More info > Run anyway**.

## Usage

Right-click a file, folder, drive, or empty space in a folder and choose **Copy absolute path** (复制绝对路径).

In File Explorer, select one or more items and press `Ctrl+Alt+C`. The selected paths are copied one per line.

## Uninstall

Double-click `Uninstall.cmd`.

This removes the context-menu entries, the startup shortcut, the background hotkey process, and the installed files under `%LOCALAPPDATA%\CopyAsPath`.

## Windows 11 context menu

Windows 11 shows legacy registry verbs under **Show more options** (显示更多选项). You can also press `Shift+F10` or use `Shift+right-click` to open the classic menu directly.

Windows 10 shows the entry directly in the normal context menu.

## How it works

- `CopyAsPath.ps1` installs and manages the per-user integration.
- The context menu launches `CopyAsPathMenu.vbs` through `wscript.exe`, which starts PowerShell with a hidden window. This avoids the console-window flash caused by launching `powershell.exe` directly.
- The hotkey listener runs in the background and registers `Ctrl+Alt+C` only while File Explorer is the foreground application.

## Notes

- The context menu is intended for a single selection. Use `Ctrl+Alt+C` to copy multiple selected paths.
- If `Ctrl+Alt+C` conflicts with another application, change `$hotkeyModifiers` and `$hotkeyVirtualKey` in `CopyAsPath.ps1`, then reinstall.
- The menu label is Chinese by default; edit the `SetValue('', '复制绝对路径', ...)` calls in `CopyAsPath.ps1` to change it.

## License

[MIT](LICENSE)
