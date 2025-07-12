# Pandoc 集成指南

## 概述

Markora 编辑器现已集成内置的 Pandoc 支持，用户无需单独安装 Pandoc 即可使用强大的文档转换功能。

## 🚀 快速开始

### 方法一：使用自动下载脚本（推荐）

```bash
# 下载所有平台的 Pandoc 可执行文件
dart run scripts/download_pandoc.dart

# 或者只下载特定平台
dart run scripts/download_pandoc.dart windows
dart run scripts/download_pandoc.dart macos
dart run scripts/download_pandoc.dart linux
```

### 方法二：手动下载

1. 访问 [Pandoc 官方发布页面](https://github.com/jgm/pandoc/releases)
2. 下载对应平台的可执行文件：
   - Windows: `pandoc-3.1.9-windows-x86_64.zip`
   - macOS: `pandoc-3.1.9-macOS.zip`
   - Linux: `pandoc-3.1.9-linux-amd64.tar.gz`
3. 解压并将可执行文件放置到对应目录：
   - Windows: `assets/pandoc/windows/pandoc.exe`
   - macOS: `assets/pandoc/macos/pandoc`
   - Linux: `assets/pandoc/linux/pandoc`

## 📁 目录结构

```
assets/pandoc/
├── windows/
│   └── pandoc.exe          # Windows 平台
├── macos/
│   └── pandoc              # macOS 平台
├── linux/
│   └── pandoc              # Linux 平台
└── README.md
```

## 🔧 功能特性

### 支持的导出格式

- **文档格式**: PDF, HTML, DOCX, ODT, RTF
- **电子书格式**: EPUB, MOBI
- **标记语言**: LaTeX, Markdown, reStructuredText, AsciiDoc
- **其他格式**: TXT, JSON, XML, OPML, MediaWiki, Textile

### 支持的导入格式

- **文档格式**: HTML, DOCX, ODT, RTF
- **电子书格式**: EPUB
- **标记语言**: LaTeX, reStructuredText, AsciiDoc
- **其他格式**: TXT, JSON, XML, OPML, MediaWiki, Textile

## 🎯 使用方法

### 1. 导出文档

1. 在编辑器中编写 Markdown 内容
2. 点击工具栏的 **导出** 按钮
3. 选择目标格式（PDF、HTML、DOCX 等）
4. 选择保存位置
5. 点击 **导出** 完成

### 2. 导入文档

1. 点击菜单栏的 **文件** → **导入**
2. 选择要导入的文件
3. 系统自动检测格式并转换为 Markdown
4. 转换后的内容将显示在编辑器中

### 3. 插件管理

- 打开 **设置** → **插件管理**
- 可以看到 **Pandoc Export** 插件
- 支持启用/禁用插件功能

## ⚙️ 技术实现

### 资源管理

- **PandocAssetManager**: 管理内置 Pandoc 资源
- **自动提取**: 首次使用时自动提取到应用数据目录
- **权限设置**: 自动设置 Unix 系统的执行权限
- **版本检测**: 支持版本检测和验证

### 优先级策略

1. **内置版本优先**: 优先使用应用内置的 Pandoc
2. **系统版本回退**: 如果内置版本不可用，尝试系统安装的版本
3. **友好提示**: 如果都不可用，显示友好的错误信息

### 平台支持

- ✅ **Windows**: 完全支持
- ✅ **macOS**: 完全支持  
- ✅ **Linux**: 完全支持
- ❌ **Web**: 不支持（显示友好提示）
- ❌ **移动端**: 不支持（显示友好提示）

## 🔍 故障排除

### 问题：插件不显示

**解决方案**：
1. 确保已下载对应平台的 Pandoc 可执行文件
2. 检查文件路径是否正确
3. 重启应用

### 问题：导出失败

**解决方案**：
1. 检查 Pandoc 是否正确安装
2. 确保目标目录有写入权限
3. 检查 Markdown 内容是否有语法错误

### 问题：权限错误（Unix 系统）

**解决方案**：
```bash
# 手动设置执行权限
chmod +x assets/pandoc/macos/pandoc
chmod +x assets/pandoc/linux/pandoc
```

## 📊 性能优化

### 文件大小

- Pandoc 可执行文件约 30-50MB
- 仅在首次使用时提取到本地
- 支持增量更新

### 内存使用

- 资源管理器使用单例模式
- 自动清理临时文件
- 延迟加载机制

## 🔐 安全考虑

### 许可证合规

- Pandoc 使用 GPL v2+ 许可证
- 符合开源软件分发要求
- 保留原始许可证信息

### 文件安全

- 临时文件自动清理
- 权限最小化原则
- 路径验证和清理

## 🚀 未来计划

### 功能扩展

- [ ] 支持更多导出格式
- [ ] 自定义导出模板
- [ ] 批量转换功能
- [ ] 云端转换服务

### 性能优化

- [ ] 压缩资源文件
- [ ] 增量下载机制
- [ ] 缓存优化策略

## 📞 技术支持

如果您在使用过程中遇到问题，请：

1. 查看控制台日志输出
2. 检查 GitHub Issues
3. 提交详细的错误报告

---

**注意**: 首次使用时，应用会自动提取 Pandoc 资源，这可能需要几秒钟时间。请耐心等待。 