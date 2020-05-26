pub const Zigsaw = struct {
    frame_buffer: *FrameBuffer,
};

pub const FrameBuffer = struct {
    base: u64,
    size: usize,
    hr: u32,
    vr: u32,
};
