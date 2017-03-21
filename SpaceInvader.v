// This is the top layer of the game
// FPGA device: Cyclone5 series
module fpga_top(
	CLOCK_50,						//	On Board 50 MHz
	// Your inputs and outputs here
        KEY,
        SW,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B   						//	VGA Blue[9:0]
	);

	input		CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [4:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output		VGA_CLK;   				//	VGA Clock
	output		VGA_HS;					//	VGA H_SYNC
	output		VGA_VS;					//	VGA V_SYNC
	output		VGA_BLANK_N;				//	VGA BLANK
	output		VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [8:0] x;
	wire [7:0] y;
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
		
	defparam VGA.RESOLUTION = "321x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	space_invader SI(
	  .clk(CLOCK_50),
	  .resetn(KEY[0]),
	  .btnL(KEY[4]),
	  .btnR(KEY[3]),
	  .fire(KEY[2]),
	  .btnStart(KEY[1]),
	  .x(x),
	  .y(y),
	  .plot(writeEn)
	);
endmodule

module space_invader(clk,resetn,btnL,btnR,fire,btnStart,x,y,colour,plot);
  input clk,resetn;
  input btnL,btnR,fire,btnStart;
 
  output reg [2:0] colour;
  output reg [8:0] x;
  output reg [7:0] y;
  output reg plot;
  
  // Game logic wires
  reg CLK_25;
  wire pulseL,pulseR,truePulseL,truePulseR;
  wire cleanL,cleanR;
  //wire [8:0] haddr;
  //wire [7:0] vaddr;
  wire R,G,B;
  
  // Player wires
  wire [8:0] playerXpos;
  wire [7:0] playerYpos;
  
  reg [8:0] player_addr;
  wire [8:0] player_addr_wire;
  wire [7:0] player_data_wire;
  
  
  // Generate a 25MHz clock from the on-board 50MHz clock
  clk_25 CLOCK_25(
    .clk(clk),
    .resetn(resetn),
    .clk_25(CLK_25));
  
  player PLAYER(
    .clk(CLK_25),
    .resetn(resetn),
    .btnLeft(pulseL),
    .btnRight(pulseR),
    .playerXpos(playerXpos),
    .playerYpos(playerYpos));
  
  motion_debounce MDL(clk,resetn,btnL,cleanL);
  motion_debounce MDR(clk,resetn,btnR,cleanR);
  
  motion_pulse MPL(clk,resetn,cleanL,pulseL);
  motion_pulse MPR(clk,resetn,cleanR,pulseR);
  
  // blk_mem_gen_0 MEMPLAYER(CLK_25,1,0,player_addr_wire,0,player_data_wire);
  
  assign player_addr_wire = player_addr;
  //assign ship_addr =  (shipborder)? space_addr : 
  //                  (lifeborder)? life_addr : 0;
  
  //assign truefire = (startscreen)? 0 : pulsefire;
  //assign truepulseL = (startscreen)? 0 : pulseL;
  //assign truepulseR = (startscreen)? 0 : pulseR;
  //assign totalgameover = (gameover) || (livesgameover);
  
  assign colour[2] = R;
  assign colour[1] = G;
  assign colour[0] = B;
endmodule

module player(clk,resetn,btnLeft,btnRight,playerXpos,playerYpos);
  input clk,resetn;
  input btnLeft,btnRight; //btnLeft and btnRight are signals that go/are high when their corresponding buttons are pushed
  output reg [8:0] playerXpos; //The X position of the Player model (Value Between 0 and 320) 9bit
  output reg [7:0] playerYpos; // The Y position of the Player model (Value Between 0 and 240) 8bit
  
  always @(posedge clk) begin //On each clock cycle
  
    if (!resetn) begin // Active low reset, so when resetn is low we set our Player position values to default (approximately middle of the screen horizontally, and bottom of the screen vertically)
      playerXpos <= 9'd167; //Approx middle of screen
      playerYpos <= 9'd200; // bottom of the screen (Adjusted to fit the actual player model)
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
	if (playerXpos < 0'd305) // Check if there is still space to move right.
	  playerXpos <= playerXpos + 9'd1; // Move one pixel right
      end   
 
    end
  end

endmodule 

module alien(clk,resetn,initX,initY,alienX,alienY,isAlive,gamestart,gameover);
  input clk,resetn;
  input gamestart,gameover;
  input [8:0] initX;
  input [7:0] initY;
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
      
      default: nextstate <= S0;
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

// Rate dividers
module clock_25(clk,resetn,clk_25);
  input clk,resetn;
  output reg clk_25;
  
  always@(posedge clk)
  begin
    if (!resetn) begin
      clk_25 <= 0;
    end else begin
      clk_25 <= ~clk;
    end
  end
endmodule

module frame_pulse(clk_25,resetn,plot);
  input clk_25,resetn;
  output reg plot;
  
  reg [18:0] counter;
  
  always@(posedge clk_25)
  begin
    if (!resetn) begin
      plot <= 0;
    end else begin
      if (counter == 19'd400_000) begin
	  plot <= 1'b1;
          counter <= 0;
        end else begin
          plot <= 0;
          counter <= counter + 1'b1;
        end
    end
  end
endmodule