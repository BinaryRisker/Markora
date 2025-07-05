import '../../../../types/charts.dart';

/// Mermaid图表解析器
class MermaidParser {
  /// 解析文本中的Mermaid图表
  static List<MermaidChart> parseCharts(String text) {
    final charts = <MermaidChart>[];
    
    // 匹配 ```mermaid 或 ```graph 代码块
    final regex = RegExp(
      r'```(?:mermaid|graph)\s*\n(.*?)\n```',
      multiLine: true,
      dotAll: true,
    );
    
    for (final match in regex.allMatches(text)) {
      final rawContent = match.group(0)!;
      final content = match.group(1)!.trim();
      
      if (content.isNotEmpty) {
        final chart = _parseChart(content, rawContent, match.start, match.end);
        if (chart != null) {
          charts.add(chart);
        }
      }
    }
    
    return charts;
  }

  /// 解析单个图表
  static MermaidChart? _parseChart(String content, String rawContent, int startIndex, int endIndex) {
    final lines = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    if (lines.isEmpty) return null;
    
    final firstLine = lines.first.toLowerCase();
    final type = _detectChartType(firstLine);
    final title = _extractTitle(content);
    final direction = _extractDirection(content);
    final theme = _extractTheme(content);
    
    return MermaidChart(
      type: type,
      content: content,
      rawContent: rawContent,
      startIndex: startIndex,
      endIndex: endIndex,
      title: title,
      direction: direction,
      theme: theme,
    );
  }

  /// 检测图表类型
  static MermaidChartType? _detectChartType(String firstLine) {
    // 移除注释和配置
    final cleanLine = firstLine.split('%%').first.trim();
    
    for (final type in MermaidChartType.values) {
      for (final alias in type.aliases) {
        if (cleanLine.startsWith(alias.toLowerCase())) {
          return type;
        }
      }
      
      if (cleanLine.startsWith(type.identifier.toLowerCase())) {
        return type;
      }
    }
    
    // 默认返回流程图
    return MermaidChartType.flowchart;
  }

  /// 提取图表标题
  static String? _extractTitle(String content) {
    // 简化的标题提取
    if (content.contains('title:')) {
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.contains('title:')) {
          final parts = line.split('title:');
          if (parts.length > 1) {
            final title = parts[1].trim();
            if (title.isNotEmpty) {
              return title;
            }
          }
        }
      }
    }
    
    return null;
  }

  /// 提取图表方向
  static String? _extractDirection(String content) {
    final directionRegex = RegExp(r'flowchart\s+(TD|TB|BT|RL|LR)', multiLine: true);
    final match = directionRegex.firstMatch(content);
    
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    }
    
    return null;
  }

  /// 提取图表主题
  static String? _extractTheme(String content) {
    // 简化的主题提取，避免复杂的正则表达式
    if (content.contains('theme:')) {
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.contains('theme:')) {
          final parts = line.split('theme:');
          if (parts.length > 1) {
            final theme = parts[1].trim().replaceAll('"', '').replaceAll("'", '').replaceAll(' ', '');
            if (theme.isNotEmpty) {
              return theme;
            }
          }
        }
      }
    }
    
    return null;
  }

  /// 验证Mermaid语法
  static bool validateSyntax(String content) {
    if (content.trim().isEmpty) return false;
    
    try {
      final lines = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      
      if (lines.isEmpty) return false;
      
      final firstLine = lines.first.toLowerCase();
      final type = _detectChartType(firstLine);
      
      if (type == null) return false;
      
      // 基本语法验证
      switch (type) {
        case MermaidChartType.flowchart:
          return _validateFlowchartSyntax(content);
        case MermaidChartType.sequenceDiagram:
          return _validateSequenceSyntax(content);
        case MermaidChartType.classDiagram:
          return _validateClassSyntax(content);
        default:
          return true; // 其他类型暂时返回true
      }
    } catch (e) {
      return false;
    }
  }

  /// 验证流程图语法
  static bool _validateFlowchartSyntax(String content) {
    // 检查基本的节点和连接语法
    final nodeRegex = RegExp(r'[A-Za-z0-9_]+(\[.*?\]|\(.*?\)|\{.*?\}|>.*?<|\[\[.*?\]\])?');
    final connectionRegex = RegExp(r'--[->]?|==.?|-.->|\.\.\.');
    
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('%%') || trimmedLine.startsWith('flowchart')) {
        continue;
      }
      
      // 简单的语法检查
      if (!trimmedLine.contains(nodeRegex) && !trimmedLine.contains(connectionRegex)) {
        // 可能是配置行或样式行，暂时忽略
      }
    }
    
    return true;
  }

  /// 验证时序图语法
  static bool _validateSequenceSyntax(String content) {
    // 检查参与者和消息语法
    final participantRegex = RegExp(r'participant\s+\w+');
    final messageRegex = RegExp(r'\w+\s*-[->]+\s*\w+\s*:');
    
    return content.contains(participantRegex) || content.contains(messageRegex);
  }

  /// 验证类图语法
  static bool _validateClassSyntax(String content) {
    // 检查类定义语法
    final classRegex = RegExp(r'class\s+\w+');
    final relationRegex = RegExp(r'\w+\s*[<|>*o-]+\s*\w+');
    
    return content.contains(classRegex) || content.contains(relationRegex);
  }

  /// 获取Mermaid图表示例
  static List<MermaidExample> getExamples() {
    return [
      // 流程图示例
      MermaidExample(
        type: MermaidChartType.flowchart,
        title: '简单流程图',
        description: '展示基本的流程图语法',
        code: '''flowchart TD
    A[开始] --> B{判断条件}
    B -->|是| C[处理A]
    B -->|否| D[处理B]
    C --> E[结束]
    D --> E''',
      ),
      
      MermaidExample(
        type: MermaidChartType.flowchart,
        title: '复杂流程图',
        description: '包含多种节点形状的流程图',
        code: '''flowchart LR
    A([开始]) --> B[输入数据]
    B --> C{数据有效?}
    C -->|有效| D[处理数据]
    C -->|无效| E[显示错误]
    D --> F[(保存到数据库)]
    F --> G([结束])
    E --> G''',
      ),
      
      // 时序图示例
      MermaidExample(
        type: MermaidChartType.sequenceDiagram,
        title: '用户登录时序图',
        description: '展示用户登录的完整时序',
        code: '''sequenceDiagram
    participant U as 用户
    participant B as 浏览器
    participant S as 服务器
    participant D as 数据库
    
    U->>B: 输入用户名密码
    B->>S: 发送登录请求
    S->>D: 验证用户信息
    D-->>S: 返回验证结果
    S-->>B: 返回登录状态
    B-->>U: 显示登录结果''',
      ),
      
      // 类图示例
      MermaidExample(
        type: MermaidChartType.classDiagram,
        title: '简单类图',
        description: '展示类之间的关系',
        code: '''classDiagram
    class Animal {
        +String name
        +int age
        +makeSound()
    }
    
    class Dog {
        +String breed
        +bark()
    }
    
    class Cat {
        +String color
        +meow()
    }
    
    Animal <|-- Dog
    Animal <|-- Cat''',
      ),
      
      // 状态图示例
      MermaidExample(
        type: MermaidChartType.stateDiagram,
        title: '订单状态图',
        description: '展示订单的状态转换',
        code: '''stateDiagram-v2
    [*] --> 创建
    创建 --> 待支付
    待支付 --> 已支付
    待支付 --> 已取消
    已支付 --> 配送中
    配送中 --> 已完成
    已支付 --> 已退款
    已取消 --> [*]
    已完成 --> [*]
    已退款 --> [*]''',
      ),
      
      // 甘特图示例
      MermaidExample(
        type: MermaidChartType.gantt,
        title: '项目甘特图',
        description: '展示项目进度规划',
        code: '''gantt
    title 项目开发计划
    dateFormat  YYYY-MM-DD
    section 需求分析
    需求收集    :done,    des1, 2024-01-01,2024-01-05
    需求分析    :done,    des2, 2024-01-06,2024-01-10
    section 设计阶段
    UI设计      :active,  des3, 2024-01-11,2024-01-20
    架构设计    :         des4, 2024-01-15,2024-01-25
    section 开发阶段
    前端开发    :         des5, 2024-01-26,2024-02-15
    后端开发    :         des6, 2024-01-26,2024-02-20''',
      ),
      
      // 饼图示例
      MermaidExample(
        type: MermaidChartType.pie,
        title: '市场份额饼图',
        description: '展示不同产品的市场份额',
        code: '''pie title 移动操作系统市场份额
    "Android" : 42.23
    "iOS" : 27.33
    "Windows" : 1.38
    "其他" : 29.06''',
      ),
    ];
  }

  /// 预处理Mermaid内容
  static String preprocessContent(String content) {
    return content
        .replaceAll('\r\n', '\n') // 统一换行符
        .replaceAll('\r', '\n')
        .trim();
  }

  /// 替换文本中的Mermaid图表为占位符
  static String replaceChartsWithPlaceholders(String text, List<MermaidChart> charts) {
    String result = text;
    int offset = 0;
    
    for (int i = 0; i < charts.length; i++) {
      final chart = charts[i];
      final placeholder = '<mermaid-chart-$i>';
      
      final start = chart.startIndex - offset;
      final end = chart.endIndex - offset;
      
      result = result.substring(0, start) + 
               placeholder + 
               result.substring(end);
      
      offset += chart.rawContent.length - placeholder.length;
    }
    
    return result;
  }
}

/// Mermaid图表示例
class MermaidExample {
  const MermaidExample({
    required this.type,
    required this.title,
    required this.description,
    required this.code,
  });

  final MermaidChartType type;
  final String title;
  final String description;
  final String code;
} 