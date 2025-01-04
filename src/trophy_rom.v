`default_nettype none
module trophy_rom(
    input  wire [3:0] row_index,   // Row index (0 to 15)
    output wire [15:0] row_data    // Pixel data for the row
);
    reg [15:0] rom_array [0:15];
    
    initial begin
        // 16x16 Trophy sprite
        rom_array[0]  = 16'b0000000000000000;
        rom_array[1]  = 16'b0000000000000000;
        rom_array[2]  = 16'b0000000000000000;
        rom_array[3]  = 16'b0000000000000000;
        rom_array[4]  = 16'b0000000000000000;
        rom_array[5]  = 16'b0000000000000000;
        rom_array[6]  = 16'b0011111111111100;
        rom_array[7]  = 16'b0011111111111100;
        rom_array[8]  = 16'b0011111111111100;
        rom_array[9]  = 16'b0011111111111100;
        rom_array[10] = 16'b0011111111111100;
        rom_array[11] = 16'b0001111111111000;
        rom_array[12] = 16'b0000011111100000;
        rom_array[13] = 16'b0000011111100000;
        rom_array[14] = 16'b0000011111100000;
        rom_array[15] = 16'b0000111111110000;
    end
    
    assign row_data = rom_array[row_index];
endmodule
