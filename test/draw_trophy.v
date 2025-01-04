`default_nettype none
module draw_trophy(
    input  wire [9:0] pix_x,           // Current pixel's X coordinate
    input  wire [9:0] pix_y,           // Current pixel's Y coordinate
    input  wire [9:0] trophy_left_x,   // Trophy sprite's top-left X position
    input  wire [9:0] trophy_top_y,    // Trophy sprite's top-left Y position
    output wire       pixel_on          // Output signal indicating if pixel is part of the trophy
);
    // Calculate pixel offsets relative to the Trophy sprite's position
    wire [9:0] x_off = pix_x - trophy_left_x;
    wire [9:0] y_off = pix_y - trophy_top_y;

    // Determine if the current pixel is within the Trophy sprite's boundaries (16x16)
    wire insider = (x_off[9:4] == 0) && (y_off[9:4] == 0); // x_off < 16 and y_off < 16

    // Extract the row index and corresponding pixel data from the ROM
    wire [3:0] row_idx = y_off[3:0];              // Row index (0 to 15)
    wire [15:0] row_bits;
    trophy_rom trophy_rom_inst (
        .row_index(row_idx),
        .row_data(row_bits)
    );

    // Extract the column index and determine if the pixel is active
    wire [3:0] col_idx = x_off[3:0];              // Column index (0 to 15)
    wire bit_on = row_bits[col_idx];               // Pixel status in the current row

    // Assign the output signal based on whether the pixel is part of the trophy
    assign pixel_on = insider && bit_on;
endmodule
