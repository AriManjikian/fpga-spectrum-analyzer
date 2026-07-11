package top_pkg;
  localparam int NFFT = 1024;
  localparam int DATA_DEPTH = NFFT;
  localparam int DATA_WIDTH = 16;
  localparam int QFORMAT = 15;
  localparam int C_BFU_LATENCY = 12;
  localparam int C_MEM_SEL_PIPE = C_BFU_LATENCY;
  localparam int C_HOLD_COUNT = 9;
  localparam int VIDEO_WIDTH = 3;
  localparam int TOTAL_COLS = 800;
  localparam int TOTAL_ROWS = 525;
  localparam int ACTIVE_COLS = 640;
  localparam int ACTIVE_ROWS = 480;
endpackage
