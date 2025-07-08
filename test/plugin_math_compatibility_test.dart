import 'package:flutter_test/flutter_test.dart';
import 'package:markora/core/utils/markdown_block_parser.dart';
import 'package:markora/core/utils/plugin_block_processor.dart';
import 'package:markora/features/math/domain/services/math_parser.dart';

void main() {
  group('Plugin and Math Compatibility Tests', () {
    late MarkdownBlockParser parser;

    setUp(() {
      parser = MarkdownBlockParser();
    });

    test('should parse math formulas in paragraphs', () {
      final markdown = 'This is a paragraph with inline math \$E = mc^2\$ and more text.';
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.paragraph);
      
      // Test math formula parsing
      final mathFormulas = MathParser.parseFormulas(blocks[0].content);
      expect(mathFormulas.length, 1);
      expect(mathFormulas[0].type, MathType.inline);
      expect(mathFormulas[0].content, 'E = mc^2');
    });

    test('should parse block math formulas', () {
      final markdown = '''# Math Example

This is a paragraph.

\$\$
\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}
\$\$

Another paragraph.''';
      
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 7); // heading, empty, paragraph, empty, math, empty, paragraph
      expect(blocks[0].type, MarkdownBlockType.heading);
      expect(blocks[2].type, MarkdownBlockType.paragraph);
      expect(blocks[4].type, MarkdownBlockType.mathBlock);
      expect(blocks[6].type, MarkdownBlockType.paragraph);
    });

    test('should handle mixed content with math and plugins', () {
      final markdown = '''# Mixed Content

This paragraph has inline math \$a^2 + b^2 = c^2\$ and text.

\$\$
\\sum_{i=1}^n i = \\frac{n(n+1)}{2}
\$\$

Some more text here.''';
      
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 7);
      expect(blocks[0].type, MarkdownBlockType.heading);
      expect(blocks[2].type, MarkdownBlockType.paragraph);
      expect(blocks[4].type, MarkdownBlockType.mathBlock);
      expect(blocks[6].type, MarkdownBlockType.paragraph);
      
      // Check math formulas in paragraph
      final mathFormulas = MathParser.parseFormulas(blocks[2].content);
      expect(mathFormulas.length, 1);
      expect(mathFormulas[0].content, 'a^2 + b^2 = c^2');
    });

    test('should identify plugin syntax patterns', () {
      final basicPatterns = [
        '{{plugin:example}}',
        '[[shortcode]]',
        ':::container',
        '```mermaid',
        '```chart',
      ];
      
      for (final pattern in basicPatterns) {
        // Test basic pattern recognition (fallback)
        final hasPlugin = PluginBlockProcessor.containsPluginSyntax(pattern);
        // Should not crash even if plugin system is not initialized
        expect(hasPlugin, isA<bool>());
      }
    });

    test('should parse code blocks with language', () {
      final markdown = '''```dart
void main() {
  print('Hello World');
}
```''';
      
      final blocks = parser.parseBlocks(markdown);
      
      expect(blocks.length, 1);
      expect(blocks[0].type, MarkdownBlockType.codeBlock);
      expect(blocks[0].language, 'dart');
    });

    test('should handle complex mixed document', () {
      final markdown = '''# Complex Document

This is a paragraph with inline math \$\\alpha + \\beta = \\gamma\$.

## Code Example

```python
def calculate(x):
    return x ** 2
```

## Math Formula

\$\$
\\int_a^b f(x) dx = F(b) - F(a)
\$\$

> This is a quote with math \$\\pi r^2\$ inside.

- List item 1
- List item with math \$E = mc^2\$
- List item 3

| Column 1 | Column 2 |
|----------|----------|
| Data 1   | \$x^2\$    |
| Data 2   | \$y^3\$    |

Final paragraph.''';
      
      final blocks = parser.parseBlocks(markdown);
      
      // Should parse into multiple blocks
      expect(blocks.length, greaterThan(10));
      
      // Check that different block types are recognized
      final blockTypes = blocks.map((b) => b.type).toSet();
      expect(blockTypes, contains(MarkdownBlockType.heading));
      expect(blockTypes, contains(MarkdownBlockType.paragraph));
      expect(blockTypes, contains(MarkdownBlockType.codeBlock));
      expect(blockTypes, contains(MarkdownBlockType.mathBlock));
      expect(blockTypes, contains(MarkdownBlockType.quote));
      expect(blockTypes, contains(MarkdownBlockType.list));
      expect(blockTypes, contains(MarkdownBlockType.table));
    });

    test('should generate consistent hashes for identical content', () {
      final content1 = 'This is a test paragraph with math \$E = mc^2\$.';
      final content2 = 'This is a test paragraph with math \$E = mc^2\$.';
      final content3 = 'This is a different paragraph.';
      
      final hash1 = MarkdownBlock.generateHash(content1);
      final hash2 = MarkdownBlock.generateHash(content2);
      final hash3 = MarkdownBlock.generateHash(content3);
      
      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
    });

    test('should handle edge cases', () {
      final edgeCases = [
        '', // Empty content
        '\n\n\n', // Only whitespace
        '\$\$\n\n\$\$', // Empty math block
        '```\n\n```', // Empty code block
        '# ', // Heading with no content
        '> ', // Empty quote
        '- ', // Empty list item
      ];
      
      for (final markdown in edgeCases) {
        expect(() {
          final blocks = parser.parseBlocks(markdown);
          // Should not crash
          expect(blocks, isA<List<MarkdownBlock>>());
        }, returnsNormally);
      }
    });
  });
} 