`default_nettype none
//---------------------------------------------
// Top-level module
//---------------------------------------------
module tt_um_space_invaders_game  (
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
    wire _unused_ok = &{ena, ui_in[7:3], uio_in};

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
    localparam SMALL_SIZE    = 16;  
    localparam MEDIUM_SIZE   = 16;  
    localparam ALIEN_SPACING = 15;
    localparam NUM_ALIENS    = 8;   
    localparam MIN_LEFT      = 80;
    localparam MAX_RIGHT     = 450;

    // Positions for each row
    localparam [9:0] SMALL_Y    = 150; 
    localparam [9:0] MEDIUM_Y1  = 180; 
    localparam [9:0] MEDIUM_Y2  = 210; 
    localparam [9:0] LARGE_Y1   = 240;  
    localparam [9:0] LARGE_Y2   = 270;  

    reg [9:0] group_x;
    reg       move_dir;    // 1 => move right, 0 => move left
    reg [9:0] prev_vpos;

    always @(posedge clk) begin
        if (~rst_n) begin
            group_x   <= 100;
            move_dir  <= 1;   
            prev_vpos <= 0;
        end else begin
            // Once per frame
            prev_vpos <= pix_y;
            if (pix_y == 0 && prev_vpos != 0) begin
                // Move entire group horizontally
                if (move_dir) group_x <= group_x + 2;
                else          group_x <= group_x - 2;

                // Bounce at boundaries
                if (group_x <= MIN_LEFT && !move_dir)
                    move_dir <= 1;
                else if ((group_x + (SMALL_SIZE+ALIEN_SPACING)*(NUM_ALIENS-1)
                          + SMALL_SIZE) >= MAX_RIGHT && move_dir)
                    move_dir <= 0;
            end
        end
    end

    //----------------------------------------------------
    // 3) Data Structures for Collision Detection
    //----------------------------------------------------
    
    localparam NUM_ALIENS_PER_ROW = 8;
    localparam NUM_ROWS_ALIENS    = 5;
    localparam NUM_BARRIERS = 4;
    reg aliens_alive [0:NUM_ROWS_ALIENS-1][0:NUM_ALIENS_PER_ROW-1];
    reg [2:0] barrier_health [0:NUM_BARRIERS-1]; 
    reg [1:0] shooter_lives; 


    //----------------------------------------------------
    // 4) Small Aliens (16×16) in one row
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

    draw_small_alien smA1(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s1_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s1_on));
    draw_small_alien smA2(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s2_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s2_on));
    draw_small_alien smA3(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s3_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s3_on));
    draw_small_alien smA4(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s4_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s4_on));
    draw_small_alien smA5(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s5_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s5_on));
    draw_small_alien smA6(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s6_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s6_on));
    draw_small_alien smA7(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s7_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s7_on));
    draw_small_alien smA8(.pix_x(pix_x), .pix_y(pix_y),
                          .alien_left_x(s8_x), .alien_top_y(SMALL_Y),
                          .pixel_on(s8_on));

    //----------------------------------------------------
    // 5) Medium Aliens (16×16) in 2 rows
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

    draw_medium_alien mdA1(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA1_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA1_on));
    draw_medium_alien mdA2(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA2_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA2_on));
    draw_medium_alien mdA3(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA3_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA3_on));
    draw_medium_alien mdA4(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA4_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA4_on));
    draw_medium_alien mdA5(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA5_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA5_on));
    draw_medium_alien mdA6(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA6_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA6_on));
    draw_medium_alien mdA7(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA7_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA7_on));
    draw_medium_alien mdA8(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mA8_x), .alien_top_y(MEDIUM_Y1),
                           .pixel_on(mA8_on));

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

    draw_medium_alien mdB1(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB1_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB1_on));
    draw_medium_alien mdB2(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB2_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB2_on));
    draw_medium_alien mdB3(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB3_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB3_on));
    draw_medium_alien mdB4(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB4_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB4_on));
    draw_medium_alien mdB5(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB5_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB5_on));
    draw_medium_alien mdB6(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB6_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB6_on));
    draw_medium_alien mdB7(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB7_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB7_on));
    draw_medium_alien mdB8(.pix_x(pix_x), .pix_y(pix_y),
                           .alien_left_x(mB8_x), .alien_top_y(MEDIUM_Y2),
                           .pixel_on(mB8_on));

    //----------------------------------------------------
    // 6) Large Aliens (16×16) in 2 rows
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

    draw_alien3 lgA1(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA1_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA1_on));
    draw_alien3 lgA2(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA2_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA2_on));
    draw_alien3 lgA3(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA3_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA3_on));
    draw_alien3 lgA4(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA4_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA4_on));
    draw_alien3 lgA5(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA5_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA5_on));
    draw_alien3 lgA6(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA6_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA6_on));
    draw_alien3 lgA7(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA7_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA7_on));
    draw_alien3 lgA8(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lA8_x), .alien_top_y(LARGE_Y1),
                     .pixel_on(lA8_on));

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

    draw_alien3 lgB1(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB1_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB1_on));
    draw_alien3 lgB2(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB2_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB2_on));
    draw_alien3 lgB3(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB3_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB3_on));
    draw_alien3 lgB4(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB4_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB4_on));
    draw_alien3 lgB5(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB5_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB5_on));
    draw_alien3 lgB6(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB6_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB6_on));
    draw_alien3 lgB7(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB7_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB7_on));
    draw_alien3 lgB8(.pix_x(pix_x), .pix_y(pix_y),
                     .alien_left_x(lB8_x), .alien_top_y(LARGE_Y2),
                     .pixel_on(lB8_on));

    //----------------------------------------------------
    // 7) Combine signals for small, medium, large aliens
    //----------------------------------------------------
    wire any_small_on =
        (s1_on && aliens_alive[0][0] || 
         s2_on && aliens_alive[0][1] || 
         s3_on && aliens_alive[0][2] || 
         s4_on && aliens_alive[0][3] ||
         s5_on && aliens_alive[0][4] || 
         s6_on && aliens_alive[0][5] || 
         s7_on && aliens_alive[0][6] || 
         s8_on && aliens_alive[0][7]);

    wire any_medium_on =
        (mA1_on && aliens_alive[1][0] || 
         mA2_on && aliens_alive[1][1] || 
         mA3_on && aliens_alive[1][2] || 
         mA4_on && aliens_alive[1][3] ||
         mA5_on && aliens_alive[1][4] || 
         mA6_on && aliens_alive[1][5] || 
         mA7_on && aliens_alive[1][6] || 
         mA8_on && aliens_alive[1][7] ||
         mB1_on && aliens_alive[2][0] || 
         mB2_on && aliens_alive[2][1] || 
         mB3_on && aliens_alive[2][2] || 
         mB4_on && aliens_alive[2][3] ||
         mB5_on && aliens_alive[2][4] || 
         mB6_on && aliens_alive[2][5] || 
         mB7_on && aliens_alive[2][6] || 
         mB8_on && aliens_alive[2][7]);

    wire any_large_on =
        (lA1_on && aliens_alive[3][0] || 
         lA2_on && aliens_alive[3][1] || 
         lA3_on && aliens_alive[3][2] || 
         lA4_on && aliens_alive[3][3] ||
         lA5_on && aliens_alive[3][4] || 
         lA6_on && aliens_alive[3][5] || 
         lA7_on && aliens_alive[3][6] || 
         lA8_on && aliens_alive[3][7] ||
         lB1_on && aliens_alive[4][0] || 
         lB2_on && aliens_alive[4][1] || 
         lB3_on && aliens_alive[4][2] || 
         lB4_on && aliens_alive[4][3] ||
         lB5_on && aliens_alive[4][4] || 
         lB6_on && aliens_alive[4][5] || 
         lB7_on && aliens_alive[4][6] || 
         lB8_on && aliens_alive[4][7]);


  //-----------------------------------------


  localparam TROPHY_X = 100; // 12 pixels padding
  localparam TROPHY_Y = 80;                // Align Y position with scoreboard

  localparam HEART_X =  398;  // Position of the heart to the left of the score
  localparam HEART_Y = 86;  

  wire pixel_on_heart;
  draw_heart draw_heart_inst (
      .pix_x(pix_x),
      .pix_y(pix_y),
      .heart_left_x(HEART_X),
      .heart_top_y(HEART_Y),
      .pixel_on(pixel_on_heart)
  );


  // Instantiate Trophy Drawing Module
  wire pixel_on_trophy;
  draw_trophy draw_trophy_inst (
      .pix_x(pix_x),
      .pix_y(pix_y),
      .trophy_left_x(TROPHY_X),
      .trophy_top_y(TROPHY_Y),
      .pixel_on(pixel_on_trophy)
  );


  //wire final_pixel_on;
  //assign final_pixel_on = pixel_on_heart | pixel_on_trophy;






    //----------------------------------------------------
    // 8) Shooter Movement Direction
    //----------------------------------------------------
    localparam [1:0] DIR_IDLE  = 2'b00,
                     DIR_LEFT  = 2'b01,
                     DIR_RIGHT = 2'b10;

    reg [1:0] movement_dir;
    reg prev_button0, prev_button1;

    always @(posedge clk) begin
      if (~rst_n) begin
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
    // 9) Shooter Position
    //----------------------------------------------------
    localparam SHOOTER_Y     = 360;  


    reg [9:0] shooter_x;
    reg [9:0] prev_vpos_shooter;

    always @(posedge clk) begin
        if (~rst_n) begin
            shooter_x <= 255;
            prev_vpos_shooter <= 0;
        end 
        else if (game_over) begin
            shooter_x <= 255;
            prev_vpos_shooter <= 0;
        end
        else if (game_won) begin
            shooter_x <= 255;
            prev_vpos_shooter <= 0;
        end
        else begin
            // Update once per frame
            prev_vpos_shooter <= pix_y;
            if (pix_y == 0 && prev_vpos_shooter != 0) begin
                case (movement_dir)
                  DIR_LEFT:  if (shooter_x >= 20) shooter_x <= shooter_x - 10;
                  DIR_RIGHT: if (shooter_x <= 500) shooter_x <= shooter_x + 10;
                  default:   /* idle */ ;
                endcase
            end
        end
    end

    //----------------------------------------------------
    // 10) Draw the Shooter
    //----------------------------------------------------
    wire shooter_on;
    draw_shooter myShooter (
        .pix_x(pix_x),
        .pix_y(pix_y),
        .shooter_left_x(shooter_x),
        .shooter_top_y(SHOOTER_Y),
        .pixel_on(shooter_on)
    );

    //----------------------------------------------------
    // 11) Barriers (32×16 now)
    //----------------------------------------------------
    wire b1_on, b2_on, b3_on, b4_on;
    localparam BARRIER_Y = 320; 

    localparam [9:0] b1_xpos = 100;
    localparam [9:0] b2_xpos = 200;
    localparam [9:0] b3_xpos = 300;
    localparam [9:0] b4_xpos = 400;

    draw_barrier barrier1(.pix_x(pix_x), .pix_y(pix_y),
                          .bar_left_x(b1_xpos), .bar_top_y(BARRIER_Y),
                          .pixel_on(b1_on));
    draw_barrier barrier2(.pix_x(pix_x), .pix_y(pix_y),
                          .bar_left_x(b2_xpos), .bar_top_y(BARRIER_Y),
                          .pixel_on(b2_on));
    draw_barrier barrier3(.pix_x(pix_x), .pix_y(pix_y),
                          .bar_left_x(b3_xpos), .bar_top_y(BARRIER_Y),
                          .pixel_on(b3_on));
    draw_barrier barrier4(.pix_x(pix_x), .pix_y(pix_y),
                          .bar_left_x(b4_xpos), .bar_top_y(BARRIER_Y),
                          .pixel_on(b4_on));

    // Only draw barriers with health > 0
    wire barrier1_visible = (barrier_health[0] > 0) && b1_on;
    wire barrier2_visible = (barrier_health[1] > 0) && b2_on;
    wire barrier3_visible = (barrier_health[2] > 0) && b3_on;
    wire barrier4_visible = (barrier_health[3] > 0) && b4_on;

    wire any_barrier_on = (barrier1_visible || barrier2_visible || barrier3_visible || barrier4_visible);

    //----------------------------------------------------
    //  Multiple Player Bullets + Alien Bullet
    //----------------------------------------------------


    reg pb_active;  
    reg [9:0] pb_x;
    reg [9:0] pb_y;

    // For detecting rising edge of ui_in[2].
    reg prev_button2;
    reg abullet_active;
    reg [9:0]  abullet_x, abullet_y;

    // Minimal LFSR for randomness
    reg [7:0] lfsr;
    wire lfsr_feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];


    // Declare new signals to avoid naming conflicts
    reg [2:0] selectedRowRand;
    reg [2:0] colRand;

    // Calculate Row Y Position
    wire [9:0] rowY_0 = SMALL_Y   + 8;
    wire [9:0] rowY_1 = MEDIUM_Y1 + 8;
    wire [9:0] rowY_2 = MEDIUM_Y2 + 8;
    wire [9:0] rowY_3 = LARGE_Y1  + 8;
    wire [9:0] rowY_4 = LARGE_Y2  + 8;
    localparam SHOOTER_WIDTH  = 16; // Adjust as per your shooter design
    localparam SHOOTER_HEIGHT = 16;

    // Barrier Bounding Box Parameters
    localparam BARRIER_WIDTH  = 32;
    localparam BARRIER_HEIGHT = 16;
    reg [9:0] score;
    reg game_over;
    reg game_won;


    
    // We move them once per frame (like your old code).
    always @(posedge clk) begin
      if (~rst_n) begin
        pb_active <= 0;
        pb_x <= 0;  pb_y <= 0;
        
        prev_button2 <= 0;
	      lfsr <= 8'hA5;
        abullet_active <= 0;
        abullet_x <= 0;
        abullet_y <= 0;
        selectedRowRand <= 0;
        colRand <= 0;
        shooter_lives <= 3;
        // Initialize Aliens as alive
        aliens_alive[0][0] <= 1'b1;
        aliens_alive[0][1] <= 1'b1;
        aliens_alive[0][2] <= 1'b1;
        aliens_alive[0][3] <= 1'b1;
        aliens_alive[0][4] <= 1'b1;
        aliens_alive[0][5] <= 1'b1;
        aliens_alive[0][6] <= 1'b1;
        aliens_alive[0][7] <= 1'b1;
        
        aliens_alive[1][0] <= 1'b1;
        aliens_alive[1][1] <= 1'b1;
        aliens_alive[1][2] <= 1'b1;
        aliens_alive[1][3] <= 1'b1;
        aliens_alive[1][4] <= 1'b1;
        aliens_alive[1][5] <= 1'b1;
        aliens_alive[1][6] <= 1'b1;
        aliens_alive[1][7] <= 1'b1;
        
        aliens_alive[2][0] <= 1'b1;
        aliens_alive[2][1] <= 1'b1;
        aliens_alive[2][2] <= 1'b1;
        aliens_alive[2][3] <= 1'b1;
        aliens_alive[2][4] <= 1'b1;
        aliens_alive[2][5] <= 1'b1;
        aliens_alive[2][6] <= 1'b1;
        aliens_alive[2][7] <= 1'b1;
        
        aliens_alive[3][0] <= 1'b1;
        aliens_alive[3][1] <= 1'b1;
        aliens_alive[3][2] <= 1'b1;
        aliens_alive[3][3] <= 1'b1;
        aliens_alive[3][4] <= 1'b1;
        aliens_alive[3][5] <= 1'b1;
        aliens_alive[3][6] <= 1'b1;
        aliens_alive[3][7] <= 1'b1;
        
        aliens_alive[4][0] <= 1'b1;
        aliens_alive[4][1] <= 1'b1;
        aliens_alive[4][2] <= 1'b1;
        aliens_alive[4][3] <= 1'b1;
        aliens_alive[4][4] <= 1'b1;
        aliens_alive[4][5] <= 1'b1;
        aliens_alive[4][6] <= 1'b1;
        aliens_alive[4][7] <= 1'b1;

        // Initialize Barriers Health to 5
        barrier_health[0] <= 3'd5;
        barrier_health[1] <= 3'd5;
        barrier_health[2] <= 3'd5;
        barrier_health[3] <= 3'd5;

      end 
       else if (game_won) begin
        game_won <= 0;
        pb_active <= 0;
        pb_x <= 0;  pb_y <= 0;
        
        prev_button2 <= 0;
	      lfsr <= 8'hA5;
        abullet_active <= 0;
        abullet_x <= 0;
        abullet_y <= 0;
        selectedRowRand <= 0;
        colRand <= 0;
        score <= 0;
        shooter_lives <= 3;
        aliens_alive[0][0] <= 1'b1;
        aliens_alive[0][1] <= 1'b1;
        aliens_alive[0][2] <= 1'b1;
        aliens_alive[0][3] <= 1'b1;
        aliens_alive[0][4] <= 1'b1;
        aliens_alive[0][5] <= 1'b1;
        aliens_alive[0][6] <= 1'b1;
        aliens_alive[0][7] <= 1'b1;
        
        aliens_alive[1][0] <= 1'b1;
        aliens_alive[1][1] <= 1'b1;
        aliens_alive[1][2] <= 1'b1;
        aliens_alive[1][3] <= 1'b1;
        aliens_alive[1][4] <= 1'b1;
        aliens_alive[1][5] <= 1'b1;
        aliens_alive[1][6] <= 1'b1;
        aliens_alive[1][7] <= 1'b1;
        
        aliens_alive[2][0] <= 1'b1;
        aliens_alive[2][1] <= 1'b1;
        aliens_alive[2][2] <= 1'b1;
        aliens_alive[2][3] <= 1'b1;
        aliens_alive[2][4] <= 1'b1;
        aliens_alive[2][5] <= 1'b1;
        aliens_alive[2][6] <= 1'b1;
        aliens_alive[2][7] <= 1'b1;
        
        aliens_alive[3][0] <= 1'b1;
        aliens_alive[3][1] <= 1'b1;
        aliens_alive[3][2] <= 1'b1;
        aliens_alive[3][3] <= 1'b1;
        aliens_alive[3][4] <= 1'b1;
        aliens_alive[3][5] <= 1'b1;
        aliens_alive[3][6] <= 1'b1;
        aliens_alive[3][7] <= 1'b1;
        
        aliens_alive[4][0] <= 1'b1;
        aliens_alive[4][1] <= 1'b1;
        aliens_alive[4][2] <= 1'b1;
        aliens_alive[4][3] <= 1'b1;
        aliens_alive[4][4] <= 1'b1;
        aliens_alive[4][5] <= 1'b1;
        aliens_alive[4][6] <= 1'b1;
        aliens_alive[4][7] <= 1'b1;

        // Initialize Barriers Health to 5
        barrier_health[0] <= 3'd5;
        barrier_health[1] <= 3'd5;
        barrier_health[2] <= 3'd5;
        barrier_health[3] <= 3'd5;
    end
    else if (game_over) begin
        game_over <= 0;
        pb_active <= 0;
        pb_x <= 0;  pb_y <= 0;
        prev_button2 <= 0;
	      lfsr <= 8'hA5;
        abullet_active <= 0;
        abullet_x <= 0;
        abullet_y <= 0;
        selectedRowRand <= 0;
        colRand <= 0;
        score <= 0;
        shooter_lives <= 3;
        aliens_alive[0][0] <= 1'b1;
        aliens_alive[0][1] <= 1'b1;
        aliens_alive[0][2] <= 1'b1;
        aliens_alive[0][3] <= 1'b1;
        aliens_alive[0][4] <= 1'b1;
        aliens_alive[0][5] <= 1'b1;
        aliens_alive[0][6] <= 1'b1;
        aliens_alive[0][7] <= 1'b1;
        
        aliens_alive[1][0] <= 1'b1;
        aliens_alive[1][1] <= 1'b1;
        aliens_alive[1][2] <= 1'b1;
        aliens_alive[1][3] <= 1'b1;
        aliens_alive[1][4] <= 1'b1;
        aliens_alive[1][5] <= 1'b1;
        aliens_alive[1][6] <= 1'b1;
        aliens_alive[1][7] <= 1'b1;
        
        aliens_alive[2][0] <= 1'b1;
        aliens_alive[2][1] <= 1'b1;
        aliens_alive[2][2] <= 1'b1;
        aliens_alive[2][3] <= 1'b1;
        aliens_alive[2][4] <= 1'b1;
        aliens_alive[2][5] <= 1'b1;
        aliens_alive[2][6] <= 1'b1;
        aliens_alive[2][7] <= 1'b1;
        
        aliens_alive[3][0] <= 1'b1;
        aliens_alive[3][1] <= 1'b1;
        aliens_alive[3][2] <= 1'b1;
        aliens_alive[3][3] <= 1'b1;
        aliens_alive[3][4] <= 1'b1;
        aliens_alive[3][5] <= 1'b1;
        aliens_alive[3][6] <= 1'b1;
        aliens_alive[3][7] <= 1'b1;
        
        aliens_alive[4][0] <= 1'b1;
        aliens_alive[4][1] <= 1'b1;
        aliens_alive[4][2] <= 1'b1;
        aliens_alive[4][3] <= 1'b1;
        aliens_alive[4][4] <= 1'b1;
        aliens_alive[4][5] <= 1'b1;
        aliens_alive[4][6] <= 1'b1;
        aliens_alive[4][7] <= 1'b1;

        // Initialize Barriers Health to 5
        barrier_health[0] <= 3'd5;
        barrier_health[1] <= 3'd5;
        barrier_health[2] <= 3'd5;
        barrier_health[3] <= 3'd5;
    end
      else begin
        // Detect rising edge of button #2 each clock:
        if (!prev_button2 && ui_in[2]) begin
          // Attempt to spawn bullet in an empty slot:
          if (!pb_active) begin
            pb_active <= 1;
            pb_x <= shooter_x + 6;
            pb_y <= SHOOTER_Y - 25;
          end 
          // else: no free slot => ignore
        end
        prev_button2 <= ui_in[2];

        // Once per frame: move active bullets up
        if (pix_y == 0 && prev_vpos != 0) begin
		      lfsr <= {lfsr[6:0], lfsr_feedback};
          // Bullet 
          if (pb_active) begin
              if (pb_y > 130)
                  pb_y <= pb_y - 25;
              else
                  pb_active <= 0; // vanish
          end
          
          // Alien Bullet Movement
          if (abullet_active) begin
              if (abullet_y < 390)
                  abullet_y <= abullet_y + 10; 
              else 
                 abullet_active <= 0;

              if (
                        abullet_x + BULLET_W > shooter_x &&
                        abullet_x < shooter_x + SHOOTER_WIDTH &&
                        abullet_y + BULLET_H > SHOOTER_Y &&
                        abullet_y < SHOOTER_Y + SHOOTER_HEIGHT
                    ) begin
                        
                        abullet_active <= 0; 
						if (shooter_lives > 0) begin
						   shooter_lives <= shooter_lives - 1;
						end
                    end
              if (barrier_health[0] > 0 &&
                        abullet_x + BULLET_W > b1_xpos &&
                        abullet_x < b1_xpos + BARRIER_WIDTH &&
                        abullet_y + BULLET_H > BARRIER_Y &&
                        abullet_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[0] <= barrier_health[0] - 1;
                            abullet_active <= 0;
                    end

                    // Barrier 1
              if (barrier_health[1] > 0 &&
                        abullet_x + BULLET_W > b2_xpos &&
                        abullet_x < b2_xpos + BARRIER_WIDTH &&
                        abullet_y + BULLET_H > BARRIER_Y &&
                        abullet_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[1] <= barrier_health[1] - 1;
                            abullet_active <= 0;
                    end

                    // Barrier 2
              if (barrier_health[2] > 0 &&
                        abullet_x + BULLET_W > b3_xpos &&
                        abullet_x < b3_xpos + BARRIER_WIDTH &&
                        abullet_y + BULLET_H > BARRIER_Y &&
                        abullet_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[2] <= barrier_health[2] - 1;
                            abullet_active <= 0;
                    end

                    // Barrier 3
              if (barrier_health[3] > 0 &&
                        abullet_x + BULLET_W > b4_xpos &&
                        abullet_x < b4_xpos + BARRIER_WIDTH &&
                        abullet_y + BULLET_H > BARRIER_Y &&
                        abullet_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[3] <= barrier_health[3] - 1;
                            abullet_active <= 0;
                    end
          end
		      else begin
			        if (lfsr[0]) begin
              abullet_active <= 1;

              // Extract rowRand and colRand from LFSR
              selectedRowRand <= lfsr[3:1];
              if (selectedRowRand > 3'd4) selectedRowRand <= 3'd4;
              colRand <= lfsr[6:4]; // 0..7

              // Calculate bullet position based on random row and column
              abullet_x <= group_x + (colRand * (SMALL_SIZE + ALIEN_SPACING)) + 8;
              abullet_y <= (selectedRowRand == 3'd0) ? rowY_0 :
                           (selectedRowRand == 3'd1) ? rowY_1 :
                           (selectedRowRand == 3'd2) ? rowY_2 :
                           (selectedRowRand == 3'd3) ? rowY_3 :
                                                       rowY_4; 
		    end
		  end
		  
		  if (shooter_lives == 0) begin
		      game_over <= 1;
		  end
      else begin
          game_over <= 0;
      end
		  
    end

    if (pix_y == 0 && prev_vpos != 0) begin
                if (pb_active) begin
                    if (aliens_alive[0][0] &&
                        pb_x + BULLET_W > s1_x &&
                        pb_x < s1_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][0] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end
                    // Alien [0][1]
                    if (aliens_alive[0][1] &&
                        pb_x + BULLET_W > s2_x &&
                        pb_x < s2_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][1] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Alien [0][2]
                    if (aliens_alive[0][2] &&
                        pb_x + BULLET_W > s3_x &&
                        pb_x < s3_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][2] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Alien [0][3]
                    if (aliens_alive[0][3] &&
                        pb_x + BULLET_W > s4_x &&
                        pb_x < s4_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][3] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Alien [0][4]
                    if (aliens_alive[0][4] &&
                        pb_x + BULLET_W > s5_x &&
                        pb_x < s5_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][4] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Alien [0][5]
                    if (aliens_alive[0][5] &&
                        pb_x + BULLET_W > s6_x &&
                        pb_x < s6_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][5] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Alien [0][6]
                    if (aliens_alive[0][6] &&
                        pb_x + BULLET_W > s7_x &&
                        pb_x < s7_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][6] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Alien [0][7]
                    if (aliens_alive[0][7] &&
                        pb_x + BULLET_W > s8_x &&
                        pb_x < s8_x + SMALL_SIZE &&
                        pb_y + BULLET_H > SMALL_Y &&
                        pb_y < SMALL_Y + SMALL_SIZE) begin
                            aliens_alive[0][7] <= 0;
                            pb_active <= 0;
                            score <= score + 30;
                    end

                    // Similarly, check for Aliens in other rows (Medium and Large)
                    // Medium Row 1: Aliens [1][0] to [1][7] (mA1 to mA8)
                    if (aliens_alive[1][0] &&
                        pb_x + BULLET_W > mA1_x &&
                        pb_x < mA1_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][0] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][1] &&
                        pb_x + BULLET_W > mA2_x &&
                        pb_x < mA2_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][1] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][2] &&
                        pb_x + BULLET_W > mA3_x &&
                        pb_x < mA3_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][2] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][3] &&
                        pb_x + BULLET_W > mA4_x &&
                        pb_x < mA4_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][3] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][4] &&
                        pb_x + BULLET_W > mA5_x &&
                        pb_x < mA5_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][4] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][5] &&
                        pb_x + BULLET_W > mA6_x &&
                        pb_x < mA6_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][5] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][6] &&
                        pb_x + BULLET_W > mA7_x &&
                        pb_x < mA7_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][6] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[1][7] &&
                        pb_x + BULLET_W > mA8_x &&
                        pb_x < mA8_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y1 &&
                        pb_y < MEDIUM_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[1][7] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    ////
                    if (aliens_alive[2][0] &&
                        pb_x + BULLET_W > mB1_x &&
                        pb_x < mB1_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][0] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][1] &&
                        pb_x + BULLET_W > mB2_x &&
                        pb_x < mB2_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][1] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][2] &&
                        pb_x + BULLET_W > mB3_x &&
                        pb_x < mB3_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][2] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][3] &&
                        pb_x + BULLET_W > mB4_x &&
                        pb_x < mB4_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][3] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][4] &&
                        pb_x + BULLET_W > mB5_x &&
                        pb_x < mB5_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][4] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][5] &&
                        pb_x + BULLET_W > mB6_x &&
                        pb_x < mB6_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][5] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][6] &&
                        pb_x + BULLET_W > mB7_x &&
                        pb_x < mB7_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][6] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    if (aliens_alive[2][7] &&
                        pb_x + BULLET_W > mB8_x &&
                        pb_x < mB8_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > MEDIUM_Y2 &&
                        pb_y < MEDIUM_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[2][7] <= 0;
                            pb_active <= 0;
                            score <= score + 20;
                    end

                    ////
                    if (aliens_alive[3][0] &&
                        pb_x + BULLET_W > lA1_x &&
                        pb_x < lA1_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][0] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][1] &&
                        pb_x + BULLET_W > lA2_x &&
                        pb_x < lA2_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][1] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][2] &&
                        pb_x + BULLET_W > lA3_x &&
                        pb_x < lA3_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][2] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][3] &&
                        pb_x + BULLET_W > lA4_x &&
                        pb_x < lA4_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][3] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][4] &&
                        pb_x + BULLET_W > lA5_x &&
                        pb_x < lA5_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][4] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][5] &&
                        pb_x + BULLET_W > lA6_x &&
                        pb_x < lA6_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][5] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][6] &&
                        pb_x + BULLET_W > lA7_x &&
                        pb_x < lA7_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][6] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[3][7] &&
                        pb_x + BULLET_W > lA8_x &&
                        pb_x < lA8_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y1 &&
                        pb_y < LARGE_Y1 + MEDIUM_SIZE) begin
                            aliens_alive[3][7] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end
                  

                     ////
                    if (aliens_alive[4][0] &&
                        pb_x + BULLET_W > lB1_x &&
                        pb_x < lB1_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][0] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][1] &&
                        pb_x + BULLET_W > lB2_x &&
                        pb_x < lB2_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][1] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][2] &&
                        pb_x + BULLET_W > lB3_x &&
                        pb_x < lB3_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][2] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][3] &&
                        pb_x + BULLET_W > lB4_x &&
                        pb_x < lB4_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][3] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][4] &&
                        pb_x + BULLET_W > lB5_x &&
                        pb_x < lB5_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][4] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][5] &&
                        pb_x + BULLET_W > lB6_x &&
                        pb_x < lB6_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][5] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][6] &&
                        pb_x + BULLET_W > lB7_x &&
                        pb_x < lB7_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][6] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    if (aliens_alive[4][7] &&
                        pb_x + BULLET_W > lB8_x &&
                        pb_x < lB8_x + MEDIUM_SIZE &&
                        pb_y + BULLET_H > LARGE_Y2 &&
                        pb_y < LARGE_Y2 + MEDIUM_SIZE) begin
                            aliens_alive[4][7] <= 0;
                            pb_active <= 0;
                            score <= score + 10;
                    end

                    

                    // Repeat similar blocks for aliens_alive[1][1] to aliens_alive[4][7]
                    // Player Bullet 0 vs. Barriers
                    // Barrier 0
                    if (barrier_health[0] > 0 &&
                        pb_x + BULLET_W > b1_xpos &&
                        pb_x < b1_xpos + BARRIER_WIDTH &&
                        pb_y + BULLET_H > BARRIER_Y &&
                        pb_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[0] <= barrier_health[0] - 1;
                            pb_active <= 0;
                    end

                    // Barrier 1
                    if (barrier_health[1] > 0 &&
                        pb_x + BULLET_W > b2_xpos &&
                        pb_x < b2_xpos + BARRIER_WIDTH &&
                        pb_y + BULLET_H > BARRIER_Y &&
                        pb_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[1] <= barrier_health[1] - 1;
                            pb_active <= 0;
                    end

                    // Barrier 2
                    if (barrier_health[2] > 0 &&
                        pb_x + BULLET_W > b3_xpos &&
                        pb_x < b3_xpos + BARRIER_WIDTH &&
                        pb_y + BULLET_H > BARRIER_Y &&
                        pb_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[2] <= barrier_health[2] - 1;
                            pb_active <= 0;
                        end

                    // Barrier 3
                    if (barrier_health[3] > 0 &&
                        pb_x + BULLET_W > b4_xpos &&
                        pb_x < b4_xpos + BARRIER_WIDTH &&
                        pb_y + BULLET_H > BARRIER_Y &&
                        pb_y < BARRIER_Y + BARRIER_HEIGHT) begin
                            barrier_health[3] <= barrier_health[3] - 1;
                            pb_active <= 0;
                    end
                end
            
        
    

  
            
                
      end
    end

    if (score == 720) begin
      game_won <= 1;
    end
    else begin
      game_won <= 0;
    end
  end







// draw alien bullet (2 wide x 6 tall, red)
    wire abullet_on;
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;
    assign abullet_on = abullet_active &&
                        (pix_x >= abullet_x) && (pix_x < abullet_x + BULLET_W) &&
                        (pix_y >= abullet_y) && (pix_y < abullet_y + BULLET_H);


    // Draw them (2×6). We'll do 4 separate signals, then combine them.
    wire bullet0_on = pb_active &&
                      (pix_x >= pb_x) && (pix_x < pb_x + 2) &&
                      (pix_y >= pb_y) && (pix_y < pb_y + 6);

    
    // Combined “player bullet on” signal if ANY bullet is on at pixel
    wire bullet_on = (bullet0_on);

    
    //-----------------------------------
    wire pixel_on_score;
   draw_score draw_score_inst (
        .pix_x(pix_x),                   // Current pixel's X coordinate
        .pix_y(pix_y),                   // Current pixel's Y coordinate
        .score(score),               // Player's current score
        .shooter_lives(shooter_lives), // Shooter's current lives
        .pixel_on(pixel_on_score)        // Output: Pixel part of score or health display
    );

    //----------------------------------
  
 
    //----------------------------------------------------
    // 14) Final Color Priority with Collision Effects
    //----------------------------------------------------
    wire [5:0] color_small   = 6'b001100;  
    wire [5:0] color_medium  = 6'b110011;  
    wire [5:0] color_large   = 6'b111100;  
    wire [5:0] color_shooter = 6'b011101; 
    wire [5:0] color_barrier = 6'b011101; 
    wire [5:0] color_bullet  = 6'b111111; 
    wire [5:0] color_alien_bullet = 6'b110000; 
    wire [5:0] color_trophy = 6'b101001;
    wire [5:0] color_heart = 6'b110000;
    wire [5:0] color_score  = 6'b111111;

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
          // Priority: alien bullet > player bullets > shooter > barrier > large > medium > small
          if (pixel_on_score) begin
            R <= color_score[5:4];
            G <= color_score[3:2];
            B <= color_score[1:0];
          end
          else if (pixel_on_trophy) begin
            R <= color_trophy[5:4];
            G <= color_trophy[3:2];
            B <= color_trophy[1:0];
          end
          else if (pixel_on_heart) begin
            R <= color_heart[5:4];
            G <= color_heart[3:2];
            B <= color_heart[1:0];
          end
          else if (abullet_on) begin
            R <= color_alien_bullet[5:4];
            G <= color_alien_bullet[3:2];
            B <= color_alien_bullet[1:0];
          end
          else if (bullet_on) begin
            R <= color_bullet[5:4];
            G <= color_bullet[3:2];
            B <= color_bullet[1:0];
          end
          else if (shooter_on) begin
            R <= color_shooter[5:4];
            G <= color_shooter[3:2];
            B <= color_shooter[1:0];
          end
          else if (any_barrier_on) begin
            R <= color_barrier[5:4];
            G <= color_barrier[3:2];
            B <= color_barrier[1:0];
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