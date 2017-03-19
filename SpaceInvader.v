// Part 2 skeleton

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

module player(


);

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