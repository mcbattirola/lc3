const std = @import("std");
const LC3 = @import("lc3.zig").LC3;

pub fn main() !void {
    var vm = LC3{};
    vm.run();
}

test "root" {
    _ = @import("lc3_test.zig");
}
