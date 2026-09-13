using Microsoft.EntityFrameworkCore;

using var db = new AppDbContext();
db.Database.EnsureCreated();

if (!db.Users.Any())
{
    db.Users.AddRange(
        new User {Name = "Alice", Email = "alice@example.com"},
        new User {Name = "Bob", Email = "bob@example.com"}
    );
    db.SaveChanges();
}

var alice = db.Users.FirstOrDefault(x => x.Name == "Alice");
if (alice is not null)
{
    alice.Email = "alice@newmail.com";
    db.SaveChanges();
}

var users = db.Users.OrderBy(x => x.Id).ToList();
Console.WriteLine($"users={users.Count}");
Console.WriteLine(string.Join(", ", users.Select(u => $"{u.Name}:{u.Email}")));

public sealed class AppDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseInMemoryDatabase("GuideDotnetSamples");
}

public sealed class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

