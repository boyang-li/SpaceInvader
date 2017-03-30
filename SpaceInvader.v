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

  wire resetn;
  assign resetn = KEY[0];

  wire go;
  assign go = SW[0];

  wire bullet_flying,plot_player_done,plot_aliens_done,plot_bullet_done,next_move,clear_done,update_xy_done;
  wire in_game,rst_xy,plot_player_en,plot_bullet_en,rst_delay_en,clear_en,update_xy_en;
  
  wire plot_alien1_en, plot_alien2_en, plot_alien3_en;

  wire [4:0] current_state,next_state;

  control c0(
    .clk(CLOCK_50),
    .resetn(resetn),
    .go(go),

    // Datapath signals
    .bullet_flying(bullet_flying),
    .plot_player_done(plot_player_done),
    .plot_aliens_done(plot_aliens_done),
    .plot_bullet_done(plot_bullet_done),
    .next_move(next_move),
    .clear_done(clear_done),
    .update_xy_done(update_xy_done),

    // Outputs to datapath
    .in_game(in_game),
    .rst_xy(rst_xy),
    .plot_player_en(plot_player_en),
      .plot_alien1_en(plot_alien1_en),
		.plot_alien2_en(plot_alien2_en),
		.plot_alien3_en(plot_alien3_en),
      .plot_bullet_en(plot_bullet_en),
      .rst_delay_en(rst_delay_en),
      .clear_en(clear_en),
      .update_xy_en(update_xy_en),

    // for test
    .current_state(current_state),
    .next_state(next_state)
    );

  datapath dp0(
    // Top level inputs
    .clk(CLOCK_50),
    .resetn(resetn),
    .btn_left(KEY[3]),
    .btn_right(KEY[2]),
    .btn_fire(~KEY[1]),
    //input [2:0] colour_in,

    // Control signals
    .in_game(in_game),
      .rst_xy(rst_xy),
      .plot_player_en(plot_player_en),
      .plot_alien1_en(plot_alien1_en),
		.plot_alien2_en(plot_alien2_en),
		.plot_alien3_en(plot_alien3_en),
      .plot_bullet_en(plot_bullet_en),
      .rst_delay_en(rst_delay_en),
      .clear_en(clear_en),
      .update_xy_en(update_xy_en),

    // Outputs to countrol
      .bullet_flying(bullet_flying),
      .plot_player_done(plot_player_done),
      .plot_aliens_done(plot_aliens_done),
      .plot_bullet_done(plot_bullet_done),
      .next_move(next_move),
      .clear_done(clear_done),
      .update_xy_done(update_xy_done),

    // Outputs to VGA
      .x_out(x),
      .y_out(y),
      .colour_out(colour),
      .wren(writeEn)
  );

endmodule

// FSM
module control(
  // Top level inputs
  input clk,resetn,go,

  // Datapath signals
  input bullet_flying,
  input plot_player_done,
  input plot_aliens_done,
  input plot_bullet_done,
  input next_move,
  input clear_done,
  input update_xy_done,

  // Outputs to datapath
  output reg in_game,
  output reg rst_xy,
  output reg plot_player_en,
  output reg plot_alien1_en,
  output reg plot_alien2_en,
  output reg plot_alien3_en,
  output reg plot_bullet_en,
  output reg check_bullet_en,
  output reg rst_delay_en,
  output reg clear_en,
  output reg update_xy_en,

  // for test
  output reg [4:0] current_state,next_state
  );

  //reg [2:0] current_state, next_state;

  localparam  S_IDLE         = 5'd0,
              S_RST_ALL      = 5'd1,
              S_CYCLE_BEGIN  = 5'd2,
              S_PLOT_PLAYER  = 5'd3,
              S_PLOT_ALIEN1  = 5'd4,
				  S_PLOT_ALIEN2  = 5'd5,
				  S_PLOT_ALIEN3  = 5'd6,
				  //add more aliens below if needed
				  
              S_CHECK_SHOT   = 5'd7,
              S_PLOT_BULLET  = 5'd8,
              S_RST_DELAY    = 5'd9,
              S_WAIT_PLOT    = 5'd10,
              S_CLEAR_SCREEN = 5'd11,
              S_UPDATE_XY    = 5'd12;

  // Next state logic aka our state table
  always @(posedge clk)
  begin: state_table
    case (current_state)
      S_IDLE:         next_state <= (go) ? S_RST_ALL : S_IDLE;
      S_RST_ALL:      next_state <= S_CYCLE_BEGIN;
      S_CYCLE_BEGIN:  next_state <= S_PLOT_PLAYER;
      S_PLOT_PLAYER:  next_state <= (plot_player_done) ? S_PLOT_ALIEN1 : S_PLOT_PLAYER;
      S_PLOT_ALIEN1:  next_state <= (plot_aliens_done) ? S_PLOT_ALIEN2 : S_PLOT_ALIEN1;
		S_PLOT_ALIEN2:  next_state <= (plot_aliens_done) ? S_PLOT_ALIEN3 : S_PLOT_ALIEN2;
		S_PLOT_ALIEN3:  next_state <= (plot_aliens_done) ? S_CHECK_SHOT : S_PLOT_ALIEN3;
      S_CHECK_SHOT:   next_state <= (bullet_flying) ? S_PLOT_BULLET : S_RST_DELAY;
      S_PLOT_BULLET:  next_state <= (plot_bullet_done) ? S_RST_DELAY : S_PLOT_BULLET;
      S_RST_DELAY:    next_state <= S_WAIT_PLOT;
      S_WAIT_PLOT:    next_state <= (next_move) ? S_CLEAR_SCREEN : S_WAIT_PLOT;
      S_CLEAR_SCREEN: next_state <= (clear_done) ? S_UPDATE_XY : S_CLEAR_SCREEN;
      S_UPDATE_XY:    next_state <= S_CYCLE_BEGIN;
      default: next_state <= S_IDLE;
    endcase
  end // state_table

  // current_state registers
  always @(posedge clk)
  begin: set_states
    if (!resetn)
      current_state <= S_IDLE;
    else
      current_state <= next_state;
  end

  // Output logic aka all of our datapath control signals
  always @(posedge clk)
  begin: enable_signals
    // By defaults...
    rst_xy         <= 1'b0;
    plot_player_en <= 1'b0;
    plot_alien1_en <= 1'b0;
	 plot_alien2_en <= 1'b0;
	 plot_alien3_en <= 1'b0;
    plot_bullet_en <= 1'b0;
    rst_delay_en   <= 1'b0;
    clear_en       <= 1'b0;
    update_xy_en   <= 1'b0;

    case (current_state)
      S_IDLE: begin
        in_game <= 1'b0;
      end
      S_RST_ALL: begin
        in_game <= 1'b1;
        rst_delay_en <= 1'b1;
        rst_xy <= 1'b1;
        //clear_en <= 1'b1;
      end
      S_PLOT_PLAYER: begin
        plot_player_en <= 1'b1;
      end
      S_PLOT_ALIEN1: begin
        plot_alien1_en <= 1'b1;
      end
		S_PLOT_ALIEN2: begin
        plot_alien2_en <= 1'b1;
      end
		S_PLOT_ALIEN3: begin
        plot_alien3_en <= 1'b1;
      end
		
		S_CHECK_SHOT: begin
        check_bullet_en <= 1'b1;
      end
		
      S_PLOT_BULLET: begin
        plot_bullet_en <= 1'b1;
      end
      S_RST_DELAY: begin
        rst_delay_en <= 1'b1;
      end
      S_CLEAR_SCREEN: begin
        clear_en <= 1'b1;
      end
      S_UPDATE_XY: begin
        update_xy_en <= 1'b1;
      end
      // default: // dold_resetn't need default since we already made sure all
      // of our outputs were assigned a value at the start of the always block
    endcase
  end // enable_signals
endmodule

// Datapath
module datapath(
    // Top level inputs
    input clk,resetn,btn_left,btn_right,btn_fire,
    //input [2:0] colour_in,

    // Control signals
    input in_game,
    input rst_xy,
    input plot_player_en,
    input plot_alien1_en,
	 input plot_alien2_en,
	 input plot_alien3_en,
    input plot_bullet_en,
	 input check_bullet_en,
    input rst_delay_en,
    input clear_en,
    input update_xy_en,

    // Outputs to countrol
    output reg bullet_flying,
    output reg plot_player_done,
    output reg plot_aliens_done,
    output reg plot_bullet_done,
    output reg next_move,
    output reg clear_done,
    output reg update_xy_done,

    // Outputs to VGA
    output reg [7:0] x_out,
    output reg [6:0] y_out,
    output reg [2:0] colour_out,
    output reg wren

    );

    //     wire [7:0] next_x;
    //     wire [6:0] next_y;
    wire frame_cnt_out,pixrate_4_out,pixrate_6_out,pixrate_10_out;
    reg on_next_move = 0;

    // 0 = player, 1 =
    reg [3:0] current_object;

    wire [7:0] player_x;
    wire [6:0] player_y;
	 reg [7:0] cur_player_x; 
	 
	 
	 wire [7:0] l_alien_col1, l_alien_col2, l_alien_col3; 
	 wire [7:0] r_alien_col1, r_alien_col2, r_alien_col3; 
	 
	 //Alien 1 path
	 assign l_alien_col1 = 8'd50;
	 assign r_alien_col1 = 8'd69;
	 
	 //Alien 2 path
	 assign l_alien_col2 = 8'd70;
	 assign r_alien_col2 = 8'd89;
	 
	 //ALien 3 path
	 assign l_alien_col3 = 8'd90;
	 assign r_alien_col3 = 8'd109;

    wire [7:0] alien1_x;
    wire [6:0] alien1_y;

    wire [7:0] alien2_x;
    wire [6:0] alien2_y;

    wire [7:0] alien3_x;
    wire [6:0] alien3_y;

    wire [7:0] bullet_x;
    wire [6:0] bullet_y;
	 wire bullet_flying_Wire;
	 //wire [2:0] bullet_colour;

    reg clear_cnt_en;
    reg [7:0] clear_x;
    reg [6:0] clear_y;

    wire plot_player_finish;
	 wire plot_alien1_finish;
	 wire plot_alien2_finish; 
	 wire plot_alien3_finish;

	 
    player Player(
      .clk(clk),
      .resetn(resetn),
      .update_xy_en(pixrate_6_out && update_xy_en),
      .btn_left(btn_left),
      .btn_right(btn_right),
      .x(player_x),
      .y(player_y),
      .plot_finish(plot_player_finish)
      );
		
	 alien Alien1(
		.clk(clk),
      .resetn(resetn),
      .update_xy_en(pixrate_4_out && update_xy_en),
		.l_border(l_alien_col1),
		.r_border(r_alien_col1),
      .x(alien1_x),
      .y(alien1_y),
      .plot_finish(plot_alien1_finish)
		
	 );
	 
	 alien Alien2(
		.clk(clk),
      .resetn(resetn),
      .update_xy_en(pixrate_4_out && update_xy_en),
		.l_border(l_alien_col2),
		.r_border(r_alien_col2),
      .x(alien2_x),
      .y(alien2_y),
      .plot_finish(plot_alien2_finish)
		
	 );
	 
	 alien Alien3(
		.clk(clk),
      .resetn(resetn),
      .update_xy_en(pixrate_4_out && update_xy_en),
		.l_border(l_alien_col3),
		.r_border(r_alien_col3),
      .x(alien3_x),
      .y(alien3_y),
      .plot_finish(plot_alien3_finish)
		
	 );
  
  bullet PlayerBullet(
		.clk(clk),
      .resetn(resetn),
		.playerXPos(cur_player_x),
      .update_xy_en(pixrate_10_out && update_xy_en),
		.btn_fire(btn_fire),
      .x(bullet_x),
      .y(bullet_y),
		.bullet_flying(bullet_flying_Wire),
      .plot_finish(plot_Pbullet_finish)
		//.colour(bullet_colour)
		
  );
	 	 

    DelayCounter dc0(
      .clk_50mhz(clk),
      .rst(rst_delay_en),
      .en(in_game),
      .clk_60hz_out(frame_cnt_out),
      .pixrate_4_out(pixrate_4_out),
      .pixrate_6_out(pixrate_6_out),
      .pixrate_10_out(pixrate_10_out)
    );


    // Main game
    always @(posedge clk) begin
      // By defaults...
      next_move <= 0;
		bullet_flying <= bullet_flying_Wire;

      if (!resetn) begin
      // Outputs to VGA
        x_out <= 0;
        y_out <= 0;
        colour_out <= 3'b000;
        wren <= 0;

        // Outputs to control
        //shot_fired <= 0;
        plot_player_done <= 0;
        plot_aliens_done <= 0;
        plot_bullet_done <= 0;
        next_move <= 0;
        clear_done <= 0;
        update_xy_done <= 0;

        // local params
        current_object <= 0;
        on_next_move <= 0;
        clear_x <= 0;
        clear_y <= 0;

      end // End if (!resetn)
      else if (in_game) begin
      if (rst_xy) begin
        //
      end

      if (plot_player_en) begin
        x_out <= player_x;
        y_out <= player_y;
	cur_player_x <= player_x;
        colour_out <= 3'b010; // Green
        wren <= 1'b1;
        plot_player_done <= plot_player_finish;    
      end else if (plot_alien1_en) begin
		  x_out <= alien1_x;
        y_out <= alien1_y;
        colour_out <= 3'b100; // Red
        wren <= 1'b1;
		  plot_aliens_done <= plot_alien1_finish;
		  
		end else if (plot_alien2_en) begin
        x_out <= alien2_x;
        y_out <= alien2_y;
		  colour_out <= 3'b100; // Red
        wren <= 1'b1;
		  plot_aliens_done <= plot_alien2_finish;
		  
		end else if (plot_alien3_en) begin
		  x_out <= alien3_x;
        y_out <= alien3_y;
		  colour_out <= 3'b100; // Red
        wren <= 1'b1;
		  plot_aliens_done <= plot_alien3_finish;
      end else if (plot_bullet_en) begin
		  x_out <= bullet_x;
        y_out <= bullet_y;
		  colour_out <= 3'b111;
        wren <= 1'b1;
		  
        plot_bullet_done <= plot_Pbullet_finish;
      end

      // S_WAIT_PLOT
      if (delay_cnt_out && !on_next_move) begin
        on_next_move <= 1'b1;
        next_move <= 1'b1;
      end else if (!delay_cnt_out) begin
        on_next_move <= 0;
      end

      // S_CLEAR_SCREEN
      if (clear_en) begin
		  clear_done <= 0;
		  x_out <= clear_x;
        y_out <= clear_y;
        colour_out <= 3'b000;
		  wren <= 1'b1;
        clear_cnt_en <= 1'b1;
        

        if (clear_x < 159) begin
         clear_x <= clear_x + 1;
        end else if (clear_x == 159 && clear_y < 119) begin
         clear_y <= clear_y + 1;
         clear_x <= 0;
        end else if (clear_x == 159 && clear_y == 119) begin
         clear_done <= 1'b1;
         clear_x <= 0;
         clear_y <= 0;
        end

      end
      end // End if (in_game)
    end // always
endmodule


module alien(
  // Inputs
  input clk,resetn,update_xy_en,
  input [7:0] l_border, r_border,
  //Outputs
  output reg [7:0] x,
  output reg [6:0] y,
  output reg plot_finish
  );

  reg [1:0] x_offset;

  always @(posedge clk) begin
    plot_finish <= 0;

    if (!resetn) begin
      // starting position of player
      x_offset <= 2'b01;
      x <= l_border;
      y <= 7'd15;
      plot_finish <= 0;
    end
    else begin
      if ((x == r_border) && (x_offset == 2'b01)) begin // left btn pressed
        x_offset <= 2'b11; // offset = -1
		  y <= y + 1; // move the alien down
      end else if ((x == l_border) && (x_offset == 2'b11)) begin // right btn pressed
        x_offset <= 2'b01; // offset = 1
		  y <= y + 1; //move alien down
      end else begin
        x_offset <= x_offset;
      end

      if (update_xy_en) begin
        if (x_offset == 2'b01)
          x <= x + 1;
        else if (x_offset == 2'b11)
          x <= x - 1;
      end

      // TODO
      plot_finish <= 1'b1;
    end

  end
endmodule

module player(
  // Inputs
  input clk,resetn,update_xy_en,
  input btn_left,btn_right,
  //Outputs
  output reg [7:0] x,
  output reg [6:0] y,
  output reg plot_finish
  );

  reg [1:0] x_offset;

  always @(posedge clk) begin
    plot_finish <= 0;

    if (!resetn) begin
      // starting position of player
      x_offset <= 0;
      x <= 8'd68;
      y <= 7'd111;
      plot_finish <= 0;
    end
    else begin
      if (btn_left && !btn_right && (x != 0)) begin // left btn pressed
        x_offset <= 2'b11; // offset = -1
      end else if (btn_right && !btn_left && (x != 159)) begin // right btn pressed
        x_offset <= 2'b01; // offset = 1
      end else begin
        x_offset <= 0;
      end

      if (update_xy_en) begin
        if (x_offset == 2'b01)
          x <= x + 1;
        else if (x_offset == 2'b11)
          x <= x - 1;
      end

      // TODO
      plot_finish <= 1'b1;
    end

  end
endmodule

module bullet(
  // Inputs
  input clk,resetn,update_xy_en,
  input btn_fire,
  //Outputs
  input [7:0] playerXPos,
  output reg [7:0] x,
  output reg [6:0] y,
  output reg plot_finish,
  output reg bullet_flying
  //output [2:0] colour
  );

  reg [1:0] y_offset;

  always @(posedge clk) begin
    plot_finish <= 0;
    if (!resetn) begin
      // starting position of player
      y_offset <= 0;
      x <= 8'd68;
      y <= 7'd111;
      plot_finish <= 0;
		bullet_flying <= 1'b0;
		//colour <= 3'b000;
    end
    else begin
		if (!bullet_flying && btn_fire) begin
			bullet_flying <= 1'b1;
			y_offset <= 2'b11;
			x <= playerXPos;
			//colour <= 3'b111;
		end
		
      if ((y == 0)) begin // left btn pressed
        y_offset <= 0; // offset = -1
		  //colour <= 3'b000;
		  y <= 7'd111;
		  bullet_flying <= 0;
		end
      if (update_xy_en && bullet_flying) begin
        if (y_offset == 2'b11)
          y <= y - 1;
		  if (y_offset == 0)
          y <= y;
      end

      // TODO
      plot_finish <= 1'b1;
    end

  end
endmodule



// generate 60 Hz from 50 MHz
module DelayCounter(clk_50mhz,rst,en,clk_60hz_out,pixrate_4_out,pixrate_6_out,pixrate_10_out);
  input clk_50mhz,rst,en;
  output reg clk_60hz_out; // This is approximating the 60hz rate
  output reg pixrate_4_out = 0; // This is the 4 pixels persec rate
  output reg pixrate_6_out = 0; // This is the 6 pixels persec rate
  output reg pixrate_10_out = 0; // This is the 10 pixels persec rate

  reg [18:0] cnt_reg_60hz = 0; // Range 0-524288
  reg [2:0] cnt_pixrate_4,cnt_pixrate_6,cnt_pixrate_10; // Range 0-7

  always @(posedge clk_50mhz or posedge rst) begin
   if (rst) begin
    cnt_reg_60hz <= 0;
      clk_60hz_out <= 0;
   end
    else if (en) begin
      if (cnt_reg_60hz < 416666) begin
      cnt_reg_60hz <= cnt_reg_60hz + 1;
      end else begin
        cnt_reg_60hz <= 0;
        clk_60hz_out <= (en) ? ~clk_60hz_out : 0;
      end
    end
  end

  // generate 1 pulse for every 15/10/6 frames
  always @(posedge clk_60hz_out or posedge rst) begin
   if (rst) begin
      cnt_pixrate_4 <= 0;
      pixrate_4_out <= 0;

      cnt_pixrate_6 <= 0;
      pixrate_6_out <= 0;
      
      cnt_pixrate_10 <= 0;
      pixrate_10_out <= 0;
   end
   else if (en) begin
      if (cnt_pixrate_4 == 3'd7) begin
	cnt_pixrate_4 <= 0;
	pixrate_4_out <= ~pixrate_4_out;
      end else begin
	cnt_pixrate_4 <= cnt_pixrate_4 + 1;
      end
      
      if (cnt_pixrate_6 == 3'd5) begin
	cnt_pixrate_6 <= 0;
	pixrate_6_out <= ~pixrate_6_out;
      end else begin
	cnt_pixrate_6 <= cnt_pixrate_6 + 1;
      end
      
      if (cnt_pixrate_10 == 3'd3) begin
	cnt_pixrate_10 <= 0;
	pixrate_10_out <= ~pixrate_10_out;
      end else begin
	cnt_pixrate_10 <= cnt_pixrate_10 + 1;
      end
    end
  end
endmodule
