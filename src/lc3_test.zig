const std = @import("std");
const t = std.testing;

const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;
const Registers = lc3.Registers;
const reg_idx = lc3.reg_idx;

test "add op" {
    // immediate mode
    {
        // dr = r7, sr=1, imm5 = 3
        var instruction: u16 = 0b0001_111_001_1_00010;
        var vm = LC3{};
        vm.add(instruction);

        var expected: Registers = lc3.newRegisters();
        expected[reg_idx.r7.val()] = 2;

        try expectEqualRegisters(expected, vm.getRegisters());

        // update r1 value and check again
        var vmr = vm.getRegisters();
        vmr[reg_idx.r1.val()] = 10;
        vm.setRegisters(vmr);
        vm.add(instruction);

        expected[reg_idx.r1.val()] = 10;
        expected[reg_idx.r7.val()] = 12;
        try expectEqualRegisters(expected, vm.getRegisters());

        // dr = r0, sr=r2, imm5 = 0
        instruction = 0b0001_000_010_1_00000;
        vm = LC3{};
        vm.add(instruction);
        expected = lc3.newRegisters();
        expected[reg_idx.r0.val()] = 0;
        // update r2 and check again
        vmr = vm.getRegisters();
        vmr[reg_idx.r2.val()] = 10_000;
        vm.setRegisters(vmr);
        vm.add(instruction);

        expected[reg_idx.r2.val()] = 10_000;
        expected[reg_idx.r0.val()] = 10_000;
        try expectEqualRegisters(expected, vm.getRegisters());
    }
}

fn expectEqualRegisters(expected: Registers, actual: Registers) !void {
    for (expected, 0..) |_, i| {
        try t.expectEqual(expected[i], actual[i]);
    }
}
