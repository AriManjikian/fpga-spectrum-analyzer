import top_pkg::*;

module spectrum_analyzer #(
    parameter int NFFT = top_pkg::NFFT,
    parameter int DATA_WIDTH = top_pkg::DATA_WIDTH,
    parameter int QFORMAT = top_pkg::QFORMAT,
    parameter int VIDEO_WIDTH = top_pkg::VIDEO_WIDTH,
    parameter int TOTAL_COLS = top_pkg::TOTAL_COLS,
    parameter int TOTAL_ROWS = top_pkg::TOTAL_ROWS,
    parameter int ACTIVE_COLS = top_pkg::ACTIVE_COLS,
    parameter int ACTIVE_ROWS = top_pkg::ACTIVE_ROWS
) (
    input logic i_Clk_100,
    input logic i_Reset
);
  fft_top #(
      .NFFT      (NFFT  /* default fft::NFFT */),
      .DATA_WIDTH(DATA_WIDTH  /* default fft::DATA_WIDTH */),
      .QFORMAT   (QFORMAT  /* default fft::QFORMAT */)
  ) fft_top_i (
      .clk       (i_Clk_100),
      .reset     (i_Reset),
      .i_tdata_re(i_tdata_re),
      .i_tdata_im(i_tdata_im),
      .i_tvalid  (i_tvalid),
      .o_tready  (o_tready),
      .o_tdata_re(o_tdata_re),
      .o_tdata_im(o_tdata_im),
      .o_mag_sq  (o_mag_sq),
      .o_xk_index(o_xk_index),
      .o_tvalid  (o_tvalid)
  );

  // VGA Ram
  sp_bram #(
      .RAM_WIDTH     (DATA_WIDTH  /* default fft::DATA_DEPTH */),
      .RAM_DEPTH_BITS(9  /* default $clog2(fft::DATA_DEPTH) */)
  ) vga_bram_i (
      .i_Clk (i_Clk_100),
      .i_addr(i_addr),
      .i_din (i_din),
      .i_we  (i_we),
      .o_dout(o_dout)
  );

  // TODO
  // FFT Renderer (gives out height, rgb, font rom ??)
  // right here <->

  vga_driver #(
      .VIDEO_WIDTH(VIDEO_WIDTH  /* default vga::VIDEO_WIDTH */),
      .TOTAL_COLS (TOTAL_COLS  /* default vga::TOTAL_COLS */),
      .TOTAL_ROWS (TOTAL_ROWS  /* default vga::TOTAL_ROWS */),
      .ACTIVE_COLS(ACTIVE_COLS  /* default vga::ACTIVE_COLS */),
      .ACTIVE_ROWS(ACTIVE_ROWS  /* default vga::ACTIVE_ROWS */)
  ) vga_driver_i (
      // TODO 25 MHZ Clock
      .i_Clk        (i_Clk_100),
      .i_Red_Video  (i_Red_Video),
      .i_Green_Video(i_Green_Video),
      .i_Blue_Video (i_Blue_Video),
      .o_HSync      (o_HSync),
      .o_VSync      (o_VSync),
      .o_Col_Count  (o_Col_Count),
      .o_Row_Count  (o_Row_Count),
      .o_Red_Video  (o_Red_Video),
      .o_Green_Video(o_Green_Video),
      .o_Blue_Video (o_Blue_Video)
  );
endmodule
