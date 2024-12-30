`default_nettype none
module distinct_alien_rom(
    input  wire [3:0]     row_index,  // Because there are 12 rows, need 4 bits
    output wire [11:0]    row_data
);

reg [11:0] rom_array [0:11];  // 12 rows, each 12 bits

initial begin
  rom_array[0]  = 12'b000011100000;
  rom_array[1]  = 12'b000111110000;
  rom_array[2]  = 12'b001111111000;
  rom_array[3]  = 12'b011011101100;
  rom_array[4]  = 12'b111111111110;
  rom_array[5]  = 12'b101111111010;
  rom_array[6]  = 12'b101001100010;
  rom_array[7]  = 12'b101000000010;
  rom_array[8]  = 12'b001100110000;
  rom_array[9]  = 12'b010000001000;
  rom_array[10] = 12'b100000000100;
  rom_array[11] = 12'b000000000000;
end

assign row_data = rom_array[row_index];

endmodule

