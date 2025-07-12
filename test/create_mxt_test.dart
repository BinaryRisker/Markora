import 'package:flutter_test/flutter_test.dart';
import '../lib/create_mxt_package.dart';

void main() {
  test('创建Pandoc插件MXT包', () async {
    // 调用MXT包创建工具
    await MxtPackageCreator.createPandocPluginPackage();
  });
} 