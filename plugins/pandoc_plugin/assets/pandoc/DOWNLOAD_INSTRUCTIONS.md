# Pandoc 可执行文件下载说明

## 必需步骤
为了使 Pandoc 插件正常工作，您需要下载对应平台的 Pandoc 可执行文件。

## Windows 平台
1. 访问 https://github.com/jgm/pandoc/releases/download/3.1.9/pandoc-3.1.9-windows-x86_64.zip
2. 下载并解压缩文件
3. 将 `pandoc.exe` 文件放置到 `plugins/pandoc_plugin/assets/pandoc/windows/` 目录下

## macOS 平台
1. 访问 https://github.com/jgm/pandoc/releases/download/3.1.9/pandoc-3.1.9-macOS.zip
2. 下载并解压缩文件
3. 将 `pandoc` 文件放置到 `plugins/pandoc_plugin/assets/pandoc/macos/` 目录下

## Linux 平台
1. 访问 https://github.com/jgm/pandoc/releases/download/3.1.9/pandoc-3.1.9-linux-amd64.tar.gz
2. 下载并解压缩文件
3. 将 `pandoc` 文件放置到 `plugins/pandoc_plugin/assets/pandoc/linux/` 目录下

## 验证安装
安装完成后，插件会自动检测可执行文件并启用导入导出功能。

## 注意事项
- 确保可执行文件具有执行权限
- 文件名必须为 `pandoc.exe`（Windows）或 `pandoc`（macOS/Linux）
- 版本必须为 3.1.9 或兼容版本 