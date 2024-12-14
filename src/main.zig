const std = @import("std");
const LC3 = @import("lc3.zig").LC3;
const rl = @import("raylib");

pub fn main() !void {
    // TODO: CLI

    // raylib call example
    std.debug.print("mouse at {?}\n", .{rl.getMousePosition()});

    var vm = LC3{};
    vm.run();
}

test "root" {
    _ = @import("lc3_test.zig");
}
