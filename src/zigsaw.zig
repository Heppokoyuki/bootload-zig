const uefi = @import("std").os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

pub const Zigsaw = packed struct {
    frame_buffer: *FrameBuffer,
    memory_map: *MemoryMap,
    kernel_start_address: u64,
    kernel_end_address: u64,
};

pub const FrameBuffer = packed struct {
    base: u64,
    size: usize,
    hr: u32,
    vr: u32,

    pub fn init(b: u64, s: usize, h: u32, v: u32) FrameBuffer {
        return FrameBuffer{
            .base = b,
            .size = s,
            .hr = h,
            .vr = v,
        };
    }
};

pub const MemoryMap = packed struct {
    num: usize,
    size: usize,
    map: [*]MemoryDescriptor,

    pub fn init(n: usize, s: usize, m: [*]MemoryDescriptor) MemoryMap {
        return MemoryMap{
            .num = n,
            .size = s,
            .map = m,
        };
    }
};
