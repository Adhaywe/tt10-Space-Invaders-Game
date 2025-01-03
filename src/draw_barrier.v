`default_nettype none
module draw_barrier(
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire [9:0] bar_left_x,
    input  wire [9:0] bar_top_y,
    output wire       pixel_on
);
    // 32 wide x 16 tall
    wire [9:0] x_off = pix_x - bar_left_x;
    wire [9:0] y_off = pix_y - bar_top_y;

    wire insider = (x_off[9:5] == 0) && (y_off[9:4] == 0);

    wire [3:0] row_idx = y_off[3:0];
    wire [31:0] row_bits;
    barrier_rom bar_rom(.row_index(row_idx), .row_data(row_bits));

    wire [4:0] col_idx = x_off[4:0];
    wire bit_on = row_bits[col_idx];

    assign pixel_on = insider && bit_on;
endmodule

