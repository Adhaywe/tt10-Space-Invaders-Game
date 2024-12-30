`default_nettype none

module tt_um_space_invader_vga (
  input  wire [7:0] ui_in,    // Dedicated inputs for player controls
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // Always 1 when powered
  input  wire       clk,      // Clock
  input  wire       rst_n     // Reset_n - low to reset
);

// State Definitions using localparam
localparam [1:0] 
  PLAYING   = 2'b00,
  GAME_WON  = 2'b01,
  GAME_OVER = 2'b10;

reg [1:0] current_state, next_state;

// Game variables
reg [9:0] score;
reg game_won_flag;
reg game_over_flag;

// VGA signals
wire hsync;
wire vsync;
wire [1:0] R;
wire [1:0] G;
wire [1:0] B;
wire video_active;
wire [9:0] pix_x;
wire [9:0] pix_y;

// TinyVGA PMOD
assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

// Unused outputs assigned to 0
assign uio_out = 0;
assign uio_oe  = 0;
wire _unused_ok = &{ena, uio_in, ui_in[7:4]};

// Player control signals
// ui_in[0]: Move right
// ui_in[1]: Move left
// ui_in[2]: Fire
// ui_in[3]: Reset game

// Define screen and shooter dimensions
localparam SCREEN_WIDTH     = 640;
localparam SHOOTER_WIDTH    = 12;
localparam SHOOTER_MIN_X    = 10;
localparam SHOOTER_MAX_X    = SCREEN_WIDTH - SHOOTER_WIDTH - 100;

// Alien movement parameters
reg [9:0] alien_offset_x;
reg [9:0] alien_offset_y;
reg       alien_direction;  
reg [31:0] alien_move_counter;

// Shooter parameters
reg [9:0] shooter_x;
reg [9:0] bullet_x;
reg [9:0] bullet_y;
reg bullet_active;

// Alien health array
localparam NUM_ROWS    = 5;
localparam NUM_COLUMNS = 11;
reg alien_health [0:NUM_ROWS-1][0:NUM_COLUMNS-1];

integer i, j;
integer row, col;
integer i_temp;

// Counter for remaining aliens
reg [6:0] aliens_remaining;

// Player health
reg [1:0] player_health;
reg [3:0] digit_health;
localparam HEALTH_DIGIT_X = 470;
localparam HEALTH_DIGIT_Y = 20;

// VGA signal generation
hvsync_generator hvsync_gen(
  .clk(clk),
  .reset(~rst_n),
  .hsync(hsync),
  .vsync(vsync),
  .display_on(video_active),
  .hpos(pix_x),
  .vpos(pix_y)
);

// ---------------------------------------------------------------------
// Instead of defining alien sprites as reg arrays, we use ROM modules.
// ---------------------------------------------------------------------
// For small alien (top row)
wire [7:0] small_alien_data;
small_alien_rom rom_small_alien(
  .row_index(sprite_y[2:0]),  // sprite_y is up to 8 for small alien
  .row_data(small_alien_data)
);

// Distinct alien (2nd and 3rd rows)
wire [11:0] distinct_alien_data;
distinct_alien_rom rom_distinct_alien(
  .row_index(sprite_y[3:0]),  // sprite_y up to 12
  .row_data(distinct_alien_data)
);

// Smaller large alien (4th and 5th rows)
wire [9:0] small_large_alien_data;
small_large_alien_rom rom_small_large_alien(
  .row_index(sprite_y[3:0]),  // up to 10 rows
  .row_data(small_large_alien_data)
);

// 7-segment display font for digits 0-9
reg [6:0] digit_segments [0:9];
reg [3:0] digit0, digit1, digit2;
initial begin
  digit_segments[0] = 7'b0111111;  // 0
  digit_segments[1] = 7'b0000110;  // 1
  digit_segments[2] = 7'b1011011;  // 2
  digit_segments[3] = 7'b1001111;  // 3
  digit_segments[4] = 7'b1100110;  // 4
  digit_segments[5] = 7'b1101101;  // 5
  digit_segments[6] = 7'b1111101;  // 6
  digit_segments[7] = 7'b0000111;  // 7
  digit_segments[8] = 7'b1111111;  // 8
  digit_segments[9] = 7'b1101111;  // 9
end

// 16x16 Heart sprite
reg [15:0] heart_sprite [0:15];
initial begin
  heart_sprite[0]  = 16'b0000000000000000;
  heart_sprite[1]  = 16'b0000000000000000;
  heart_sprite[2]  = 16'b0001110001110000;
  heart_sprite[3]  = 16'b0011111011111000;
  heart_sprite[4]  = 16'b0011111111111000;
  heart_sprite[5]  = 16'b0011111111111000;
  heart_sprite[6]  = 16'b0001111111110000;
  heart_sprite[7]  = 16'b0000111111100000;
  heart_sprite[8]  = 16'b0000011111000000;
  heart_sprite[9]  = 16'b0000001110000000;
  heart_sprite[10] = 16'b0000000100000000;
  heart_sprite[11] = 16'b0000000000000000;
  heart_sprite[12] = 16'b0000000000000000;
  heart_sprite[13] = 16'b0000000000000000;
  heart_sprite[14] = 16'b0000000000000000;
  heart_sprite[15] = 16'b0000000000000000;
end

// 16x16 Trophy Sprite Definition
reg [15:0] trophy_sprite [0:15];
initial begin
  trophy_sprite[0]  = 16'b0000000000000000;
  trophy_sprite[1]  = 16'b0000000000000000;
  trophy_sprite[2]  = 16'b0000000000000000;
  trophy_sprite[3]  = 16'b0000000000000000;
  trophy_sprite[4]  = 16'b0000000000000000;
  trophy_sprite[5]  = 16'b0000000000000000;
  trophy_sprite[6]  = 16'b0011111111111100;
  trophy_sprite[7]  = 16'b0011111111111100;
  trophy_sprite[8]  = 16'b0011111111111100;
  trophy_sprite[9]  = 16'b0011111111111100;
  trophy_sprite[10] = 16'b0011111111111100;
  trophy_sprite[11] = 16'b0001111111111000;
  trophy_sprite[12] = 16'b0000011111100000;
  trophy_sprite[13] = 16'b0000011111100000;
  trophy_sprite[14] = 16'b0000011111100000;
  trophy_sprite[15] = 16'b0000111111110000;
end

// Position Parameters
localparam TROPHY_WIDTH     = 16;
localparam TROPHY_HEIGHT    = 16;
localparam DIGIT_WIDTH      = 10;
localparam DIGIT_HEIGHT     = 14;
localparam DIGIT2_X         = 60;
localparam DIGIT1_X         = 90;
localparam DIGIT0_X         = 120;
localparam DIGIT_Y          = 20;
localparam TROPHY_X         = DIGIT2_X - TROPHY_WIDTH - 12;
localparam TROPHY_Y         = DIGIT_Y - 3;
localparam HEART_X          = DIGIT2_X + 430;
localparam HEART_Y          = DIGIT_Y + 1;
localparam ALIEN_WIDTH      = 24;
localparam ALIEN_HEIGHT     = 24;
localparam ALIEN_SPACING_X  = 6;
localparam ALIEN_SPACING_Y  = 8;
localparam BULLET_WIDTH     = 4;
localparam BULLET_HEIGHT    = 8;

// Barrier
localparam BARRIER_WIDTH  = 60;
localparam BARRIER_HEIGHT = 30;
localparam [9:0] barrier_x0 = 80;
localparam [9:0] barrier_x1 = 200;
localparam [9:0] barrier_x2 = 320;
localparam [9:0] barrier_x3 = 440;
localparam [9:0] barrier_y  = 400;
reg [3:0] barrier_hitpoints [0:3];
reg barrier_pixel;

// Initialize variables
initial begin
  shooter_x = 253;
  bullet_x  = 0;
  bullet_y  = 0;
  bullet_active = 0;
  movement_counter = 0;
  bullet_move_counter = 0;
  score = 0;
  game_won_flag = 0;
  game_over_flag = 0;
  player_health = 2'b11;
  aliens_remaining = NUM_ROWS * NUM_COLUMNS;

  alien_offset_x = 0;
  alien_offset_y = 0;
  alien_direction = 1;
  alien_move_counter = 0;

  // Initialize alien health
  for (i = 0; i < NUM_ROWS; i = i + 1) begin
    for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
      alien_health[i][j] = 1'b1;
    end
  end

  // Initialize alien bullets
  for (i = 0; i < MAX_ALIEN_BULLETS; i = i + 1) begin
    alien_bullet_x[i] = 0;
    alien_bullet_y[i] = 0;
    alien_bullet_active[i] = 0;
  end

  // Barrier HP
  barrier_hitpoints[0] = 4'd10;
  barrier_hitpoints[1] = 4'd10;
  barrier_hitpoints[2] = 4'd10;
  barrier_hitpoints[3] = 4'd10;
end

// Alien bullet parameters
localparam MAX_ALIEN_BULLETS = 5;
reg [9:0] alien_bullet_x [0:MAX_ALIEN_BULLETS-1];
reg [9:0] alien_bullet_y [0:MAX_ALIEN_BULLETS-1];
reg       alien_bullet_active [0:MAX_ALIEN_BULLETS-1];

// Counter for alien shooting
reg [31:0] alien_shoot_counter;

// LFSR for random
reg [15:0] lfsr;
wire lfsr_feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    lfsr <= 16'hACE1;
  else
    lfsr <= {lfsr[14:0], lfsr_feedback};
end

// Alien movement & shooting logic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n || ui_in[3]) begin
    alien_offset_x <= 0;
    alien_offset_y <= 0;
    alien_direction <= 1;
    alien_move_counter <= 0;
    alien_shoot_counter <= 0;
    barrier_hitpoints[0] <= 4'd10;
    barrier_hitpoints[1] <= 4'd10;
    barrier_hitpoints[2] <= 4'd10;
    barrier_hitpoints[3] <= 4'd10;
  end
  else if (current_state == PLAYING) begin
    alien_move_counter <= alien_move_counter + 1;
    alien_shoot_counter <= alien_shoot_counter + 1;

    if (alien_move_counter >= 50000) begin
      alien_move_counter <= 0;
      if (alien_direction) begin
        if (alien_offset_x < 100)
          alien_offset_x <= alien_offset_x + 1;
        else
          alien_direction <= 0;
      end else begin
        if (alien_offset_x > 0)
          alien_offset_x <= alien_offset_x - 1;
        else
          alien_direction <= 1;
      end
    end

    if (alien_shoot_counter >= 100000) begin
      alien_shoot_counter <= 0;
      if (lfsr[0]) begin
        spawn_alien_bullet();
      end
    end
  end else begin
    alien_move_counter <= 0;
    alien_shoot_counter <= 0;
  end
end

integer col_tmp, row_tmp;

task spawn_alien_bullet;
begin
  col_tmp <= lfsr[3:0] % NUM_COLUMNS;
  for (row_tmp = NUM_ROWS-1; row_tmp >= 0; row_tmp = row_tmp - 1) begin
    if (alien_health[row_tmp][col_tmp]) begin
      for (i_temp = 0; i_temp < MAX_ALIEN_BULLETS; i_temp = i_temp + 1) begin
        if (!alien_bullet_active[i_temp]) begin
          alien_bullet_active[i_temp] = 1;
          alien_x = col_tmp*(ALIEN_WIDTH+ALIEN_SPACING_X)+70+alien_offset_x;
          alien_y = row_tmp*(ALIEN_HEIGHT+ALIEN_SPACING_Y)+150+alien_offset_y;
          alien_bullet_x[i_temp] = alien_x+(ALIEN_WIDTH/2)-(BULLET_WIDTH/2);
          alien_bullet_y[i_temp] = alien_y+ALIEN_HEIGHT;
          i_temp = MAX_ALIEN_BULLETS;
        end
      end
      row_tmp = -1;
    end
  end
end
endtask

// Alien bullet movement
reg [19:0] alien_bullet_move_counter;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n || ui_in[3]) begin
    alien_bullet_move_counter <= 0;
  end 
  else if (current_state == PLAYING) begin
    alien_bullet_move_counter <= alien_bullet_move_counter + 1;
    if (alien_bullet_move_counter >= 100000) begin
      alien_bullet_move_counter <= 0;
      for (i = 0; i < MAX_ALIEN_BULLETS; i = i + 1) begin
        if (alien_bullet_active[i]) begin
          alien_bullet_y[i] <= alien_bullet_y[i] + 2;
          if (alien_bullet_y[i] > 480) 
            alien_bullet_active[i] <= 0;
        end
      end
    end
  end
end

// Alien drawing logic with movement
reg alien_pixel;
reg [2:0] alien_color;
reg [9:0] alien_x, alien_y;
reg [9:0] sprite_x, sprite_y;
integer row_tmp1, col_tmp1;

always @(*) begin
  // Default
  alien_pixel = 0;
  alien_color = 3'b000;
  alien_x = 0;
  alien_y = 0;
  sprite_x = 0;
  sprite_y = 0;
  row_tmp1 = 0;
  col_tmp1 = 0;

  if (current_state == PLAYING) begin
    for (row_tmp1 = 0; row_tmp1 < NUM_ROWS; row_tmp1 = row_tmp1 + 1) begin
      for (col_tmp1 = 0; col_tmp1 < NUM_COLUMNS; col_tmp1 = col_tmp1 + 1) begin
        if (alien_health[row_tmp1][col_tmp1]) begin
          alien_x = col_tmp1*(ALIEN_WIDTH+ALIEN_SPACING_X)+70+alien_offset_x;
          alien_y = row_tmp1*(ALIEN_HEIGHT+ALIEN_SPACING_Y)+150+alien_offset_y;

          // row 0 => use small_alien_data
          if (row_tmp1 == 0) begin
            sprite_x = (pix_x - alien_x) / 2;
            sprite_y = (pix_y - alien_y) / 2;
            if ((pix_x >= alien_x) && (pix_x < alien_x + 16) &&
                (pix_y >= alien_y) && (pix_y < alien_y + 16) &&
                (sprite_x < 8) && (sprite_y < 8) &&
                small_alien_data[sprite_x]) begin
              alien_pixel = 1;
              alien_color = 3'b011; // bright white
            end
          end
          // row1 or row2 => distinct_alien_data
          else if (row_tmp1 == 1 || row_tmp1 == 2) begin
            sprite_x = (pix_x - alien_x) / 2;
            sprite_y = (pix_y - alien_y) / 2;
            if ((pix_x >= alien_x) && (pix_x < alien_x + 24) &&
                (pix_y >= alien_y) && (pix_y < alien_y + 24) &&
                (sprite_x < 12) && (sprite_y < 12) &&
                distinct_alien_data[sprite_x]) begin
              alien_pixel = 1;
              alien_color = 3'b101;
            end
          end
          // row3 or row4 => small_large_alien_data
          else if (row_tmp1 == 3 || row_tmp1 == 4) begin
            sprite_x = (pix_x - alien_x) / 2;
            sprite_y = (pix_y - alien_y) / 2;
            if ((pix_x >= alien_x) && (pix_x < alien_x + 20) &&
                (pix_y >= alien_y) && (pix_y < alien_y + 20) &&
                (sprite_x < 10) && (sprite_y < 10) &&
                small_large_alien_data[sprite_x]) begin
              alien_pixel = 1;
              alien_color = 3'b110;
            end
          end
        end
      end
    end
  end
end

reg collision_occurred;

// Movement Direction Tracking
localparam [1:0] DIR_IDLE  = 2'b00,
                 DIR_LEFT  = 2'b01,
                 DIR_RIGHT = 2'b10;
reg [1:0] movement_dir;
reg prev_button0, prev_button1;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    prev_button0 <= 0;
    prev_button1 <= 0;
    movement_dir <= DIR_IDLE;
  end else begin
    prev_button0 <= ui_in[0];
    prev_button1 <= ui_in[1];
    if (ui_in[0] && !prev_button0) begin
      movement_dir <= DIR_RIGHT;
    end
    else if (ui_in[1] && !prev_button1) begin
      movement_dir <= DIR_LEFT;
    end
    else if (!ui_in[0] && !ui_in[1]) begin
      movement_dir <= DIR_IDLE;
    end
  end
end

// Shooter logic, bullet, collision detection
reg [19:0] movement_counter;
reg [19:0] bullet_move_counter;
reg prev_fire_button;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    prev_fire_button <= 0;
  else
    prev_fire_button <= ui_in[2];
end

wire fire_button_rising_edge = ui_in[2] && !prev_fire_button;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n || ui_in[3] || game_over_flag || game_won_flag) begin
    shooter_x <= 253;
    bullet_x <= 0;
    bullet_y <= 0;
    bullet_active <= 0;
    movement_counter <= 0;
    bullet_move_counter <= 0;
    score <= 0;
    game_won_flag <= 0;
    game_over_flag <= 0;
    player_health <= 2'b11;
    aliens_remaining <= NUM_ROWS*NUM_COLUMNS;
    for (i = 0; i < NUM_ROWS; i = i + 1) begin
      for (j = 0; j < NUM_COLUMNS; j = j + 1) begin
        alien_health[i][j] <= 1'b1;
      end
    end
    alien_offset_x <= 0;
    alien_offset_y <= 0;
    alien_direction <= 1;
    alien_move_counter <= 0;
    prev_fire_button <= 0;
    collision_occurred <= 0;
    for (i = 0; i < MAX_ALIEN_BULLETS; i = i + 1) begin
      alien_bullet_x[i] <= 0;
      alien_bullet_y[i] <= 0;
      alien_bullet_active[i] <= 0;
    end
    alien_shoot_counter <= 0;
    alien_bullet_move_counter <= 0;
    lfsr <= 16'hACE1;
    barrier_hitpoints[0] <= 4'd10;
    barrier_hitpoints[1] <= 4'd10;
    barrier_hitpoints[2] <= 4'd10;
    barrier_hitpoints[3] <= 4'd10;
  end else begin
    if (current_state == PLAYING) begin
      collision_occurred <= 0;

      // Bullet movement
      if (bullet_active) begin
        bullet_move_counter <= bullet_move_counter + 1;
        if (bullet_move_counter >= 3000) begin
          bullet_move_counter <= 0;
          if (bullet_y > 0)
            bullet_y <= bullet_y - 1;
          else
            bullet_active <= 0;
        end
      end else if (fire_button_rising_edge && !bullet_active) begin
        bullet_active <= 1;
        bullet_x <= shooter_x + 4;
        bullet_y <= 460;
        bullet_move_counter <= 0;
      end

      
      // Collision Detection and Scoring
      if (bullet_active) begin
        // Check collision with aliens
        for (row = 0; row < NUM_ROWS; row = row + 1) begin
          for (col = 0; col < NUM_COLUMNS; col = col + 1) begin
            if (alien_health[row][col] && !collision_occurred) begin
              // Calculate the alien's position
              alien_x = col * (ALIEN_WIDTH + ALIEN_SPACING_X) + 70 + alien_offset_x;
              alien_y = row * (ALIEN_HEIGHT + ALIEN_SPACING_Y) + 150 + alien_offset_y;

              // Check for collision
              if (bullet_x + BULLET_WIDTH >= alien_x && bullet_x <= alien_x + ALIEN_WIDTH &&
                  bullet_y <= alien_y + ALIEN_HEIGHT && bullet_y + BULLET_HEIGHT >= alien_y) begin  // Adjusted for bullet size

                // Alien is destroyed upon first hit
                alien_health[row][col] <= 1'b0;  // Set alien health to 0

                // Deactivate the bullet
                bullet_active <= 0;
                bullet_y <= 0;
                collision_occurred <= 1; // Prevent further collisions in this cycle

                // Decrement aliens_remaining
                aliens_remaining <= aliens_remaining - 1;

                // Increment score based on the row
                case (row)
                  0: score <= score + 30;  // 1st row = 30 points
                  1, 2: score <= score + 20;  // 2nd and 3rd row = 20 points
                  3, 4: score <= score + 10;  // 4th and 5th row = 10 points
                endcase
              end
            end
          end
        end

        // ----- Barrier Collision Detection Start -----
        if (bullet_active) begin
          // Barrier 0 Collision
          if (barrier_hitpoints[0] > 0 &&
              bullet_x + BULLET_WIDTH >= barrier_x0 &&
              bullet_x <= barrier_x0 + BARRIER_WIDTH &&
              bullet_y <= barrier_y + BARRIER_HEIGHT &&
              bullet_y + BULLET_HEIGHT >= barrier_y) begin
            barrier_hitpoints[0] <= barrier_hitpoints[0] - 1; // Reduce barrier hitpoints
            bullet_active <= 0; // Deactivate bullet
          end
          // Barrier 1 Collision
          else if (barrier_hitpoints[1] > 0 &&
                   bullet_x + BULLET_WIDTH >= barrier_x1 &&
                   bullet_x <= barrier_x1 + BARRIER_WIDTH &&
                   bullet_y <= barrier_y + BARRIER_HEIGHT &&
                   bullet_y + BULLET_HEIGHT >= barrier_y) begin
            barrier_hitpoints[1] <= barrier_hitpoints[1] - 1; // Reduce barrier hitpoints
            bullet_active <= 0; // Deactivate bullet
          end
          // Barrier 2 Collision
          else if (barrier_hitpoints[2] > 0 &&
                   bullet_x + BULLET_WIDTH >= barrier_x2 &&
                   bullet_x <= barrier_x2 + BARRIER_WIDTH &&
                   bullet_y <= barrier_y + BARRIER_HEIGHT &&
                   bullet_y + BULLET_HEIGHT >= barrier_y) begin
            barrier_hitpoints[2] <= barrier_hitpoints[2] - 1; // Reduce barrier hitpoints
            bullet_active <= 0; // Deactivate bullet
          end
          // Barrier 3 Collision
          else if (barrier_hitpoints[3] > 0 &&
                   bullet_x + BULLET_WIDTH >= barrier_x3 &&
                   bullet_x <= barrier_x3 + BARRIER_WIDTH &&
                   bullet_y <= barrier_y + BARRIER_HEIGHT &&
                   bullet_y + BULLET_HEIGHT >= barrier_y) begin
            barrier_hitpoints[3] <= barrier_hitpoints[3] - 1; // Reduce barrier hitpoints
            bullet_active <= 0; // Deactivate bullet
          end
        end
        // ----- Barrier Collision Detection End -----
      end

      // Collision Detection: Alien Bullets and Player & Barriers
      for (i = 0; i < MAX_ALIEN_BULLETS; i = i + 1) begin
        if (alien_bullet_active[i]) begin
          // Check if alien bullet hits the shooter
          if (alien_bullet_x[i] + BULLET_WIDTH >= shooter_x && alien_bullet_x[i] <= shooter_x + SHOOTER_WIDTH && // Shooter width
              alien_bullet_y[i] + BULLET_HEIGHT >= 460 && alien_bullet_y[i] <= 470) begin // Shooter Y position
            // Bullet hits the shooter
            alien_bullet_active[i] <= 0; // Deactivate bullet
            if (player_health > 0) begin
              player_health <= player_health - 1; // Decrease player health
            end
          end else begin
            // Check collision with barriers
            // Barrier 0
            if (barrier_hitpoints[0] > 0 &&
                alien_bullet_x[i] + BULLET_WIDTH >= barrier_x0 &&
                alien_bullet_x[i] <= barrier_x0 + BARRIER_WIDTH &&
                alien_bullet_y[i] + BULLET_HEIGHT >= barrier_y &&
                alien_bullet_y[i] <= barrier_y + BARRIER_HEIGHT) begin
              barrier_hitpoints[0] <= barrier_hitpoints[0] - 1; // Reduce barrier hitpoints
              alien_bullet_active[i] <= 0; // Deactivate bullet
            end
            // Barrier 1
            else if (barrier_hitpoints[1] > 0 &&
                     alien_bullet_x[i] + BULLET_WIDTH >= barrier_x1 &&
                     alien_bullet_x[i] <= barrier_x1 + BARRIER_WIDTH &&
                     alien_bullet_y[i] + BULLET_HEIGHT >= barrier_y &&
                     alien_bullet_y[i] <= barrier_y + BARRIER_HEIGHT) begin
              barrier_hitpoints[1] <= barrier_hitpoints[1] - 1; // Reduce barrier hitpoints
              alien_bullet_active[i] <= 0; // Deactivate bullet
            end
            // Barrier 2
            else if (barrier_hitpoints[2] > 0 &&
                     alien_bullet_x[i] + BULLET_WIDTH >= barrier_x2 &&
                     alien_bullet_x[i] <= barrier_x2 + BARRIER_WIDTH &&
                     alien_bullet_y[i] + BULLET_HEIGHT >= barrier_y &&
                     alien_bullet_y[i] <= barrier_y + BARRIER_HEIGHT) begin
              barrier_hitpoints[2] <= barrier_hitpoints[2] - 1; // Reduce barrier hitpoints
              alien_bullet_active[i] <= 0; // Deactivate bullet
            end
            // Barrier 3
            else if (barrier_hitpoints[3] > 0 &&
                     alien_bullet_x[i] + BULLET_WIDTH >= barrier_x3 &&
                     alien_bullet_x[i] <= barrier_x3 + BARRIER_WIDTH &&
                     alien_bullet_y[i] + BULLET_HEIGHT >= barrier_y &&
                     alien_bullet_y[i] <= barrier_y + BARRIER_HEIGHT) begin
              barrier_hitpoints[3] <= barrier_hitpoints[3] - 1; // Reduce barrier hitpoints
              alien_bullet_active[i] <= 0; // Deactivate bullet
            end
          end
        end
      end

      // Check for game over
      if (player_health == 0 && !game_over_flag) begin
        game_over_flag <= 1;
      end

      // Check if all aliens have been destroyed
      if (aliens_remaining == 0 && !game_won_flag) begin
        game_won_flag <= 1;
      end

      // Movement logic
      if (movement_counter == 0) begin
        case (movement_dir)
          DIR_LEFT: begin
            if (shooter_x > SHOOTER_MIN_X)
              shooter_x <= shooter_x - 10;
          end
          DIR_RIGHT: begin
            if (shooter_x < SHOOTER_MAX_X)
              shooter_x <= shooter_x + 10;
          end
          default: ;
        endcase
      end
      movement_counter <= movement_counter + 1;
      if (movement_counter == 500000)
        movement_counter <= 0;
    end
  end
end

// Bullet Rendering
wire bullet_pixel = bullet_active &&
                    (pix_x >= bullet_x && pix_x < bullet_x + 4 &&
                     pix_y >= bullet_y && pix_y < bullet_y + 8);

// Alien bullet
wire alien_bullet_pixel;
reg alien_bullet_pixel_reg;
always @* begin
  alien_bullet_pixel_reg = 0;
  for (i = 0; i < MAX_ALIEN_BULLETS; i = i + 1) begin
    if (alien_bullet_active[i] &&
        pix_x >= alien_bullet_x[i] && pix_x < alien_bullet_x[i] + 4 &&
        pix_y >= alien_bullet_y[i] && pix_y < alien_bullet_y[i] + 8) begin
      alien_bullet_pixel_reg = 1;
    end
  end
end
assign alien_bullet_pixel = alien_bullet_pixel_reg;

// Shooter drawing logic
wire shooter_pixel = (
  (pix_y >= 460 && pix_y < 462 && pix_x >= shooter_x + 6 && pix_x < shooter_x + 14) ||
  (pix_y >= 462 && pix_y < 468 && pix_x >= shooter_x + 8 && pix_x < shooter_x + 12) ||
  (pix_y >= 468 && pix_y < 470 && pix_x >= shooter_x + 4 && pix_x < shooter_x + 16)
);

// Score digits
always @(*) begin
  digit0 = score % 10;
  digit1 = (score / 10) % 10;
  digit2 = (score / 100) % 10;
  digit_health = player_health;
end

// Function to render digit using 7-segment
function digit_segment;
  input [6:0] segments;
  input [9:0] x, y;
  input [9:0] x0, y0;
  begin
    digit_segment = 0;
    if (segments[0] && y >= y0 && y < y0 + 2 && x >= x0 + 2 && x < x0 + 8)
      digit_segment = 1;
    else if (segments[1] && x >= x0 + 8 && x < x0 + 10 && y >= y0 + 2 && y < y0 + 7)
      digit_segment = 1;
    else if (segments[2] && x >= x0 + 8 && x < x0 + 10 && y >= y0 + 7 && y < y0 + 12)
      digit_segment = 1;
    else if (segments[3] && y >= y0 + 12 && y < y0 + 14 && x >= x0 + 2 && x < x0 + 8)
      digit_segment = 1;
    else if (segments[4] && x >= x0 && x < x0 + 2 && y >= y0 + 7 && y < y0 + 12)
      digit_segment = 1;
    else if (segments[5] && x >= x0 && x < x0 + 2 && y >= y0 + 2 && y < y0 + 7)
      digit_segment = 1;
    else if (segments[6] && y >= y0 + 7 && y < y0 + 9 && x >= x0 + 2 && x < x0 + 8)
      digit_segment = 1;
  end
endfunction

reg heart_pixel;
integer heart_sprite_x, heart_sprite_y;
reg trophy_pixel;
integer trophy_sprite_x, trophy_sprite_y;

always @(*) begin
  heart_pixel = 0;
  heart_sprite_x = 0;
  heart_sprite_y = 0;
  trophy_pixel = 0;
  trophy_sprite_x = 0;
  trophy_sprite_y = 0;

  if (current_state == PLAYING || current_state == GAME_OVER) begin
    if (pix_x >= HEART_X && pix_x < HEART_X + 16 &&
        pix_y >= HEART_Y && pix_y < HEART_Y + 16) begin
      heart_sprite_x = pix_x - HEART_X;
      heart_sprite_y = pix_y - HEART_Y;
      if (heart_sprite[heart_sprite_y][heart_sprite_x])
        heart_pixel = 1;
    end
  end

  if (pix_x >= TROPHY_X && pix_x < TROPHY_X + TROPHY_WIDTH &&
      pix_y >= TROPHY_Y && pix_y < TROPHY_Y + TROPHY_HEIGHT) begin
    trophy_sprite_x = pix_x - TROPHY_X;
    trophy_sprite_y = pix_y - TROPHY_Y;
    if (trophy_sprite[trophy_sprite_y][trophy_sprite_x])
      trophy_pixel = 1;
  end

  barrier_pixel = 0;
  if (barrier_hitpoints[0] > 0 &&
      pix_x >= barrier_x0 && pix_x < barrier_x0 + BARRIER_WIDTH &&
      pix_y >= barrier_y && pix_y < barrier_y + BARRIER_HEIGHT) begin
    barrier_pixel = 1;
  end
  if (barrier_hitpoints[1] > 0 &&
      pix_x >= barrier_x1 && pix_x < barrier_x1 + BARRIER_WIDTH &&
      pix_y >= barrier_y && pix_y < barrier_y + BARRIER_HEIGHT) begin
    barrier_pixel = 1;
  end
  if (barrier_hitpoints[2] > 0 &&
      pix_x >= barrier_x2 && pix_x < barrier_x2 + BARRIER_WIDTH &&
      pix_y >= barrier_y && pix_y < barrier_y + BARRIER_HEIGHT) begin
    barrier_pixel = 1;
  end
  if (barrier_hitpoints[3] > 0 &&
      pix_x >= barrier_x3 && pix_x < barrier_x3 + BARRIER_WIDTH &&
      pix_y >= barrier_y && pix_y < barrier_y + BARRIER_HEIGHT) begin
    barrier_pixel = 1;
  end
end

wire health_pixel = (
  pix_x >= HEALTH_DIGIT_X &&
  pix_x < HEALTH_DIGIT_X + DIGIT_WIDTH &&
  pix_y >= HEALTH_DIGIT_Y &&
  pix_y < HEALTH_DIGIT_Y + DIGIT_HEIGHT &&
  digit_segment(digit_segments[digit_health], pix_x, pix_y, HEALTH_DIGIT_X, HEALTH_DIGIT_Y)
);

wire score_pixel =
    ((pix_x >= DIGIT2_X) && (pix_x < DIGIT2_X + DIGIT_WIDTH) && (pix_y >= DIGIT_Y) && (pix_y < DIGIT_Y + DIGIT_HEIGHT) &&
     digit_segment(digit_segments[digit2], pix_x, pix_y, DIGIT2_X, DIGIT_Y))
 || ((pix_x >= DIGIT1_X) && (pix_x < DIGIT1_X + DIGIT_WIDTH) && (pix_y >= DIGIT_Y) && (pix_y < DIGIT_Y + DIGIT_HEIGHT) &&
     digit_segment(digit_segments[digit1], pix_x, pix_y, DIGIT1_X, DIGIT_Y))
 || ((pix_x >= DIGIT0_X) && (pix_x < DIGIT0_X + DIGIT_WIDTH) && (pix_y >= DIGIT_Y) && (pix_y < DIGIT_Y + DIGIT_HEIGHT) &&
     digit_segment(digit_segments[digit0], pix_x, pix_y, DIGIT0_X, DIGIT_Y));

// VGA Output
assign R = video_active ? (
    (alien_pixel ? alien_color[2] : 1'b0) ||
    (bullet_pixel ? 1'b1 : 1'b0) ||
    (alien_bullet_pixel ? 1'b1 : 1'b0) ||
    (score_pixel ? 1'b1 : 1'b0) ||
    (health_pixel ? 1'b1 : 1'b0) ||
    (heart_pixel ? 1'b1 : 1'b0) ||
    (trophy_pixel ? 1'b1 : 1'b0)
) : 1'b0;

assign G = video_active ? (
    (alien_pixel ? alien_color[1] : 1'b0) ||
    (bullet_pixel ? 1'b1 : 1'b0) ||
    (shooter_pixel ? 1'b1 : 1'b0) ||
    (trophy_pixel ? 1'b1 : 1'b0) ||
    (barrier_pixel ? 1'b1 : 1'b0)
) : 1'b0;

assign B = video_active ? (
    (alien_pixel ? alien_color[0] : 1'b0) ||
    (bullet_pixel ? 1'b1 : 1'b0) ||
    (shooter_pixel ? 1'b1 : 1'b0) ||
    (health_pixel ? 1'b1 : 1'b0)
) : 1'b0;

// State Machine Implementation
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= PLAYING;
  end else begin
    current_state <= next_state;
  end
end

always @* begin
  case (current_state)
    PLAYING: begin
      if (game_won_flag)
        next_state = GAME_WON;
      else if (game_over_flag)
        next_state = GAME_OVER;
      else
        next_state = PLAYING;
    end
    GAME_WON: begin
      next_state = PLAYING;
    end
    GAME_OVER: begin
      next_state = PLAYING;
    end
    default: next_state = PLAYING;
  endcase
end

endmodule

