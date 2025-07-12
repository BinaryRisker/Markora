# Pandoc 可执行文件资源

本目录用于存储各平台的Pandoc可执行文件，以便插件能够直接使用，无需用户单独安装。

## 目录结构

```
assets/pandoc/
├── windows/
│   └── pandoc.exe          # Windows平台的Pandoc可执行文件
├── macos/
│   └── pandoc              # macOS平台的Pandoc可执行文件
├── linux/
│   └── pandoc              # Linux平台的Pandoc可执行文件
└── README.md               # 本文件
```

## 获取Pandoc可执行文件

### 1. Windows (pandoc.exe)

从Pandoc官方GitHub发布页面下载Windows版本：
- 访问：https://github.com/jgm/pandoc/releases
- 下载：`pandoc-x.x.x-windows-x86_64.zip`
- 解压后将 `pandoc.exe` 复制到 `assets/pandoc/windows/` 目录

### 2. macOS (pandoc)

从Pandoc官方GitHub发布页面下载macOS版本：
- 访问：https://github.com/jgm/pandoc/releases
- 下载：`pandoc-x.x.x-macOS.zip`
- 解压后将 `pandoc` 可执行文件复制到 `assets/pandoc/macos/` 目录

### 3. Linux (pandoc)

从Pandoc官方GitHub发布页面下载Linux版本：
- 访问：https://github.com/jgm/pandoc/releases
- 下载：`pandoc-x.x.x-linux-amd64.tar.gz`
- 解压后将 `pandoc` 可执行文件复制到 `assets/pandoc/linux/` 目录

## 推荐版本

建议使用Pandoc 3.1.9或更高版本，以确保最佳兼容性和功能支持。

## 文件大小注意事项

Pandoc可执行文件通常较大（30-50MB），这会增加应用的整体大小。请确保：
1. 只包含必要的平台版本
2. 考虑使用压缩或延迟加载策略
3. 在发布前测试各平台的功能

## 许可证

请确保遵循Pandoc的许可证要求（GPL v2+）。Pandoc是开源软件，可以自由分发，但需要遵循相应的许可证条款。

## 验证

放置文件后，可以通过以下方式验证：
1. 运行应用
2. 打开插件管理页面
3. 检查Pandoc插件状态
4. 尝试导出功能

如果一切正常，插件应该能够检测到内置的Pandoc并正常工作。 