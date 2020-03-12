const uefi = @import("std").os.uefi;
const BootServices = uefi.tables.BootServices;
const Guid = uefi.Guid;
const fmt = @import("std").fmt;
const SimpleFileSystemProtocol = uefi.protocols.SimpleFileSystemProtocol;
const FileProtocol = uefi.protocols.FileProtocol;
const Time = uefi.Time;
const FileInfo = uefi.protocols.FileInfo;

var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_:0]u16{ c, 0 });
    }
}

fn puts_multi(msg: []const u16) void {
    var i: usize = 0;
    while (msg[i] != 0) : (i += 1) {
        _ = con_out.outputString(&[_:0]u16{ msg[i], 0 });
    }
}

fn printf(buf: []u8, comptime format: []const u8, args: var) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

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
    const sfsp_guid align(8) = SimpleFileSystemProtocol.guid;

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
