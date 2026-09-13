fn readFile(path: []const u8) ![2]u8 {
    return error.FileNotFound;
}

fn processFile() !void {
    const data = try readFile("test.txt");
}
