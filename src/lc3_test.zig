const std = @import("std");
const t = std.testing;

const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;
const Registers = lc3.Registers;
const reg_idx = lc3.reg_idx;
const flag = lc3.flag;

// TODO(matheus): test tables

test "add" {
    var instruction: u16 = 0;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    instruction = add(reg_idx.r1, reg_idx.r1, reg_idx.r1);
    vm = LC3{};
    vm.opADD(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    try expectEqualRegisters(expected, vm.registers);
    vm.registers = [_]u16{ 0, 10, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    vm.opADD(instruction);
    expected = [_]u16{ 0, 20, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);

    instruction = add(reg_idx.r1, reg_idx.r2, reg_idx.r3);
    vm = LC3{};
    vm.opADD(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    try expectEqualRegisters(expected, vm.registers);
    vm.registers = [_]u16{ 0, 10, 20, 30, 0, 0, 0, 0, 0, flag.pos.val() };
    vm.opADD(instruction);
    expected = [_]u16{ 0, 50, 20, 30, 0, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);
    try t.expectEqual(@intFromEnum(flag.pos), vm.registers[reg_idx.cond.val()]);
}

test "add immediate" {
    var instruction: u16 = 0;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    // dr = r7, sr = 1, imm5 = 3
    instruction = addI(reg_idx.r7, reg_idx.r1, 3);
    vm = LC3{};
    vm.opADD(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 3, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);

    // update r1 value and check again
    vm.registers = [_]u16{ 0, 10, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    vm.registers[reg_idx.r1.val()] = 10;
    vm.opADD(instruction);
    expected = [_]u16{ 0, 10, 0, 0, 0, 0, 0, 13, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);

    // dr = r0, sr = r2, imm5 = 0
    instruction = addI(reg_idx.r0, reg_idx.r2, 0);
    vm = LC3{};
    vm.opADD(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    // update r2 and check again
    vm.registers[reg_idx.r2.val()] = 10_000;
    vm.registers = [_]u16{ 0, 0, 10_000, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    vm.opADD(instruction);
    expected = [_]u16{ 10_000, 0, 10_000, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);

    // dr = r1, sr = r1, imm5 = 5
    instruction = addI(reg_idx.r1, reg_idx.r1, 5);
    vm = LC3{};
    vm.opADD(instruction);
    expected = [_]u16{ 0, 65, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    vm.registers = [_]u16{ 0, 60, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    vm.opADD(instruction);
    try expectEqualRegisters(expected, vm.registers);

    // dr = r1, sr = r1, imm5 = -1
    instruction = addI(reg_idx.r1, reg_idx.r1, 65535);
    vm = LC3{};
    vm.opADD(instruction);
    expected = lc3.newRegisters();
    // -1 in two's complement
    expected = [_]u16{ 0, 65535, 0, 0, 0, 0, 0, 0, 0, flag.neg.val() };
    try expectEqualRegisters(expected, vm.registers);

    vm.registers[reg_idx.r1.val()] = 1;
    vm.registers = [_]u16{ 0, 1, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    vm.opADD(instruction);
    try expectEqualRegisters(expected, vm.registers);

    // dr = r1, sr = r1, imm5 = -4
    instruction = addI(reg_idx.r1, reg_idx.r1, 65532);
    vm = LC3{};
    vm.opADD(instruction);
    expected = [_]u16{ 0, 65532, 0, 0, 0, 0, 0, 0, 0, flag.neg.val() };
    try expectEqualRegisters(expected, vm.registers);

    vm.registers[reg_idx.r1.val()] = 128;
    vm.opADD(instruction);
    expected = [_]u16{ 0, 124, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);
}

test "and" {
    var instruction: u16 = 0;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    instruction = andNonImm(reg_idx.r1, reg_idx.r1, reg_idx.r1);
    vm = LC3{};
    vm.opAND(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    try expectEqualRegisters(expected, vm.registers);
    vm.registers[reg_idx.r1.val()] = 20;
    vm.opAND(instruction);
    expected = [_]u16{ 0, 20, 0, 0, 0, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);

    instruction = andNonImm(reg_idx.r2, reg_idx.r3, reg_idx.r4);
    vm = LC3{};
    vm.registers[reg_idx.r3.val()] = 0b00001111;
    vm.registers[reg_idx.r4.val()] = 0b11111111;
    vm.opAND(instruction);
    expected = [_]u16{ 0, 0, 0b00001111, 0b00001111, 0b11111111, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);
}

test "and immediate" {
    var instruction: u16 = 0;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    instruction = andI(reg_idx.r1, reg_idx.r1, 65535);
    vm = LC3{};
    vm.opAND(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    try expectEqualRegisters(expected, vm.registers);

    vm.registers[reg_idx.r1.val()] = 65535;
    vm.opAND(instruction);
    expected = [_]u16{ 0, 65535, 0, 0, 0, 0, 0, 0, 0, flag.neg.val() };
    try expectEqualRegisters(expected, vm.registers);

    instruction = andI(reg_idx.r2, reg_idx.r3, 5);
    vm = LC3{};
    vm.registers[reg_idx.r3.val()] = 1;
    vm.opAND(instruction);
    expected = [_]u16{ 0, 0, 1, 1, 0, 0, 0, 0, 0, flag.pos.val() };
    try expectEqualRegisters(expected, vm.registers);
}

test "br" {
    var instruction: u16 = 0b0000_100_000000000;
    var vm: LC3 = undefined;
    var expected: Registers = undefined;

    vm = LC3{};
    vm.opBR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    try expectEqualRegisters(expected, vm.registers);

    // check n, offset = 3
    instruction = 0b0000_100_000000011;
    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.neg.val() };
    vm.opBR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 3, flag.neg.val() };
    try expectEqualRegisters(expected, vm.registers);

    vm.opBR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 6, flag.neg.val() };
    try expectEqualRegisters(expected, vm.registers);

    // check z, offset = 5
    instruction = 0b0000_010_000000101;
    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    vm.opBR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 5, flag.zero.val() };
    try expectEqualRegisters(expected, vm.registers);

    // check p, offset = 16
    instruction = 0b0000_010_000010000;
    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, flag.zero.val() };
    vm.opBR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 16, flag.zero.val() };
    try expectEqualRegisters(expected, vm.registers);
}

test "jsr" {
    var instruction: u16 = 0b0100_1_00000000001;
    var vm: LC3 = LC3{};
    var expected: Registers = undefined;

    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0xFE, 0 };
    vm.opJSR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0xFE, 0xFF, 0 };
    try expectEqualRegisters(expected, vm.registers);

    instruction = 0b0100_1_00000001111;
    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    vm.opJSR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0b1111, 0 };
    try expectEqualRegisters(expected, vm.registers);
}

test "jssr" {
    var instruction: u16 = 0b0100_0_00_111_000000;
    var vm: LC3 = LC3{};
    var expected: Registers = undefined;

    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0xFE, 0 };
    vm.opJSR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0xFE, 0b111, 0 };
    try expectEqualRegisters(expected, vm.registers);

    instruction = 0b0100_0_00_101_000000;
    vm.registers = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    vm.opJSR(instruction);
    expected = [_]u16{ 0, 0, 0, 0, 0, 0, 0, 0, 0b101, 0 };
    try expectEqualRegisters(expected, vm.registers);
}

fn expectEqualRegisters(expected: Registers, actual: Registers) !void {
    for (expected, 0..) |_, i| {
        try t.expectEqual(expected[i], actual[i]);
    }
}

fn addI(comptime dr: reg_idx, comptime sr: reg_idx, comptime imm5: u16) u16 {
    return immOp(0b0001, dr, sr, imm5);
}

fn add(comptime dr: reg_idx, comptime sr1: reg_idx, comptime sr2: reg_idx) u16 {
    return op(0b0001, dr, sr1, sr2);
}

fn andI(comptime dr: reg_idx, comptime sr: reg_idx, comptime imm5: u16) u16 {
    return immOp(0b0101, dr, sr, imm5);
}

fn andNonImm(comptime dr: reg_idx, comptime sr1: reg_idx, comptime sr2: reg_idx) u16 {
    return op(0b0101, dr, sr1, sr2);
}

// works for ADD and AND
fn immOp(comptime code: u16, comptime dr: reg_idx, comptime sr: reg_idx, comptime imm5: u16) u16 {
    const op_code = code << 12;
    const dr_mask = @intFromEnum(dr) << 9; // Destination register
    const sr_mask = @intFromEnum(sr) << 6; // Source register
    const mode = 0b1 << 5; // Immediate mode
    const imm5_mask = imm5 & 0b11111; // Immediate value (5 bits)
    return op_code | dr_mask | sr_mask | mode | imm5_mask;
}

// works for ADD and AND
fn op(comptime code: u16, comptime dr: reg_idx, comptime sr1: reg_idx, comptime sr2: reg_idx) u16 {
    const op_code = code << 12;
    const dr_mask = @intFromEnum(dr) << 9; // Destination register
    const sr1_mask = @intFromEnum(sr1) << 6; // First source register
    const mode = 0b0 << 5; // Register mode
    const sr2_mask = @intFromEnum(sr2); // Second source register
    return op_code | dr_mask | sr1_mask | mode | sr2_mask;
}
