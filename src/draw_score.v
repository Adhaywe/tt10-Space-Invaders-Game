`default_nettype none
module draw_score(
    input  wire [9:0] pix_x,          // Current pixel's X coordinate
    input  wire [9:0] pix_y,          // Current pixel's Y coordinate
    input  wire [9:0] score,          // Player's score (0-999)
    input  wire [1:0] shooter_lives,  // Shooter's remaining lives (0-9)
    output wire       pixel_on         // Output: 1 if pixel is part of any digit's segment
);
    // Position Parameters
    localparam DIGIT_WIDTH  = 10;    // Width of each digit in pixels
    localparam DIGIT_HEIGHT = 14;    // Height of each digit in pixels

    // Score Digits Positions
    localparam DIGIT2_X = 30;        // X position for Hundreds place (score)
    localparam DIGIT1_X = 60;        // X position for Tens place (score)
    localparam DIGIT0_X = 90;        // X position for Ones place (score)
    localparam DIGIT_Y  = 20;        // Y position for score digits

    // Health Digit Position
    localparam HEALTH_DIGIT_X = 420; // X position for Health digit
    localparam HEALTH_DIGIT_Y = 20;  // Y position for Health digit

    // Registers to hold individual digits
    reg [3:0] digit0, digit1, digit2; // Score digits: ones, tens, hundreds
    reg [3:0] digit_health;            // Health digit

    // Splitting the score and shooter_lives into individual digits
    always @* begin
        digit0 = score % 10;                  // Ones place
        digit1 = (score / 10) % 10;           // Tens place
        digit2 = (score / 100) % 10;          // Hundreds place
        digit_health = shooter_lives;         // Health digit
    end

    // Instantiate Segment ROMs for each digit
    wire [6:0] segments0, segments1, segments2, segments_health;

    segment_rom segment_rom0 (
        .digit(digit0),
        .segments(segments0)
    );

    segment_rom segment_rom1 (
        .digit(digit1),
        .segments(segments1)
    );

    segment_rom segment_rom2 (
        .digit(digit2),
        .segments(segments2)
    );

    segment_rom segment_rom_health (
        .digit(digit_health),
        .segments(segments_health)
    );

    // Function to determine if a pixel is part of any active segment
    function automatic is_pixel_on;
        input [6:0] segments;    // Active segments for the digit
        input [9:0] x_rel;       // X coordinate relative to the digit's top-left corner
        input [9:0] y_rel;       // Y coordinate relative to the digit's top-left corner
        begin
            is_pixel_on = 1'b0;
            // Segment a (top horizontal) - Bit 0
            if (segments[0] && y_rel >= 0 && y_rel < 2 && x_rel >= 2 && x_rel < 8)
                is_pixel_on = 1'b1;
            // Segment b (top-right vertical) - Bit 1
            else if (segments[1] && x_rel >= 8 && x_rel < 10 && y_rel >= 2 && y_rel < 7)
                is_pixel_on = 1'b1;
            // Segment c (bottom-right vertical) - Bit 2
            else if (segments[2] && x_rel >= 8 && x_rel < 10 && y_rel >= 7 && y_rel < 12)
                is_pixel_on = 1'b1;
            // Segment d (bottom horizontal) - Bit 3
            else if (segments[3] && y_rel >= 12 && y_rel < 14 && x_rel >= 2 && x_rel < 8)
                is_pixel_on = 1'b1;
            // Segment e (bottom-left vertical) - Bit 4
            else if (segments[4] && x_rel >= 0 && x_rel < 2 && y_rel >= 7 && y_rel < 12)
                is_pixel_on = 1'b1;
            // Segment f (top-left vertical) - Bit 5
            else if (segments[5] && x_rel >= 0 && x_rel < 2 && y_rel >= 2 && y_rel < 7)
                is_pixel_on = 1'b1;
            // Segment g (middle horizontal) - Bit 6
            else if (segments[6] && y_rel >= 7 && y_rel < 9 && x_rel >= 2 && x_rel < 8)
                is_pixel_on = 1'b1;
        end
    endfunction

    // Determine pixel_on for each digit
    wire seg0_on, seg1_on, seg2_on, seg_health_on;

    // Calculate relative positions for each digit
    wire [9:0] rel_x0 = pix_x - DIGIT0_X;
    wire [9:0] rel_y0 = pix_y - DIGIT_Y;

    wire [9:0] rel_x1 = pix_x - DIGIT1_X;
    wire [9:0] rel_y1 = pix_y - DIGIT_Y;

    wire [9:0] rel_x2 = pix_x - DIGIT2_X;
    wire [9:0] rel_y2 = pix_y - DIGIT_Y;

    wire [9:0] rel_x_health = pix_x - HEALTH_DIGIT_X;
    wire [9:0] rel_y_health = pix_y - HEALTH_DIGIT_Y;

    // Check if pixel is within each digit's boundaries
    wire in_digit0 = (pix_x >= DIGIT0_X) && (pix_x < DIGIT0_X + DIGIT_WIDTH) &&
                     (pix_y >= DIGIT_Y) && (pix_y < DIGIT_Y + DIGIT_HEIGHT);

    wire in_digit1 = (pix_x >= DIGIT1_X) && (pix_x < DIGIT1_X + DIGIT_WIDTH) &&
                     (pix_y >= DIGIT_Y) && (pix_y < DIGIT_Y + DIGIT_HEIGHT);

    wire in_digit2 = (pix_x >= DIGIT2_X) && (pix_x < DIGIT2_X + DIGIT_WIDTH) &&
                     (pix_y >= DIGIT_Y) && (pix_y < DIGIT_Y + DIGIT_HEIGHT);

    wire in_digit_health = (pix_x >= HEALTH_DIGIT_X) && (pix_x < HEALTH_DIGIT_X + DIGIT_WIDTH) &&
                           (pix_y >= HEALTH_DIGIT_Y) && (pix_y < HEALTH_DIGIT_Y + DIGIT_HEIGHT);

    // Apply the is_pixel_on function for each digit if the pixel is within
    assign seg0_on       = in_digit0       ? is_pixel_on(segments0, rel_x0, rel_y0)       : 1'b0;
    assign seg1_on       = in_digit1       ? is_pixel_on(segments1, rel_x1, rel_y1)       : 1'b0;
    assign seg2_on       = in_digit2       ? is_pixel_on(segments2, rel_x2, rel_y2)       : 1'b0;
    assign seg_health_on = in_digit_health ? is_pixel_on(segments_health, rel_x_health, rel_y_health) : 1'b0;

    // Combine the segment outputs to determine the final pixel state
    assign pixel_on = seg0_on | seg1_on | seg2_on | seg_health_on;

endmodule