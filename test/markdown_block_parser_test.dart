import 'package:flutter_test/flutter_test.dart';
import 'package:markora/core/utils/markdown_block_parser.dart';

void main() {
  group('MarkdownBlockParser Tests', () {
    late MarkdownBlockParser parser;

    setUp(() {
      parser = MarkdownBlockParser();
    });

    test('should parse empty markdown', () {
      final blocks = parser.parseBlocks('');
      expect(blocks, isEmpty);
    });

    test('should parse simple paragraph', () {
      final markdown = 'This is a simple paragraph.';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.paragraph);
      expect(blocks[0].content, markdown);
      expect(blocks[0].startLine, 0);
      expect(blocks[0].endLine, 0);
    });

    test('should parse heading', () {
      final markdown = '# This is a heading';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.heading);
      expect(blocks[0].content, markdown);
      expect(blocks[0].level, 1);
    });

    test('should parse code block', () {
      final markdown = '''```dart
void main() {
  print('Hello World');
}
```''';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.codeBlock);
      expect(blocks[0].language, 'dart');
      expect(blocks[0].content, markdown);
    });

    test('should parse math block', () {
      final markdown = '''\$\$
E = mc^2
\$\$''';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.mathBlock);
      expect(blocks[0].content, markdown);
    });

    test('should parse quote block', () {
      final markdown = '''> This is a quote
> Second line of quote''';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.quote);
      expect(blocks[0].content, markdown);
    });

    test('should parse list', () {
      final markdown = '''- Item 1
- Item 2
  - Sub item
- Item 3''';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.list);
      expect(blocks[0].content, markdown);
    });

    test('should parse table', () {
      final markdown = '''| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |''';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.table);
      expect(blocks[0].content, markdown);
    });

    test('should parse horizontal rule', () {
      final markdown = '---';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.horizontalRule);
      expect(blocks[0].content, markdown);
    });

    test('should parse mixed content', () {
      final markdown = '''# Heading

This is a paragraph.

```dart
void main() {}
```

- List item 1
- List item 2

> Quote block

Another paragraph.''';
      
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 9); // heading, empty, paragraph, empty, code, empty, list, quote, paragraph
      expect(blocks[0].type, MarkdownBlockType.heading);
      expect(blocks[1].type, MarkdownBlockType.empty);
      expect(blocks[2].type, MarkdownBlockType.paragraph);
      expect(blocks[3].type, MarkdownBlockType.empty);
      expect(blocks[4].type, MarkdownBlockType.codeBlock);
      expect(blocks[5].type, MarkdownBlockType.empty);
      expect(blocks[6].type, MarkdownBlockType.list);
      expect(blocks[7].type, MarkdownBlockType.quote);
      expect(blocks[8].type, MarkdownBlockType.paragraph);
    });

    test('should generate consistent hashes', () {
      final markdown = 'Test content';
      final blocks1 = parser.parseBlocks(markdown);
      final blocks2 = parser.parseBlocks(markdown);
      
      expect(blocks1[0].hash, blocks2[0].hash);
    });

    test('should generate different hashes for different content', () {
      final blocks1 = parser.parseBlocks('Content 1');
      final blocks2 = parser.parseBlocks('Content 2');
      
      expect(blocks1[0].hash, isNot(blocks2[0].hash));
    });
  });
} 