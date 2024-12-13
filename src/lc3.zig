const std = @import("std");
const OP = @import("op.zig").OP;

// 65536 memory locations
const MEMORY_SIZE = 1 << 16;
const PC_START = 0x3000;

// register indexes
pub const reg_idx = enum(usize) {
    r0 = 0,
    r1,
    r2,
    r3,
    r4,
    r5,
    r6,
    r7,
    pc,
    cond,

    pub fn val(self: reg_idx) usize {
        return @intFromEnum(self);
    }
};

pub const Registers = [10]u16;
pub fn newRegisters() Registers {
    var r: Registers = undefined;
    @memset(&r, 0);
    return r;
}

// condition flags
pub const flag = enum(u8) {
    pos = 1 << 0,
    zero = 1 << 1,
    neg = 1 << 2,

    pub fn val(self: flag) u8 {
        return @intFromEnum(self);
    }
};

pub const LC3 = struct {
    memory: [MEMORY_SIZE]u16 = undefined,
    registers: Registers = newRegisters(),

    running: bool = true,

    pub fn run(self: *LC3) void {
        const qty = 10;
        self.memory[qty - 1] = 10;
        std.debug.print("First {d} bytes: {any}!\n", .{ qty, self.memory[0..qty] });

        self.registers[reg_idx.pc.val()] = PC_START;
        while (self.running) {
            const instruction = self.fetch();
            const op: OP = @enumFromInt(instruction >> 12);
            std.debug.print("got instruction {d}!\n", .{op.val()});
            switch (op) {
                OP.BR => self.opBR(instruction),
                OP.ADD => self.opADD(instruction),
                OP.LD => self.opLD(instruction),
                OP.ST => self.opST(instruction),
                OP.JSR => self.opJSR(instruction),
                OP.AND => self.opAND(instruction),
                OP.LDR => self.opLDR(instruction),
                OP.STR => self.opSTR(instruction),
                OP.NOT => self.opNOT(instruction),
                OP.LDI => self.opLDI(instruction),
                OP.STI => self.opSTI(instruction),
                OP.JMP => self.opJMP(instruction),
                OP.LEA => self.opLEA(instruction),
                OP.TRAP => self.opTRAP(instruction),
                else => {
                    printRegisters(self.registers);
                    self.running = false;
                    std.debug.print("unknown instruction {d}, stop\n", .{op.val()});
                },
            }
        }
    }

    // returns an instruction from memory and increments pc
    pub fn fetch(self: *LC3) u16 {
        if (self.registers[reg_idx.pc.val()] == PC_START) {
            std.debug.print("return ADD\n", .{});
            self.incrementPC();
            return 0b0001_111_001_1_00011;
        }
        // TODO(matheus): fetch from memory

        self.incrementPC();
        return OP.BR.val() << 12;
    }

    pub fn incrementPC(self: *LC3) void {
        self.registers[reg_idx.pc.val()] += 1;
    }

    pub fn opBR(self: *LC3, instruction: u16) void {
        const pc_offset = signExtend(instruction & 0x1FF, 9);
        const cond_flag = (instruction >> 9) & 0b111;
        if ((cond_flag & self.registers[reg_idx.cond.val()] != 0)) {
            self.registers[reg_idx.pc.val()] += pc_offset;
        }
    }

    pub fn opADD(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const sr1 = (instruction >> 6) & 0b111;

        const immediate = (instruction >> 5) & 0b1;
        if (immediate == 1) {
            const imm5 = signExtend(instruction & 0b11111, 5);
            self.registers[dr], _ = @addWithOverflow(self.registers[sr1], imm5);
        } else {
            const sr2 = instruction & 0b111;
            self.registers[dr], _ = @addWithOverflow(self.registers[sr1], self.registers[sr2]);
        }
        self.updateFlags(@enumFromInt(dr));
    }

    // TODO: tests
    pub fn opLD(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const pc_offset = signExtend(instruction & 0x1FF, 9);

        self.registers[dr] = self.readMem(self.registers[reg_idx.pc.val()] + pc_offset);
        self.updateFlags(@enumFromInt(dr));
    }

    // TODO: test
    pub fn opST(self: *LC3, instruction: u16) void {
        const sr = (instruction >> 9) & 0b111;
        const pc_offset = signExtend(instruction & 0x1FF, 9);
        // mem[pc + offset] = sr
        self.writeMem(self.registers[reg_idx.pc.val() + pc_offset], self.registers[sr]);
    }

    pub fn opJSR(self: *LC3, instruction: u16) void {
        // store PC in r7
        self.registers[reg_idx.r7.val()] = self.registers[reg_idx.pc.val()];

        if ((instruction >> 11) & 1 == 1) {
            // JSR
            const pc_offset = signExtend(instruction & 0x1FF, 11);
            self.registers[reg_idx.pc.val()] += pc_offset;
        } else {
            // JSSR
            const base = (instruction >> 6) & 0x7;
            self.registers[reg_idx.pc.val()] = base;
        }
    }

    pub fn opAND(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const sr1 = (instruction >> 6) & 0b111;

        const immediate = (instruction >> 5) & 0b1;
        if (immediate == 1) {
            const imm5 = signExtend(instruction & 0b11111, 5);
            self.registers[dr] = self.registers[sr1] & imm5;
        } else {
            const sr2 = instruction & 0b111;
            self.registers[dr] = self.registers[sr1] & self.registers[sr2];
        }
        self.updateFlags(@enumFromInt(dr));
    }

    // TODO: tests
    pub fn opLDR(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0x7;
        const base = (instruction >> 6) & 0x7;
        const offset = signExtend(instruction & 0x3F, 6);

        self.registers[dr] = self.readMem(self.registers[base] + offset);
        self.updateFlags(@enumFromInt(dr));
    }

    pub fn opSTR(self: *LC3, instruction: u16) void {
        self.TODO(instruction);
    }

    pub fn opNOT(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const sr = (instruction >> 6) & 0b111;
        self.registers[dr] = ~self.registers[sr];
        self.updateFlags(@enumFromInt(dr));
    }

    // TODO: tests when readMem is implemented
    pub fn opLDI(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const pc_offset = signExtend(instruction & 0x1FF, 9);

        self.registers[dr] = self.readMem(self.readMem(self.registers[reg_idx.pc.val()] + pc_offset));
        self.updateFlags(@enumFromInt(dr));
    }

    // TODO: test
    pub fn opSTI(self: *LC3, instruction: u16) void {
        const sr = (instruction >> 9) & 0b111;
        const pc_offset = signExtend(instruction & 0x1FF, 9);
        // mem[mem[pc + offset]] = sr
        self.writeMem(self.readMem(self.registers[reg_idx.pc.val() + pc_offset]), self.registers[sr]);
    }

    pub fn opJMP(self: *LC3, instruction: u16) void {
        // also handles RET since 'base' will be 7
        const base = (instruction >> 6) & 0x7;
        self.registers[reg_idx.pc.val()] = base;
    }

    // TODO: tests
    pub fn opLEA(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const pc_offset = signExtend(instruction & 0x1FF, 9);
        self.registers[dr] = self.registers[reg_idx.pc.val()] + pc_offset;
        self.updateFlags(@enumFromInt(dr));
    }

    pub fn opTRAP(self: *LC3, instruction: u16) void {
        self.TODO(instruction);
    }

    pub fn updateFlags(self: *LC3, reg: reg_idx) void {
        // zero
        if (self.registers[reg.val()] == 0) {
            self.registers[reg_idx.cond.val()] = flag.zero.val();
            return;
        }
        // negative
        if ((self.registers[reg.val()] >> 15) == 1) {
            self.registers[reg_idx.cond.val()] = flag.neg.val();
            return;
        }
        // positive
        self.registers[reg_idx.cond.val()] = flag.pos.val();
    }

    pub fn readMem(self: *LC3, addr: u16) u16 {
        return self.memory[addr];
    }

    pub fn writeMem(self: *LC3, addr: u16, val: u16) void {
        self.memory[addr] = val;
    }

    pub fn TODO(self: *LC3, instruction: u16) void {
        std.debug.print("TODO - {d}, {any}", .{ instruction, self.running });
    }
};

pub fn printRegisters(registers: Registers) void {
    std.debug.print("R0: {d}\nR1: {d}\nR2: {d}\nR3: {d}\nR4: {d}\nR5: {d}\nR6: {d}\nR7: {d}\nPC: {d}\nCOND: {d}\n", .{
        registers[reg_idx.r0.val()],
        registers[reg_idx.r1.val()],
        registers[reg_idx.r2.val()],
        registers[reg_idx.r3.val()],
        registers[reg_idx.r4.val()],
        registers[reg_idx.r5.val()],
        registers[reg_idx.r6.val()],
        registers[reg_idx.r7.val()],
        registers[reg_idx.pc.val()],
        registers[reg_idx.cond.val()],
    });
}

fn signExtend(val: u16, comptime bit_count: u16) u16 {
    const sign_bit = 1 << (bit_count - 1);
    if (val & sign_bit != 0) {
        return val | @as(u16, @truncate((0xFFFF << bit_count)));
        // return val | mask;
    }
    return val;
}

test "signExtend" {
    // Test with a positive value that doesn't need sign extension
    try std.testing.expectEqual(0, signExtend(0, 5));
    try std.testing.expectEqual(0b01100, signExtend(0b01100, 5));

    // Test with a negative value (highest bit set) needing sign extension
    try std.testing.expectEqual(65535, signExtend(0b11111, 5));
    try std.testing.expectEqual(0xFFFE, signExtend(0b11110, 5));

    // Test with full bit-width (16 bits) - no extension needed
    try std.testing.expectEqual(0x7FFF, signExtend(0x7FFF, 16));
    try std.testing.expectEqual(0xFFFF, signExtend(0xFFFF, 16));
}
