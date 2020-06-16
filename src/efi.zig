const uefi = @import("std").os.uefi;
const BootServices = uefi.tables.BootServices;
const FileProtocol = uefi.protocols.FileProtocol;
const FileInfo = uefi.protocols.FileInfo;
const SimpleFileSystemProtocol = uefi.protocols.SimpleFileSystemProtocol;
const GraphicsOutputProtocol = uefi.protocols.GraphicsOutputProtocol;
const GraphicsOutputProtocolMode = uefi.protocols.GraphicsOutputProtocolMode;
const SimpleTextOutputProtocol = uefi.protocols.SimpleTextOutputProtocol;
const AllocateType = uefi.tables.AllocateType;
const MemoryType = uefi.tables.MemoryType;
const Guid = uefi.Guid;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const fmt = @import("std").fmt;
const MemoryMap = @import("zigsaw.zig").MemoryMap;

var boot_services: *BootServices = undefined;
var simple_file_system_protocol: ?*SimpleFileSystemProtocol = undefined;
var con_out: *SimpleTextOutputProtocol = undefined;
var graphics: *GraphicsOutputProtocol = undefined;
var sfsp_guid align(8) = SimpleFileSystemProtocol.guid;
var gop_guid align(8) = GraphicsOutputProtocol.guid;
var file_info_guid align(8) = FileProtocol.guid;
var fmt_buf: [1024]u8 = undefined;

pub var root_file: *FileProtocol = undefined;
var mmap: [*]MemoryDescriptor = undefined;
var mmap_desc_size: usize = undefined;
var mmap_desc_ver: u32 = undefined;

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
        @panic("locateProtocol Error!!\r\n");
    }
    if (boot_services.locateProtocol(&gop_guid, null, @ptrCast(*?*c_void, &graphics)) != uefi.Status.Success) {
        @panic("locateProtocol Error!!\r\n");
    }
    if (simple_file_system_protocol.?.openVolume(&root_file) != uefi.Status.Success) {
        @panic("openVolume Error!!\r\n");
    }
}

pub fn get_memory_map_and_exit_boot_services(map: *MemoryMap) void {
    var status: uefi.Status = undefined;
    var mmapsize: usize = 0;
    var key: usize = undefined;

    puts("trying to exit BootServices...\r\n");
    while (boot_services.getMemoryMap(&mmapsize, mmap, &key, &mmap_desc_size, &mmap_desc_ver) == uefi.Status.BufferTooSmall) {
        if (uefi.Status.Success != boot_services.allocatePool(uefi.tables.MemoryType.LoaderData, mmapsize, @ptrCast(*[*]align(8) u8, &mmap))) {
            @panic("allocatePool() failed!\r\n");
        }
    }
    map.* = MemoryMap.init(mmapsize / mmap_desc_size, mmapsize, mmap);
    if (boot_services.exitBootServices(uefi.handle, key) != uefi.Status.Success) {
        @panic("exitBootServices() failed!\r\n");
    }
}

pub fn open_file(path: [*:0]const u16) *FileProtocol {
    var file: *FileProtocol = undefined;
    if (root_file.open(&file, path, FileProtocol.efi_file_mode_read, 0) != uefi.Status.Success) {
        @panic("file open error!!\r\n");
    }
    return file;
}

pub fn read_file_info(file: *FileProtocol, info: *FileInfo) void {
    var buf_size: u64 = @sizeOf(FileInfo) + @sizeOf(u16) * 100;
    if (file.get_info(&file_info_guid, &buf_size, @ptrCast([*]u8, info)) != uefi.Status.Success) {
        @panic("read file info error!!\r\n");
    }
}

pub fn get_graphics_mode() *GraphicsOutputProtocolMode {
    return graphics.mode;
}

pub fn allocate_pages(size: usize) [*]align(4096) u8 {
    var pages: [*]align(4096) u8 = undefined;
    if (boot_services.allocatePages(AllocateType.AllocateAnyPages, MemoryType.LoaderData, size, &pages) != uefi.Status.Success) {
        @panic("allocate pages error!!\r\n");
    }
    return pages;
}

pub fn allocate_pool(size: usize) [*]align(8) u8 {
    var buf: [*]align(8) u8 = undefined;
    if (boot_services.allocatePool(MemoryType.LoaderData, size, &buf) != uefi.Status.Success) {
        @panic("allocate pool error!!\r\n");
    }
    return buf;
}
