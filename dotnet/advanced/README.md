// 高级主题示例
// 文件位置: advanced/README.md

# .NET 10.0 高级主题

本目录包含高级开发话题的示例代码。

## 目录

| 目录 | 说明 |
|------|------|
| `microservices/` | 微服务架构模式 |
| `docker/` | Docker 容器化 |
| `kubernetes/` | Kubernetes 部署 |
| `security/` | 安全最佳实践 |
| `observability/` | 可观察性与监控 |
| `messaging/` | 消息队列与事件驱动 |

## 快速开始

```bash
# 每个子目录都是独立的项目
cd advanced/microservices
dotnet run

# 构建 Docker 镜像
docker build -t myapp .
docker run -p 5000:80 myapp
```

## 最佳实践

1. **使用秒钟分配** - 使用 Span<T> 和 Memory<T>
2. **配置驱动** - 使用强烈的类型配置
3. **异常处理** - 实现全局异常处理
4. **日志记录** - 结构化日志记录
5. **测试** - 单元测试 + 集成测试

## 相关资源

- [微服务架构](https://learn.microsoft.com/zh-cn/dotnet/architecture/microservices/)
- [Docker 容器化](https://learn.microsoft.com/zh-cn/dotnet/core/docker/)
- [安全性指南](https://learn.microsoft.com/zh-cn/dotnet/standard/security/)