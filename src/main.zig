const std = @import("std");
const cli = @import("cli.zig");
const LC3 = @import("lc3.zig").LC3;
const rl = @import("raylib");

pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = general_purpose_allocator.allocator();

    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const params = try cli.parseParams(arena);

    // raylib call example
    std.debug.print("mouse at {?}\n", .{rl.getMousePosition()});

    var vm = LC3{};
    vm.memory = params.rom;
    vm.run();
}

test "root" {
    _ = @import("lc3_test.zig");
}
