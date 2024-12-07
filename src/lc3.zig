const std = @import("std");

const MEMORY_SIZE = 1 << 16;

pub const LC3 = struct {
    memory: [MEMORY_SIZE]u16 = undefined,

    pub fn run(self: *LC3) void {
        self.memory[0] = 10;
        std.debug.print("hello from VM {any}!\n", .{self.memory[0..10]});
    }
};
