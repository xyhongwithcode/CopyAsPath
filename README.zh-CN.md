<div align="center">

# CopyAsPath

**从 Windows 资源管理器右键复制文件或文件夹的绝对路径。**

[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white)](https://github.com/xyhongwithcode/CopyAsPath)
[![License](https://img.shields.io/github/license/xyhongwithcode/CopyAsPath?style=flat-square)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/xyhongwithcode/CopyAsPath?style=flat-square)](https://github.com/xyhongwithcode/CopyAsPath/releases)

[English](README.md)

</div>

## 为什么需要 CopyAsPath？

Windows 10 自带的路径复制方式是 **Shift + 右键 → 复制为路径**。CopyAsPath 把常用操作做得更直接：

- 右键菜单直接提供 **复制绝对路径**。
- 资源管理器快捷键：<kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd>。
- 支持文件、文件夹、文件夹空白处和驱动器。
- 按当前用户安装，无需管理员权限。

> **Windows 11 说明：** Windows 11 已自带 <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd>（22463 及以上版本）以及右键菜单中的 **复制为路径**。本项目主要面向 Windows 10，但在 Windows 11 上也可以使用，用于统一经典菜单入口和 <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> 快捷键。

## 功能

| 功能 | 说明 |
| --- | --- |
| 右键菜单 | 右键文件、文件夹、文件夹空白处或驱动器，选择 **复制绝对路径** |
| 快捷键 | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> 复制所有选中路径 |
| 文件夹回退 | 没有选中项时，快捷键复制当前文件夹路径 |
| 多选 | 快捷键按每行一个路径复制 |
| 无控制台闪窗 | 右键菜单通过隐藏的 WScript 启动器调用 |
| 按用户安装 | 只写入 `HKCU` 和 `%LOCALAPPDATA%` |

## 系统要求

- Windows 10（主要目标）或 Windows 11
- Windows PowerShell 5.1（Windows 自带）
- Windows Script Host（`wscript.exe`，Windows 自带）

## 安装

### 方式一：下载 ZIP

1. 下载最新发布版，或点击 **Code → Download ZIP**。
2. 解压压缩包。
3. 双击 `Install.cmd`。

### 方式二：克隆仓库

```powershell
git clone https://github.com/xyhongwithcode/CopyAsPath.git
cd CopyAsPath
.\Install.cmd
```

正常情况下不会弹出管理员权限提示。如果 SmartScreen 对下载的 `.cmd` 文件发出警告，请先检查源码，然后选择 **更多信息 → 仍要运行**。

## 使用

### 右键菜单

右键单击文件、文件夹、文件夹空白处或驱动器，选择 **复制绝对路径**。

- Windows 10：直接显示在普通右键菜单中。
- Windows 11：位于 **显示更多选项** 中，也可以按 <kbd>Shift</kbd> + <kbd>F10</kbd> 打开经典菜单。

### 快捷键

| 操作 | 结果 |
| --- | --- |
| 选中项目后按 <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> | 复制所有选中路径，每行一个 |
| 没有选中项时按 <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd> | 复制当前文件夹路径 |

快捷键仅在资源管理器位于前台时注册。

## 安装程序会修改什么

| 项目 | 位置 |
| --- | --- |
| 运行文件 | `%LOCALAPPDATA%\CopyAsPath` |
| 右键菜单项 | `HKCU\Software\Classes\*\shell\CopyAsPath`<br>`HKCU\Software\Classes\Directory\shell\CopyAsPath`<br>`HKCU\Software\Classes\Directory\Background\shell\CopyAsPath`<br>`HKCU\Software\Classes\Drive\shell\CopyAsPath` |
| 开机启动快捷方式 | `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CopyAsPath.lnk` |
| 后台进程 | 隐藏的 PowerShell 快捷键监听进程 |

## 卸载

双击 `Uninstall.cmd`，或运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\CopyAsPath.ps1 -Uninstall
```

它会删除右键菜单项、开机启动快捷方式、后台进程和安装文件。

## 实现方式

1. `CopyAsPath.ps1` 将自身和生成的 VBS 启动器复制到 `%LOCALAPPDATA%\CopyAsPath`。
2. 右键菜单通过 `wscript.exe` 运行 VBS 启动器。
3. 启动器使用 `SW_HIDE` 启动 PowerShell，因此不会闪控制台窗口。
4. 快捷键监听进程仅在资源管理器处于前台时注册 <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd>。

## 常见问题

| 问题 | 解决方法 |
| --- | --- |
| Windows 11 中看不到菜单项 | 使用 **显示更多选项** 或 <kbd>Shift</kbd> + <kbd>F10</kbd>；传统注册表菜单项不会显示在精简菜单中 |
| 快捷键没有反应 | 确认资源管理器处于前台；`Ctrl` + `Alt` + `C` 可能被其他软件占用 |
| 想换一个快捷键 | 修改 `CopyAsPath.ps1` 中的 `$hotkeyModifiers` 和 `$hotkeyVirtualKey`，然后重新安装 |
| 想改菜单文字 | 修改 `CopyAsPath.ps1` 中的 `SetValue('', '复制绝对路径', ...)` 调用 |

## 安全与隐私

- 不联网。
- 不收集遥测。
- 不读取文件内容。
- 只将选中的路径字符串写入剪贴板。

## 许可证

[MIT](LICENSE)
