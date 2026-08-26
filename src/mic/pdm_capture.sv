module pdm_capture #(
    parameter int CLK_FREQ_HZ     = 100_000_000,
    parameter int PDM_CLK_FREQ_HZ = 3_125_000,
    parameter bit SAMPLE_FALLING  = 1'b0
) (
    input  logic i_Clk,
    output logic o_PDM_Clk = 1'b0,

    input logic i_PDM_Data,

    output logic o_PDM_Bit = 1'b0,
    output logic o_PDM_Valid = 1'b0
);

  // PDM_CLK = CLK_FREQ / (2 * CLK_DIV)
  //
  // Example:
  //   CLK_FREQ      = 100 MHz
  //   PDM_CLK_FREQ  = 3.125 MHz
  //
  //   CLK_DIV = 100e6 / (2 * 3.125e6) = 16
  localparam int CLK_DIV = CLK_FREQ_HZ / (2 * PDM_CLK_FREQ_HZ);

  localparam int CNT_WIDTH = $clog2(CLK_DIV);

  logic [CNT_WIDTH-1:0] r_Cnt = '0;
  logic r_PDM_Clk_Prev = 1'b0;

  logic w_Rising_Edge;
  logic w_Falling_Edge;
  logic w_Sample;

  assign w_Rising_Edge = o_PDM_Clk & ~r_PDM_Clk_Prev;
  assign w_Falling_Edge = ~o_PDM_Clk & r_PDM_Clk_Prev;

  assign w_Sample = SAMPLE_FALLING ? w_Falling_Edge : w_Rising_Edge;

  always_ff @(posedge i_Clk) begin
    o_PDM_Valid <= 1'b0;

    if (r_Cnt == CLK_DIV - 1) begin
      r_Cnt <= '0;
      o_PDM_Clk <= ~o_PDM_Clk;
    end else begin
      r_Cnt <= r_Cnt + 1'b1;
    end

    r_PDM_Clk_Prev <= o_PDM_Clk;

    if (w_Sample) begin
      o_PDM_Bit   <= i_PDM_Data;
      o_PDM_Valid <= 1'b1;
    end
  end

endmodule
