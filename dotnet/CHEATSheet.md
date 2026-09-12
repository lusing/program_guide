# .NET 10.0 开发清单

## 环境设置

- [ ] 安装 .NET 10.0 SDK
- [ ] 验证安装: `dotnet --version`
- [ ] 安装 Visual Studio 2022 17.8+ 或 VS Code
- [ ] 安装 C# 扩展 (VS Code)

## 项目创建

```bash
# 控制台应用
dotnet new console -n MyApplication

# Web API
dotnet new webapi -n MyApi

# 类库
dotnet new classlib -n MyLibrary

# 单元测试
dotnet new xunit -n MyTests
```

## 开发流程

- [ ] 创建项目结构
- [ ] 设置版本控制 (Git)
- [ ] 配置 .gitignore
- [ ] 设置 CI/CD

## 代码规范

- [ ] 使用有意义的命名
- [ ] 添加 XML 注释
- [ ] 遵循 SOLID 原则
- [ ] 实现异常处理
- [ ] 添加日志记录

## 测试

- [ ] 编写单元测试
- [ ] 编写集成测试
- [ ] 代码覆盖率 > 80%
- [ ] 使用 Mock 框架

## 部署

- [ ] 配置生产环境
- [ ] 设置应用程序 Insights
- [ ] 配置日志聚合
- [ ] 设置监控告警

## 性能优化

- [ ] 使用 ANALYZE 进行性能分析
- [ ] 优化数据库查询
- [ ] 实现缓存策略
- [ ] 使用异步编程

## 安全

- [ ] 敏感数据加密
- [ ] 实现身份验证
- [ ] 实现授权
- [ ] 防止 SQL 注入
- [ ] 防止 XSS 攻击