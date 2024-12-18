const std = @import("std");
const cli = @import("cli.zig");
const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;
const rl = @import("raylib");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const params = try cli.parseParams(arena);

    // raylib call example
    std.debug.print("mouse at {?}\n", .{rl.getMousePosition()});

    var vm = LC3{};
    std.mem.copyForwards(u16, vm.memory[0..params.rom.len], params.rom);

    vm.run();
}

test "root" {
    _ = @import("lc3_test.zig");
}
