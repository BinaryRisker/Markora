# Pandoc Plugin Assets

This directory contains the platform-specific Pandoc executables for the Pandoc plugin.

## Directory Structure

```
assets/pandoc/
├── windows/
│   └── pandoc.exe          # Windows platform executable
├── macos/
│   └── pandoc              # macOS platform executable
├── linux/
│   └── pandoc              # Linux platform executable
└── README.md               # This file
```

## Getting Pandoc Executables

### Method 1: Download from Official Releases

1. Visit [Pandoc Releases](https://github.com/jgm/pandoc/releases)
2. Download the appropriate version for your platform:
   - Windows: `pandoc-x.x.x-windows-x86_64.zip`
   - macOS: `pandoc-x.x.x-macOS.zip`
   - Linux: `pandoc-x.x.x-linux-amd64.tar.gz`
3. Extract and place the executable in the corresponding directory

### Method 2: Use System Installation

If you have Pandoc installed system-wide, the plugin will automatically detect and use it as a fallback.

## Recommended Version

Use Pandoc 3.1.9 or newer for best compatibility.

## File Sizes

Note that Pandoc executables are typically 30-50MB in size. Consider the impact on your application's distribution size.

## License

Pandoc is licensed under GPL v2+. Ensure compliance with license requirements when distributing. 