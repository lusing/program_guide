// Entity Framework Core 示例
// 文件位置: samples/efcore/CodeFirst/Program.cs

using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;

// 数据上下文
public class AppDbContext : DbContext
{
    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Post> Posts { get; set; } = null!;
    public DbSet<Category> Categories { get; set; } = null!;

    protected override void OnConfiguring(DbContextOptionsBuilder options)
        => options.UseInMemoryDatabase("TestDb");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // 用户配置
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(u => u.Id);
            entity.Property(u => u.Email).IsRequired();
            entity.Property(u => u.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
        });

        // 分类配置
        modelBuilder.Entity<Category>(entity =>
        {
            entity.ToTable("Categories");
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Name).HasMaxLength(50);
        });

        // 帖子配置
        modelBuilder.Entity<Post>(entity =>
        {
            entity.ToTable("Posts");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Title).HasMaxLength(100);
            entity.HasOne(p => p.User)
                .WithMany(u => u.Posts)
                .HasForeignKey(p => p.UserId);
            entity.HasOne(p => p.Category)
                .WithMany(c => c.Posts)
                .HasForeignKey(p => p.CategoryId);
        });

        // 种子数据
        modelBuilder.Entity<Category>().HasData(
            new Category { Id = 1, Name = "技术" },
            new Category { Id = 2, Name = "生活" }
        );

        modelBuilder.Entity<User>().HasData(
            new User { Id = 1, Name = "Alice", Email = "alice@example.com" },
            new User { Id = 2, Name = "Bob", Email = "bob@example.com" }
        );

        modelBuilder.Entity<Post>().HasData(
            new Post { Id = 1, Title = "EF Core 入门", Content = "内容...", UserId = 1, CategoryId = 1 },
            new Post { Id = 2, Title = "生活随笔", Content = "内容...", UserId = 2, CategoryId = 2 }
        );
    }
}

// 实体类
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // 导航属性
    public ICollection<Post> Posts { get; set; } = new List<Post>();
}

public class Category
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    // 导航属性
    public ICollection<Post> Posts { get; set; } = new List<Post>();
}

public class Post
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public int UserId { get; set; }
    public int CategoryId { get; set; }

    // 导航属性
    public User User { get; set; } = null!;
    public Category Category { get; set; } = null!;
}

// 数据操作示例
void InsertData()
{
    using var context = new AppDbContext();

    var user = new User { Name = "Charlie", Email = "charlie@example.com" };
    context.Users.Add(user);
    context.SaveChanges();

    Console.WriteLine($"新增用户 ID: {user.Id}");
}

void QueryData()
{
    using var context = new AppDbContext();

    // 获取所有用户
    var users = context.Users.ToList();
    Console.WriteLine($"用户数量: {users.Count}");

    // 条件查询
    var user = context.Users.FirstOrDefault(u => u.Name == "Alice");
    Console.WriteLine($"找到用户: {user?.Name}");

    // 包含导航属性
    var posts = context.Posts.Include(p => p.User).Include(p => p.Category).ToList();
    Console.WriteLine($"帖子数量: {posts.Count}");
}

void UpdateData()
{
    using var context = new AppDbContext();

    var user = context.Users.First();
    user.Name = "Alice Smith";
    context.SaveChanges();

    Console.WriteLine($"更新用户: {user.Name}");
}

void DeleteData()
{
    using var context = new AppDbContext();

    var user = context.Users.FirstOrDefault(u => u.Name == "Bob");
    if (user != null)
    {
        context.Users.Remove(user);
        context.SaveChanges();
        Console.WriteLine("删除用户成功");
    }
}

void RawSql()
{
    using var context = new AppDbContext();

    // 原始 SQL 查询
    var users = context.Users.FromSqlRaw("SELECT * FROM Users WHERE Name LIKE {0}", "%a%").ToList();
    Console.WriteLine($"SQL 查询结果: {users.Count}");

    // 原始 SQL 命令
    var rowsAffected = context.Database.ExecuteSqlRaw("UPDATE Users SET Email = Email");
    Console.WriteLine($"受影响行数: {rowsAffected}");
}

// 运行示例
Console.WriteLine("=== EF Core Code First 示例 ===");
Console.WriteLine("\n1. 插入数据");
InsertData();

Console.WriteLine("\n2. 查询数据");
QueryData();

Console.WriteLine("\n3. 更新数据");
UpdateData();

Console.WriteLine("\n4. 删除数据");
DeleteData();

Console.WriteLine("\n5. 原始 SQL");
RawSql();