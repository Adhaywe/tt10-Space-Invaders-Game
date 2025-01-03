`default_nettype none
module draw_medium_alien (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [9:0] alien_left_x,
    input  wire [9:0] alien_top_y,
    output wire       pixel_on
);
    wire [9:0] x_off = pix_x - alien_left_x;
    wire [9:0] y_off = pix_y - alien_top_y;

    wire insider = (x_off[9:4] == 0) && (y_off[9:4] == 0);

    wire [3:0] ry = y_off[3:0];
    wire [15:0] row_bits;
    medium_alien_rom med_rom(
        .row_index(ry),
        .row_data(row_bits)
    );

    wire [3:0] rx = x_off[3:0];
    wire bit_on = row_bits[rx];

    assign pixel_on = insider && bit_on;
endmodule