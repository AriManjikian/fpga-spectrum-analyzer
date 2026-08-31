`timescale 1ns / 1ps

import top_pkg::*;

module spectrum_analyzer (
    input  logic       i_Clk_100,
    input  logic       i_Resetn,
    output logic [3:0] o_VGA_R,
    output logic [3:0] o_VGA_G,
    output logic [3:0] o_VGA_B,
    output logic       o_VGA_HS,
    output logic       o_VGA_VS,
    input  logic       i_M_DATA,
    output logic       o_M_CLK,
    output logic       o_M_LRSEL
);

  assign o_M_LRSEL = 1'b0;

  // 25MHz pixel clock
  // TODO: replace with a proper mmcm/pll clock
  reg [1:0] r_Clk_25_div;
  always @(posedge i_Clk_100) r_Clk_25_div <= r_Clk_25_div + 1;
  wire  w_Clk_25 = r_Clk_25_div[1];


  // PDM capture
  logic w_PDM_Bit;
  logic w_PDM_Valid;

  pdm_capture #(
      .CLK_FREQ_HZ    (top_pkg::CLK_FREQ_HZ),
      .PDM_CLK_FREQ_HZ(top_pkg::PDM_CLK_FREQ_HZ),
      .SAMPLE_FALLING (top_pkg::SAMPLE_FALLING)
  ) pdm_capture_i (
      .i_Clk      (i_Clk_100),
      .o_PDM_Clk  (o_M_CLK),
      .i_PDM_Data (i_M_DATA),
      .o_PDM_Bit  (w_PDM_Bit),
      .o_PDM_Valid(w_PDM_Valid)
  );

  // PDM -> PCM decimation
  logic signed [top_pkg::DATA_WIDTH-1:0] w_PCM_Sample;
  logic                                  w_PCM_Valid;

  pdm_to_pcm #(
      .DECIMATE (top_pkg::DECIMATE),
      .PCM_WIDTH(top_pkg::DATA_WIDTH)
  ) pdm_to_pcm_i (
      .i_Clk       (i_Clk_100),
      .i_PDM_Bit   (w_PDM_Bit),
      .i_PDM_Valid (w_PDM_Valid),
      .o_PCM_Sample(w_PCM_Sample),
      .o_PCM_Valid (w_PCM_Valid)
  );

  // ila_0 ila_mic (
  //     .clk(i_Clk_100),
  //     .probe0(w_PCM_Valid),
  //     .probe1(w_PDM_Bit),
  //     .probe2(w_PDM_Valid),
  //     .probe4(w_PCM_Sample),
  //     .probe5(w_tdata_re),
  //     .probe6(w_tdata_im)
  // );

  // FFT front end
  logic signed [top_pkg::DATA_WIDTH-1:0] w_tdata_re;
  logic signed [top_pkg::DATA_WIDTH-1:0] w_tdata_im;
  logic                                  w_tvalid;
  logic                                  w_tready;

  assign w_tdata_re = w_PCM_Sample;
  assign w_tdata_im = '0;
  assign w_tvalid   = w_PCM_Valid;

  logic signed [  top_pkg::DATA_WIDTH-1:0] w_tdata_re_o;
  logic signed [  top_pkg::DATA_WIDTH-1:0] w_tdata_im_o;
  logic        [  top_pkg::DATA_WIDTH-1:0] w_mag_sq;
  logic        [$clog2(top_pkg::NFFT)-1:0] w_xk_index;
  logic                                    w_fft_tvalid;


  fft_top #(
      .NFFT      (top_pkg::NFFT),
      .DATA_WIDTH(top_pkg::DATA_WIDTH),
      .QFORMAT   (top_pkg::QFORMAT)
  ) fft_top_i (
      .i_Clk     (i_Clk_100),
      .reset     (~i_Resetn),
      .i_tdata_re(w_tdata_re),
      .i_tdata_im(w_tdata_im),
      .i_tvalid  (w_tvalid),
      .o_tready  (w_tready),
      .o_tdata_re(w_tdata_re_o),
      .o_tdata_im(w_tdata_im_o),
      .o_mag_sq  (w_mag_sq),
      .o_xk_index(w_xk_index),
      .o_tvalid  (w_fft_tvalid)
  );

  // ila_0 ila_fft (
  //     .clk(i_Clk_100),
  //     .probe0(w_fft_tvalid),
  //     .probe1(w_tready),
  //     .probe2(i_Resetn),
  //     .probe3(w_tvalid),
  //     .probe4(w_tdata_re_o),
  //     .probe5(w_tdata_im_o),
  //     .probe6(w_mag_sq),
  //     .probe7(w_xk_index)
  // );

  // VGA timing generator
  logic [9:0] w_Col_Count, w_Row_Count;
  logic [top_pkg::VIDEO_WIDTH-1:0] w_Red_In, w_Green_In, w_Blue_In;
  logic [top_pkg::VIDEO_WIDTH-1:0] w_Red_Out, w_Green_Out, w_Blue_Out;

  wire w_HSync, w_VSync;
  vga_sync_pulses #(
      .TOTAL_COLS (TOTAL_COLS  /* default vga::TOTAL_COLS */),
      .TOTAL_ROWS (TOTAL_ROWS  /* default vga::TOTAL_ROWS */),
      .ACTIVE_COLS(ACTIVE_COLS  /* default vga::ACTIVE_COLS */),
      .ACTIVE_ROWS(ACTIVE_ROWS  /* default vga::ACTIVE_ROWS */)
  ) vga_sync_pulses (
      .i_Clk      (w_Clk_25),
      .o_HSync    (w_HSync),
      .o_VSync    (w_VSync),
      .o_Col_Count(w_Col_Count),
      .o_Row_Count(w_Row_Count)
  );

  vga_driver #(
      .VIDEO_WIDTH(VIDEO_WIDTH  /* default vga::VIDEO_WIDTH */),
      .TOTAL_COLS (TOTAL_COLS  /* default vga::TOTAL_COLS */),
      .TOTAL_ROWS (TOTAL_ROWS  /* default vga::TOTAL_ROWS */),
      .ACTIVE_COLS(ACTIVE_COLS  /* default vga::ACTIVE_COLS */),
      .ACTIVE_ROWS(ACTIVE_ROWS  /* default vga::ACTIVE_ROWS */)
  ) vga_driver (
      .i_Clk        (w_Clk_25),
      .i_HSync      (w_HSync),
      .i_VSync      (w_VSync),
      .i_Red_Video  (w_Red_In),
      .i_Green_Video(w_Green_In),
      .i_Blue_Video (w_Blue_In),
      .i_Col_Count  (w_Col_Count),
      .i_Row_Count  (w_Row_Count),
      .o_HSync      (o_VGA_HS),
      .o_VSync      (o_VGA_VS),
      .o_Red_Video  (w_Red_Out),
      .o_Green_Video(w_Green_Out),
      .o_Blue_Video (w_Blue_Out)
  );

  assign o_VGA_R = w_Red_Out;
  assign o_VGA_G = w_Green_Out;
  assign o_VGA_B = w_Blue_Out;

  // CDC for col_count/row_count (25MHz -> 100MHz)
  // 2-flop synchronizer per bit
  logic [9:0] r_Col_Count_meta, r_Col_Count_sync;
  logic [9:0] r_Row_Count_meta, r_Row_Count_sync;

  always_ff @(posedge i_Clk_100) begin
    r_Col_Count_meta <= w_Col_Count;
    r_Col_Count_sync <= r_Col_Count_meta;
    r_Row_Count_meta <= w_Row_Count;
    r_Row_Count_sync <= r_Row_Count_meta;
  end

  // FFT renderer
  logic [3:0] w_Red_FFT, w_Green_FFT, w_Blue_FFT;
  fft_renderer #(
      .DATA_WIDTH(top_pkg::DATA_WIDTH),
      .NFFT      (top_pkg::NFFT)
  ) fft_renderer_i (
      .i_Clk        (i_Clk_100),
      .i_fft_valid  (w_fft_tvalid),
      .i_fft_data   (w_mag_sq),
      .i_xk_index   (w_xk_index),
      .i_Col_Count  (r_Col_Count_sync),
      .i_Row_Count  (r_Row_Count_sync),
      .o_Red_Video  (w_Red_FFT),
      .o_Green_Video(w_Green_FFT),
      .o_Blue_Video (w_Blue_FFT)
  );

  // Text Renderer
  logic w_Text_Active;
  logic [3:0] w_Red_Text, w_Green_Text, w_Blue_Text;

  text_renderer #(
      .SCALE(2  /* default 2 */)
  ) text_renderer (
      .i_Clk        (w_Clk_25),
      .i_Col_Count  (w_Col_Count),
      .i_Row_Count  (w_Row_Count),
      .o_Text_Active(w_Text_Active),
      .o_Red_Video  (w_Red_Text),
      .o_Green_Video(w_Green_Text),
      .o_Blue_Video (w_Blue_Text)
  );

  assign w_Red_In   = w_Text_Active ? w_Red_Text : w_Red_FFT;
  assign w_Green_In = w_Text_Active ? w_Green_Text : w_Green_FFT;
  assign w_Blue_In  = w_Text_Active ? w_Blue_Text : w_Blue_FFT;
endmodule
