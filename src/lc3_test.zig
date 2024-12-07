const std = @import("std");
const t = std.testing;

test "sometest" {
    try t.expect(1 == 1);
}
