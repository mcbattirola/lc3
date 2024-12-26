const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;
const termios = linux.termios;
const windows = std.os.windows;
const kernel32 = windows.kernel32;

pub const TerminalState = union(enum) {
    none: void,
    linux: *std.os.linux.termios,
    windows: u32,
};

pub fn disableInputBuffering(input: *anyopaque) TerminalState {
    var terminal_state: TerminalState = .none;
    switch (builtin.os.tag) {
        .linux => {
            const st = try disableInputBufferingLinux(input);
            terminal_state = TerminalState{ .linux = st };
        },
        .windows => {
            const st = disableInputBufferingWindows();
            terminal_state = TerminalState{ .windows = st };
        },
        else => @panic("unsupported platform"),
    }
    return terminal_state;
}

fn disableInputBufferingLinux(in: *std.fs.File) !termios {
    var t = termios{
        .iflag = .{},
        .oflag = .{},
        .cflag = .{},
        .lflag = .{},
        .cc = std.mem.zeroes([32]u8),
        .line = 0,
        .ispeed = linux.speed_t.B38400,
        .ospeed = linux.speed_t.B38400,
    };

    // Get current terminal attributes
    _ = linux.tcgetattr(in.handle, &t);
    const original_state = t;

    t.lflag.ECHO = false;
    t.lflag.ICANON = false;

    setAttr(in, &t);

    return original_state;
}

fn disableInputBufferingWindows() windows.DWORD {
    const in = windows.GetStdHandle(windows.STD_INPUT_HANDLE) catch unreachable;
    const ENABLE_ECHO_INPUT: windows.DWORD = 0x0004;
    const ENABLE_LINE_INPUT: windows.DWORD = 0x0002;
    var old_mode: windows.DWORD = 0;

    // ignoring errors for now
    _ = kernel32.GetConsoleMode(in, &old_mode);
    const new_mode = old_mode & ~ENABLE_ECHO_INPUT & ~ENABLE_LINE_INPUT;
    _ = kernel32.SetConsoleMode(in, new_mode);
    return old_mode;
}

pub fn openInputTTY(allocator: std.mem.Allocator) !*std.fs.File {
    const f = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_only });
    const p = try allocator.create(std.fs.File);
    p.* = f;
    return p;
}

pub fn setTermState(st: TerminalState) void {
    switch (builtin.os.tag) {
        .linux => {
            setAttr(st.linux);
        },
        .windows => {
            const in = windows.GetStdHandle(windows.STD_INPUT_HANDLE) catch unreachable;
            _ = kernel32.SetConsoleMode(in, st.windows);
        },
        else => @panic("unsupported platform"),
    }
}

// set linux terminal attr
fn setAttr(in: *std.fs.File, t: *linux.termios) void {
    _ = linux.tcsetattr(in.handle, linux.TCSA.NOW, t);
}
