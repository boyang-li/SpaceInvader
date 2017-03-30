// Part 2 skeleton

module part2
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
    wire  ld_x_wire, ld_y_wire, ld_colour_wire, update_counter_wire;
    wire [4:0] counter_wire;
    // Instansiate datapath
	datapath DATA(
	  //Input
	  .data_in(SW[6:0]),
	  .colour_in(SW[9:7]),
	  .resetn(KEY[0]),
	  .ld_x(ld_x_wire),
	  .ld_y(ld_y_wire),
	  .ld_colour(ld_colour_wire),
    .update_counter(update_counter_wire),
	  //Output
	  .colour(colour),
	  .X(x),
	  .Y(y),
    .counter(counter_wire)
	);

    // Instansiate FSM control
      control c0(
	//Input
	.clk(CLOCK_50),
	.resetn(KEY[0]),
	.go(KEY[1]),
	.load(KEY[3]),
  .counter(counter_wire),

	//Output
	.ld_x(ld_x_wire),
	.ld_y(ld_y_wire),
	.ld_colour(ld_colour_wire),
	.wren(writeEn),
  .update_counter(update_counter_wire)
      );


endmodule

module control(
    input clk,
    input resetn,
    input go, load, counter,

    output reg  ld_y, ld_x, ld_colour, wren, update_counter
    );

    reg [2:0] current_state, next_state;

    localparam  S_LOAD_X        = 4'd0,
                S_LOAD_X_WAIT   = 4'd1,
                S_LOAD_Y        = 4'd2,
                S_LOAD_Y_WAIT   = 4'd3,
                S_LOAD_COLOUR   = 4'd4,
                S_PLOT      	= 4'd5;

    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                S_LOAD_X: next_state = load ? S_LOAD_X_WAIT : S_LOAD_X;
                S_LOAD_X_WAIT: next_state = load ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                S_LOAD_Y: next_state = load ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_COLOUR; // Loop in current state until go signal goes low
                S_LOAD_COLOUR: next_state = S_PLOT;
                S_PLOT: next_state = (counter == 4'd16) S_LOAD_X: S_PLOT; // we will be done our two operations, start over after
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_x = 1'b0;
        ld_y = 1'b0;
	wren = 1'b0;
	ld_colour = 1'b0;
  update_counter = 1'b0;
        case (current_state)
	    S_LOAD_X: begin
                ld_x = 1'b1;
                end
	    S_LOAD_Y: begin
	    ld_y = 1'b1;
		end
	    S_LOAD_COLOUR: begin
	    ld_colour = 1'b1;
		end

            S_PLOT: begin // Do A <- A * X
                wren = 1'b1;
                update_counter = 1'b1;
		end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end
endmodule

module datapath(
    input clk,
    input resetn,
    input ld_x, ld_y, update_counter,
    input [2:0] colour_in,
    input [6:0] data_in,

    output reg [4:0] counter,
    output reg [7:0] X,
    output reg [6:0] Y,
    output reg [2:0] colour
    );

    // Registers a, b, c, x with respective input logic
    always @ (posedge clk) begin
        if (!resetn) begin
            X <= 8'b0;
            Y <= 7'b0;
            colour <= 3'b0;
            counter <= 5'd0;
        end
        else begin
            if (ld_x)
                X <= 8'b0 + data_in;

            if (ld_y)
                Y <= data_in;
            if (update_counter) begin
                if(counter == 5'd17)begin
                  counter <= 5'd0;
                end else begin

                end begin
                  X <= X + ( 8'b00000000 + counter[1:0]);
                  Y <= Y + ( 8'b00000000 + counter[3:2]);
                  counter <= counter + 5'd1;
                end
            end


            colour <= colour_in;
        end
    end
endmodule
