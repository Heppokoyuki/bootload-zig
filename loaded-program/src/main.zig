const std = @import("std");
const fmt = std.fmt;
const Zigsaw = @import("zigsaw.zig").Zigsaw;

export fn _start(zigsaw: *Zigsaw) noreturn {
    var fb: [*]u8 = @intToPtr([*]u8, zigsaw.frame_buffer.base);
    var i: u32 = 0;
    while (i < 640 * 480 * 4) : (i += 4) {
        fb[i] = @truncate(u8, @divTrunc(i, 256));
        fb[i + 1] = @truncate(u8, @divTrunc(i, 1536));
        fb[i + 2] = @truncate(u8, @divTrunc(i, 2560));
    }
    while (true) {}
}
