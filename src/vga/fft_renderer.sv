import top_pkg::*;

module fft_renderer #(
    parameter int DATA_WIDTH = top_pkg::DATA_WIDTH,
    parameter int NFFT       = top_pkg::NFFT
) (
    input  logic                            i_Clk,
    input  logic                            i_fft_valid,
    input  logic [          DATA_WIDTH-1:0] i_fft_data,
    input  logic [        $clog2(NFFT)-1:0] i_xk_index,
    input  logic [                     9:0] i_Col_Count,
    input  logic [                     9:0] i_Row_Count,
    output logic [top_pkg::VIDEO_WIDTH-1:0] o_Red_Video,
    output logic [top_pkg::VIDEO_WIDTH-1:0] o_Green_Video,
    output logic [top_pkg::VIDEO_WIDTH-1:0] o_Blue_Video
);

  localparam int NUM_BINS = NFFT;
  localparam int ADDR_W = $clog2(NUM_BINS);

  localparam int PLOT_X_START = 64;
  localparam int PLOT_WIDTH = 512;

  localparam int PLOT_BOTTOM_PAD = 48;
  localparam int PLOT_HEIGHT = 300;

  localparam int PLOT_Y_END = top_pkg::ACTIVE_ROWS - PLOT_BOTTOM_PAD;
  localparam int PLOT_Y_START = PLOT_Y_END - PLOT_HEIGHT;

  localparam int BIN_WIDTH = PLOT_WIDTH / NFFT;
  localparam int BIN_SHIFT = $clog2(BIN_WIDTH);

  logic [    ADDR_W-1:0] w_addr;
  logic [    ADDR_W-1:0] r_addr;
  logic [    ADDR_W-1:0] addr_mux;
  logic                  we;

  logic [DATA_WIDTH-1:0] dout;

  // Write side (FFT capture)
  assign w_addr = i_xk_index[ADDR_W-1:0];
  assign we     = i_fft_valid && (i_xk_index < NUM_BINS);

  // Read side (video render)
  //
  logic in_plot;
  logic [9:0] plot_x;

  assign in_plot =
    (i_Col_Count >= PLOT_X_START) &&
    (i_Col_Count <  PLOT_X_START + PLOT_WIDTH) &&
    (i_Row_Count >= PLOT_Y_START) &&
    (i_Row_Count <  PLOT_Y_END);

  assign plot_x = i_Col_Count - PLOT_X_START;

  assign r_addr = plot_x >> BIN_SHIFT;

  // Writes get priority on the shared single port.
  assign addr_mux = we ? w_addr : r_addr;

  sp_bram #(
      .RAM_WIDTH     (DATA_WIDTH),
      .RAM_DEPTH_BITS(ADDR_W)
  ) fft_bram_i (
      .i_Clk (i_Clk),
      .i_addr(addr_mux),
      .i_din (i_fft_data),
      .i_we  (we),
      .o_dout(dout)
  );

  // Video alignment
  logic [9:0] row_d1;
  logic       in_plot_d1;

  always_ff @(posedge i_Clk) begin
    row_d1     <= i_Row_Count;
    in_plot_d1 <= in_plot;
  end


  // Bar-graph render
  localparam int ROW_BITS = $clog2(PLOT_HEIGHT);
  localparam int WIDE_BITS = (DATA_WIDTH > ROW_BITS) ? DATA_WIDTH : ROW_BITS;

  logic [WIDE_BITS-1:0] dout_ext;
  logic                 bar_lit;

  assign dout_ext = {{(WIDE_BITS - DATA_WIDTH) {1'b0}}, dout};

  // Take the upper bits as the height
  logic [ROW_BITS-1:0] raw_bar_height;
  logic [         9:0] bar_height_clamped;

  assign raw_bar_height = dout_ext[WIDE_BITS-1-:ROW_BITS];

  assign bar_height_clamped = (raw_bar_height >= PLOT_HEIGHT) ? PLOT_HEIGHT : raw_bar_height;

  assign bar_lit = in_plot_d1 && (row_d1 >= PLOT_Y_END - bar_height_clamped);

  localparam logic [top_pkg::VIDEO_WIDTH-1:0] FULL_ON = '1;

  assign o_Red_Video   = '0;
  assign o_Green_Video = bar_lit ? FULL_ON : '0;
  assign o_Blue_Video  = '0;

endmodule
