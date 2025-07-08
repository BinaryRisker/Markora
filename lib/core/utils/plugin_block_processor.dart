import 'package:flutter/widgets.dart';
import '../../features/plugins/domain/plugin_implementations.dart';
import '../../main.dart';
import 'markdown_block_parser.dart';

/// Plugin block processor for handling plugin syntax in markdown blocks
class PluginBlockProcessor {
  /// Check if content contains plugin syntax
  static bool containsPluginSyntax(String content) {
    try {
      final syntaxRegistry = globalSyntaxRegistry;
      final blockRules = syntaxRegistry.blockSyntaxRules;
      
      for (final rule in blockRules.values) {
        if (rule.pattern.hasMatch(content)) {
          return true;
        }
      }
      
      final inlineRules = syntaxRegistry.inlineSyntaxRules;
      for (final rule in inlineRules.values) {
        if (rule.pattern.hasMatch(content)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // If plugin system is not available, fall back to basic patterns
      return _hasBasicPluginPatterns(content);
    }
  }

  /// Check if line starts a plugin block
  static bool startsPluginBlock(String line) {
    try {
      final syntaxRegistry = globalSyntaxRegistry;
      final blockRules = syntaxRegistry.blockSyntaxRules;
      
      for (final rule in blockRules.values) {
        final match = rule.pattern.firstMatch(line);
        if (match != null && match.start == 0) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // Fall back to basic patterns
      return _hasBasicPluginPatterns(line);
    }
  }

  /// Process plugin syntax in a block and return widgets
  static List<PluginElement> processPluginBlock(MarkdownBlock block) {
    final elements = <PluginElement>[];
    
    try {
      final syntaxRegistry = globalSyntaxRegistry;
      final blockRules = syntaxRegistry.blockSyntaxRules;
      
      // Process block syntax rules
      for (final rule in blockRules.values) {
        final matches = rule.pattern.allMatches(block.content);
        
        for (final match in matches) {
          try {
            final widget = rule.builder(match.group(0)!);
            elements.add(PluginElement(
              name: rule.name,
              startIndex: match.start,
              endIndex: match.end,
              content: match.group(0)!,
              widget: widget,
              isBlock: true,
            ));
          } catch (e) {
            print('Error building plugin widget for ${rule.name}: $e');
          }
        }
      }
      
      // Process inline syntax rules
      final inlineRules = syntaxRegistry.inlineSyntaxRules;
      for (final rule in inlineRules.values) {
        final matches = rule.pattern.allMatches(block.content);
        
        for (final match in matches) {
          try {
            final widget = rule.builder(match.group(0)!);
            elements.add(PluginElement(
              name: rule.name,
              startIndex: match.start,
              endIndex: match.end,
              content: match.group(0)!,
              widget: widget,
              isBlock: false,
            ));
          } catch (e) {
            print('Error building plugin widget for ${rule.name}: $e');
          }
        }
      }
      
    } catch (e) {
      print('Error processing plugin syntax: $e');
    }
    
    // Sort by position
    elements.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    return elements;
  }

  /// Parse multi-line plugin block
  static MarkdownBlock? parseMultiLinePlugin(List<String> lines, int startLine) {
    try {
      final syntaxRegistry = globalSyntaxRegistry;
      final blockRules = syntaxRegistry.blockSyntaxRules;
      
      final firstLine = lines[startLine];
      
      for (final rule in blockRules.values) {
        final match = rule.pattern.firstMatch(firstLine);
        if (match != null && match.start == 0) {
          // Check if this is a multi-line plugin pattern
          if (_isMultiLinePattern(rule.pattern)) {
            return _parseMultiLinePluginBlock(lines, startLine, rule);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check basic plugin patterns (fallback)
  static bool _hasBasicPluginPatterns(String content) {
    return content.contains('{{') || 
           content.contains('[[') || 
           content.startsWith(':::') ||
           content.contains('```mermaid') ||
           content.contains('```chart');
  }

  /// Check if pattern is for multi-line content
  static bool _isMultiLinePattern(RegExp pattern) {
    final patternStr = pattern.pattern;
    return patternStr.contains('\\n') || 
           patternStr.contains('.*?') ||
           patternStr.contains('.+?') ||
           pattern.isMultiLine ||
           pattern.isDotAll;
  }

  /// Parse multi-line plugin block
  static MarkdownBlock _parseMultiLinePluginBlock(
    List<String> lines, 
    int startLine, 
    BlockSyntaxRule rule,
  ) {
    // For multi-line patterns, we need to find the end
    int endLine = startLine;
    String content = lines[startLine];
    
    // Simple heuristic: look for closing patterns
    final patternStr = rule.pattern.pattern;
    if (patternStr.contains('```')) {
      // Code block style plugin
      endLine = startLine + 1;
      while (endLine < lines.length && !lines[endLine].trim().startsWith('```')) {
        endLine++;
      }
      if (endLine < lines.length) {
        content = lines.sublist(startLine, endLine + 1).join('\n');
      }
    } else if (patternStr.contains(':::')) {
      // Container style plugin
      endLine = startLine + 1;
      while (endLine < lines.length && !lines[endLine].trim().startsWith(':::')) {
        endLine++;
      }
      if (endLine < lines.length) {
        content = lines.sublist(startLine, endLine + 1).join('\n');
      }
    } else {
      // Single line plugin
      content = lines[startLine];
    }
    
    return MarkdownBlock(
      type: MarkdownBlockType.plugin,
      content: content,
      startLine: startLine,
      endLine: endLine,
      hash: MarkdownBlock.generateHash(content),
      metadata: {'pluginRule': rule.name},
    );
  }

  /// Get all registered plugin patterns (for debugging)
  static List<String> getRegisteredPatterns() {
    try {
      final syntaxRegistry = globalSyntaxRegistry;
      final patterns = <String>[];
      
      for (final rule in syntaxRegistry.blockSyntaxRules.values) {
        patterns.add('Block: ${rule.name} -> ${rule.pattern.pattern}');
      }
      
      for (final rule in syntaxRegistry.inlineSyntaxRules.values) {
        patterns.add('Inline: ${rule.name} -> ${rule.pattern.pattern}');
      }
      
      return patterns;
    } catch (e) {
      return ['Error: Plugin system not available'];
    }
  }
}

/// Plugin element in markdown content
class PluginElement {
  const PluginElement({
    required this.name,
    required this.startIndex,
    required this.endIndex,
    required this.content,
    required this.widget,
    required this.isBlock,
  });

  /// Plugin rule name
  final String name;
  
  /// Start position in content
  final int startIndex;
  
  /// End position in content
  final int endIndex;
  
  /// Original content
  final String content;
  
  /// Rendered widget
  final Widget widget;
  
  /// Whether this is a block-level plugin
  final bool isBlock;

  @override
  String toString() {
    return 'PluginElement(name: $name, range: $startIndex-$endIndex, isBlock: $isBlock)';
  }
} 