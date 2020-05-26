const std = @import("std");
const fmt = std.fmt;
const x86 = @import("x86.zig");

const port: u16 = @enumToInt(Port.COM1);

pub const Port = enum(u16) {
    COM1 = 0x3F8, COM2 = 0x2F8, COM3 = 0x3E8, COM4 = 0x2E8
};

pub fn init() void {
    x86.outb(port + 1, 0x00);
    x86.outb(port + 3, 0x80);
    x86.outb(port + 0, 0x01);
    x86.outb(port + 1, 0x00);
    x86.outb(port + 3, 0x03);
    x86.outb(port + 2, 0xc7);
    x86.outb(port + 4, 0x0b);
}

fn isTransmitEmpty() bool {
    return x86.inb(port + 5) & 0x20 > 0;
}

pub fn write(c: u8) void {
    while (!isTransmitEmpty()) {}
    x86.outb(port, c);
}

pub fn writeString(str: []const u8) void {
    for (str) |c| {
        write(c);
    }
}

pub fn printf(buf: []u8, comptime format: []const u8, args: var) void {
    writeString(fmt.bufPrint(buf, format, args) catch unreachable);
}
