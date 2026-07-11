module vga_sync_pulses #(
    parameter int TOTAL_COLS  = 800,
    parameter int TOTAL_ROWS  = 525,
    parameter int ACTIVE_COLS = 640,
    parameter int ACTIVE_ROWS = 480
) (
    input logic i_Clk,
    output logic o_HSync,
    output logic o_VSync,
    output logic [9:0] o_Col_Count = 0,
    output logic [9:0] o_Row_Count = 0
);

  always @(posedge i_Clk) begin
    if (o_Col_Count == TOTAL_COLS - 1) begin
      o_Col_Count <= 0;
      if (o_Row_Count == TOTAL_ROWS - 1) begin
        o_Row_Count <= 0;
      end else begin
        o_Row_Count <= o_Row_Count + 1;
      end
    end else begin
      o_Col_Count <= o_Col_Count + 1;
    end
  end

  assign o_HSync = o_Col_Count < ACTIVE_COLS ? 1'b1 : 1'b0;
  assign o_VSync = o_Row_Count < ACTIVE_ROWS ? 1'b1 : 1'b0;
endmodule
