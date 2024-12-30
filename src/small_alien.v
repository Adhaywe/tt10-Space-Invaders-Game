`default_nettype none
module small_alien_rom(
    input  wire [2:0]  row_index,  // Because there are 8 rows, 3 bits needed
    output wire [7:0]  row_data
);

reg [7:0] rom_array [0:7];  // 8 rows, each 8 bits

initial begin
  rom_array[0] = 8'b00011000;
  rom_array[1] = 8'b00111100;
  rom_array[2] = 8'b01111110;
  rom_array[3] = 8'b11011011;
  rom_array[4] = 8'b11111111;
  rom_array[5] = 8'b00100100;
  rom_array[6] = 8'b01000010;
  rom_array[7] = 8'b10000001;
end

assign row_data = rom_array[row_index];

endmodule

