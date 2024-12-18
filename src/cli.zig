const std = @import("std");
const MEMORY_SIZE = @import("lc3.zig").MEMORY_SIZE;

pub const Params = struct {
    rom: []const u16 = undefined,
};

pub fn parseParams(allocator: std.mem.Allocator) !Params {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // ignore bin name

    var params = Params{};

    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--rom") or std.mem.startsWith(u8, arg, "-r")) {
            const file_path = args.next() orelse return error.InvalidArgument;
            params.rom = try readRom(file_path, allocator);
            continue;
        }
    }
    return params;
}

fn readRom(file_path: []const u8, allocator: std.mem.Allocator) ![]u16 {
    // The first 16 bits of the program file specify the address in memory where the program should start.
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        return err;
    };
    defer file.close();
    const reader = file.reader();

    var origin = try reader.readVarInt(u16, std.builtin.Endian.little, 1);
    origin = @byteSwap(origin);

    const max_read = @as(u32, @intCast(MEMORY_SIZE)) - @as(u32, @intCast(origin));

    const bytes = try allocator.alignedAlloc(u8, @alignOf(u16), max_read * @sizeOf(u16));
    _ = try reader.readAll(bytes);

    const words: []u16 = std.mem.bytesAsSlice(u16, bytes[0..]);
    for (words) |*w| {
        w.* = @byteSwap(w.*);
    }
    return words;
}
