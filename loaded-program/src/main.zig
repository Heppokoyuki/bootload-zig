const std = @import("std");
const fmt = std.fmt;
const Zigsaw = @import("zigsaw.zig").Zigsaw;
const FrameBuffer = @import("zigsaw.zig").FrameBuffer;
const serial = @import("serial.zig");
const builtin = @import("builtin");

var buf: [200]u8 = undefined;

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);
    serial.writeString("PANIC: ");
    serial.writeString(msg);
    serial.writeString("\n");
    while (true) {}
}

export fn _start(zigsaw: *Zigsaw) noreturn {
    serial.init();
    var fb: [*]u8 = @intToPtr([*]u8, zigsaw.frame_buffer.base);
    var i: u32 = 0;

    serial.writeString("hello\n");
    while (i < zigsaw.frame_buffer.hr * zigsaw.frame_buffer.vr * 4) : (i += 4) {
        fb[i] = 0;
        fb[i + 1] = 255;
        fb[i + 2] = 0;
    }
    while (true) {}
}
