import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'document.g.dart';

/// Document type enumeration
@HiveType(typeId: 10)
enum DocumentType {
  @HiveField(0)
  markdown('md', 'Regular Markdown document'),
  @HiveField(1)
  notebook('mdnb', 'Markora notebook'),
  @HiveField(2)
  text('txt', 'Plain text document'),
  @HiveField(3)
  html('html', 'HTML document');

  const DocumentType(this.extension, this.description);
  
  final String extension;
  final String description;
}

/// Document entity class
@HiveType(typeId: 11)
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

  /// Document unique identifier
  @HiveField(0)
  final String id;
  
  /// Document title
  @HiveField(1)
  final String title;
  
  /// Document content (Markdown format)
  @HiveField(2)
  final String content;
  
  /// Document type
  @HiveField(3)
  final DocumentType type;
  
  /// File path (local file)
  @HiveField(4)
  final String? filePath;
  
  /// Creation time
  @HiveField(5)
  final DateTime createdAt;
  
  /// Update time
  @HiveField(6)
  final DateTime updatedAt;
  
  /// Tag list
  @HiveField(7)
  final List<String> tags;
  
  /// Whether favorited
  @HiveField(8)
  final bool isFavorite;
  
  /// Whether read-only
  @HiveField(9)
  final bool isReadOnly;

  /// Copy and update document
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

/// Document metadata (for document list display)
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
  
  /// Word count
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