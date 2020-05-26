pub const Zigsaw = packed struct {
    frame_buffer: *FrameBuffer,
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
