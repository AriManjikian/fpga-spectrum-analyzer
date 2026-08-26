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

  logic [    ADDR_W-1:0] w_addr;
  logic [    ADDR_W-1:0] r_addr;
  logic [    ADDR_W-1:0] addr_mux;
  logic                  we;

  logic [DATA_WIDTH-1:0] dout;

  // Write side (FFT capture)
  assign w_addr = i_xk_index[ADDR_W-1:0];
  assign we     = i_fft_valid && (i_xk_index < NUM_BINS);

  // Read side (video render)
  assign r_addr = i_Col_Count[ADDR_W-1:0];
  logic col_in_range;
  assign col_in_range = (i_Col_Count < NUM_BINS) && (i_Row_Count < top_pkg::ACTIVE_ROWS);

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
  logic       col_in_range_d1;

  always_ff @(posedge i_Clk) begin
    row_d1          <= i_Row_Count;
    col_in_range_d1 <= col_in_range;
  end

  // Bar-graph render
  localparam int ROW_BITS = $clog2(top_pkg::ACTIVE_ROWS);
  localparam int WIDE_BITS = (DATA_WIDTH > ROW_BITS) ? DATA_WIDTH : ROW_BITS;

  logic [WIDE_BITS-1:0] dout_ext;
  logic [ ROW_BITS-1:0] bar_height;
  logic                 bar_lit;

  assign dout_ext = {{(WIDE_BITS - DATA_WIDTH) {1'b0}}, dout};
  assign bar_height = dout_ext[WIDE_BITS-1-:ROW_BITS];

  assign bar_lit =
      col_in_range_d1 &&
      (row_d1 >=
       (top_pkg::ACTIVE_ROWS[9:0] -
        {{(10 - ROW_BITS){1'b0}}, bar_height}));

  localparam logic [top_pkg::VIDEO_WIDTH-1:0] FULL_ON = '1;

  assign o_Red_Video   = '0;
  assign o_Green_Video = bar_lit ? FULL_ON : '0;
  assign o_Blue_Video  = '0;

endmodule
