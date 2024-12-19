const std = @import("std");

pub const OP = enum(u8) {
    BR = 0,
    ADD,
    LD,
    ST,
    JSR,
    AND,
    LDR,
    STR,
    RTI, // unused
    NOT,
    LDI,
    STI,
    JMP,
    RES, // reserved (unused)
    LEA,
    TRAP,

    pub fn val(self: OP) u16 {
        return @intFromEnum(self);
    }

    pub fn print(self: OP) void {
        switch (self) {
            OP.BR => std.debug.print("BR ({X})\n", .{@intFromEnum(self)}),
            OP.ADD => std.debug.print("ADD ({X})\n", .{@intFromEnum(self)}),
            OP.LD => std.debug.print("LD ({X})\n", .{@intFromEnum(self)}),
            OP.ST => std.debug.print("ST ({X})\n", .{@intFromEnum(self)}),
            OP.JSR => std.debug.print("JSR ({X})\n", .{@intFromEnum(self)}),
            OP.AND => std.debug.print("AND ({X})\n", .{@intFromEnum(self)}),
            OP.LDR => std.debug.print("LDR ({X})\n", .{@intFromEnum(self)}),
            OP.STR => std.debug.print("STR ({X})\n", .{@intFromEnum(self)}),
            OP.NOT => std.debug.print("NOT ({X})\n", .{@intFromEnum(self)}),
            OP.LDI => std.debug.print("LDI ({X})\n", .{@intFromEnum(self)}),
            OP.STI => std.debug.print("STI ({X})\n", .{@intFromEnum(self)}),
            OP.JMP => std.debug.print("JMP ({X})\n", .{@intFromEnum(self)}),
            OP.LEA => std.debug.print("LEA ({X})\n", .{@intFromEnum(self)}),
            OP.TRAP => std.debug.print("TRAP ({X})\n", .{@intFromEnum(self)}),
            else => std.debug.print("unknown ({X})\n", .{@intFromEnum(self)}),
        }
    }
};
