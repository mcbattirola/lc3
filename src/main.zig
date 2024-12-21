const std = @import("std");
const builtin = @import("builtin");
const term = @import("term.zig");
const cli = @import("cli.zig");
const UI = @import("ui.zig").UI;
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
    vm.init();

    const input = try term.openInputTTY(arena);

    var original_tty_state = try term.disableInputBuffering(input);
    defer term.setAttr(input, &original_tty_state); // reset original term state

    if (builtin.os.tag == .linux) {
        const sa = std.os.linux.Sigaction{ .handler = .{
            .handler = handleSigInt,
        }, .mask = [_]u32{0} ** 32, .flags = 0 };
        _ = std.os.linux.sigaction(2, &sa, null);
    }

    // no debug window
    if (!params.window) {
        vm.run();
        return;
    }

    // windows mode
    var ui = UI{ .vm = &vm };
    ui.init();
    ui.run();
}

fn handleSigInt(_: i32) callconv(.C) void {
    std.process.exit(0);
}

test "root" {
    _ = @import("lc3_test.zig");
}
