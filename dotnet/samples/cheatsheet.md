# .NET 10.0 常用代码片段

## 目录

- [配置管理](#配置管理)
- [日志记录](#日志记录)
- [数据库操作](#数据库操作)
- [HTTP 客户端](#http-客户端)
- [验证](#验证)
- [缓存](#缓存)
- [CORS](#cors)
- [文件操作](#文件操作)

---

## 配置管理

```csharp
// appsettings.json
{
  "AppSettings": {
    "Title": "MyApp",
    "Version": "1.0.0"
  },
  "ConnectionStrings": {
    "Default": "Server=localhost;Database=MyDB;Trusted_Connection=True;"
  }
}

// 读取配置
var builder = WebApplication.CreateBuilder(args);

// 绑定到类
public class AppSettings
{
    public string Title { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
}

var settings = builder.Configuration.Get<AppSettings>();
Console.WriteLine($"App: {settings.Title} v{settings.Version}");

// 读取连接字符串
string connString = builder.Configuration.GetConnectionString("Default");
```

---

## 日志记录

```csharp
// 使用 ILogger
public class MyService
{
    private readonly ILogger<MyService> _logger;

    public MyService(ILogger<MyService> logger)
    {
        _logger = logger;
    }

    public void DoWork()
    {
        _logger.LogInformation("开始处理工作");

        try
        {
            // 业务逻辑
            _logger.LogInformation("工作完成");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "处理工作时出错");
        }
    }
}

// 结构化日志
_logger.LogInformation("用户 {UserId} 登录 from {IpAddress}", userId, ipAddress);

// 日志范围
using (_logger.BeginScope(new Dictionary<string, object> { ["TraceId"] = Guid.NewGuid() }))
{
    _logger.LogInformation("在范围内");
}
```

---

## 数据库操作

```csharp
// EF Core 查询
public class UserRepository
{
    private readonly AppDbContext _context;

    public UserRepository(AppDbContext context)
    {
        _context = context;
    }

    // 查询所有
    public async Task<List<User>> GetAllAsync()
    {
        return await _context.Users.ToListAsync();
    }

    // 查询单个
    public async Task<User?> GetByIdAsync(int id)
    {
        return await _context.Users.FindAsync(id);
    }

    // 条件查询
    public async Task<List<User>> GetByStatusAsync(string status)
    {
        return await _context.Users
            .Where(u => u.Status == status)
            .OrderBy(u => u.CreatedAt)
            .ToListAsync();
    }

    // 分页
    public async Task<PagedResult<User>> GetPageAsync(int page, int pageSize)
    {
        var total = await _context.Users.CountAsync();
        var items = await _context.Users
            .OrderBy(u => u.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<User>(items, total, page, pageSize);
    }

    // 插入
    public async Task AddAsync(User user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
    }

    // 更新
    public async Task UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }

    // 删除
    public async Task DeleteAsync(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user != null)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
        }
    }
}

public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling(Total / (double)PageSize);
}
```

---

## HTTP 客户端

```csharp
// 配置 HttpClient
builder.Services.AddHttpClient("GitHub", client =>
{
    client.BaseAddress = new Uri("https://api.github.com/");
    client.DefaultRequestHeaders.Add("Accept", "application/vnd.github.v3+json");
    client.DefaultRequestHeaders.Add("User-Agent", "MyApp");
});

// 使用 IHttpClientFactory
public class GitHubService
{
    private readonly HttpClient _client;

    public GitHubService(IHttpClientFactory factory)
    {
        _client = factory.CreateClient("GitHub");
    }

    public async Task<List<Repository>> GetReposAsync(string username)
    {
        var response = await _client.GetStringAsync($"users/{username}/repos");
        return JsonSerializer.Deserialize<List<Repository>>(response);
    }
}

// 发送 POST 请求
public async Task<string> PostDataAsync(string url, object data)
{
    using var client = new HttpClient();
    var content = new StringContent(JsonSerializer.Serialize(data),
        Encoding.UTF8, "application/json");

    var response = await client.PostAsync(url, content);
    response.EnsureSuccessStatusCode();
    return await response.Content.ReadAsStringAsync();
}

// 轮询策略
var retryPolicy = Policy
    .Handle<HttpRequestException>()
    .WaitAndRetryAsync(3, i => TimeSpan.FromSeconds(Math.Pow(2, i)));

await retryPolicy.ExecuteAsync(async () =>
{
    var response = await _client.GetAsync(url);
    response.EnsureSuccessStatusCode();
});
```

---

## 验证

```csharp
// Data Annotations
public class UserDto
{
    [Required]
    [StringLength(50, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Range(18, 120)]
    public int Age { get; set; }

    [Url]
    public string? Website { get; set; }
}

// 模型验证
public class UserController : Controller
{
    [HttpPost]
    public IActionResult Create([FromBody] UserDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { errors = ModelState.Values.SelectMany(v => v.Errors) });
        }

        // 处理请求
        return Ok();
    }
}

// 自定义验证属性
public class MustBeAdultAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is DateTime date && date.Year >= 2000)
        {
            return new ValidationResult("必须是成年人才能使用");
        }
        return ValidationResult.Success;
    }
}
```

---

## 缓存

```csharp
// 内存缓存
builder.Services.AddMemoryCache();

public class CacheService
{
    private readonly IMemoryCache _cache;

    public CacheService(IMemoryCache cache)
    {
        _cache = cache;
    }

    public async Task<T?> GetOrCreateAsync<T>(string key, Func<Task<T>> factory,
        TimeSpan absoluteExpiration)
    {
        return await _cache.GetOrCreateAsync(key, async entry =>
        {
            entry.AbsoluteExpiration = absoluteExpiration;
            return await factory();
        });
    }

    public T? Get<T>(string key)
    {
        return _cache.Get<T>(key);
    }

    public void Set<T>(string key, T value, TimeSpan expiration)
    {
        _cache.Set(key, value, expiration);
    }

    public void Remove(string key)
    {
        _cache.Remove(key);
    }
}

// 分布式缓存 (Redis)
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "localhost:6379";
});

// 系统输出缓存
app.UseOutputCache();

app.MapGet("/cached", () => DateTime.UtcNow.ToString("o"))
    .CacheOutput();
```

---

## CORS

```csharp
// 配置 CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader());

    options.AddPolicy("Specific", builder =>
        builder.WithOrigins("https://example.com")
               .AllowAnyMethod()
               .WithHeaders("content-type", "authorization"));
});

var app = builder.Build();

// 使用 CORS
app.UseCors("AllowAll");

// 控制器级别
[EnableCors("Specific")]
[ApiController]
[Route("api/[controller]")]
public class ControllerBase : ControllerBase { }

// 方法级别
[HttpGet]
[EnableCors("AllowAll")]
public IActionResult Get() => Ok();
```

---

## 文件操作

```csharp
// I Psychic<FileProvider>
public class FileService
{
    private readonly IWebHostEnvironment _env;

    public FileService(IWebHostEnvironment env)
    {
        _env = env;
    }

    // 读取文件
    public string ReadFile(string path)
    {
        return System.IO.File.ReadAllText(path);
    }

    // 写入文件
    public async Task WriteFileAsync(string path, string content)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        await System.IO.File.WriteAllTextAsync(path, content);
    }

    // 列出文件
    public List<string> ListFiles(string directory)
    {
        return Directory.GetFiles(directory, "*.txt").ToList();
    }

    // 上传文件
    public async Task<string> UploadFileAsync(IFormFile file)
    {
        var fileName = Path.GetFileName(file.FileName);
        var path = Path.Combine(_env.ContentRootPath, "Uploads", fileName);

        using (var stream = new FileStream(path, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        return path;
    }

    // 下载文件
    public PhysicalFileResult DownloadFile(string path)
    {
        return PhysicalFile(path, "application/octet-stream", Path.GetFileName(path));
    }
}

// 文件监控
public class FileWatcher
{
    public void Watch(string path)
    {
        using var watcher = new FileSystemWatcher(path);
        watcher.NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName;

        watcher.Changed += (s, e) => Console.WriteLine($"更改: {e.FullPath}");
        watcher.Created += (s, e) => Console.WriteLine($"创建: {e.FullPath}");
        watcher.Deleted += (s, e) => Console.WriteLine($"删除: {e.FullPath}");

        watcher.EnableRaisingEvents = true;
    }
}
```

---

## 常用工具方法

```csharp
// 雪花 ID 生成器
public static class SnowflakeId
{
    private static readonly DateTime UnixEpoch = new(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
    private static long _workerId = 1;
    private static long _sequence = 0;
    private static long _lastTimestamp = -1;

    public static long NewId()
    {
        long timestamp = DateTime.UtcNow.Subtract(UnixEpoch).Ticks;

        if (timestamp < _lastTimestamp)
            throw new Exception("时钟回拨");

        if (timestamp == _lastTimestamp)
            _sequence = (_sequence + 1) & 0xFFF;
        else
            _sequence = 0;

        _lastTimestamp = timestamp;
        return (timestamp << 22) | (_workerId << 12) | _sequence;
    }
}

// 时间扩展
public static class DateTimeExtensions
{
    public static long ToUnixTimestamp(this DateTime dateTime)
    {
        return new DateTimeOffset(dateTime).ToUnixTimeSeconds();
    }

    public static DateTime FromUnixTimestamp(this long unixTimestamp)
    {
        return DateTimeOffset.FromUnixTimeSeconds(unixTimestamp).DateTime;
    }
}