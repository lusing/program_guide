var u = new User("alice", 22);
string level = u switch
{
    {Age: < 18} => "minor",
    {Age: >= 18 and < 60} => "adult",
    _ => "senior"
};

var (name, age) = u;
Console.WriteLine($"{name}:{age} => {level}");

record User(string Name, int Age);
