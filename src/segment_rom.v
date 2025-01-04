`default_nettype none
module segment_rom(
    input  wire [3:0] digit,        // Digit to display (0-9)
    output wire [6:0] segments       // 7 segments: a-g
);
    reg [6:0] rom_array [0:9];

    initial begin
        // Initialize 7-segment patterns for digits 0-9
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

    assign segments = rom_array[digit];
endmodule