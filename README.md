<div align="center">

# CopyAsPath

**Copy absolute file and folder paths from Windows File Explorer.**

[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white)](https://github.com/xyhongwithcode/CopyAsPath)
[![License](https://img.shields.io/github/license/xyhongwithcode/CopyAsPath?style=flat-square)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/xyhongwithcode/CopyAsPath?style=flat-square)](https://github.com/xyhongwithcode/CopyAsPath/releases)

[简体中文](README.zh-CN.md)

</div>

## Why CopyAsPath?

Windows 10 can copy a full path with **Shift + right-click → Copy as path**. CopyAsPath makes that workflow faster:

- A direct **Copy absolute path** item in the right-click menu.
- A File Explorer hotkey: <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd>.
- Support for files, folders, folder background, and drives.
- Runs as the current user; no administrator rights required.

> **Windows 11 note:** Windows 11 already includes <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> (build 22463+) and a built-in **Copy as path** item. CopyAsPath is primarily intended for Windows 10, but it also works on Windows 11 if you want a consistent legacy-menu entry and the <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> shortcut.

## Features

| Area | What it does |
| --- | --- |
| Context menu | Right-click a file, folder, folder background, or drive and choose **Copy absolute path** |
| Hotkey | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> copies all selected paths |
| Folder fallback | With no selection, the hotkey copies the current folder path |
| Multi-select | The hotkey copies one path per line |
| No console flash | The context menu uses a hidden WScript launcher |
| Per-user install | Writes only to `HKCU` and `%LOCALAPPDATA%` |

## Requirements

- Windows 10 (primary target) or Windows 11
- Windows PowerShell 5.1 (included with Windows)
- Windows Script Host (`wscript.exe`, included with Windows)

## Install

### Option 1: Download ZIP

1. Download the latest release or use **Code → Download ZIP**.
2. Extract the archive.
3. Double-click `Install.cmd`.

### Option 2: Clone

```powershell
git clone https://github.com/xyhongwithcode/CopyAsPath.git
cd CopyAsPath
.\Install.cmd
```

No administrator prompt is expected. If SmartScreen warns about the downloaded `.cmd`, review the source and choose **More info → Run anyway**.

## Usage

### Right-click menu

Right-click a file, folder, folder background, or drive and choose **Copy absolute path** (复制绝对路径).

- On Windows 10, the item appears in the normal context menu.
- On Windows 11, it appears under **Show more options**, or you can press <kbd>Shift</kbd> + <kbd>F10</kbd>.

### Hotkey

| Action | Result |
| --- | --- |
| Select items and press <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> | Copies every selected path, one per line |
| Press <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> with no selection | Copies the current folder path |

The hotkey is registered only while File Explorer is the foreground window.

## What the installer changes

| Item | Location |
| --- | --- |
| Runtime files | `%LOCALAPPDATA%\CopyAsPath` |
| Context-menu verbs | `HKCU\Software\Classes\*\shell\CopyAsPath`<br>`HKCU\Software\Classes\Directory\shell\CopyAsPath`<br>`HKCU\Software\Classes\Directory\Background\shell\CopyAsPath`<br>`HKCU\Software\Classes\Drive\shell\CopyAsPath` |
| Startup shortcut | `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CopyAsPath.lnk` |
| Background process | Hidden PowerShell hotkey listener |

## Uninstall

Double-click `Uninstall.cmd`, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\CopyAsPath.ps1 -Uninstall
```

This removes the context-menu entries, startup shortcut, background process, and installed files.

## How it works

1. `CopyAsPath.ps1` copies itself and a generated VBS launcher to `%LOCALAPPDATA%\CopyAsPath`.
2. The context menu runs the VBS launcher through `wscript.exe`.
3. The launcher starts PowerShell with `SW_HIDE`, so no console window flashes.
4. The hotkey listener registers <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> only when File Explorer is active.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Windows 11 menu item is missing | Use **Show more options** or <kbd>Shift</kbd> + <kbd>F10</kbd>; legacy registry verbs are not shown in the compact menu |
| Hotkey does nothing | Make sure File Explorer is focused; another app may own <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> |
| Want a different hotkey | Edit `$hotkeyModifiers` and `$hotkeyVirtualKey` in `CopyAsPath.ps1`, then reinstall |
| Menu label is not English | Edit the `SetValue('', '复制绝对路径', ...)` calls in `CopyAsPath.ps1` |

## Security and privacy

- No network access.
- No telemetry.
- No file content is read.
- Only the selected path strings are written to the clipboard.

## License

[MIT](LICENSE)
