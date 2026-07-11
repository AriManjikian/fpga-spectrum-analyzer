module vga_driver #(
    parameter int VIDEO_WIDTH = vga::VIDEO_WIDTH,
    parameter int TOTAL_COLS  = vga::TOTAL_COLS,
    parameter int TOTAL_ROWS  = vga::TOTAL_ROWS,
    parameter int ACTIVE_COLS = vga::ACTIVE_COLS,
    parameter int ACTIVE_ROWS = vga::ACTIVE_ROWS
) (
    input logic i_Clk,
    input logic [VIDEO_WIDTH-1:0] i_Red_Video,
    input logic [VIDEO_WIDTH-1:0] i_Green_Video,
    input logic [VIDEO_WIDTH-1:0] i_Blue_Video,
    output logic o_HSync,
    output logic o_VSync,
    output logic [9:0] o_Col_Count,
    output logic [9:0] o_Row_Count,
    output logic [VIDEO_WIDTH-1:0] o_Red_Video,
    output logic [VIDEO_WIDTH-1:0] o_Green_Video,
    output logic [VIDEO_WIDTH-1:0] o_Blue_Video
);

  parameter int C_FRONT_PORCH_H = 18;
  parameter int C_BACK_PORCH_H = 50;
  parameter int C_FRONT_PORCH_V = 10;
  parameter int C_BACK_PORCH_V = 33;

  wire w_HSync, w_VSync;
  wire [9:0] w_Col_Count;
  wire [9:0] w_Row_Count;

  reg [VIDEO_WIDTH-1:0] r_Red_Video = 0;
  reg [VIDEO_WIDTH-1:0] r_Green_Video = 0;
  reg [VIDEO_WIDTH-1:0] r_Blue_Video = 0;

  vga_sync_pulses #(
      .TOTAL_COLS (TOTAL_COLS  /* default 800 */),
      .TOTAL_ROWS (TOTAL_ROWS  /* default 525 */),
      .ACTIVE_COLS(ACTIVE_COLS  /* default 640 */),
      .ACTIVE_ROWS(ACTIVE_ROWS  /* default 480 */)
  ) vga_sync_pulses (
      .i_Clk      (i_Clk),
      .o_HSync    (w_HSync),
      .o_VSync    (w_VSync),
      .o_Col_Count(w_Col_Count),
      .o_Row_Count(w_Row_Count)
  );

  always @(posedge i_Clk) begin
    if((w_Col_Count < C_FRONT_PORCH_H + ACTIVE_COLS) ||
          (w_Col_Count > TOTAL_COLS - C_BACK_PORCH_H -1) ) begin
      o_HSync <= 1'b1;
    end else begin
      o_HSync <= w_HSync;
    end

    if((w_Row_Count < C_FRONT_PORCH_V + ACTIVE_ROWS) ||
          (w_Row_Count > TOTAL_ROWS - C_BACK_PORCH_V -1) ) begin
      o_VSync <= 1'b1;
    end else begin
      o_VSync <= w_VSync;
    end
  end

  always @(posedge i_Clk) begin
    r_Red_Video   <= i_Red_Video;
    r_Green_Video <= i_Green_Video;
    r_Blue_Video  <= i_Blue_Video;

    o_Red_Video   <= r_Red_Video;
    o_Green_Video <= r_Green_Video;
    o_Blue_Video  <= r_Blue_Video;
  end

  assign o_Col_Count = w_Col_Count;
  assign o_Row_Count = w_Row_Count;
endmodule
