
module vga_sync_generator (
    input  wire clk,       // ~31.5MHz pixel clock input
    input  wire reset,
    output reg  hsync,
    output reg  vsync,
    output wire display_on,
    output reg  [9:0] hpos,
    output reg  [9:0] vpos
);

    // For 640×480@72 Hz
    parameter H_DISPLAY = 640;
    parameter H_FRONT   = 24;   // Horizontal front porch
    parameter H_SYNC    = 40;   // Hsync pulse
    parameter H_BACK    = 128;  // Horizontal back porch

    parameter V_DISPLAY = 480;
    parameter V_BOTTOM  = 9;    // Vertical front porch
    parameter V_SYNC    = 3;    // Vsync pulse
    parameter V_TOP     = 28;    // Vertical back porch


    // Calculate the horizontal and vertical totals.
    localparam H_SYNC_START = H_DISPLAY + H_FRONT;
    localparam H_SYNC_END   = H_DISPLAY + H_FRONT + H_SYNC - 1;
    localparam H_MAX        = H_DISPLAY + H_FRONT + H_SYNC + H_BACK - 1;

    localparam V_SYNC_START = V_DISPLAY + V_BOTTOM;
    localparam V_SYNC_END   = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
    localparam V_MAX        = V_DISPLAY + V_BOTTOM + V_SYNC + V_TOP - 1;

    // Track when we hit the end of a line (horizontal)
    wire hmaxxed = (hpos == H_MAX) || reset;
    // Track when we hit the end of a frame (vertical)
    wire vmaxxed = (vpos == V_MAX) || reset;

    //----------------------------------
    // Horizontal position and sync
    //----------------------------------
    always @(posedge clk) begin
        if (reset) begin
            hpos  <= 0;
            hsync <= 0;
        end else begin
            if (hmaxxed)
                hpos <= 0;
            else
                hpos <= hpos + 1;

            hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
        end
    end

    //----------------------------------
    // Vertical position and sync
    //----------------------------------
    always @(posedge clk) begin
        if (reset) begin
            vpos  <= 0;
            vsync <= 0;
        end else if (hmaxxed) begin
            if (vmaxxed)
                vpos <= 0;
            else
                vpos <= vpos + 1;

            vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);
        end
    end

    assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);

endmodule

