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
};
