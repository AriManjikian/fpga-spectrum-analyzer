module pdm_to_pcm #(
    parameter int DECIMATE  = 128,
    parameter int PCM_WIDTH = 16
) (
    input logic i_Clk,

    input logic i_PDM_Bit,
    input logic i_PDM_Valid,

    output logic signed [PCM_WIDTH-1:0] o_PCM_Sample,
    output logic o_PCM_Valid
);

  localparam int ACC_BITS = $clog2(DECIMATE + 1);

  localparam int COUNT_BITS = $clog2(DECIMATE);

  localparam int ACC_CENTER = DECIMATE / 2;

  // Scale accumulator result into PCM range
  //
  // Accumulator range:
  //   -DECIMATE/2 ... +DECIMATE/2
  localparam int SCALE_SHIFT = PCM_WIDTH - $clog2(DECIMATE);

  logic [  ACC_BITS-1:0] r_Acc = '0;
  logic [COUNT_BITS-1:0] r_Count = '0;


  always_ff @(posedge i_Clk) begin
    o_PCM_Valid <= 1'b0;
    if (i_PDM_Valid) begin
      if (r_Count == DECIMATE - 1) begin
        r_Count <= '0;
        // Include current bit in final average
        o_PCM_Sample <= $signed(({1'b0, r_Acc} + i_PDM_Bit) - ACC_CENTER) <<< SCALE_SHIFT;
        o_PCM_Valid <= 1'b1;
        // Start next accumulation window
        r_Acc <= '0;
      end else begin
        r_Count <= r_Count + 1'b1;
        r_Acc   <= r_Acc + i_PDM_Bit;
      end
    end
  end

endmodule
