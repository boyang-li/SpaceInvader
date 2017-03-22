// This is the top layer of the game
// FPGA device: Cyclone5 series
module SpaceInvader(
  CLOCK_50,           //  On Board 50 MHz
  // Your inputs and outputs here
   KEY,
   SW,
  // The ports below are for the VGA output.  Do not change.
  VGA_CLK,              //  VGA Clock
  VGA_HS,             //  VGA H_SYNC
  VGA_VS,             //  VGA V_SYNC
  VGA_BLANK_N,            //  VGA BLANK
  VGA_SYNC_N,           //  VGA SYNC
  VGA_R,              //  VGA Red[9:0]
  VGA_G,              //  VGA Green[9:0]
  VGA_B               //  VGA Blue[9:0]
  );

  input   CLOCK_50;       //  50 MHz
  input   [9:0]   SW;
  input   [3:0]   KEY;

  // Declare your inputs and outputs here
  // Do not change the following outputs
  output    VGA_CLK;          //  VGA Clock
  output    VGA_HS;         //  VGA H_SYNC
  output    VGA_VS;         //  VGA V_SYNC
  output    VGA_BLANK_N;        //  VGA BLANK
  output    VGA_SYNC_N;       //  VGA SYNC
  output  [9:0] VGA_R;          //  VGA Red[9:0]
  output  [9:0] VGA_G;          //  VGA Green[9:0]
  output  [9:0] VGA_B;          //  VGA Blue[9:0]

  wire resetn;
  assign resetn = KEY[0];

  // Create the colour, x, y and writeEn wires that are inputs to the controller.
  wire [2:0] colour;
  wire [7:0] x;
  wire [6:0] y;
  wire writeEn;

  // Create an Instance of a VGA controller - there can be only one!
  // Define the number of colours as well as the initial background
  // image file (.MIF) for the controller.
  vga_adapter VGA(
    .resetn(resetn),
    .clock(CLOCK_50),
    .colour(colour),
    .x(x),
    .y(y),
    .plot(writeEn),
    /* Signals for the DAC to drive the monitor. */
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK(VGA_BLANK_N),
    .VGA_SYNC(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK));

  defparam VGA.RESOLUTION = "160x120";
  defparam VGA.MONOCHROME = "FALSE";
  defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
  defparam VGA.BACKGROUND_IMAGE = "black.mif";

  // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
  // for the VGA controller, in addition to any other functionality your design may require.

  // space_invader SI(
  //   .clk(CLOCK_50),
  //   .resetn(KEY[0]),
  //   .btnL(KEY[4]),
  //   .btnR(KEY[3]),
  //   .btnFire(KEY[2]),
  //   .btnStart(KEY[1]),
  //   .x(x),
  //   .y(y),
  //   .wren(writeEn)
  // );

  // Hack Stuff     -------------------------------------------------
  reg CLOCK_25, slow_clk;
  // Generate a 25MHz clock from the on-board 50MHz clock
  always @(posedge CLOCK_50)
    CLOCK_25 <= ~CLOCK_25;
  reg [31:0] slow_counter;
  always @(posedge CLOCK_50)
  begin
    if (slow_counter == 50000) begin
      slow_counter <= 0;
      slow_clk <= ~slow_clk;
    end else begin
      slow_counter <= slow_counter + 1;
    end
  end

  //The ship draw
  wire [2:0] shipRGB;
  reg [9:0] shipX;
  always@(posedge slow_clk)
    if(~KEY[1] && |shipX)
      shipX <= shipX - 1;
    else if(~KEY[0] && shipX<150)
      shipX <= shipX + 1;
  assign shipRGB = (x>shipX && x<shipX+10 && y>100 && y<110) ? 3'b111 : 0;

  //Draw a bullet
  // reg [8:0] bulletX, bulletY;
  // reg fire, hit;
  // wire [2:0] bulletRGB;
  // always @(posedge slow_clk)
  //   if(~btnFire && ~fire) begin
  //     bulletX <= shipX+6;
  //     fire <= 1;
  //   end else if(fire && bulletY>0)
  //     bulletY <= bulletY - 1;
  //   else begin
  //     fire <= 0;
  //     bulletY <= 225;
  //   end
  // Don't need hit condition until next week!
  //always@(posedge clk)
    //if(bulletY>enemyY && bulletY < enemyY+25 && bulletX>enemyX && bulletX < enemyX+25)
      //hit <= 1;
    //else
      //hit <= 0;
  //assign bulletRGB = (fire && y>bulletY && y<bulletY+12 && x>bulletX && x<bulletX+1) ? 3'b111 : 0;

  // x,y counters
  wire [7:0] localX;
  wire [6:0] localY;
  wire line,frame;
  assign line = (localX==159);
  assign frame = (localY==119);
  assign wren = ((localY>9 && localY<129) && (localX>36 && localX<196));
  assign colour = (wren) ? shipRGB|bulletRGB : 0;
  assign wren = ((localY>9 && localY<129) && (localX>36 && localX<196));
  assign x = wren?x-36:0;
  assign y = wren?y-9:0;

  always @(posedge CLOCK_25)
    if(line)
      localX <= 0;
    else
      localX <= localX + 1;

  always @(posedge CLOCK_25)
    if(frame)
      localY <= 0;
    else
      localY <= localY + 1;

  // ----------------------------------------------------------------

endmodule

module space_invader(clk,resetn,btnL,btnR,btnFire,btnStart,x,y,colour,wren);
  input clk,resetn;
  input btnL,btnR,btnFire,btnStart;

  output [2:0] colour;
  output reg [8:0] x;
  output reg [7:0] y;
  output wren;

  // General wires

  //wire pulseL,pulseR,truePulseL,truePulseR;
  //wire cleanL,cleanR;

  //wire [8:0] playerXpos;
  //wire [7:0] playerYpos;
  //reg border, player_border;
  //reg [4:0] player_addr; // Mem address corresponds to a X,Y pair
  //wire [3:0] player_din; // Mem data stores the RGB color for the pixel
  //wire [3:0] player_dout;
  reg clk_25;
  //wire R,G,B;

  //ram32x4 MEMPLAYER(player_addr,clk_25,player_din,wren,player_dout);


  //wire btnShoot_wire;
  // Projectile wires
  //wire [8:0] projectileXpos;
  //wire [7:0] projectileYpos;




//  player PLAYER(
//    .clk(CLK_25),
//    .resetn(resetn),
//    .btnShoot(btnFire),
//
//    .btnLeft(pulseL),
//    .btnRight(pulseR),
//    .playerXpos(playerXpos),
//    .playerYpos(playerYpos),
//  .shoot(btnShoot_wire)
//);

//  projectile p0(
//
//    .startXpos(playerXpos),
//    .startYpos(playerYpos),
//    .shoot(btnShoot_wire),
//    .clk(CLK_25),
//    .resetn(resetn),
//    .direction(1'b0),
//
//    .projectileXpos(projectileXpos),
//    .projectileYpos(projectileYpos)
//  );

//  motion_debounce MDL(clk,resetn,btnL,cleanL);
//  motion_debounce MDR(clk,resetn,btnR,cleanR);
//
//  motion_pulse MPL(clk,resetn,cleanL,pulseL);
//  motion_pulse MPR(clk,resetn,cleanR,pulseR);

  // blk_mem_gen_0 MEMPLAYER(CLK_25,1,0,player_addr_wire,0,player_data_wire);

  //assign ship_addr =  (shipborder)? space_addr :
  //                  (lifeborder)? life_addr : 0;

  //assign truefire = (startscreen)? 0 : pulsefire;
  //assign truepulseL = (startscreen)? 0 : pulseL;
  //assign truepulseR = (startscreen)? 0 : pulseR;
  //assign totalgameover = (gameover) || (livesgameover);

  // RGB OUTPUT
//  always @(posedge clk)
//  begin
//    colour[2] <= R;
//    colour[1] <= G;
//    colour[0] <= B;
//  end

  // Update colour channels with memory data based on game logics
//  always@(posedge clk)
//  begin
//    R <=  (player_border)   ? player_dout[2] : 0;
//    G <=  (player_border)   ? player_dout[1] :
//          (border)       ? 1 : 0;
//    B <=  (player_border)   ? player_dout[0] : 0;
//  end else begin
//    R <= 0;
//    B <= 0;
//    G <= 0;
//  end

  // Update game logics at the 25MHz pulse
//  always @(posedge CLK_25)
//  begin
//    if(!resetn) begin
//      player_addr <= 0;
//    end else begin
//      player_addr <= ( == playerYpos) ? 0 : ((player_border)? (player_addr +  1'b1) : (player_addr));
//    end
//  end

endmodule

module projectile(projectileXpos, projectileYpos, startXpos, colour, startYpos, shoot, clk, resetn, direction);
  input clk, resetn;
  input [8:0] startXpos;
  input [7:0] startYpos;
  input shoot, direction; //direction 0 = up, 1 = down

  output reg [8:0] projectileXpos; // the current X position of the projectile
  output reg [7:0] projectileYpos; // the current Y position of the projectile
  output reg [2:0] colour;

  reg shot;

  always @(posedge clk) begin

    if (!resetn) begin //active low reset, on reset assign the shot value to not be high
      shot <= 1'b0; //we set this to low to indicate that the projectile isnt in motion.
      colour <= 3'b0; // set projectile colour to black so it blends with
    end
    else begin
      if (shoot) begin
        shot <= 1'b1; // indicate that the projectile should be in motion (incrementing the Y position)
        projectileXpos <= startXpos; // assign the starting X position of the projectile to be the X position of the entity that shot it at that moment
        projectileYpos <= startYpos; // assign the starting Y position of the projectile to be the Y position of the entity that shot it at that moment
        colour <= 3'b111; //set the projectile colour to white so it stands out from the background (is visible)
      end
      if (shot) begin
        if(direction) // check direction, not necessary for milestone one but added for future ease
          projectileYpos <= projectileYpos + 1; //projectile going down
        else
          projectileYpos <= projectileYpos - 1; // projectile going up
        if ((projectileYpos == 0) || (projectileYpos == 240)) //if the rocket reaches the end of the screen (top or bottom), dont have to worry about collision of enemies until later
          //TODO
          shot <= 1'b0; //indicate that the bullet is no longer traveling across the screen, so stop incrementing the Yposition (indirectly does this by not entering the if shot                   statement
      end

    end


  end
endmodule

module player(playerXpos,playerYpos, shoot, clk,resetn,btnLeft,btnRight, btnShoot);
  input clk,resetn;
  input btnLeft,btnRight, btnShoot; //btnLeft and btnRight are signals that go/are high when their corresponding buttons are pushed
  output reg [8:0] playerXpos; //The X position of the Player model (Value Between 0 and 320) 9bit
  output reg [7:0] playerYpos; // The Y position of the Player model (Value Between 0 and 240) 8bit
  output reg shoot; // 1bit signal indicating whether or not the projectile should be rendered

  always @(posedge clk) begin //On each clock cycle

    if (!resetn) begin // Active low reset, so when resetn is low we set our Player position values to default (approximately middle of the screen horizontally, and bottom of the screen vertically)
      playerXpos <= 9'd167; //Approx middle of screen
      playerYpos <= 9'd200; // bottom of the screen (Adjusted to fit the actual player model)
      shoot <= 1'b0; // Dont fire a projectile yet
    end
    else begin
      /*
  Movement block of the Player, Detects corners and behaves accordingly
  i.e. doesnt move model on edges if they are moving into the edge.
      */
      if (btnLeft) begin // On button left press
  if (playerXpos == 0) //Check if the Player model is hugging the left edge of the screen
    playerXpos <= playerXpos; // Stay there
  if (playerXpos > 0) // Check if there is still space to move left.
    playerXpos <= playerXpos - 9'd1; // Move one pixel left
      end
      else if (btnRight) begin // On button right press
  if (playerXpos == 9'd305) //Check if the Player model is hugging the right edge of the screen (Adjusted for 15pixel wide model)
    playerXpos <= playerXpos; // Dont move
  if (playerXpos < 9'd305) // Check if there is still space to move right.
    playerXpos <= playerXpos + 9'd1; // Move one pixel right
      end
      if (btnShoot) begin
  //TODO
  shoot <= 1'b1; // signal that the projectile should be fired
      end
    end
  end

endmodule

module alien(clk,resetn,initX,initY,alienX,alienY,isAlive,gamestart,gameover);
  input clk,resetn;
  input gamestart,gameover;
  input [8:0] initX;
  input [7:0] initY;
  input isAlive;

  output reg [8:0] alienX;
  output reg [7:0] alienY;

  // TODO: 19-bits can support 512000 decimal numbers
  reg [18:0] counter;
  reg speed,direction;

  always @(posedge clk)
  begin
    if (!resetn) begin
      alienX <= initX;
    end else if (counter == 19'd400_000) begin
      counter <= 0;
      speed <= 1'b1;
    end else begin
      if (direction) begin
  counter <= counter + 1'b1;
  alienX <= gamestart ? (alienX + speed) : alienX;
  speed <= 0;
      end else begin
  counter <= counter + 1'b1;
  alienX <= gamestart ? (alienX - speed) : alienX;
  speed <= 0;
      end
    end
  end

  always @(posedge clk)
  begin
    if (!resetn) begin
      alienY <= initY;
      direction <= 0;
    end else begin
      if ((alienX == initX - 85) && (direction == 0)) begin
  direction <= 1'b1;
  alienY <= gameover ? alienY : (alienY + 10);
      end else if ((alienX == initX + 25) && (direction == 1)) begin
  direction <= 0;
  alienY <= gameover ? alienY : (alienY + 10);
      end
    end
  end

endmodule

module motion_debounce(clk,resetn,noisy,clean);
  input clk,resetn,noisy;
  output reg clean;

  reg [19:0] counter;
  reg temp;
  wire [19:0] edge_delay = 20'd1000000;

  always @(posedge clk)
  begin
    if (!resetn) begin
      counter <= 20'b0;
      clean <= 1'b0;
      temp <= 1'b0;
    end else begin
      if (noisy) begin
  if (counter == edge_delay) begin
    clean <= temp;
  end else begin
    temp <= noisy;
    clean <= clean;
    counter <= counter + 1'b1;
  end
      end else begin
  counter <= 20'b0;
  clean <= 1'b0;
      end
    end
  end
endmodule

module motion_pulse(clk,resetn,level,pulse);
  input clk,resetn,level;
  output reg pulse;

  reg [23:0] counter;
  reg [1:0] current_state;
  reg [1:0] next_state;

  localparam  S0 = 2'd00,
              S1 = 2'd01;

  // FSM
  always @(posedge clk)
  begin
    case(current_state)
      S0:begin
  pulse <= 1'b0;
  counter <= 0;
  if(level) begin
    next_state <= S1;
  end else begin
    next_state <= S0;
  end
      end

      S1:begin
  if (counter == 24'd400_000) begin
    pulse <= 1'b1;
          counter <= 0;
        end else begin
          pulse <= 0;
          counter <= counter + 1'b1;
        end

  if (level) begin
    next_state <= S1;
  end else begin
    next_state <= S0;
  end
      end

      default: next_state <= S0;
    endcase
  end

  // Set the new state
  always @(posedge clk)
  begin
    if(!resetn)
      current_state <= 2'b0;
    else
      current_state <= next_state;
  end
endmodule

//module frame_pulse(clk_25,resetn,plot);
//  input clk_25,resetn;
//  output reg plot;
//
//  reg [18:0] counter;
//
//  always@(posedge clk_25)
//  begin
//    if (!resetn) begin
//      plot <= 0;
//    end else begin
//      if (counter == 19'd400_000) begin
//    plot <= 1'b1;
//          counter <= 0;
//        end else begin
//          plot <= 0;
//          counter <= counter + 1'b1;
//        end
//    end
//  end
//endmodule