/// 导出格式枚举
enum ExportFormat {
  pdf('PDF', 'pdf', '便携式文档格式'),
  html('HTML', 'html', '网页格式'),
  docx('Word', 'docx', 'Microsoft Word文档'),
  png('PNG', 'png', '便携式网络图形'),
  jpeg('JPEG', 'jpeg', 'JPEG图像格式');

  const ExportFormat(this.displayName, this.extension, this.description);
  
  final String displayName;
  final String extension;
  final String description;
}

/// PDF导出设置
class PdfExportSettings {
  final String pageSize; // A4, A3, Letter等
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final bool includeTableOfContents;
  final bool includePageNumbers;
  final bool includeFooter;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final bool enableSyntaxHighlighting;
  final bool includeCodeLineNumbers;

  const PdfExportSettings({
    this.pageSize = 'A4',
    this.marginTop = 72.0, // 1英寸 = 72点
    this.marginBottom = 72.0,
    this.marginLeft = 72.0,
    this.marginRight = 72.0,
    this.includeTableOfContents = true,
    this.includePageNumbers = true,
    this.includeFooter = false,
    this.fontFamily = 'Times New Roman',
    this.fontSize = 12.0,
    this.lineHeight = 1.5,
    this.enableSyntaxHighlighting = true,
    this.includeCodeLineNumbers = false,
  });

  PdfExportSettings copyWith({
    String? pageSize,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    bool? includeTableOfContents,
    bool? includePageNumbers,
    bool? includeFooter,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    bool? enableSyntaxHighlighting,
    bool? includeCodeLineNumbers,
  }) {
    return PdfExportSettings(
      pageSize: pageSize ?? this.pageSize,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      includeTableOfContents: includeTableOfContents ?? this.includeTableOfContents,
      includePageNumbers: includePageNumbers ?? this.includePageNumbers,
      includeFooter: includeFooter ?? this.includeFooter,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      enableSyntaxHighlighting: enableSyntaxHighlighting ?? this.enableSyntaxHighlighting,
      includeCodeLineNumbers: includeCodeLineNumbers ?? this.includeCodeLineNumbers,
    );
  }
}

/// HTML导出设置
class HtmlExportSettings {
  final String theme; // GitHub, Typora, Custom等
  final bool includeInlineCss;
  final bool includeTableOfContents;
  final bool enableSyntaxHighlighting;
  final bool includeCodeLineNumbers;
  final bool enableMathJax;
  final bool enableMermaid;
  final bool responsiveDesign;
  final String customCss;
  final String title;
  final String author;
  final String description;

  const HtmlExportSettings({
    this.theme = 'GitHub',
    this.includeInlineCss = true,
    this.includeTableOfContents = true,
    this.enableSyntaxHighlighting = true,
    this.includeCodeLineNumbers = false,
    this.enableMathJax = true,
    this.enableMermaid = true,
    this.responsiveDesign = true,
    this.customCss = '',
    this.title = '',
    this.author = '',
    this.description = '',
  });

  HtmlExportSettings copyWith({
    String? theme,
    bool? includeInlineCss,
    bool? includeTableOfContents,
    bool? enableSyntaxHighlighting,
    bool? includeCodeLineNumbers,
    bool? enableMathJax,
    bool? enableMermaid,
    bool? responsiveDesign,
    String? customCss,
    String? title,
    String? author,
    String? description,
  }) {
    return HtmlExportSettings(
      theme: theme ?? this.theme,
      includeInlineCss: includeInlineCss ?? this.includeInlineCss,
      includeTableOfContents: includeTableOfContents ?? this.includeTableOfContents,
      enableSyntaxHighlighting: enableSyntaxHighlighting ?? this.enableSyntaxHighlighting,
      includeCodeLineNumbers: includeCodeLineNumbers ?? this.includeCodeLineNumbers,
      enableMathJax: enableMathJax ?? this.enableMathJax,
      enableMermaid: enableMermaid ?? this.enableMermaid,
      responsiveDesign: responsiveDesign ?? this.responsiveDesign,
      customCss: customCss ?? this.customCss,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
    );
  }
}

/// 图像导出设置
class ImageExportSettings {
  final int width;
  final int height;
  final double scale; // 缩放比例
  final int quality; // JPEG质量 (1-100)
  final bool transparentBackground; // PNG透明背景
  final String backgroundColor;

  const ImageExportSettings({
    this.width = 1200,
    this.height = 800,
    this.scale = 1.0,
    this.quality = 90,
    this.transparentBackground = false,
    this.backgroundColor = '#FFFFFF',
  });

  ImageExportSettings copyWith({
    int? width,
    int? height,
    double? scale,
    int? quality,
    bool? transparentBackground,
    String? backgroundColor,
  }) {
    return ImageExportSettings(
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
      quality: quality ?? this.quality,
      transparentBackground: transparentBackground ?? this.transparentBackground,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

/// 综合导出设置
class ExportSettings {
  final ExportFormat format;
  final String outputPath;
  final String fileName;
  final bool openAfterExport;
  final PdfExportSettings pdfSettings;
  final HtmlExportSettings htmlSettings;
  final ImageExportSettings imageSettings;

  const ExportSettings({
    required this.format,
    required this.outputPath,
    required this.fileName,
    this.openAfterExport = true,
    this.pdfSettings = const PdfExportSettings(),
    this.htmlSettings = const HtmlExportSettings(),
    this.imageSettings = const ImageExportSettings(),
  });

  ExportSettings copyWith({
    ExportFormat? format,
    String? outputPath,
    String? fileName,
    bool? openAfterExport,
    PdfExportSettings? pdfSettings,
    HtmlExportSettings? htmlSettings,
    ImageExportSettings? imageSettings,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      outputPath: outputPath ?? this.outputPath,
      fileName: fileName ?? this.fileName,
      openAfterExport: openAfterExport ?? this.openAfterExport,
      pdfSettings: pdfSettings ?? this.pdfSettings,
      htmlSettings: htmlSettings ?? this.htmlSettings,
      imageSettings: imageSettings ?? this.imageSettings,
    );
  }

  /// 获取完整文件路径
  String get fullPath {
    final extension = format.extension;
    final name = fileName.endsWith('.$extension') ? fileName : '$fileName.$extension';
    return '$outputPath/$name';
  }
}

/// 导出进度信息
class ExportProgress {
  final double progress; // 0.0 - 1.0
  final String status;
  final String? currentStep;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;

  const ExportProgress({
    required this.progress,
    required this.status,
    this.currentStep,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });

  ExportProgress copyWith({
    double? progress,
    String? status,
    String? currentStep,
    bool? isCompleted,
    bool? hasError,
    String? errorMessage,
  }) {
    return ExportProgress(
      progress: progress ?? this.progress,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 导出结果
class ExportResult {
  final bool success;
  final String? outputPath;
  final String? errorMessage;
  final int? fileSizeBytes;
  final Duration? duration;

  const ExportResult({
    required this.success,
    this.outputPath,
    this.errorMessage,
    this.fileSizeBytes,
    this.duration,
  });

  factory ExportResult.success(String outputPath, {int? fileSizeBytes, Duration? duration}) {
    return ExportResult(
      success: true,
      outputPath: outputPath,
      fileSizeBytes: fileSizeBytes,
      duration: duration,
    );
  }

  factory ExportResult.failure(String errorMessage) {
    return ExportResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
} 