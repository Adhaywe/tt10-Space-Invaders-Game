`default_nettype none

//---------------------------------------------
// Top-level module
//---------------------------------------------
module tt_um_space_invaders_game (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    //----------------------------------------------------
    // 1) VGA Sync + signals
    //----------------------------------------------------
    wire hsync, vsync, video_active;
    wire [9:0] pix_x, pix_y;
    reg  [1:0] R, G, B;

    // Output to VGA: bits => { hsync, B0, G0, R0, vsync, B1, G1, R1 }
    assign uo_out = { hsync, B[0], G[0], R[0],
                      vsync, B[1], G[1], R[1] };

    // Unused I/O
    assign uio_out = 0;
    assign uio_oe  = 0;
    wire _unused_ok = &{ena, ui_in[7:2], uio_in};

    // Minimal VGA generator
    vga_sync_generator sync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    //----------------------------------------------------
    // 2) Shared horizontal movement for Alien Group
    //----------------------------------------------------
    localparam SMALL_SIZE   = 16;  // 16×16 for small
    localparam MEDIUM_SIZE  = 16;  // 16×16 for medium
    localparam ALIEN_SPACING= 20;
    localparam NUM_ALIENS   = 8;   // 8 aliens in each row
    localparam MIN_LEFT     = 50;
    localparam MAX_RIGHT    = 540;

    // Positions for each row
    localparam [9:0] SMALL_Y   = 150; 
    localparam [9:0] MEDIUM_Y1 = 180; 
    localparam [9:0] MEDIUM_Y2 = 210; 
    localparam [9:0] LARGE_Y1  = 240;  
    localparam [9:0] LARGE_Y2  = 270;  

    reg [9:0] group_x;
    reg       move_dir;    // 1 => move right, 0 => move left
    reg [9:0] prev_vpos;

    always @(posedge clk) begin
        if (~rst_n) begin
            group_x   <= 100;
            move_dir  <= 1;   // move right initially
            prev_vpos <= 0;
        end else begin
            // Once per frame (detect start of new frame)
            prev_vpos <= pix_y;
            if (pix_y == 0 && prev_vpos != 0) begin
                // Move entire group horizontally (speed = 2)
                if (move_dir) group_x <= group_x + 2;
                else          group_x <= group_x - 2;

                // Bounce left
                if (group_x <= MIN_LEFT && !move_dir)
                    move_dir <= 1;

                // Bounce right
                else if ((group_x + (SMALL_SIZE+ALIEN_SPACING)*(NUM_ALIENS-1)
                          + SMALL_SIZE) >= MAX_RIGHT && move_dir)
                    move_dir <= 0;
            end
        end
    end

    //----------------------------------------------------
    // 3) Small Aliens (16×16) in one row
    //----------------------------------------------------
    wire s1_on, s2_on, s3_on, s4_on;
    wire s5_on, s6_on, s7_on, s8_on;

    wire [9:0] s1_x = group_x;
    wire [9:0] s2_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*1;
    wire [9:0] s3_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*2;
    wire [9:0] s4_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*3;
    wire [9:0] s5_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*4;
    wire [9:0] s6_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*5;
    wire [9:0] s7_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*6;
    wire [9:0] s8_x = group_x + (SMALL_SIZE + ALIEN_SPACING)*7;

    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA1(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s1_x), .alien_top_y(SMALL_Y),
        .pixel_on(s1_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA2(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s2_x), .alien_top_y(SMALL_Y),
        .pixel_on(s2_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA3(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s3_x), .alien_top_y(SMALL_Y),
        .pixel_on(s3_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA4(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s4_x), .alien_top_y(SMALL_Y),
        .pixel_on(s4_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA5(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s5_x), .alien_top_y(SMALL_Y),
        .pixel_on(s5_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA6(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s6_x), .alien_top_y(SMALL_Y),
        .pixel_on(s6_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA7(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s7_x), .alien_top_y(SMALL_Y),
        .pixel_on(s7_on)
    );
    draw_small_alien #(.ALIASIZE(SMALL_SIZE)) smA8(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(s8_x), .alien_top_y(SMALL_Y),
        .pixel_on(s8_on)
    );

    //----------------------------------------------------
    // 4) Medium Aliens (16×16) in 2 rows
    //----------------------------------------------------
    wire mA1_on, mA2_on, mA3_on, mA4_on;
    wire mA5_on, mA6_on, mA7_on, mA8_on;

    wire [9:0] mA1_x = group_x;
    wire [9:0] mA2_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*1;
    wire [9:0] mA3_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*2;
    wire [9:0] mA4_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*3;
    wire [9:0] mA5_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*4;
    wire [9:0] mA6_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*5;
    wire [9:0] mA7_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*6;
    wire [9:0] mA8_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*7;

    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA1(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA1_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA1_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA2(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA2_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA2_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA3(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA3_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA3_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA4(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA4_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA4_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA5(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA5_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA5_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA6(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA6_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA6_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA7(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA7_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA7_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdA8(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mA8_x), .alien_top_y(MEDIUM_Y1),
        .pixel_on(mA8_on)
    );

    wire mB1_on, mB2_on, mB3_on, mB4_on;
    wire mB5_on, mB6_on, mB7_on, mB8_on;

    wire [9:0] mB1_x = group_x;
    wire [9:0] mB2_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*1;
    wire [9:0] mB3_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*2;
    wire [9:0] mB4_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*3;
    wire [9:0] mB5_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*4;
    wire [9:0] mB6_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*5;
    wire [9:0] mB7_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*6;
    wire [9:0] mB8_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*7;

    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB1(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB1_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB1_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB2(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB2_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB2_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB3(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB3_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB3_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB4(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB4_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB4_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB5(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB5_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB5_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB6(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB6_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB6_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB7(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB7_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB7_on)
    );
    draw_medium_alien #(.ALIASIZE(MEDIUM_SIZE)) mdB8(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(mB8_x), .alien_top_y(MEDIUM_Y2),
        .pixel_on(mB8_on)
    );

    //----------------------------------------------------
    // 5) Large Aliens (16×16) in 2 rows
    //----------------------------------------------------
    wire lA1_on, lA2_on, lA3_on, lA4_on;
    wire lA5_on, lA6_on, lA7_on, lA8_on;

    wire [9:0] lA1_x = group_x;
    wire [9:0] lA2_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*1;
    wire [9:0] lA3_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*2;
    wire [9:0] lA4_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*3;
    wire [9:0] lA5_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*4;
    wire [9:0] lA6_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*5;
    wire [9:0] lA7_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*6;
    wire [9:0] lA8_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*7;

    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA1(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA1_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA1_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA2(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA2_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA2_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA3(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA3_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA3_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA4(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA4_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA4_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA5(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA5_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA5_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA6(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA6_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA6_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA7(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA7_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA7_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgA8(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lA8_x), .alien_top_y(LARGE_Y1),
        .pixel_on(lA8_on)
    );

    wire lB1_on, lB2_on, lB3_on, lB4_on;
    wire lB5_on, lB6_on, lB7_on, lB8_on;

    wire [9:0] lB1_x = group_x;
    wire [9:0] lB2_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*1;
    wire [9:0] lB3_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*2;
    wire [9:0] lB4_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*3;
    wire [9:0] lB5_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*4;
    wire [9:0] lB6_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*5;
    wire [9:0] lB7_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*6;
    wire [9:0] lB8_x = group_x + (MEDIUM_SIZE + ALIEN_SPACING)*7;

    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB1(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB1_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB1_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB2(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB2_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB2_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB3(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB3_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB3_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB4(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB4_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB4_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB5(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB5_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB5_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB6(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB6_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB6_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB7(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB7_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB7_on)
    );
    draw_alien3 #(.ALIASIZE(MEDIUM_SIZE)) lgB8(
        .pix_x(pix_x), .pix_y(pix_y),
        .alien_left_x(lB8_x), .alien_top_y(LARGE_Y2),
        .pixel_on(lB8_on)
    );

    //----------------------------------------------------
    // Combine signals for small, medium, large aliens
    //----------------------------------------------------
    wire any_small_on =
        (s1_on || s2_on || s3_on || s4_on ||
         s5_on || s6_on || s7_on || s8_on);

    wire any_medium_on =
        (mA1_on || mA2_on || mA3_on || mA4_on ||
         mA5_on || mA6_on || mA7_on || mA8_on ||
         mB1_on || mB2_on || mB3_on || mB4_on ||
         mB5_on || mB6_on || mB7_on || mB8_on);

    wire any_large_on =
        (lA1_on || lA2_on || lA3_on || lA4_on ||
         lA5_on || lA6_on || lA7_on || lA8_on ||
         lB1_on || lB2_on || lB3_on || lB4_on ||
         lB5_on || lB6_on || lB7_on || lB8_on);

    //----------------------------------------------------
    // 6) Shooter Movement Direction
    //----------------------------------------------------
    localparam [1:0] DIR_IDLE  = 2'b00,
                     DIR_LEFT  = 2'b01,
                     DIR_RIGHT = 2'b10;

    reg [1:0] movement_dir;
    reg prev_button0, prev_button1;

    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        prev_button0  <= 0;
        prev_button1  <= 0;
        movement_dir  <= DIR_IDLE;
      end else begin
        // Capture previous button states for edge-detection
        prev_button0 <= ui_in[0];
        prev_button1 <= ui_in[1];

        // Rising edge on button0 => move right
        if (ui_in[0] && !prev_button0) begin
          movement_dir <= DIR_RIGHT;
        end
        // Rising edge on button1 => move left
        else if (ui_in[1] && !prev_button1) begin
          movement_dir <= DIR_LEFT;
        end
        // If both buttons are released => idle
        else if (!ui_in[0] && !ui_in[1]) begin
          movement_dir <= DIR_IDLE;
        end
      end
    end

    //----------------------------------------------------
    // 7) Shooter Position
    //----------------------------------------------------
    localparam SHOOTER_SIZE  = 16;
    localparam SHOOTER_Y     = 430;  // near bottom of 480
    localparam SHOOTER_MIN_X = 0;
    localparam SHOOTER_MAX_X = DISPLAY_WIDTH - 118;

    reg [9:0] shooter_x;
    reg [9:0] prev_vpos_shooter;

    always @(posedge clk) begin
        if (~rst_n) begin
            shooter_x <= 320; // roughly center
            prev_vpos_shooter <= 0;
        end else begin
            // Update once per frame
            prev_vpos_shooter <= pix_y;
            if (pix_y == 0 && prev_vpos_shooter != 0) begin
                // Move shooter based on direction
                case (movement_dir)
                  DIR_LEFT:  if (shooter_x >= 2) shooter_x <= shooter_x - 2;
                  DIR_RIGHT: if (shooter_x <= (SHOOTER_MAX_X-2)) shooter_x <= shooter_x + 2;
                  default:   /* idle */ ;
                endcase
            end
        end
    end

    //----------------------------------------------------
    // 8) Draw the Shooter
    //----------------------------------------------------
    wire shooter_on;
    draw_shooter #(.SHSIZE(SHOOTER_SIZE)) myShooter (
        .pix_x(pix_x),
        .pix_y(pix_y),
        .shooter_left_x(shooter_x),
        .shooter_top_y(SHOOTER_Y),
        .pixel_on(shooter_on)
    );

    //----------------------------------------------------
    // 9) Final Color Priority
    //----------------------------------------------------
    wire [5:0] color_small   = 6'b111111; // white
    wire [5:0] color_medium  = 6'b110000; // red
    wire [5:0] color_large   = 6'b001011; // cyan
    wire [5:0] color_shooter = 6'b000111; // bright blue

    always @(posedge clk) begin
      if (~rst_n) begin
        R <= 0;
        G <= 0;
        B <= 0;
      end else begin
        // Default black
        R <= 0;
        G <= 0;
        B <= 0;

        if (video_active) begin
          // Example priority: shooter > large > medium > small
          if (shooter_on) begin
            R <= color_shooter[5:4];
            G <= color_shooter[3:2];
            B <= color_shooter[1:0];
          end
          else if (any_large_on) begin
            R <= color_large[5:4];
            G <= color_large[3:2];
            B <= color_large[1:0];
          end
          else if (any_medium_on) begin
            R <= color_medium[5:4];
            G <= color_medium[3:2];
            B <= color_medium[1:0];
          end
          else if (any_small_on) begin
            R <= color_small[5:4];
            G <= color_small[3:2];
            B <= color_small[1:0];
          end
        end
      end
    end

endmodule