using System.Text.Json;

var user = new User(1, "alice");
var path = Path.Combine(Path.GetTempPath(), "dotnet-user.json");
var json = JsonSerializer.Serialize(user, new JsonSerializerOptions {WriteIndented = true});
File.WriteAllText(path, json);

var loaded = File.ReadAllText(path);
var obj = JsonSerializer.Deserialize<User>(loaded);
Console.WriteLine($"{obj?.Id}:{obj?.Name}");

record User(int Id, string Name);

