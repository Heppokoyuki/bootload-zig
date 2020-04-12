const uefi = @import("std").os.uefi;
const FileProtocol = uefi.protocols.FileProtocol;
const FileInfo = uefi.protocols.FileInfo;
const SimpleFileSystemProtocol = uefi.protocols.SimpleFileSystemProtocol;
const AllocateType = uefi.tables.AllocateType;
const MemoryType = uefi.tables.MemoryType;
const Guid = uefi.Guid;
const fmt = @import("std").fmt;

var boot_services: *uefi.tables.BootServices = undefined;
var simple_file_system_protocol: ?*SimpleFileSystemProtocol = undefined;
var con_out: *uefi.protocols.SimpleTextOutputProtocol = undefined;

var sfsp_guid align(8) = SimpleFileSystemProtocol.guid;
var file_info_guid align(8) = FileProtocol.guid;

pub var root_file: *FileProtocol = undefined;

pub fn puts(msg: []const u8) void {
    for (msg) |c| {
        _ = con_out.outputString(&[_:0]u16{ c, 0 });
    }
}

pub fn puts_multi(msg: [*:0]const u16) void {
    var i: usize = 0;
    while (msg[i] != 0) : (i += 1) {
        _ = con_out.outputString(&[_:0]u16{ msg[i], 0 });
    }
}

pub fn puts_raw(msg: [*:0]const u16) void {
    _ = con_out.outputString(msg);
}

pub fn printf(buf: []u8, comptime format: []const u8, args: var) void {
    puts(fmt.bufPrint(buf, format, args) catch unreachable);
}

pub fn init() void {
    boot_services = uefi.system_table.boot_services.?;
    con_out = uefi.system_table.con_out.?;

    _ = con_out.clearScreen();

    if (boot_services.locateProtocol(&sfsp_guid, null, @ptrCast(*?*c_void, &simple_file_system_protocol)) != uefi.Status.Success) {
        puts("locateProtocol Error!!\r\n");
    }

    if (simple_file_system_protocol.?.openVolume(&root_file) != uefi.Status.Success) {
        puts("openVolume Error!!\r\n");
    }
}

pub fn open_file(path: [*:0]const u16) *FileProtocol {
    var file: *FileProtocol = undefined;
    if (root_file.open(&file, path, FileProtocol.efi_file_mode_read, 0) != uefi.Status.Success) {
        puts("file open error!!\r\n");
    }
    return file;
}

pub fn read_file_info(file: *FileProtocol, info: **FileInfo) void {
    var buf_size: usize = 1024;
    var buf: [1024]u8 = undefined;
    var fmt_buf: [1024]u8 = undefined;
    if (file.get_info(&file_info_guid, &buf_size, @ptrCast([*]u8, &buf)) != uefi.Status.Success) {
        puts("read file info error!!\r\n");
    }
    printf(fmt_buf[0..], "aaa: {}, {}, {}, {}, {}, {}, {}, {}", .{ buf[0], buf[1], buf[2], buf[3], buf[4], buf[5], buf[6], buf[7] });
    info.* = @ptrCast(*FileInfo, @alignCast(8, &buf));
}

pub fn allocate_pages(size: usize) [*]align(4096) u8 {
    var pages: [*]align(4096) u8 = undefined;
    if (boot_services.allocatePages(AllocateType.AllocateAnyPages, MemoryType.LoaderData, size, &pages) != uefi.Status.Success) {
        puts("allocate pages error!!\r\n");
    }
    return pages;
}
