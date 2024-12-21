const std = @import("std");
const linux = std.os.linux;
const termios = linux.termios;

pub fn disableInputBuffering(in: *std.fs.File) !termios {
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

pub fn openInputTTY(allocator: std.mem.Allocator) !*std.fs.File {
    const f = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_only });
    const p = try allocator.create(std.fs.File);
    p.* = f;
    return p;
}

pub fn setAttr(in: *std.fs.File, t: *linux.termios) void {
    _ = linux.tcsetattr(in.handle, linux.TCSA.NOW, t);
}
