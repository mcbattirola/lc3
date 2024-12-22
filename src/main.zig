const std = @import("std");
const builtin = @import("builtin");
const term = @import("term.zig");
const cli = @import("cli.zig");
const UI = @import("ui.zig").UI;
const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;

// TODO: move this to term.zig, return a TerminalState from disableInputBuffering.
pub const TerminalState = union(enum) {
    none: void,
    linux: *std.os.linux.termios,
    windows: u32,
};

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

    // TODO: use a single switch (builtin.os.tag) block
    const input = switch (builtin.os.tag) {
        .linux => term.openInputTTY(arena),
        .windows => |_| blk: {
            const windows = std.os.windows;
            const handle = try windows.GetStdHandle(windows.STD_INPUT_HANDLE);
            break :blk handle;
        },
        else => @panic("unsupported platform"),
    };

    var terminal_state: TerminalState = .none;
    switch (builtin.os.tag) {
        .linux => {
            const st = try term.disableInputBufferingLinux(input);
            terminal_state = TerminalState{ .linux = st };
            const sa = std.os.linux.Sigaction{ .handler = .{
                .handler = handleSigInt,
            }, .mask = [_]u32{0} ** 32, .flags = 0 };
            _ = std.os.linux.sigaction(2, &sa, null);
        },
        .windows => {
            const st = term.disableInputBufferingWindows();
            terminal_state = TerminalState{ .windows = st };
        },
        else => @panic("unsupported platform"),
    }

    // TODO: fix this
    defer switch (terminal_state) {
        .linux => |st| term.setAttr(term.openInputTTY(arena) catch unreachable, st),
        .windows => |original_mode| _ = std.os.windows.kernel32.SetConsoleMode(input, original_mode),
        else => {},
    };

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
