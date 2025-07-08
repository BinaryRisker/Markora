import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markora/core/utils/markdown_block_parser.dart';
import 'package:markora/core/utils/markdown_block_cache.dart';
import 'package:markora/features/math/domain/services/math_parser.dart';

void main() {
  group('Performance Benchmark Tests', () {
    late MarkdownBlockParser parser;

    setUp(() {
      parser = MarkdownBlockParser();
      markdownBlockCache.clear();
    });

    test('benchmark markdown block parsing performance', () {
      // Generate large markdown document
      final largeMarkdown = _generateLargeMarkdown(1000); // 1000 blocks
      
      final stopwatch = Stopwatch()..start();
      final blocks = parser.parseBlocks(largeMarkdown);
      stopwatch.stop();
      
      print('Parsed ${blocks.length} blocks in ${stopwatch.elapsedMilliseconds}ms');
      print('Average time per block: ${stopwatch.elapsedMilliseconds / blocks.length}ms');
      
      // Performance expectations
      expect(blocks.length, greaterThan(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be under 5 seconds
      expect(stopwatch.elapsedMilliseconds / blocks.length, lessThan(10)); // Under 10ms per block
    });

    test('benchmark cache performance', () {
      final testContent = _generateMixedContent();
      final blocks = parser.parseBlocks(testContent);
      
      // First parse - cache miss
      final stopwatch1 = Stopwatch()..start();
      for (final block in blocks) {
        final cacheKey = 'test_${block.hash}';
        markdownBlockCache.get(cacheKey);
        // Simulate widget creation and caching
        markdownBlockCache.put(cacheKey, _createMockWidget());
      }
      stopwatch1.stop();
      
      // Second parse - cache hit
      final stopwatch2 = Stopwatch()..start();
      for (final block in blocks) {
        final cacheKey = 'test_${block.hash}';
        final cachedWidget = markdownBlockCache.get(cacheKey);
        expect(cachedWidget, isNotNull);
      }
      stopwatch2.stop();
      
      print('Cache miss time: ${stopwatch1.elapsedMicroseconds}μs');
      print('Cache hit time: ${stopwatch2.elapsedMicroseconds}μs');
      print('Cache speedup: ${stopwatch1.elapsedMicroseconds / stopwatch2.elapsedMicroseconds}x');
      
      // Cache should be significantly faster
      expect(stopwatch2.elapsedMicroseconds, lessThan(stopwatch1.elapsedMicroseconds / 2));
      
      // Check cache statistics
      final stats = markdownBlockCache.statistics;
      print('Cache statistics: $stats');
      expect(stats.hitRatio, greaterThan(0.5)); // At least 50% hit ratio
    });

    test('benchmark math formula parsing performance', () {
      final mathContent = _generateMathContent(500); // 500 formulas
      
      final stopwatch = Stopwatch()..start();
      final formulas = MathParser.parseFormulas(mathContent);
      stopwatch.stop();
      
      print('Parsed ${formulas.length} math formulas in ${stopwatch.elapsedMilliseconds}ms');
      print('Average time per formula: ${stopwatch.elapsedMilliseconds / formulas.length}ms');
      
      expect(formulas.length, greaterThan(400));
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds
    });

    test('benchmark large document with mixed content', () {
      final largeDocument = _generateLargeDocumentWithMixedContent(2000);
      
      // Parse blocks
      final parseStopwatch = Stopwatch()..start();
      final blocks = parser.parseBlocks(largeDocument);
      parseStopwatch.stop();
      
      // Simulate rendering with cache
      final renderStopwatch = Stopwatch()..start();
      for (final block in blocks) {
        final cacheKey = 'render_${block.hash}';
        var widget = markdownBlockCache.get(cacheKey);
        if (widget == null) {
          // Simulate widget creation
          widget = _createMockWidget();
          markdownBlockCache.put(cacheKey, widget);
        }
      }
      renderStopwatch.stop();
      
      print('Large document statistics:');
      print('  Total size: ${largeDocument.length} characters');
      print('  Blocks parsed: ${blocks.length}');
      print('  Parse time: ${parseStopwatch.elapsedMilliseconds}ms');
      print('  Render time: ${renderStopwatch.elapsedMilliseconds}ms');
      print('  Total time: ${parseStopwatch.elapsedMilliseconds + renderStopwatch.elapsedMilliseconds}ms');
      
      final totalTime = parseStopwatch.elapsedMilliseconds + renderStopwatch.elapsedMilliseconds;
      expect(totalTime, lessThan(10000)); // Under 10 seconds for 2000 blocks
    });

    test('benchmark cache memory usage', () {
      final testBlocks = <String>[];
      
      // Generate many unique blocks
      for (int i = 0; i < 1000; i++) {
        testBlocks.add('Block content $i with some text to make it realistic.');
      }
      
      // Fill cache
      for (int i = 0; i < testBlocks.length; i++) {
        final cacheKey = 'memory_test_$i';
        markdownBlockCache.put(cacheKey, _createMockWidget());
      }
      
      final memoryUsage = markdownBlockCache.estimatedMemoryUsage;
      final cacheSize = markdownBlockCache.size;
      
      print('Cache memory usage:');
      print('  Cache size: $cacheSize items');
      print('  Estimated memory: ${memoryUsage / 1024}KB');
      print('  Average per item: ${memoryUsage / cacheSize} bytes');
      
      // Memory usage should be reasonable
      expect(memoryUsage, lessThan(50 * 1024 * 1024)); // Under 50MB
      expect(cacheSize, lessThan(1000)); // Cache should have size limits
    });

    test('stress test with very large document', () {
      final veryLargeDocument = _generateLargeDocumentWithMixedContent(5000);
      
      print('Stress test with ${veryLargeDocument.length} character document');
      
      final stopwatch = Stopwatch()..start();
      final blocks = parser.parseBlocks(veryLargeDocument);
      stopwatch.stop();
      
      print('Stress test results:');
      print('  Blocks: ${blocks.length}');
      print('  Time: ${stopwatch.elapsedMilliseconds}ms');
      print('  Characters per second: ${veryLargeDocument.length / (stopwatch.elapsedMilliseconds / 1000)}');
      
      // Should still be reasonably fast
      expect(blocks.length, greaterThan(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Under 30 seconds
    });
  });
}

/// Generate large markdown document for testing
String _generateLargeMarkdown(int numBlocks) {
  final buffer = StringBuffer();
  
  for (int i = 0; i < numBlocks; i++) {
    switch (i % 8) {
      case 0:
        buffer.writeln('# Heading $i');
        break;
      case 1:
        buffer.writeln('This is paragraph $i with some content to make it realistic. '
            'It contains multiple sentences and should be long enough to test parsing performance.');
        break;
      case 2:
        buffer.writeln('```dart');
        buffer.writeln('void function$i() {');
        buffer.writeln('  print("Function $i");');
        buffer.writeln('}');
        buffer.writeln('```');
        break;
      case 3:
        buffer.writeln('\$\$');
        buffer.writeln('f_$i(x) = x^$i + ${i * 2}x + $i');
        buffer.writeln('\$\$');
        break;
      case 4:
        buffer.writeln('> Quote block $i with some quoted content.');
        break;
      case 5:
        buffer.writeln('- List item ${i}a');
        buffer.writeln('- List item ${i}b');
        buffer.writeln('- List item ${i}c');
        break;
      case 6:
        buffer.writeln('| Column A | Column B | Column C |');
        buffer.writeln('|----------|----------|----------|');
        buffer.writeln('| Data ${i}1 | Data ${i}2 | Data ${i}3 |');
        break;
      case 7:
        buffer.writeln('---');
        break;
    }
    buffer.writeln();
  }
  
  return buffer.toString();
}

/// Generate mixed content with math formulas
String _generateMixedContent() {
  return '''# Mixed Content Test

This paragraph contains inline math \$E = mc^2\$ and more text.

\$\$
\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}
\$\$

```python
def calculate(x):
    return x ** 2
```

> Quote with math \$\\pi r^2\$ inside.

- Item with \$\\alpha + \\beta\$
- Another item

| Math | Formula |
|------|---------|
| Area | \$\\pi r^2\$ |
| Volume | \$\\frac{4}{3}\\pi r^3\$ |

Final paragraph.''';
}

/// Generate content with many math formulas
String _generateMathContent(int numFormulas) {
  final buffer = StringBuffer();
  
  for (int i = 0; i < numFormulas; i++) {
    if (i % 2 == 0) {
      buffer.write('Inline formula \$x_$i = ${i * 2}\$ and ');
    } else {
      buffer.writeln('\$\$');
      buffer.writeln('f_$i(x) = x^$i + ${i}x + ${i * 3}');
      buffer.writeln('\$\$');
    }
  }
  
  return buffer.toString();
}

/// Generate large document with mixed content types
String _generateLargeDocumentWithMixedContent(int numSections) {
  final buffer = StringBuffer();
  
  buffer.writeln('# Large Document Test');
  buffer.writeln();
  
  for (int i = 0; i < numSections; i++) {
    buffer.writeln('## Section $i');
    buffer.writeln();
    
    // Add paragraph with math
    buffer.writeln('This is section $i with inline math \$f_$i(x) = x^$i\$ content.');
    buffer.writeln();
    
    // Add code block occasionally
    if (i % 10 == 0) {
      buffer.writeln('```javascript');
      buffer.writeln('function section$i() {');
      buffer.writeln('  return $i * 2;');
      buffer.writeln('}');
      buffer.writeln('```');
      buffer.writeln();
    }
    
    // Add math block occasionally
    if (i % 15 == 0) {
      buffer.writeln('\$\$');
      buffer.writeln('\\sum_{k=1}^{$i} k = \\frac{$i($i+1)}{2}');
      buffer.writeln('\$\$');
      buffer.writeln();
    }
    
    // Add list occasionally
    if (i % 20 == 0) {
      buffer.writeln('- Point ${i}a');
      buffer.writeln('- Point ${i}b with \$\\alpha_$i\$');
      buffer.writeln('- Point ${i}c');
      buffer.writeln();
    }
  }
  
  return buffer.toString();
}

/// Create mock widget for testing
Widget _createMockWidget() {
  return Container(); // Simple mock widget
} 