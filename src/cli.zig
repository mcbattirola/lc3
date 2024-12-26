const std = @import("std");
const MEMORY_SIZE = @import("lc3.zig").MEMORY_SIZE;

const help =
    \\ Usage: 
    \\  lc3 [options]
    \\
    \\ Options:
    \\  -h, --help                  Display this help
    \\  -r <file>, --rom <file>     Runs the ROM file (required)
    \\
;

const err_msg = "run `lc3 --help` to see all options";

pub const Params = struct {
    rom: []const u16 = undefined,
};

pub const ParamsError = error{
    MissingROM,
};

pub fn parseParams(allocator: std.mem.Allocator) !Params {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // ignore bin name

    var params = Params{};
    var rom_init = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            printHelp();
            std.process.exit(0);
        }
        if (std.mem.startsWith(u8, arg, "--rom") or std.mem.startsWith(u8, arg, "-r")) {
            const file_path = args.next() orelse return error.InvalidArgument;
            params.rom = try readRom(file_path, allocator);
            rom_init = true;
            continue;
        }
    }

    if (!rom_init) {
        std.debug.print("rom option is required\n", .{});
        std.debug.print(err_msg, .{});
        std.debug.print("\n", .{});
        return ParamsError.MissingROM;
    }

    return params;
}

fn printHelp() void {
    std.io.getStdOut().writer().print(help, .{}) catch unreachable;
}

fn readRom(file_path: []const u8, allocator: std.mem.Allocator) ![]u16 {
    // The first 16 bits of the program file specify the address in memory where the program should start.
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        return err;
    };
    defer file.close();
    const reader = file.reader();

    var origin = try reader.readInt(u16, std.builtin.Endian.little);
    origin = @byteSwap(origin);

    const max_read = @as(u32, @intCast(MEMORY_SIZE)) - @as(u32, @intCast(origin));

    const bytes: []u16 = try allocator.alloc(u16, MEMORY_SIZE);
    @memset(bytes, 0);

    var mem_idx = origin;
    while (mem_idx <= max_read) {
        const word = reader.readInt(u16, std.builtin.Endian.little) catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        bytes[mem_idx] = @byteSwap(word);
        mem_idx += 1;
    }
    return bytes;
}
