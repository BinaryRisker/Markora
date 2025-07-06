import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'document.g.dart';

/// 文档类型枚举
@HiveType(typeId: 2)
enum DocumentType {
  @HiveField(0)
  markdown('md', '普通Markdown文档'),
  @HiveField(1)
  notebook('mdnb', 'Markora笔记本'),
  @HiveField(2)
  text('txt', '纯文本文档'),
  @HiveField(3)
  html('html', 'HTML文档');

  const DocumentType(this.extension, this.description);
  
  final String extension;
  final String description;
}

/// 文档实体类
@HiveType(typeId: 3)
class Document extends Equatable {
  const Document({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.filePath,
    this.tags = const [],
    this.isFavorite = false,
    this.isReadOnly = false,
  });

  /// 文档唯一标识
  @HiveField(0)
  final String id;
  
  /// 文档标题
  @HiveField(1)
  final String title;
  
  /// 文档内容（Markdown格式）
  @HiveField(2)
  final String content;
  
  /// 文档类型
  @HiveField(3)
  final DocumentType type;
  
  /// 文件路径（本地文件）
  @HiveField(4)
  final String? filePath;
  
  /// 创建时间
  @HiveField(5)
  final DateTime createdAt;
  
  /// 更新时间
  @HiveField(6)
  final DateTime updatedAt;
  
  /// 标签列表
  @HiveField(7)
  final List<String> tags;
  
  /// 是否收藏
  @HiveField(8)
  final bool isFavorite;
  
  /// 是否只读
  @HiveField(9)
  final bool isReadOnly;

  /// 复制并更新文档
  Document copyWith({
    String? id,
    String? title,
    String? content,
    DocumentType? type,
    String? filePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isFavorite,
    bool? isReadOnly,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        type,
        filePath,
        createdAt,
        updatedAt,
        tags,
        isFavorite,
        isReadOnly,
      ];
}

/// 文档元数据（用于文档列表显示）
class DocumentMetadata extends Equatable {
  const DocumentMetadata({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.filePath,
    this.tags = const [],
    this.isFavorite = false,
    this.isReadOnly = false,
    this.wordCount = 0,
  });

  final String id;
  final String title;
  final DocumentType type;
  final String? filePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isFavorite;
  final bool isReadOnly;
  
  /// 字数统计
  final int wordCount;

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        filePath,
        createdAt,
        updatedAt,
        tags,
        isFavorite,
        isReadOnly,
        wordCount,
      ];
} 