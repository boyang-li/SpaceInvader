// 4x4 Box animation
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

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
// 	vga_adapter VGA(
// 			.resetn(resetn),
// 			.clock(CLOCK_50),
// 			.colour(colour),
// 			.x(x),
// 			.y(y),
// 			.plot(writeEn),
// 			/* Signals for the DAC to drive the monitor. */
// 			.VGA_R(VGA_R),
// 			.VGA_G(VGA_G),
// 			.VGA_B(VGA_B),
// 			.VGA_HS(VGA_HS),
// 			.VGA_VS(VGA_VS),
// 			.VGA_BLANK(VGA_BLANK_N),
// 			.VGA_SYNC(VGA_SYNC_N),
// 			.VGA_CLK(VGA_CLK));
// 		defparam VGA.RESOLUTION = "160x120";
// 		defparam VGA.MONOCHROME = "FALSE";
// 		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
// 		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

//   reg CLOCK_25;
//   // Generate 25 MHz for duty clock
//   always @(posedge CLOCK_50) begin
//     if (!resetn) begin
//       // reset
//       CLOCK_25 <= 0;
//     end else begin
//       CLOCK_25 <= ~CLOCK_25;
//     end
//   end
  
  //TEST
  wire [7:0] next_x;
  wire [6:0] next_y;
  wire [2:0] cur_state;
  
  wire go;
  wire on_plot,next_move;
  wire delay_cnt_rst;
  wire active,draw_en,erase_en,update_xy;
  assign resetn = KEY[0];
  assign go = ~KEY[1];

  // Instansiate control
  control c0(
    //Input
    .clk(CLOCK_50),
    .resetn(resetn),
    .go(go),
    .on_plot(on_plot),
    .next_move(next_move),
    //Output
    .delay_cnt_rst(delay_cnt_rst),
    .active(active),
    .draw_en(draw_en),
    .erase_en(erase_en),
    .update_xy(update_xy),
    .current_state(cur_state)
  );

  // Instansiate datapath
  datapath d0(
    //Input
    .clk(CLOCK_50),
    .resetn(resetn),
    .colour_in(SW[9:7]),
    .delay_cnt_rst(delay_cnt_rst),
    .active(active),
    .draw_en(draw_en),
    .update_xy(update_xy),
    .x_in(x),
    .y_in(y),
    //Output
    .on_plot(on_plot),
    .next_move(next_move),
    .x_out(x),
    .y_out(y),
    .colour_out(colour),
    .wren(writeEn),
    .next_x(next_x),
    .next_y(next_y)
    );
endmodule

// FSM
module control(
  input clk,resetn,go,

  input on_plot,
  input next_move,

  output reg delay_cnt_rst,
  output reg active,draw_en,erase_en,update_xy,
  output reg [2:0] current_state 
  );

  //reg [2:0] current_state, next_state;
  reg [2:0] next_state;
  
  localparam  S_RST_ALL	  = 3'd0,
              S_IDLE      = 3'd1,
	      S_DRAW_BOX  = 3'd2,
              S_RST_DELAY = 3'd3,
              S_WAIT_PLOT = 3'd4,
              S_ERASE_BOX = 3'd5,
              S_UPDATE_XY = 3'd6;

  // Next state logic aka our state table
  always @(posedge clk)
  begin: state_table
    case (current_state)
      S_RST_ALL:   next_state <= S_IDLE;
      S_IDLE:      next_state <= (go) ? S_DRAW_BOX : S_IDLE;
      S_DRAW_BOX:  next_state <= (on_plot) ? S_RST_DELAY : S_DRAW_BOX;
      S_RST_DELAY: next_state <= S_WAIT_PLOT;
      S_WAIT_PLOT: next_state <= (next_move) ? S_ERASE_BOX : S_WAIT_PLOT;
      S_ERASE_BOX: next_state <= S_UPDATE_XY;
      S_UPDATE_XY: next_state <= S_DRAW_BOX;
      default:     next_state <= S_RST_ALL;
    endcase
  end // state_table

  // current_state registers
  always @(posedge clk)
  begin: set_states
    if (!resetn) begin
      active <= 1'b0;
      current_state <= S_RST_ALL;
    end else begin
      if (go) begin
        active <= 1'b1;
      end
      current_state <= next_state;
    end
  end

  // Output logic aka all of our datapath control signals
  always @(*)
  begin: enable_signals
    // By defaults...
    delay_cnt_rst = 1'b0;
    draw_en = 1'b0;
    erase_en = 1'b0;
    update_xy = 1'b0;

    case (current_state)
      S_RST_ALL: begin
        delay_cnt_rst = 1'b1;
      end
      S_DRAW_BOX: begin
        draw_en = 1'b1;
      end
      S_RST_DELAY: begin
        delay_cnt_rst = 1'b1;
        draw_en = 1'b1;
      end
      S_WAIT_PLOT: begin
        draw_en = 1'b1;
      end
      S_ERASE_BOX: begin
	// We just need to reset the vga_adapter
        erase_en = 1'b1;
      end
      S_UPDATE_XY: begin
        update_xy = 1'b1;
      end
      // default: // dold_resetn't need default since we already made sure all
      // of our outputs were assigned a value at the start of the always block
    endcase
  end // enable_signals
endmodule

// Datapath
module datapath(
    // Input
    input clk,resetn,
    input [2:0] colour_in,
    input delay_cnt_rst,
    input active,draw_en,update_xy,
    input [7:0] x_in,
    input [6:0] y_in,
    // Output
    output reg on_plot,next_move,
    output reg [7:0] x_out,
    output reg [6:0] y_out,
    output reg [2:0] colour_out,
    output reg wren,
    output [7:0] next_x,
    output [6:0] next_y
    );
    
//     wire [7:0] next_x;
//     wire [6:0] next_y;
    wire delay_cnt_out;
    reg x_offset,y_offset;

    always @(posedge clk) begin
      // By defaults...
      next_move <= 0;
    
      if (!resetn) begin
        x_out <= 0;
        y_out <= 7'd60;
        // 0 = -1, 1 = 1, default: up-right
        x_offset <= 1'b1;
        y_offset <= 0;
        colour_out <= 3'b000;
        on_plot <= 0;
        next_move <= 0;
        wren <= 0;
      end
      else if (active) begin
        if (draw_en) begin
          wren <= 1'b1;
          colour_out <= colour_in;
          // This needs to change to make a 4x4 box
          on_plot <= 1'b1;
        end else begin
	  wren <= 0;
	  colour_out <= 3'b000;
	  on_plot <= 1'b0;
        end
	// If this is 4x4 box, it would be x_out == (0-4)
        if ((x_out == 0) && (!x_offset)) begin
          x_offset <= ~x_offset;
        end
        // If this is 4x4 box, it would be x_out == (159+4)
        else if ((x_out == 159) && (x_offset)) begin
          x_offset <= ~x_offset;
        end
	// If this is 4x4 box, it would be y_out == (0-4)
        if ((y_out == 0) && (!y_offset)) begin
          y_offset <= ~y_offset;
        end
        // If this is 4x4 box, it would be y_out == (119+4)
        else if ((y_out == 119) && (y_offset)) begin
          y_offset <= ~y_offset;
        end

        if (update_xy) begin
          x_out <= next_x;
          y_out <= next_y;
        end
      end
    end
   
    always @(posedge delay_cnt_out) begin
      if (active && draw_en) begin
	next_move <= 1'b1;
      end
    end
    
    XCounter xc0(
      .clk(clk),
      .en(active),
      .x(x_out),
      .offset(x_offset),
      .x_out(next_x)
    );
    YCounter yc0(
      .clk(clk),
      .en(active),
      .y(y_out),
      .offset(y_offset),
      .y_out(next_y)
    );
    DelayCounter dc0(
      .clk_50mhz(clk),
      .rst(delay_cnt_rst),
      .en(active),
      .clk_15hz_out(delay_cnt_out)
    );
endmodule

// XCounter takes current X position & direction,
// and then offset +1/-1 depending on the direction.
module XCounter(
  input clk,
  input en,
  input [7:0] x, // X position
  input offset, // 0 = -1; 1 = 1

  output reg [7:0] x_out
  );

  always @(posedge clk) begin
    if (en) begin
      if (offset) begin
        x_out <= x + 1;
      end else begin
        x_out <= x - 1;
      end
    end else begin
      x_out <= x;
    end
  end
endmodule

// YCounter takes current Y position & direction,
// and then offset +1/-1 depending on the direction.
module YCounter(
  input clk,
  input en,
  input [6:0] y, // y position
  input offset, // 0 = -1; 1 = 1

  output reg [6:0] y_out
  );

  always @(posedge clk) begin
    if (en) begin
      if (offset) begin
        y_out <= y + 1;
      end else begin
        y_out <= y - 1;
      end
    end else begin
      y_out <= y;
    end
  end
endmodule

// generate 60 Hz from 50 MHz
module DelayCounter(clk_50mhz,rst,en,clk_15hz_out);
  input clk_50mhz,rst,en;
  output reg clk_15hz_out = 0;
  
  reg clk_60hz; // This is approximating the 60fps rate
  reg [3:0] cnt_reg_15hz = 0; // Range 0-15
  reg [18:0] cnt_reg_60hz = 0; // Range 0-524288
  always @(posedge clk_50mhz) begin
    if (rst) begin
      cnt_reg_60hz <= 0;
      clk_60hz <= 0;
      
      cnt_reg_15hz <= 0;
      clk_15hz_out <= 0;
    end else begin
      if (cnt_reg_60hz < 416666) begin
	cnt_reg_60hz <= cnt_reg_60hz + 1;
      end else begin
        cnt_reg_60hz <= 0;
        clk_60hz <= (en) ? ~clk_60hz : 0;
      end
    end
  end
  // generate 1 pulse for every 15 pulses
  always @(posedge clk_60hz) begin
    if (en) begin
      if (cnt_reg_15hz == 7) begin
	cnt_reg_15hz <= 0;
	clk_15hz_out <= ~clk_15hz_out;
      end else begin
	cnt_reg_15hz <= cnt_reg_15hz + 1;
      end
    end
  end
endmodule
