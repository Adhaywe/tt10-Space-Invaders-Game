`default_nettype none
module small_large_alien_rom(
    input  wire [3:0]   row_index,  // 10 rows => need 4 bits (0..9)
    output wire [9:0]   row_data
);

reg [9:0] rom_array [0:9];  // 10 rows, each 10 bits

initial begin
  rom_array[0] = 10'b0011111100;
  rom_array[1] = 10'b0111111110;
  rom_array[2] = 10'b1101101101;
  rom_array[3] = 10'b1111111111;
  rom_array[4] = 10'b0111111110;
  rom_array[5] = 10'b0010010010;
  rom_array[6] = 10'b0100000100;
  rom_array[7] = 10'b1000000010;
  rom_array[8] = 10'b1100000110;
  rom_array[9] = 10'b0111111110;
end

assign row_data = rom_array[row_index];

endmodule