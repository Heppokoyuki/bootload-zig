pub const Zigsaw = packed struct {
    frame_buffer: *FrameBuffer,
};

pub const FrameBuffer = packed struct {
    base: u64,
    size: usize,
    hr: u32,
    vr: u32,
};
