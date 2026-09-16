using PortableLib;

Console.WriteLine(Greeting.Runtime);                          // net10.0 目标 → ".NET (Core) 5+"
Console.WriteLine(Greeting.BuildFilePath("data", "notes.txt")); // Windows 上输出 data\notes.txt
Console.Write(Greeting.Format("portable"));
