`default_nettype none
module draw_heart(
    input  wire [9:0] pix_x,          // Current pixel's X coordinate
    input  wire [9:0] pix_y,          // Current pixel's Y coordinate
    input  wire [9:0] heart_left_x,   // Heart sprite's top-left X position
    input  wire [9:0] heart_top_y,    // Heart sprite's top-left Y position
    output wire       pixel_on         // Output signal indicating if pixel is part of the heart
);
    
    wire [9:0] x_off = pix_x - heart_left_x;
    wire [9:0] y_off = pix_y - heart_top_y;

   
    wire insider = (x_off[9:4] == 0) && (y_off[9:4] == 0); 

    
    wire [3:0] row_idx = y_off[3:0];              
    wire [15:0] row_bits;
    heart_rom heart_rom_inst (
        .row_index(row_idx),
        .row_data(row_bits)
    );

    
    wire [3:0] col_idx = x_off[3:0];              // Column index (0 to 15)
    wire bit_on = row_bits[col_idx];               // Pixel status in the current row

    // Assign the output signal based on whether the pixel is part of the heart
    assign pixel_on = insider && bit_on;
endmodule
