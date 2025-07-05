/// Mermaid图表相关类型定义

/// Mermaid图表类型
enum MermaidChartType {
  flowchart('流程图', 'flowchart', ['flowchart', 'graph']),
  sequenceDiagram('时序图', 'sequenceDiagram', ['sequenceDiagram', 'sequence']),
  classDiagram('类图', 'classDiagram', ['classDiagram', 'class']),
  stateDiagram('状态图', 'stateDiagram', ['stateDiagram', 'state']),
  entityRelationshipDiagram('实体关系图', 'erDiagram', ['erDiagram', 'er']),
  userJourney('用户旅程图', 'journey', ['journey']),
  gantt('甘特图', 'gantt', ['gantt']),
  pie('饼图', 'pie', ['pie']),
  gitgraph('Git图', 'gitgraph', ['gitgraph', 'git']),
  mindmap('思维导图', 'mindmap', ['mindmap']),
  timeline('时间轴', 'timeline', ['timeline']),
  requirement('需求图', 'requirementDiagram', ['requirementDiagram', 'requirement']);

  const MermaidChartType(this.displayName, this.identifier, this.aliases);

  /// 显示名称
  final String displayName;
  
  /// 标识符
  final String identifier;
  
  /// 别名列表
  final List<String> aliases;

  /// 根据标识符获取图表类型
  static MermaidChartType? fromIdentifier(String? identifier) {
    if (identifier == null || identifier.isEmpty) return null;
    
    final lowercaseId = identifier.toLowerCase().trim();
    
    for (final type in MermaidChartType.values) {
      if (type.aliases.contains(lowercaseId) || type.identifier.toLowerCase() == lowercaseId) {
        return type;
      }
    }
    
    return null;
  }
}

/// Mermaid图表
class MermaidChart {
  const MermaidChart({
    required this.type,
    required this.content,
    required this.rawContent,
    required this.startIndex,
    required this.endIndex,
    this.title,
    this.direction,
    this.theme,
  });

  /// 图表类型
  final MermaidChartType? type;
  
  /// 图表内容（去掉标记的纯Mermaid代码）
  final String content;
  
  /// 原始内容（包含```mermaid标记）
  final String rawContent;
  
  /// 在原文本中的开始位置
  final int startIndex;
  
  /// 在原文本中的结束位置
  final int endIndex;
  
  /// 图表标题
  final String? title;
  
  /// 图表方向（对于流程图）
  final String? direction;
  
  /// 图表主题
  final String? theme;

  @override
  String toString() {
    return 'MermaidChart(type: $type, title: $title, range: $startIndex-$endIndex)';
  }
}

/// Mermaid图表节点
class MermaidNode {
  const MermaidNode({
    required this.id,
    required this.label,
    required this.shape,
    this.style,
    this.classes,
  });

  /// 节点ID
  final String id;
  
  /// 节点标签
  final String label;
  
  /// 节点形状
  final MermaidNodeShape shape;
  
  /// 节点样式
  final MermaidNodeStyle? style;
  
  /// 节点类名
  final List<String>? classes;
}

/// Mermaid图表边/连接
class MermaidEdge {
  const MermaidEdge({
    required this.from,
    required this.to,
    required this.type,
    this.label,
    this.style,
  });

  /// 起始节点ID
  final String from;
  
  /// 目标节点ID
  final String to;
  
  /// 边的类型
  final MermaidEdgeType type;
  
  /// 边的标签
  final String? label;
  
  /// 边的样式
  final MermaidEdgeStyle? style;
}

/// Mermaid节点形状
enum MermaidNodeShape {
  rectangle('矩形', 'rectangle'),
  roundedRectangle('圆角矩形', 'roundedRectangle'),
  circle('圆形', 'circle'),
  diamond('菱形', 'diamond'),
  hexagon('六边形', 'hexagon'),
  parallelogram('平行四边形', 'parallelogram'),
  trapezoid('梯形', 'trapezoid'),
  database('数据库', 'database'),
  cloud('云形', 'cloud'),
  oval('椭圆', 'oval');

  const MermaidNodeShape(this.displayName, this.identifier);

  final String displayName;
  final String identifier;
}

/// Mermaid边类型
enum MermaidEdgeType {
  solid('实线', '-->', 'solid'),
  dashed('虚线', '-..->', 'dashed'),
  thick('粗线', '==>', 'thick'),
  dotted('点线', '...>', 'dotted'),
  arrow('箭头', '-->', 'arrow'),
  noArrow('无箭头', '---', 'noArrow');

  const MermaidEdgeType(this.displayName, this.symbol, this.identifier);

  final String displayName;
  final String symbol;
  final String identifier;
}

/// Mermaid节点样式
class MermaidNodeStyle {
  const MermaidNodeStyle({
    this.fill,
    this.stroke,
    this.strokeWidth,
    this.strokeDasharray,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  final String? fill;
  final String? stroke;
  final double? strokeWidth;
  final String? strokeDasharray;
  final String? color;
  final double? fontSize;
  final String? fontWeight;
}

/// Mermaid边样式
class MermaidEdgeStyle {
  const MermaidEdgeStyle({
    this.stroke,
    this.strokeWidth,
    this.strokeDasharray,
    this.color,
  });

  final String? stroke;
  final double? strokeWidth;
  final String? strokeDasharray;
  final String? color;
}

/// Mermaid图表配置
class MermaidConfig {
  const MermaidConfig({
    this.theme = 'default',
    this.themeVariables,
    this.flowchart,
    this.sequence,
    this.gantt,
    this.journey,
    this.class2,
    this.state,
    this.er,
    this.pie,
    this.git,
  });

  final String theme;
  final Map<String, dynamic>? themeVariables;
  final FlowchartConfig? flowchart;
  final SequenceConfig? sequence;
  final GanttConfig? gantt;
  final JourneyConfig? journey;
  final ClassConfig? class2;
  final StateConfig? state;
  final ErConfig? er;
  final PieConfig? pie;
  final GitConfig? git;
}

/// 流程图配置
class FlowchartConfig {
  const FlowchartConfig({
    this.htmlLabels = true,
    this.curve = 'linear',
    this.padding = 15,
    this.useMaxWidth = true,
  });

  final bool htmlLabels;
  final String curve;
  final int padding;
  final bool useMaxWidth;
}

/// 时序图配置
class SequenceConfig {
  const SequenceConfig({
    this.diagramMarginX = 50,
    this.diagramMarginY = 10,
    this.actorMargin = 50,
    this.width = 150,
    this.height = 65,
    this.boxMargin = 10,
    this.boxTextMargin = 5,
    this.noteMargin = 10,
    this.messageMargin = 35,
    this.mirrorActors = true,
    this.bottomMarginAdj = 1,
    this.useMaxWidth = true,
  });

  final int diagramMarginX;
  final int diagramMarginY;
  final int actorMargin;
  final int width;
  final int height;
  final int boxMargin;
  final int boxTextMargin;
  final int noteMargin;
  final int messageMargin;
  final bool mirrorActors;
  final int bottomMarginAdj;
  final bool useMaxWidth;
}

/// 甘特图配置
class GanttConfig {
  const GanttConfig({
    this.titleTopMargin = 25,
    this.barHeight = 20,
    this.barGap = 4,
    this.topPadding = 50,
    this.leftPadding = 75,
    this.gridLineStartPadding = 35,
    this.fontSize = 11,
    this.fontFamily = 'Open-Sans, sans-serif',
    this.numberSectionStyles = 4,
    this.useMaxWidth = true,
  });

  final int titleTopMargin;
  final int barHeight;
  final int barGap;
  final int topPadding;
  final int leftPadding;
  final int gridLineStartPadding;
  final int fontSize;
  final String fontFamily;
  final int numberSectionStyles;
  final bool useMaxWidth;
}

/// 用户旅程图配置
class JourneyConfig {
  const JourneyConfig({
    this.diagramMarginX = 50,
    this.diagramMarginY = 10,
    this.leftMargin = 150,
    this.width = 150,
    this.height = 50,
    this.boxMargin = 10,
    this.boxTextMargin = 5,
    this.noteMargin = 10,
    this.messageMargin = 35,
    this.bottomMarginAdj = 1,
    this.useMaxWidth = true,
  });

  final int diagramMarginX;
  final int diagramMarginY;
  final int leftMargin;
  final int width;
  final int height;
  final int boxMargin;
  final int boxTextMargin;
  final int noteMargin;
  final int messageMargin;
  final int bottomMarginAdj;
  final bool useMaxWidth;
}

/// 类图配置
class ClassConfig {
  const ClassConfig({
    this.useMaxWidth = true,
  });

  final bool useMaxWidth;
}

/// 状态图配置
class StateConfig {
  const StateConfig({
    this.useMaxWidth = true,
  });

  final bool useMaxWidth;
}

/// 实体关系图配置
class ErConfig {
  const ErConfig({
    this.diagramPadding = 20,
    this.layoutDirection = 'TB',
    this.minEntityWidth = 100,
    this.minEntityHeight = 75,
    this.entityPadding = 15,
    this.stroke = 'gray',
    this.fill = 'honeydew',
    this.fontSize = 12,
    this.useMaxWidth = true,
  });

  final int diagramPadding;
  final String layoutDirection;
  final int minEntityWidth;
  final int minEntityHeight;
  final int entityPadding;
  final String stroke;
  final String fill;
  final int fontSize;
  final bool useMaxWidth;
}

/// 饼图配置
class PieConfig {
  const PieConfig({
    this.useMaxWidth = true,
  });

  final bool useMaxWidth;
}

/// Git图配置
class GitConfig {
  const GitConfig({
    this.mainBranchName = 'main',
    this.showBranches = true,
    this.showCommitLabel = true,
    this.useMaxWidth = true,
  });

  final String mainBranchName;
  final bool showBranches;
  final bool showCommitLabel;
  final bool useMaxWidth;
}

/// Mermaid渲染选项
class MermaidRenderOptions {
  const MermaidRenderOptions({
    this.width,
    this.height,
    this.backgroundColor = '#ffffff',
    this.theme = 'default',
    this.config,
  });

  final double? width;
  final double? height;
  final String backgroundColor;
  final String theme;
  final MermaidConfig? config;
} 