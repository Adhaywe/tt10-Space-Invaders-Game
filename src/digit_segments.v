`default_nettype none
module digit_segments_rom (
    input  wire [3:0] digit_index, // 4 bits for digits 0-9
    output wire [6:0] segments
);

    reg [6:0] rom_array [0:9];  // 10 digits, each 7 segments

    initial begin
        rom_array[0] = 7'b0111111;  // 0
        rom_array[1] = 7'b0000110;  // 1
        rom_array[2] = 7'b1011011;  // 2
        rom_array[3] = 7'b1001111;  // 3
        rom_array[4] = 7'b1100110;  // 4
        rom_array[5] = 7'b1101101;  // 5
        rom_array[6] = 7'b1111101;  // 6
        rom_array[7] = 7'b0000111;  // 7
        rom_array[8] = 7'b1111111;  // 8
        rom_array[9] = 7'b1101111;  // 9
    end

    // Combinational read
    assign segments = (digit_index <= 9) ? rom_array[digit_index] : 7'b0000000;

endmodule