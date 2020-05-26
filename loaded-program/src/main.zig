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
    serial.printf(buf[0..], "zigsaw: {*}, fb: {*}, base: {x}\n", .{ zigsaw, zigsaw.frame_buffer, zigsaw.frame_buffer.base });
    var fb: [*]u8 = @intToPtr([*]u8, zigsaw.frame_buffer.base);
    var i: u32 = 0;
    while (i < 640 * 480 * 4) : (i += 4) {
        fb[i] = @truncate(u8, @divTrunc(i, 256));
        fb[i + 1] = @truncate(u8, @divTrunc(i, 1536));
        fb[i + 2] = @truncate(u8, @divTrunc(i, 2560));
    }
    serial.writeString("hello\n");
    while (true) {}
}
