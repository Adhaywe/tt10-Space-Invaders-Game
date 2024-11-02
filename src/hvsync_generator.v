///////////////
module hvsync_generator(
    input  wire clk,          // Pixel clock (25 MHz for 640x480 @ 60Hz)
    input  wire reset,        // Active high reset
    output reg  hsync,        // Horizontal sync signal
    output reg  vsync,        // Vertical sync signal
    output wire display_on,   // High when display is active
    output wire [9:0] hpos,   // Current pixel x position
    output wire [9:0] vpos    // Current pixel y position
);

    // VGA 640x480 @ 60Hz Timing Parameters
    localparam H_DISPLAY       = 640;
    localparam H_FRONT_PORCH   = 16;
    localparam H_SYNC_PULSE    = 96;
    localparam H_BACK_PORCH    = 48;
    localparam H_TOTAL         = H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

    localparam V_DISPLAY       = 480;
    localparam V_FRONT_PORCH   = 10;
    localparam V_SYNC_PULSE    = 2;
    localparam V_BACK_PORCH    = 33;
    localparam V_TOTAL         = V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // Horizontal Counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1)
                h_count <= 0;
            else
                h_count <= h_count + 1;
        end
    end

    // Vertical Counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end
        end
    end

    // Generate HSYNC
    always @(posedge clk or posedge reset) begin
        if (reset)
            hsync <= 1;
        else
            if (h_count >= (H_DISPLAY + H_FRONT_PORCH) && h_count < (H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE))
                hsync <= 0;  // Active low
            else
                hsync <= 1;
    end

    // Generate VSYNC
    always @(posedge clk or posedge reset) begin
        if (reset)
            vsync <= 1;
        else
            if (v_count >= (V_DISPLAY + V_FRONT_PORCH) && v_count < (V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE))
                vsync <= 0;  // Active low
            else
                vsync <= 1;
    end

    // Display Active Signal
    assign display_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    // Current Pixel Position
    assign hpos = h_count;
    assign vpos = v_count;

endmodule

//////////////