const std = @import("std");
const builtin = @import("builtin");
const term = @import("term.zig");
const cli = @import("cli.zig");
const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const params = try cli.parseParams(arena);

    var vm = LC3{};
    std.mem.copyForwards(u16, vm.memory[0..params.rom.len], params.rom);

    // set terminal mode
    const input = switch (builtin.os.tag) {
        .linux => term.openInputTTY(arena),
        .windows => |_| blk: {
            const windows = std.os.windows;
            const handle = try windows.GetStdHandle(windows.STD_INPUT_HANDLE);
            break :blk handle;
        },
        else => @panic("unsupported platform"),
    };

    const original_state = term.disableInputBuffering(input);
    defer term.setTermState(original_state);

    if (builtin.os.tag == .linux) {
        const sa = std.os.linux.Sigaction{ .handler = .{
            .handler = handleSigInt,
        }, .mask = [_]u32{0} ** 32, .flags = 0 };
        _ = std.os.linux.sigaction(2, &sa, null);
    }

    vm.init();
    vm.run();
}

fn handleSigInt(_: i32) callconv(.C) void {
    std.process.exit(0);
}

test "root" {
    _ = @import("lc3_test.zig");
}
