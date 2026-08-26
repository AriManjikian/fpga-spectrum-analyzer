package top_pkg;
  localparam int DATA_WIDTH = 16;
  // FFT
  localparam int NFFT = 512;
  localparam int DATA_DEPTH = NFFT;
  localparam int QFORMAT = 15;
  localparam int C_BFU_LATENCY = 12;
  localparam int C_MEM_SEL_PIPE = C_BFU_LATENCY;
  localparam int C_HOLD_COUNT = 9;
  // PDM
  localparam int CLK_FREQ_HZ = 100_000_000;
  localparam int PDM_CLK_FREQ_HZ = 3_125_000;
  localparam int SAMPLE_FALLING = 0;
  localparam int DECIMATE = 128;
  // VGA
  localparam int VIDEO_WIDTH = 4;
  localparam int TOTAL_COLS = 800;
  localparam int TOTAL_ROWS = 525;
  localparam int ACTIVE_COLS = 640;
  localparam int ACTIVE_ROWS = 480;
endpackage
