const std = @import("std");

const Person = struct {
    name: []const u8,
    age: u32,

    fn greet(self: Person) void {
        std.debug.print("Hello, I'm {}, {} years old.\n", .{ self.name, self.age });
    }
};

pub fn main() void {
    var person = Person{
        .name = "Alice",
        .age = 25,
    };
    person.greet();
}
