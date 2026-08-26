`timescale 1ns / 1ps
module vga_driver #(
    parameter int VIDEO_WIDTH = vga::VIDEO_WIDTH,
    parameter TOTAL_COLS = vga::TOTAL_COLS,
    parameter TOTAL_ROWS = vga::TOTAL_ROWS,
    parameter ACTIVE_COLS = vga::ACTIVE_COLS,
    parameter ACTIVE_ROWS = vga::ACTIVE_ROWS
) (
    input i_Clk,
    input i_HSync,
    input i_VSync,
    input [VIDEO_WIDTH-1:0] i_Red_Video,
    input [VIDEO_WIDTH-1:0] i_Green_Video,
    input [VIDEO_WIDTH-1:0] i_Blue_Video,
    input [9:0] i_Col_Count,
    input [9:0] i_Row_Count,
    output reg o_HSync,
    output reg o_VSync,
    output reg [VIDEO_WIDTH-1:0] o_Red_Video,
    output reg [VIDEO_WIDTH-1:0] o_Green_Video,
    output reg [VIDEO_WIDTH-1:0] o_Blue_Video
);

  parameter C_FRONT_PORCH_H = 18;
  parameter C_BACK_PORCH_H = 50;
  parameter C_FRONT_PORCH_V = 10;
  parameter C_BACK_PORCH_V = 33;

  always @(posedge i_Clk) begin
    if((i_Col_Count < C_FRONT_PORCH_H + ACTIVE_COLS) ||
          (i_Col_Count > TOTAL_COLS - C_BACK_PORCH_H -1) ) begin
      o_HSync <= 1'b1;
    end else begin
      o_HSync <= i_HSync;
    end

    if((i_Row_Count < C_FRONT_PORCH_V + ACTIVE_ROWS) ||
          (i_Row_Count > TOTAL_ROWS - C_BACK_PORCH_V -1) ) begin
      o_VSync <= 1'b1;
    end else begin
      o_VSync <= i_VSync;
    end
  end

  wire w_Video_Active = (i_Col_Count < ACTIVE_COLS) && (i_Row_Count < ACTIVE_ROWS);

  always @(posedge i_Clk) begin
    o_Red_Video   <= w_Video_Active ? i_Red_Video : {VIDEO_WIDTH{1'b0}};
    o_Green_Video <= w_Video_Active ? i_Green_Video : {VIDEO_WIDTH{1'b0}};
    o_Blue_Video  <= w_Video_Active ? i_Blue_Video : {VIDEO_WIDTH{1'b0}};
  end
endmodule

