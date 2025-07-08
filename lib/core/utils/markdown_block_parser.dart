import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'plugin_block_processor.dart';

/// Markdown block types
enum MarkdownBlockType {
  heading,        // # ## ### etc.
  paragraph,      // Normal text
  codeBlock,      // ```...```
  mathBlock,      // $$...$$
  mathInline,     // $...$
  quote,          // > ...
  list,           // - * 1. etc.
  table,          // | ... |
  horizontalRule, // ---
  plugin,         // Plugin syntax
  empty,          // Empty lines
}

/// Represents a markdown block
class MarkdownBlock {
  const MarkdownBlock({
    required this.type,
    required this.content,
    required this.startLine,
    required this.endLine,
    required this.hash,
    this.language,
    this.level,
    this.metadata,
  });

  /// Block type
  final MarkdownBlockType type;
  
  /// Block content
  final String content;
  
  /// Start line number (0-based)
  final int startLine;
  
  /// End line number (0-based)
  final int endLine;
  
  /// Content hash for caching
  final String hash;
  
  /// Language for code blocks
  final String? language;
  
  /// Level for headings (1-6)
  final int? level;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Generate hash from content
  static String generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  @override
  String toString() {
    return 'MarkdownBlock(type: $type, lines: $startLine-$endLine, hash: $hash)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownBlock && other.hash == hash;
  }

  @override
  int get hashCode => hash.hashCode;
}

/// Markdown block parser
class MarkdownBlockParser {
  MarkdownBlockParser();

  /// Parse markdown text into blocks
  List<MarkdownBlock> parseBlocks(String markdown) {
    if (markdown.isEmpty) return [];

    final lines = markdown.split('\n');
    final blocks = <MarkdownBlock>[];
    
    int currentLine = 0;
    
    while (currentLine < lines.length) {
      final block = _parseNextBlock(lines, currentLine);
      if (block != null) {
        blocks.add(block);
        currentLine = block.endLine + 1;
      } else {
        currentLine++;
      }
    }
    
    return blocks;
  }

  /// Parse next block starting from currentLine
  MarkdownBlock? _parseNextBlock(List<String> lines, int startLine) {
    if (startLine >= lines.length) return null;
    
    final line = lines[startLine];
    
    // Empty line
    if (line.trim().isEmpty) {
      return _parseEmptyBlock(lines, startLine);
    }
    
    // Code block
    if (line.trim().startsWith('```')) {
      return _parseCodeBlock(lines, startLine);
    }
    
    // Math block
    if (line.trim().startsWith(r'$$')) {
      return _parseMathBlock(lines, startLine);
    }
    
    // Heading
    if (line.startsWith('#')) {
      return _parseHeading(lines, startLine);
    }
    
    // Quote
    if (line.startsWith('>')) {
      return _parseQuote(lines, startLine);
    }
    
    // List
    if (_isListItem(line)) {
      return _parseList(lines, startLine);
    }
    
    // Table
    if (_isTableRow(line)) {
      return _parseTable(lines, startLine);
    }
    
    // Horizontal rule
    if (_isHorizontalRule(line)) {
      return _parseHorizontalRule(lines, startLine);
    }
    
    // Plugin syntax (check registered patterns)
    if (PluginBlockProcessor.startsPluginBlock(line)) {
      final pluginBlock = PluginBlockProcessor.parseMultiLinePlugin(lines, startLine);
      if (pluginBlock != null) {
        return pluginBlock;
      }
      return _parsePluginBlock(lines, startLine);
    }
    
    // Default: paragraph
    return _parseParagraph(lines, startLine);
  }

  /// Parse empty block
  MarkdownBlock _parseEmptyBlock(List<String> lines, int startLine) {
    int endLine = startLine;
    
    // Find consecutive empty lines
    while (endLine < lines.length && lines[endLine].trim().isEmpty) {
      endLine++;
    }
    endLine--; // Last empty line
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.empty,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse code block
  MarkdownBlock _parseCodeBlock(List<String> lines, int startLine) {
    final firstLine = lines[startLine];
    final language = firstLine.substring(3).trim();
    
    int endLine = startLine + 1;
    
    // Find closing ```
    while (endLine < lines.length && !lines[endLine].trim().startsWith('```')) {
      endLine++;
    }
    
    if (endLine >= lines.length) {
      endLine = lines.length - 1;
    }
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.codeBlock,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
      language: language.isEmpty ? null : language,
    );
  }

  /// Parse math block
  MarkdownBlock _parseMathBlock(List<String> lines, int startLine) {
    int endLine = startLine + 1;
    
    // Find closing $$
    while (endLine < lines.length && !lines[endLine].trim().startsWith(r'$$')) {
      endLine++;
    }
    
    if (endLine >= lines.length) {
      endLine = lines.length - 1;
    }
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.mathBlock,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse heading
  MarkdownBlock _parseHeading(List<String> lines, int startLine) {
    final line = lines[startLine];
    final level = line.indexOf(' ');
    
    return MarkdownBlock(
      type: MarkdownBlockType.heading,
      content: line,
      startLine: startLine,
      endLine: startLine,
      hash: MarkdownBlock.generateHash(line),
      level: level > 0 ? level : 1,
    );
  }

  /// Parse quote
  MarkdownBlock _parseQuote(List<String> lines, int startLine) {
    int endLine = startLine;
    
    // Find consecutive quote lines
    while (endLine < lines.length && 
           (lines[endLine].startsWith('>') || lines[endLine].trim().isEmpty)) {
      endLine++;
    }
    endLine--; // Last quote line
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.quote,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse list
  MarkdownBlock _parseList(List<String> lines, int startLine) {
    int endLine = startLine;
    
    // Find consecutive list items and sub-items
    while (endLine < lines.length) {
      final line = lines[endLine];
      if (line.trim().isEmpty) {
        endLine++;
        continue;
      }
      
      if (_isListItem(line) || _isListContinuation(line)) {
        endLine++;
      } else {
        break;
      }
    }
    endLine--; // Last list line
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.list,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse table
  MarkdownBlock _parseTable(List<String> lines, int startLine) {
    int endLine = startLine;
    
    // Find consecutive table rows
    while (endLine < lines.length && _isTableRow(lines[endLine])) {
      endLine++;
    }
    endLine--; // Last table row
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.table,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse horizontal rule
  MarkdownBlock _parseHorizontalRule(List<String> lines, int startLine) {
    final content = lines[startLine];
    
    return MarkdownBlock(
      type: MarkdownBlockType.horizontalRule,
      content: content,
      startLine: startLine,
      endLine: startLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse plugin block
  MarkdownBlock _parsePluginBlock(List<String> lines, int startLine) {
    // For now, treat as single line. Can be extended for multi-line plugins
    final content = lines[startLine];
    
    return MarkdownBlock(
      type: MarkdownBlockType.plugin,
      content: content,
      startLine: startLine,
      endLine: startLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Parse paragraph
  MarkdownBlock _parseParagraph(List<String> lines, int startLine) {
    int endLine = startLine;
    
    // Find consecutive non-empty lines that don't start special blocks
    while (endLine < lines.length) {
      final line = lines[endLine];
      
      if (line.trim().isEmpty) {
        break;
      }
      
      // Check if this line starts a new block type
      if (endLine > startLine && _startsNewBlock(line)) {
        break;
      }
      
      endLine++;
    }
    endLine--; // Last paragraph line
    
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    
    return MarkdownBlock(
      type: MarkdownBlockType.paragraph,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
    );
  }

  /// Check if line is a list item
  bool _isListItem(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('- ') || 
           trimmed.startsWith('* ') || 
           trimmed.startsWith('+ ') ||
           RegExp(r'^\d+\.\s').hasMatch(trimmed);
  }

  /// Check if line is list continuation (indented)
  bool _isListContinuation(String line) {
    return line.startsWith('  ') || line.startsWith('\t');
  }

  /// Check if line is a table row
  bool _isTableRow(String line) {
    final trimmed = line.trim();
    return trimmed.contains('|') && trimmed.length > 1;
  }

  /// Check if line is horizontal rule
  bool _isHorizontalRule(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('---') || 
           trimmed.startsWith('***') || 
           trimmed.startsWith('___');
  }

  /// Check if line contains plugin syntax
  bool _isPluginSyntax(String line) {
    return PluginBlockProcessor.startsPluginBlock(line);
  }

  /// Check if line starts a new block
  bool _startsNewBlock(String line) {
    return line.startsWith('#') ||
           line.startsWith('>') ||
           line.trim().startsWith('```') ||
           line.trim().startsWith(r'$$') ||
           _isListItem(line) ||
           _isTableRow(line) ||
           _isHorizontalRule(line) ||
           _isPluginSyntax(line);
  }
} 