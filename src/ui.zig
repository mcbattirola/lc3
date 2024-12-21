const std = @import("std");
const lc3 = @import("lc3.zig");
const LC3 = lc3.LC3;
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;

pub const State = enum {
    stopped,
    running,
};

pub const UI = struct {
    sim_state: State = State.stopped,
    vm: *LC3,

    pub fn init(_: *UI) void {}

    pub fn run(self: *UI) void {
        rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "lc3");
        defer rl.closeWindow();

        rl.setTargetFPS(60);

        while (!rl.windowShouldClose()) {
            self.update();
            self.draw();
        }
    }

    fn update(self: *UI) void {
        if (rl.isKeyPressed(rl.KeyboardKey.key_d)) {
            self.vm.debug = !self.vm.debug;
        }

        switch (self.sim_state) {
            State.stopped => {
                // input handling
                if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
                    self.sim_state = State.running;
                }
            },
            State.running => {
                // input handling
                if (rl.isKeyPressed(rl.KeyboardKey.key_p)) {
                    self.sim_state = State.stopped;
                }

                self.vm.runCycle();
            },
        }
    }

    fn draw(self: *UI) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);
        rl.drawText("TODO", 0, 0, 40, rl.Color.red);
        drawTextFmt("current state: {d}", .{@intFromEnum(self.sim_state)}, 100, 100, 20, rl.Color.lime) catch unreachable;
        drawTextFmt("debug: {?}", .{self.vm.debug}, 100, 130, 20, rl.Color.lime) catch unreachable;
    }
};

var buf: [80]u8 = undefined;
pub fn drawTextFmt(comptime fmt: []const u8, args: anytype, x: i32, y: i32, size: i32, color: rl.Color) !void {
    const r = try std.fmt.bufPrintZ(&buf, fmt, args);
    rl.drawText(r, x, y, size, color);
}
