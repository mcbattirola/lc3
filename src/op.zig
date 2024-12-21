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
            OP.BR => std.debug.print("BR ({X})\n", .{self.val()}),
            OP.ADD => std.debug.print("ADD ({X})\n", .{self.val()}),
            OP.LD => std.debug.print("LD ({X})\n", .{self.val()}),
            OP.ST => std.debug.print("ST ({X})\n", .{self.val()}),
            OP.JSR => std.debug.print("JSR ({X})\n", .{self.val()}),
            OP.AND => std.debug.print("AND ({X})\n", .{self.val()}),
            OP.LDR => std.debug.print("LDR ({X})\n", .{self.val()}),
            OP.STR => std.debug.print("STR ({X})\n", .{self.val()}),
            OP.NOT => std.debug.print("NOT ({X})\n", .{self.val()}),
            OP.LDI => std.debug.print("LDI ({X})\n", .{self.val()}),
            OP.STI => std.debug.print("STI ({X})\n", .{self.val()}),
            OP.JMP => std.debug.print("JMP ({X})\n", .{self.val()}),
            OP.LEA => std.debug.print("LEA ({X})\n", .{self.val()}),
            OP.TRAP => std.debug.print("TRAP ({X})\n", .{self.val()}),
            else => std.debug.print("unknown ({X})\n", .{self.val()}),
        }
    }
};
