module SpaceInvader(
	
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

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

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
		
	defparam VGA.RESOLUTION = "321x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
	
endmodule

module player(PlayerXpos, PlayerYpos, resetn, clk
  );
  input resetn,clk, btnLeft, btnRight; //btnLeft and btnRight are signals that go/are high when their corresponding buttons are pushed
  output reg [8:0] PlayerXpos; //The X position of the Player model (Value Between 0 and 320) 9bit
  output reg [7:0] PlayerYpos; // The Y position of the Player model (Value Between 0 and 240) 8bit
  
  always @(posedge clk) begin //On each clock cycle
  
    if (!resetn) begin // Active low reset, so when resetn is low we set our Player position values to default (approximately middle of the screen horizontally, and bottom of the screen vertically)
      PlayerXpos <= 9'd167; //Approx middle of screen
      PlayerYpos <= 9'd200; // bottom of the screen (Adjusted to fit the actual player model)
    end 
    else begin
      /*
	Movement block of the Player, Detects corners and behaves accordingly
	i.e. doesnt move model on edges if they are moving into the edge.
      */
      if (btnLeft) begin // On button left press
	if (PlayerXpos == 0) //Check if the Player model is hugging the left edge of the screen
	  PlayerXpos <= PlayerXpos; // Stay there
	if (PlayerXpos > 0) // Check if there is still space to move left.
	  PlayerXpos <= PlayerXpos - 9'd1; // Move one pixel left
      end
      else if (btnRight) begin // On button right press
	if (PlayerXpos == 9'd305) //Check if the Player model is hugging the right edge of the screen (Adjusted for 15pixel wide model)
	  PlayerXpos <= PlayerXpos; // Dont move
	if (PlayerXpos < 0'd305) // Check if there is still space to move right.
	  PlayerXpos <= PlayerXpos + 9'd1; // Move one pixel right
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
  

endmodule 