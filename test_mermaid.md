# Mermaid 图表测试

## 流程图

```mermaid
graph TD
    A[开始] --> B{判断条件}
    B -->|是| C[执行操作]
    B -->|否| D[结束]
    C --> D
```

## 时序图

```mermaid
sequenceDiagram
    participant A as 用户
    participant B as 系统
    participant C as 数据库
    
    A->>B: 发起请求
    B->>C: 查询数据
    C-->>B: 返回结果
    B-->>A: 响应数据
```

## 类图

```mermaid
classDiagram
    class Document {
        +String id
        +String title
        +String content
        +DateTime createdAt
        +save()
        +load()
    }
    
    class Editor {
        +Document document
        +String content
        +edit()
        +preview()
    }
    
    Document --> Editor : uses
```

## 甘特图

```mermaid
gantt
    title 项目开发计划
    dateFormat  YYYY-MM-DD
    section 设计阶段
    需求分析       :done,    des1, 2024-01-01,2024-01-05
    UI设计        :done,    des2, 2024-01-06, 5d
    section 开发阶段
    前端开发      :active,  dev1, 2024-01-12, 10d
    后端开发      :         dev2, 2024-01-15, 8d
    section 测试阶段
    单元测试      :         test1, after dev1, 3d
    集成测试      :         test2, after dev2, 2d
```

## Git 图

```mermaid
gitgraph
    commit
    commit
    branch develop
    checkout develop
    commit
    commit
    checkout main
    merge develop
    commit
``` 