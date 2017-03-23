// Box animation
module part3
	(
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
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
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
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    wire  ld_plot_wire, ld_erase_wire , ld_counter_reset_wire, ld_clk_pix_wire, ld_reset_wire, out_pix_wire;
    // Instansiate datapath
	datapath d0(
	  //Input
	  .data_in(SW[6:0]),
	  .colour_in(SW[9:7]),
	  .resetn(KEY[0]),
	  .ld_plot(ld_plot_wire),
	  .ld_erase(ld_erase_wire),
	  .ld_counter_reset(ld_counter_reset_wire),
	  .ld_clk_pix(ld_clk_pix_wire),
	  .ld_reset(ld_reset_wire),
	  
	  //Output
	  .out_pix(out_pix_wire),
	  .colour(colour),
	  .X(x),
	  .Y(y)
	);
   
    // Instansiate FSM control
      control c0(
	//Input
	.clk(CLOCK_50),
	.resetn(KEY[0]),
	.frames(out_pix_wire),
	//.go(KEY[1]),
	//.load(KEY[3]),
	
	//Output
	.ld_plot(ld_plot_wire),
	.ld_erase(ld_erase_wire),
	.ld_counter_reset(ld_counter_reset_wire),
	.ld_clk_pix(ld_clk_pix_wire),
	.ld_reset(ld_reset_wire),
	.wren(writeEn)
      );
    
    
endmodule

// FSM
module control(
    input clk,
    input resetn,
    input frames,

    output reg  ld_plot, ld_erase, ld_counter_reset, ld_clk_pix, ld_reset, wren
    );

    reg [2:0] current_state, next_state; 
    
    localparam  S_RESET			= 3'd0,
		S_PLOT      		= 3'd1,
                S_COUNTER_RESET 	= 3'd2,
                S_ERASE        		= 3'd3,
                S_PLOT 			= 3'd4,
                S_UPDATE_COUNTERS	= 3'd5;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
		S_RESET: next_state = S_PLOT;
                S_PLOT: next_state = S_COUNTER_RESET; // Loop in current state until value is input
                S_COUNTER_RESET: next_state = frames  ? S_ERASE: S_COUNTER_RESET; // Loop in current state until go signal goes low
                S_ERASE: next_state = S_UPDATE_COUNTER;
                S_UPDATE_COUNTERS: next_state = S_PLOT; // we will be done our two operations, start over after
            default:     next_state = S_RESET;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_plot = 1'b0;
        ld_clk_pix = 1'b0;
	ld_erase = 1'b0;
	ld_counter_reset = 1'b1;
	ld_reset = 1'b0;
	wren = 1'b0;
        case (current_state)
	    S_RESET: begin
                ld_reset = 1'b1;
                end
	    S_COUNTER_RESET: begin
	      ld_counter_reset = 1'b0;
	    end
	    S_ERASE: begin
	      ld_erase = 1'b1;
	    end
            S_UPDATE_COUNTERS: begin // Do A <- A * X
	      ld_clk_pix = 1'b1;
	    end
	    S_PLOT: begin // Do A <- A * X
	      ld_plot = 1'b1;
	      wren = 1'b1;
	    end
        // default:    // dold_resetn't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin
        if(!resetn)
            current_state <= S_RESET;
        elseq
            current_state <= next_state;
    end 
endmodule

// Datapath
module datapath(
    input resetn,
    input clk_50,
    input [2:0] colour_in,
    input [6:0] data_in,
    input ld_plot, ld_erase, ld_counter_reset, ld_clk_pix, ld_reset,
    
    output reg [7:0] X,
    output reg [6:0] Y,
    output reg [2:0] colour
    output reg out_pix;
    );
    reg left, up;
    wire [7:0] X_pos_wire;
    wire [6:0] Y_pos_wire;
    wire clk_pix_wire, clk_60hz_wire;
 
    
    // Registers a, b, c, x with respective input logic
    always @ (clk_50) begin
        if (!resetn) begin
            X <= 8'b0;
            Y <= 7'b0111100;
            colour <= 3'b0;
            left <= 1'b0;
            up <= 1'b1;
        end
        else begin
            if (ld_erase)
                colour <= 3'b0;
	    end
	    
	    if (ld_plot)
                colour <= colour_in;
	    end
	    
	    if (ld_reset)
                X <= 8'b0;
		Y <= 7'b0111100;
		left <= 1'b0;
		up <= 1'b1;
	    end
	    
    end
    
    XCounter x0(
      .clk_pix(ld_clk_pix),
      .cur_x_pos(X),
      .left(left),
      
      .out_x_pos(X_pos_wire),
      .out_left(left)
    );
    
    YCounter y0(
      .clk_pix(ld_clk_pix),
      .cur_y_pos(Y),
      .up(up),
      
      .out_y_pos(Y_pos_wire),
      .out_up(up)
    );
    
    DelayCounter d0(
      .clk_50(clk_50), 
      .resetn(ld_counter_reset), 
      .out_60hz(clk_60hz_wire)
    );
    FrameCounter f0(
      .clk_60hz(clk_60hz), 
      .resetn(ld_counter_reset), 
      .out_pix(out_pix)
    );
endmodule

// XCounter takes start pos and horizontal direction,
// and outputs the next x pos and direction for the next pixel-plot.
module XCounter(
  input clk_pix,
  //input en, Not used
  input [7:0] cur_x_pos,
  input left,
  
  output reg [7:0] out_x_pos;
  output reg out_left;
  );
  
  always @(posedge clk_pix) begin
    if (!left) begin // x moving towards right
      if (cur_x_pos < 160) begin // x has not reached right edge
	out_left <= left; // keep direction
	out_x_pos <= cur_x_pos + 1; // increment pos
      end else begin // x has reached right edge
	out_left = ~left; // flip direction
	out_x_pos <= cur_x_pos - 1; // decrement pos
      end
    end else begin // x moving towards left
      if (cur_x_pos > 0) begin // x has not reached left edge
	out_left <= left; // keep direction
	out_x_pos <= cur_x_pos - 1; // decrement pos
      end else begin // x has reached left edge
	out_left = ~left; // flip direction
	out_x_pos <= cur_x_pos + 1; // increment pos
      end
    end
  end
endmodule

// YCounter takes start pos and vertical direction,
// and outputs the next x pos and direction for the next pixel-plot.
module YCounter(
  input clk_pix,
  //input en, not used
  input [6:0] cur_y_pos,
  input up,
  
  output reg [6:0] out_y_pos;
  output reg out_up;
  );
  
  always @(posedge clk_pix) begin
    if (!up) begin // x moving down
      if (cur_y_pos < 120) begin // x has not reached bottom edge
	out_up <= up; // keep direction
	out_y_pos <= cur_y_pos + 1; // increment pos
      end else begin // x has reached bottom edge
	out_up = ~up; // flip direction
	out_y_pos <= cur_y_pos - 1; // decrement pos
      end
    end else begin // x moving up
      if (cur_y_pos > 0) begin // x has not reached top edge
	out_up <= up; // keep direction
	out_y_pos <= cur_y_pos - 1; // decrement pos
      end else begin // x has reached top edge
	out_up = ~up; // flip direction
	out_y_pos <= cur_y_pos + 1; // increment pos
      end
    end
  end
endmodule

// generate 60 Hz from 50 MHz
module DelayCounter(clk_50, resetn, out_60hz);
  input clk_50, resetn;
  output reg out_60hz = 0;

  reg [19:0] count_reg = 0;

  always @(posedge clk_50) begin
    if (!resetn) begin
      count_reg <= 0;
      out_60hz <= 0;
    end else begin
      if (count_reg < 416666) begin
	count_reg <= count_reg + 1;
      end else begin
	count_reg <= 0;
        out_60hz <= ~out_60hz;
      end
  end
endmodule

// generate 1 pulse (a single pixel-plot) every 15 frames
module FrameCounter(clk_60hz, resetn, out_pix);
  input clk_60hz, resetn;
  output reg out_pix = 0;

  reg [3:0] count_reg = 0;

  always @(posedge clk_50) begin
    if (!resetn) begin
      count_reg <= 0;
      out_pix <= 0;
    end else begin
      if (count_reg < 15) begin
	count_reg <= count_reg + 1;
      end else begin
	count_reg <= 0;
        out_pix <= ~out_pix;
      end
  end
endmodule
