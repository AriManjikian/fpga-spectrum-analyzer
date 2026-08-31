import font_rom_pkg::*;

module text_renderer #(
    parameter SCALE = 2,
    parameter VIDEO_HEIGHT = 480,
    parameter VIDEO_WIDTH = 640
) (
    input  logic       i_Clk,
    input  logic [9:0] i_Col_Count,
    input  logic [9:0] i_Row_Count,
    output logic       o_Text_Active,
    output logic [3:0] o_Red_Video,
    output logic [3:0] o_Green_Video,
    output logic [3:0] o_Blue_Video
);

  localparam int TITLE_X_PADDING = 144;
  localparam int TITLE_Y_PADDING = 16;
  localparam int CHAR_WIDTH = 8 * SCALE;
  localparam int CHAR_HEIGHT = 16 * SCALE;
  localparam int FPGA_WIDTH = 4 * CHAR_WIDTH;
  localparam int SPECTRUM_WIDTH = 8 * CHAR_WIDTH;
  localparam int ANALYZER_WIDTH = 8 * CHAR_WIDTH;
  localparam int NFFT_WIDTH = 9 * CHAR_WIDTH;
  localparam int ARIMANJIKIAN_WIDTH = 13 * CHAR_WIDTH;


  localparam FPGA_X = TITLE_X_PADDING;
  localparam SPECTRUM_X = TITLE_X_PADDING + FPGA_WIDTH + CHAR_WIDTH;
  localparam ANALYZER_X = TITLE_X_PADDING + FPGA_WIDTH + CHAR_WIDTH + SPECTRUM_WIDTH + CHAR_WIDTH;
  localparam NFFT_X = 64;
  localparam ARIMANJIKIAN_X = VIDEO_WIDTH - 64 - ARIMANJIKIAN_WIDTH; 
  localparam FOOTER_Y = VIDEO_HEIGHT - 16;

  logic in_fpga, in_spectrum, in_analyzer, in_nfft, in_arimanjikian;

  assign in_fpga = (i_Col_Count >= FPGA_X) && (i_Col_Count <= FPGA_X + FPGA_WIDTH) &&
                    (i_Row_Count >= TITLE_Y_PADDING) && (i_Row_Count <= TITLE_Y_PADDING + CHAR_HEIGHT);

  assign in_spectrum = (i_Col_Count >= SPECTRUM_X) && (i_Col_Count <= SPECTRUM_X + SPECTRUM_WIDTH) &&
                        (i_Row_Count >= TITLE_Y_PADDING) && (i_Row_Count <= TITLE_Y_PADDING + CHAR_HEIGHT);

  assign in_analyzer = (i_Col_Count >= ANALYZER_X) && (i_Col_Count <= ANALYZER_X + ANALYZER_WIDTH) &&
                        (i_Row_Count >= TITLE_Y_PADDING) && (i_Row_Count <= TITLE_Y_PADDING + CHAR_HEIGHT);

  assign in_nfft = (i_Col_Count >= NFFT_X) && (i_Col_Count <= NFFT_X + NFFT_WIDTH) &&
                        (i_Row_Count >= FOOTER_Y - CHAR_HEIGHT) && (i_Row_Count <= FOOTER_Y);

  assign in_arimanjikian = (i_Col_Count >= ARIMANJIKIAN_X) && (i_Col_Count <= ARIMANJIKIAN_X + ARIMANJIKIAN_WIDTH) &&
                        (i_Row_Count >= FOOTER_Y - CHAR_HEIGHT) && (i_Row_Count <= FOOTER_Y);

  logic [9:0] w_col_rel, w_col_unscaled;
  logic [9:0] w_row_rel, w_row_unscaled;

  always_comb begin
    if (in_fpga) w_col_rel = i_Col_Count - FPGA_X;
    else if (in_spectrum) w_col_rel = i_Col_Count - SPECTRUM_X;
    else if (in_analyzer) w_col_rel = i_Col_Count - ANALYZER_X;
    else if (in_nfft) w_col_rel = i_Col_Count - NFFT_X;
    else if (in_arimanjikian) w_col_rel = i_Col_Count - ARIMANJIKIAN_X;
    else w_col_rel = '0;
  end

  always_comb begin
    if (in_fpga) w_row_rel = i_Row_Count - TITLE_Y_PADDING;
    else if (in_spectrum) w_row_rel = i_Row_Count - TITLE_Y_PADDING;
    else if (in_analyzer) w_row_rel = i_Row_Count - TITLE_Y_PADDING;
    else if (in_nfft) w_row_rel = i_Row_Count - (FOOTER_Y - CHAR_HEIGHT);
    else if (in_arimanjikian) w_row_rel = i_Row_Count - (FOOTER_Y - CHAR_HEIGHT);
    else w_row_rel = '0;
  end

  assign w_col_unscaled = w_col_rel / SCALE;
  assign w_row_unscaled = w_row_rel / SCALE;

  logic [3:0] w_col_addr_1_8_doubled;  // character index within a 16-char word
  logic [2:0] w_col_addr_1_8;  // character index within an 8-char word
  logic [1:0] w_col_addr_1_8_half;  // character index within a 4-char word
  logic [2:0] w_col_addr;  // pixel column within character [0-7]
  logic [3:0] w_row_addr;  // pixel row within character [0-15]

  assign w_col_addr_1_8_doubled = w_col_unscaled[6:3];
  assign w_col_addr_1_8         = w_col_unscaled[5:3];
  assign w_col_addr_1_8_half    = w_col_unscaled[4:3];
  assign w_col_addr             = w_col_unscaled[2:0];
  assign w_row_addr             = w_row_unscaled[3:0];

  // pick character index combinationally, then register the font line
  logic [5:0] w_tilemap_index;
  logic w_draw_fpga, w_draw_spectrum, w_draw_analyzer, w_draw_nfft, w_draw_arimanjikian;

  assign w_draw_fpga     = in_fpga;
  assign w_draw_spectrum = in_spectrum;
  assign w_draw_analyzer = in_analyzer;
  assign w_draw_nfft     = in_nfft;
  assign w_draw_arimanjikian = in_arimanjikian;

  always_comb begin
    w_tilemap_index = '0;
    if (in_fpga) w_tilemap_index = font_rom_pkg::C_TILEMAP_FPGA[w_col_addr_1_8_half];
    else if (in_spectrum) w_tilemap_index = font_rom_pkg::C_TILEMAP_SPECTRUM[w_col_addr_1_8];
    else if (in_analyzer) w_tilemap_index = font_rom_pkg::C_TILEMAP_ANALYZER[w_col_addr_1_8];
    else if (in_nfft)     w_tilemap_index = font_rom_pkg::C_TILEMAP_NFFT_1024[w_col_addr_1_8_doubled];
    else if (in_arimanjikian) w_tilemap_index = font_rom_pkg::C_TILEMAP_ARIMANJIKIAN[w_col_addr_1_8_doubled];
  end

  logic [7:0] r_font_line;
  logic r_draw_fpga, r_draw_spectrum, r_draw_analyzer, r_draw_nfft, r_draw_arimanjikian;

  always_ff @(posedge i_Clk) begin
    r_font_line     <= font_rom_pkg::C_FONT_ROM[w_tilemap_index][w_row_addr];
    r_draw_fpga     <= w_draw_fpga;
    r_draw_spectrum <= w_draw_spectrum;
    r_draw_analyzer <= w_draw_analyzer;
    r_draw_nfft <= w_draw_nfft;
    r_draw_arimanjikian <= w_draw_arimanjikian;
  end

  // pipeline the column address so it lines up with r_font_line
  logic [2:0] r_col_addr;

  always_ff @(posedge i_Clk) begin
    r_col_addr <= w_col_addr;
  end

  // output
  logic w_pixel_lit;
  assign w_pixel_lit = r_font_line[3'd7-r_col_addr];

  always_ff @(posedge i_Clk) begin
    o_Text_Active <= r_draw_fpga | r_draw_spectrum | r_draw_analyzer | r_draw_nfft | r_draw_arimanjikian;

    if (w_pixel_lit) begin
      o_Red_Video   <= 4'hF;
      o_Green_Video <= 4'hF;
      o_Blue_Video  <= 4'hF;
    end else begin
      o_Red_Video   <= 4'h0;
      o_Green_Video <= 4'h0;
      o_Blue_Video  <= 4'h0;
    end
  end

endmodule
