`default_nettype none
module draw_shooter (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [9:0] shooter_left_x,
    input  wire [9:0] shooter_top_y,
    output wire       pixel_on
);
    wire [9:0] x_off = pix_x - shooter_left_x;
    wire [9:0] y_off = pix_y - shooter_top_y;

    // Are we within the 16×16 bounding box?
    wire insider = (x_off[9:4] == 0) && (y_off[9:4] == 0);

    wire [3:0] row_addr = y_off[3:0];
    wire [15:0] row_bits;
    shooter_rom srom(.row_index(row_addr), .row_data(row_bits));

    wire [3:0] col_addr = x_off[3:0];
    wire bit_on = row_bits[col_addr];

    assign pixel_on = insider && bit_on;
endmodule