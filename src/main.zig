const uefi = @import("std").os.uefi;
const BootServices = uefi.tables.BootServices;
const Guid = uefi.Guid;
const fmt = @import("std").fmt;

var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_:0]u16{ c, 0 });
    }
}

fn puts_multi(msg: []const u16) void {
    var i: usize = 0;
    puts("a\r\n");
    while (msg[i] != 0) : (i += 1) {
        _ = con_out.outputString(&[_:0]u16{ msg[i], 0 });
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: var) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

const SimpleFileSystemProtocol = extern struct {
    revision: u64,
    _open_volume: extern fn (*const SimpleFileSystemProtocol, **const FileProtocol) usize,

    pub fn openVolume(self: *const SimpleFileSystemProtocol, root: **const FileProtocol) usize {
        return self._open_volume(self, root);
    }
};

const FileProtocol = extern struct {
    _buf: u64,
    _open: extern fn (*const FileProtocol, **const FileProtocol, *u16, u64, u64) usize,
    _close: extern fn (*const FileProtocol) usize,
    _buf2: u64,
    _read: extern fn (*const FileProtocol, *u64, *c_void) usize,
    _write: extern fn (*const FileProtocol, *u64, *c_void) usize,
    _buf3: [4]u64,
    _flush: extern fn (*const FileProtocol) usize,

    pub fn open(self: *const FileProtocol, new_handle: **const FileProtocol, file_name: *u16, open_mode: u64, attributes: u64) usize {
        return self._open(self, new_handle, file_name, open_mode, attributes);
    }

    pub fn close(self: *const FileProtocol) usize {
        return self._close(self);
    }

    pub fn read(self: *const FileProtocol, buffer_size: *u64, buffer: *c_void) usize {
        return self._read(self, buffer_size, buffer);
    }

    pub fn write(self: *const FileProtocol, buffer_size: *u64, buffer: *c_void) usize {
        return self._write(self, buffer_size, buffer);
    }

    pub fn flush(self: *const FileProtocol) usize {
        return self._flush(self);
    }
};

const Time = extern struct {
    year: u16, month: u8, day: u8, hour: u8, minute: u8, second: u8, pad1: u8, nano_second: u32, time_zone: i16, day_light: u8, pad2: u8
};

const FileInfo = extern struct {
    size: u64, file_size: u64, physical_size: u64, create_time: Time, last_access_time: Time, modification_time: Time, attribute: u64, file_name: [100:0]u16
};

const max_file_buf: usize = 1024;

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;
    var root: *FileProtocol = undefined;
    var file_info: FileInfo = undefined;
    var file_buf: [max_file_buf]u8 = undefined;
    var buf_size: u64 = @bitCast(u64, max_file_buf);
    var simple_file_system_protocol: ?*SimpleFileSystemProtocol = undefined;
    var key: uefi.protocols.InputKey = undefined;
    var str: [3:0]u16 = undefined;
    var buf: [100]u8 = undefined;
    const sfsp_guid align(8) = Guid{
        .time_low = 0x0964e5b22,
        .time_mid = 0x6459,
        .time_high_and_version = 0x11d2,
        .clock_seq_high_and_reserved = 0x8e,
        .clock_seq_low = 0x39,
        .node = [_]u8{ 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b },
    };
    con_out = uefi.system_table.con_out.?;
    _ = con_out.clearScreen();
    puts("Hello, UEFI!\r\n");
    if (boot_services.locateProtocol(&sfsp_guid, null, @ptrCast(*?*c_void, &simple_file_system_protocol)) != uefi.status.success) {
        puts("locateProtocol Error!!\r\n");
    }
    if (simple_file_system_protocol.?.openVolume(&root) != uefi.status.success) {
        puts("openVolume Error!!\r\n");
    }
    while (true) {
        _ = root.read(&buf_size, @ptrCast(*c_void, &file_info));
        if (buf_size == 0)
            break;
        puts_multi(&file_info.file_name);
        puts(" ");
    }

    while (true) {
        if (uefi.system_table.con_in.?.readKeyStroke(&key) == uefi.status.success) {
            if (key.unicode_char != '\r') {
                str[0] = key.unicode_char;
                str[1] = 0;
            } else {
                str[0] = '\r';
                str[1] = '\n';
                str[2] = 0;
            }
            _ = con_out.outputString(&str);
        }
    }
}
