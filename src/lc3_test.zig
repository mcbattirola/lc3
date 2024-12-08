const std = @import("std");
const t = std.testing;

const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;
const Registers = lc3.Registers;
const reg_idx = lc3.reg_idx;
const flag = lc3.flag;

test "add op - immediate mode" {
    // TODO(matheus): test table;
    var instruction: u16 = 0;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    // dr = r7, sr = 1, imm5 = 3
    instruction = addI(reg_idx.r7, reg_idx.r1, 3);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r7.val()] = 3;
    expected[reg_idx.cond.val()] = flag.pos.val();
    try expectEqualRegisters(expected, vm.registers);

    // update r1 value and check again
    vm.registers[reg_idx.r1.val()] = 10;
    vm.add(instruction);
    expected[reg_idx.r1.val()] = 10;
    expected[reg_idx.r7.val()] = 13;
    try expectEqualRegisters(expected, vm.registers);

    // dr = r0, sr = r2, imm5 = 0
    instruction = addI(reg_idx.r0, reg_idx.r2, 0);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r0.val()] = 0;
    // update r2 and check again
    vm.registers[reg_idx.r2.val()] = 10_000;
    vm.add(instruction);
    expected[reg_idx.r2.val()] = 10_000;
    expected[reg_idx.r0.val()] = 10_000;
    expected[reg_idx.cond.val()] = flag.pos.val();
    try expectEqualRegisters(expected, vm.registers);

    // dr = r1, sr = r1, imm5 = 5
    instruction = addI(reg_idx.r1, reg_idx.r1, 5);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r1.val()] = 65;
    vm.registers[reg_idx.r1.val()] = 60;
    vm.add(instruction);
    expected[reg_idx.cond.val()] = flag.pos.val();
    try expectEqualRegisters(expected, vm.registers);

    // dr = r1, sr = r1, imm5 = -1
    instruction = addI(reg_idx.r1, reg_idx.r1, 65535);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r1.val()] = 65535; // -1 in two's complement
    expected[reg_idx.cond.val()] = flag.neg.val();
    try expectEqualRegisters(expected, vm.registers);

    vm.registers[reg_idx.r1.val()] = 1;
    expected[reg_idx.r1.val()] = 0;
    expected[reg_idx.cond.val()] = flag.zero.val();
    vm.add(instruction);
    try expectEqualRegisters(expected, vm.registers);

    // dr = r1, sr = r1, imm5 = -4
    instruction = addI(reg_idx.r1, reg_idx.r1, 65532);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r1.val()] = 65532; // -4 in two's complement
    expected[reg_idx.cond.val()] = flag.neg.val();

    try expectEqualRegisters(expected, vm.registers);
    vm.registers[reg_idx.r1.val()] = 128;
    vm.add(instruction);
    expected[reg_idx.r1.val()] = 124;
    expected[reg_idx.cond.val()] = flag.pos.val();
    try expectEqualRegisters(expected, vm.registers);
}

test "add op - non-immediate mode" {
    var instruction: u16 = 0;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    instruction = add(reg_idx.r1, reg_idx.r1, reg_idx.r1);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r7.val()] = 0;
    expected[reg_idx.cond.val()] = flag.zero.val();
    try expectEqualRegisters(expected, vm.registers);
    vm.registers[reg_idx.r1.val()] = 10;
    vm.add(instruction);
    expected[reg_idx.r1.val()] = 20;
    expected[reg_idx.cond.val()] = flag.pos.val();
    try expectEqualRegisters(expected, vm.registers);

    instruction = add(reg_idx.r1, reg_idx.r2, reg_idx.r3);
    vm = LC3{};
    vm.add(instruction);
    expected = lc3.newRegisters();
    expected[reg_idx.r7.val()] = 0;
    expected[reg_idx.cond.val()] = flag.zero.val();
    try expectEqualRegisters(expected, vm.registers);
    vm.registers[reg_idx.r1.val()] = 10;
    vm.registers[reg_idx.r2.val()] = 20;
    vm.registers[reg_idx.r3.val()] = 30;
    vm.add(instruction);
    expected[reg_idx.r1.val()] = 50;
    expected[reg_idx.r2.val()] = 20;
    expected[reg_idx.r3.val()] = 30;
    expected[reg_idx.cond.val()] = flag.pos.val();
    try expectEqualRegisters(expected, vm.registers);
    try t.expectEqual(@intFromEnum(flag.pos), vm.registers[reg_idx.cond.val()]);
}

fn expectEqualRegisters(expected: Registers, actual: Registers) !void {
    for (expected, 0..) |_, i| {
        try t.expectEqual(expected[i], actual[i]);
    }
}

fn addI(comptime dr: reg_idx, comptime sr: reg_idx, comptime imm5: u16) u16 {
    const opcode = 0b0001 << 12; // Opcode for ADD
    const dr_mask = @intFromEnum(dr) << 9; // Destination register
    const sr_mask = @intFromEnum(sr) << 6; // Source register
    const mode = 0b1 << 5; // Immediate mode
    const imm5_mask = imm5 & 0b11111; // Immediate value (5 bits)
    return opcode | dr_mask | sr_mask | mode | imm5_mask;
}

fn add(comptime dr: reg_idx, comptime sr1: reg_idx, comptime sr2: reg_idx) u16 {
    const opcode = 0b0001 << 12; // Opcode for ADD
    const dr_mask = @intFromEnum(dr) << 9; // Destination register
    const sr1_mask = @intFromEnum(sr1) << 6; // First source register
    const mode = 0b0 << 5; // Register mode
    const sr2_mask = @intFromEnum(sr2); // Second source register
    return opcode | dr_mask | sr1_mask | mode | sr2_mask;
}
