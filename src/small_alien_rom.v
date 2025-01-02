`default_nettype none
module small_alien_rom(
    input  wire [3:0]  row_index,   // 0..15
    output wire [15:0] row_data
);
    reg [15:0] rom_array[0:15];

    initial begin
      // Example placeholder bits for a 16×16 small alien
      rom_array[0]  = 16'h03C0;  
      rom_array[1]  = 16'h03C0;  
      rom_array[2]  = 16'h0FF0;  
      rom_array[3]  = 16'h0FF0;
      rom_array[4]  = 16'h3FFC;  
      rom_array[5]  = 16'h3FFC;
      rom_array[6]  = 16'hF3CF;  
      rom_array[7]  = 16'hF3CF;
      rom_array[8]  = 16'hFFFF;  
      rom_array[9]  = 16'hFFFF;
      rom_array[10] = 16'h0C30;
      rom_array[11] = 16'h0C30;
      rom_array[12] = 16'h300C;
      rom_array[13] = 16'h300C;
      rom_array[14] = 16'hC003;
      rom_array[15] = 16'hC003;
    end

    assign row_data = rom_array[row_index];
endmodule


