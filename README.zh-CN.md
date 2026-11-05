# CopyAsPath

在 Windows 资源管理器中复制文件或文件夹的绝对路径。

[English](README.md)

## 功能

- 右键菜单增加 **复制绝对路径**，支持：
  - 文件
  - 文件夹
  - 文件夹空白处（复制当前文件夹路径）
  - 驱动器（复制根目录，例如 `C:\`）
- 在资源管理器中按 `Ctrl+Alt+C`，复制所有选中项的路径。
- 资源管理器中没有选中项时，`Ctrl+Alt+C` 复制当前文件夹路径。
- 按用户安装，无需管理员权限。
- 不联网、不收集遥测、不读取文件内容。

## 系统要求

- Windows 10 或 Windows 11
- Windows PowerShell 5.1（Windows 自带）
- Windows Script Host（`wscript.exe`，Windows 自带）

## 安装

1. 下载本仓库的 ZIP，或克隆仓库。
2. 双击 `Install.cmd`。

安装程序会：

- 将运行文件复制到 `%LOCALAPPDATA%\CopyAsPath`
- 在 `HKCU\Software\Classes` 下添加当前用户的右键菜单项
- 创建开机启动快捷方式，并启动 `Ctrl+Alt+C` 后台监听进程

正常情况下不会弹出管理员权限提示。如果 Windows SmartScreen 对下载的 `.cmd` 文件发出警告，请先检查源码，然后选择“更多信息 > 仍要运行”。

## 使用

右键单击文件、文件夹、驱动器或文件夹空白处，选择 **复制绝对路径**。

在资源管理器中选中一个或多个项目，按 `Ctrl+Alt+C`，路径会按每行一个复制到剪贴板。

## 卸载

双击 `Uninstall.cmd`。

它会删除右键菜单项、开机启动快捷方式、后台快捷键进程，以及 `%LOCALAPPDATA%\CopyAsPath` 下的安装文件。

## Windows 11 右键菜单

Windows 11 会把这类传统注册表菜单项放在 **显示更多选项** 中。也可以按 `Shift+F10`，或使用 `Shift + 右键` 直接打开经典菜单。

Windows 10 会直接在普通右键菜单中显示。

## 实现方式

- `CopyAsPath.ps1` 负责安装和管理当前用户级别的集成。
- 右键菜单通过 `wscript.exe` 调用 `CopyAsPathMenu.vbs`，再由它用隐藏窗口启动 PowerShell，避免直接启动 `powershell.exe` 时控制台窗口闪一下的问题。
- 快捷键监听进程在后台运行，仅在资源管理器位于前台时注册 `Ctrl+Alt+C`。

## 说明

- 右键菜单按单项选择设计；需要复制多个选中项时请使用 `Ctrl+Alt+C`。
- 如果 `Ctrl+Alt+C` 和其他软件冲突，可修改 `CopyAsPath.ps1` 中的 `$hotkeyModifiers` 和 `$hotkeyVirtualKey`，然后重新安装。
- 菜单文字默认为中文；如需修改，请编辑 `CopyAsPath.ps1` 中的 `SetValue('', '复制绝对路径', ...)` 调用。

## 许可证

[MIT](LICENSE)
