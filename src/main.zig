const LC3 = @import("lc3.zig").LC3;

pub fn main() !void {
    // TODO: CLI
    var vm = LC3{};
    vm.run();
}

test "root" {
    _ = @import("lc3_test.zig");
}
