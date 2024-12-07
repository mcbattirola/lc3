const std = @import("std");
const OP = @import("op.zig").OP;

// 65536 memory locations
const MEMORY_SIZE = 1 << 16;
const PC_START = 0x3000;

// register indexes
const reg = enum(usize) {
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

    pub fn val(self: reg) usize {
        return @intFromEnum(self);
    }
};

// condition flags
const flag = enum(u8) {
    pos = 1 << 0,
    zero = 1 << 1,
    neg = 1 << 2,
};

pub const LC3 = struct {
    memory: [MEMORY_SIZE]u16 = undefined,
    registers: [10]u16 = undefined,

    running: bool = true,

    pub fn run(self: *LC3) void {
        const qty = 10;
        self.memory[qty - 1] = 10;
        std.debug.print("First {d} bytes: {any}!\n", .{ qty, self.memory[0..qty] });

        self.registers[reg.pc.val()] = PC_START;
        while (self.running) {
            const instruction = self.fetch();
            const op: OP = @enumFromInt(instruction >> 12);
            std.debug.print("got instruction {d}!\n", .{op.val()});
            switch (op) {
                // OP.BR => {},
                OP.ADD => self.add(instruction),
                else => {
                    self.printRegisters();
                    self.running = false;
                },
            }
        }
    }

    // returns an instruction from memory and increments pc
    pub fn fetch(self: *LC3) u16 {
        if (self.registers[reg.pc.val()] == PC_START) {
            std.debug.print("return ADD\n", .{});
            self.incrementPC();
            return 0b0001_111_001_1_00010;
        }
        // TODO: fetch from memory

        self.incrementPC();
        return OP.BR.val() << 12;
    }

    pub fn incrementPC(self: *LC3) void {
        self.registers[reg.pc.val()] += 1;
    }

    pub fn add(self: *LC3, instruction: u16) void {
        const dr = (instruction >> 9) & 0b111;
        const sr1 = (instruction >> 6) & 0b111;

        const immediate = (instruction >> 5) & 0b1;
        if (immediate == 1) {
            const imm5 = instruction & 0b11111;
            self.registers[dr] = self.registers[sr1] + imm5;
            return;
        }

        const sr2 = instruction & 0b111;
        self.registers[dr] = self.registers[sr1] + self.registers[sr2];
    }

    // prints the state of the the machine
    pub fn printRegisters(self: *LC3) void {
        std.debug.print("R0: {d}\nR1: {d}\nR2: {d}\nR3: {d}\nR4: {d}\nR5: {d}\nR6: {d}\nR7: {d}\nPC: {d}\nCOND: {d}\n", .{
            self.registers[reg.r0.val()],
            self.registers[reg.r1.val()],
            self.registers[reg.r2.val()],
            self.registers[reg.r3.val()],
            self.registers[reg.r4.val()],
            self.registers[reg.r5.val()],
            self.registers[reg.r6.val()],
            self.registers[reg.r7.val()],
            self.registers[reg.pc.val()],
            self.registers[reg.cond.val()],
        });
    }
};
