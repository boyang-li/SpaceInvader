// This is the top layer of the game
// FPGA device: Cyclone5 series
module SpaceInvader(
  CLOCK_50,           //  On Board 50 MHz
  // Your inputs and outputs here
   KEY,
   SW,
  //  7-SEG Displays
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
  //  PS2 data and clock lines		
  	PS2_DAT,
   PS2_CLK,
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
  input	PS2_DAT;
  input	PS2_CLK;
  output  [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

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
  
  // IO stuff
  wire resetn;
  assign resetn = KEY[0];

  wire go;
  assign go = SW[0];
  
  // Game logic
  wire bullet_flying, a1bullet_flying,plot_player_done,plot_aliens_done,plot_bullet_done, plot_a1bullet_done,next_move,clear_done,update_xy_done;
  wire check_p_hit_en,check_a_hit_en;
  wire [3:0] player_lives;
  wire player_hit,aliens_eliminated;
  wire in_game,rst_xy,plot_player_en,plot_bullet_en, plot_a1bullet_en,rst_delay_en,clear_en,update_xy_en;
  
  wire plot_alien1_en, plot_alien2_en, plot_alien3_en;

  wire [4:0] current_state,next_state;

  control c0(
    .clk(CLOCK_50),
    .resetn(resetn),
    .go(go),

    // Datapath signals
    .bullet_flying(bullet_flying),
	 .a1bullet_flying(a1bullet_flying),
    .player_hit(player_hit),
    .player_lives(player_lives),
    .aliens_eliminated(aliens_eliminated),
    .plot_player_done(plot_player_done),
    .plot_aliens_done(plot_aliens_done),
    .plot_bullet_done(plot_bullet_done),
    .plot_a1bullet_done(plot_a1bullet_done),
    .next_move(next_move),
    .clear_done(clear_done),
    .update_xy_done(update_xy_done),

    // Outputs to datapath
    .in_game(in_game),
    .rst_xy(rst_xy),
    .check_p_hit_en(check_p_hit_en),
    .check_a_hit_en(check_a_hit_en),
    .plot_player_en(plot_player_en),
    .plot_alien1_en(plot_alien1_en),
    .plot_alien2_en(plot_alien2_en),
    .plot_alien3_en(plot_alien3_en),
    .plot_bullet_en(plot_bullet_en),
    .plot_a1bullet_en(plot_a1bullet_en),
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
    .check_p_hit_en(check_p_hit_en),
    .check_a_hit_en(check_a_hit_en),
    .plot_player_en(plot_player_en),
    .plot_alien1_en(plot_alien1_en),
    .plot_alien2_en(plot_alien2_en),
    .plot_alien3_en(plot_alien3_en),
    .plot_bullet_en(plot_bullet_en),
    .plot_a1bullet_en(plot_a1bullet_en),
    .rst_delay_en(rst_delay_en),
    .clear_en(clear_en),
    .update_xy_en(update_xy_en),

    // Outputs to countrol
    .bullet_flying(bullet_flying),
	 .a1bullet_flying(a1bullet_flying),
    .player_hit(player_hit),
    .player_lives(player_lives),
    .aliens_eliminated(aliens_eliminated),
    .plot_player_done(plot_player_done),
    .plot_aliens_done(plot_aliens_done),
    .plot_bullet_done(plot_bullet_done),
    .plot_a1bullet_done(plot_a1bullet_done),
    .next_move(next_move),
    .clear_done(clear_done),
    .update_xy_done(update_xy_done),

    // Outputs to VGA
    .x_out(x),
    .y_out(y),
    .colour_out(colour),
    .wren(writeEn)
  );
  
  // score and player lives
  hex_7seg dsp6(player_lives[3:0],HEX6); // player lives
  hex_7seg dsp7(history[4][7:4],HEX7);
  
  
  
  // Keyboard Begin----------------------------------------
  wire [7:0] scan_code;
  reg [7:0] history[1:4];
  wire read, scan_ready;
  
  oneshot pulser(
    .pulse_out(read),
    .trigger_in(scan_ready),
    .clk(CLOCK_50)
  );
  
//  keyboard 
//(
//    .keyboard_clk(PS2_CLK),
//    .keyboard_data(PS2_DAT),
//    .clock50(CLOCK_50),
//    .resetn(resetn),
//    .read(read),
//    .scan_ready(scan_ready),
//    .scan_code(scan_code)
//  );
  
  // Output keyboard inputs to hex displays
  hex_7seg dsp0(history[1][3:0],HEX0);
  hex_7seg dsp1(history[1][7:4],HEX1);

  hex_7seg dsp2(history[2][3:0],HEX2);
  hex_7seg dsp3(history[2][7:4],HEX3);

  hex_7seg dsp4(history[3][3:0],HEX4);
  hex_7seg dsp5(history[3][7:4],HEX5);

  //hex_7seg dsp6(history[4][3:0],HEX6);
  //hex_7seg dsp7(history[4][7:4],HEX7);
  
  always @(posedge scan_ready)
  begin
    history[4] <= history[3];
    history[3] <= history[2];
    history[2] <= history[1];
    history[1] <= scan_code;
  end
  
  keyboard kbd(
    .keyboard_clk(PS2_CLK),
    .keyboard_data(PS2_DAT),
    .clock50(CLOCK_50),
    .resetn(reset),
    .read(read),
    .scan_ready(scan_ready),
    .scan_code(scan_code)
  );
  // Keyboard End----------------------------------------
  
endmodule

// FSM
module control(
  // Top level inputs
  input clk,resetn,go,

  // Datapath signals
  input bullet_flying,
  input a1bullet_flying,
  input player_hit,
  input [1:0] player_lives,
  input aliens_eliminated,
  input plot_player_done,
  input plot_aliens_done,
  input plot_bullet_done,
  input plot_a1bullet_done,
  input next_move,
  input clear_done,
  input update_xy_done,

  // Outputs to datapath
  output reg in_game,
  output reg rst_xy,
  output reg check_p_hit_en,
  output reg check_a_hit_en,
  output reg plot_player_en,
  output reg plot_alien1_en,
  output reg plot_alien2_en,
  output reg plot_alien3_en,
  output reg plot_bullet_en,
  output reg plot_a1bullet_en,
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
	      S_CHECK_P_HIT  = 5'd3,
	      S_CHECK_A_HIT  = 5'd4,
              S_PLOT_PLAYER  = 5'd5,
              S_PLOT_ALIEN1  = 5'd6,
	      S_PLOT_ALIEN2  = 5'd7,
	      S_PLOT_ALIEN3  = 5'd8,
	      //add more aliens below if needed
              S_CHECK_SHOT   = 5'd9,
              S_PLOT_BULLET  = 5'd10,
	      S_PLOT_A1BULLET= 5'd11,
              S_RST_DELAY    = 5'd12,
              S_WAIT_PLOT    = 5'd13,
              S_CLEAR_SCREEN = 5'd14,
              S_UPDATE_XY    = 5'd15,
	      S_CHECK_LIVES  = 5'd16,
			S_CHECK_a1SHOT = 5'd17;
          

  // Next state logic aka our state table
  always @(posedge clk)
  begin: state_table
    case (current_state)
      S_IDLE:         next_state <= (go) ? S_RST_ALL : S_IDLE;
      S_RST_ALL:      next_state <= S_CYCLE_BEGIN;
      S_CYCLE_BEGIN:  next_state <= S_CHECK_P_HIT;
      S_CHECK_P_HIT:  next_state <= (player_hit) ? S_CHECK_LIVES : S_CHECK_A_HIT;
      S_CHECK_LIVES:  next_state <= (player_lives > 0) ? S_CHECK_A_HIT : S_IDLE;
      S_CHECK_A_HIT:  next_state <= (aliens_eliminated) ? S_IDLE : S_PLOT_PLAYER;
      S_PLOT_PLAYER:  next_state <= (plot_player_done) ? S_PLOT_ALIEN1 : S_PLOT_PLAYER;
      S_PLOT_ALIEN1:  next_state <= (plot_aliens_done) ? S_PLOT_ALIEN2 : S_PLOT_ALIEN1;
      S_PLOT_ALIEN2:  next_state <= (plot_aliens_done) ? S_PLOT_ALIEN3 : S_PLOT_ALIEN2;
      S_PLOT_ALIEN3:  next_state <= (plot_aliens_done) ? S_CHECK_SHOT : S_PLOT_ALIEN3;
		
      S_CHECK_SHOT:   next_state <= (bullet_flying) ? S_PLOT_BULLET : S_CHECK_a1SHOT;
      S_PLOT_BULLET:  next_state <= (plot_bullet_done) ? S_PLOT_A1BULLET : S_PLOT_BULLET;
		
		S_CHECK_a1SHOT: next_state <= (a1bullet_flying) ? S_PLOT_A1BULLET : S_RST_DELAY;
      S_PLOT_A1BULLET:next_state <= (plot_a1bullet_done) ? S_RST_DELAY : S_PLOT_A1BULLET;
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
    check_p_hit_en <= 1'b0;
    check_a_hit_en <= 1'b0;
    plot_player_en <= 1'b0;
    plot_alien1_en <= 1'b0;
    plot_alien2_en <= 1'b0;
    plot_alien3_en <= 1'b0;
    plot_bullet_en <= 1'b0;
    plot_a1bullet_en <= 1'b0;
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
		S_CHECK_P_HIT: begin
		  check_p_hit_en <= 1'b1;
		end
		S_CHECK_A_HIT: begin
		  check_a_hit_en <= 1'b1;
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
		S_PLOT_A1BULLET: begin
        plot_a1bullet_en <= 1'b1;
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
	 input check_p_hit_en,
	 input check_a_hit_en,
    input plot_player_en,
    input plot_alien1_en,
	 input plot_alien2_en,
	 input plot_alien3_en,
    input plot_bullet_en,
	 input plot_a1bullet_en,
	 input check_bullet_en,
    input rst_delay_en,
    input clear_en,
    input update_xy_en,

    // Outputs to countrol
    output reg bullet_flying,
	 output reg a1bullet_flying,
	 output reg player_hit,
	 output reg [3:0] player_lives,
	 output reg aliens_eliminated,
    output reg plot_player_done,
    output reg plot_aliens_done,
    output reg plot_bullet_done,
	 output reg plot_a1bullet_done,
    output reg next_move,
    output reg clear_done,
    output reg update_xy_done,
    
    // player score
    output reg [3:0] player_score,
    
    // Outputs to VGA
    output reg [7:0] x_out,
    output reg [6:0] y_out,
    output reg [2:0] colour_out,
    output reg wren

    );

    //     wire [7:0] next_x;
    //     wire [6:0] next_y;
    wire frame_cnt_out,delay_cnt_out;
    reg on_next_move = 0;

    // 0 = player, 1 =
    reg [3:0] current_object;

    wire [7:0] player_x;
    wire [6:0] player_y;
	 reg [7:0] cur_player_x; 
	 
	 
	 wire [7:0] l_alien_col1, l_alien_col2, l_alien_col3; 
	 wire [7:0] r_alien_col1, r_alien_col2, r_alien_col3; 
	 reg alien1_hit, alien2_hit, alien3_hit;
	 
	 wire a1_fire_ready;
	 reg [7:0] cur_alien1_x;
	 reg [6:0] cur_alien1_y;
	 
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
	 wire [7:0] a1bullet_x;
    wire [6:0] a1bullet_y;
	 wire a1bullet_flying_wire;

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
	 wire a1_bullet_offset_done;

	 
    player Player(
      .clk(clk),
      .resetn(resetn),
      .update_xy_en(update_xy_en),
      .btn_left(btn_left),
      .btn_right(btn_right),
      .x(player_x),
      .y(player_y),
      .plot_finish(plot_player_finish)
      );
		
	 alien Alien1(
		.clk(clk),
      .resetn(resetn),
      .update_xy_en(update_xy_en),
		.l_border(l_alien_col1),
		.r_border(r_alien_col1),
      .x(alien1_x),
      .y(alien1_y),
      .plot_finish(plot_alien1_finish)
		
	 );
	 
	 alien Alien2(
		.clk(clk),
      .resetn(resetn),
      .update_xy_en(update_xy_en),
		.l_border(l_alien_col2),
		.r_border(r_alien_col2),
      .x(alien2_x),
      .y(alien2_y),
      .plot_finish(plot_alien2_finish)
		
	 );
	 
	 alien Alien3(
		.clk(clk),
      .resetn(resetn),
      .update_xy_en(update_xy_en),
		.l_border(l_alien_col3),
		.r_border(r_alien_col3),
      .x(alien3_x),
      .y(alien3_y),
      .plot_finish(plot_alien3_finish)
		
	 );
  
  bullet PlayerBullet(
		.clk(clk),
      .resetn(resetn),
		.offset(2'b11),
		.playerXPos(cur_player_x),
		.playerYPos(7'd111),
      .update_xy_en(update_xy_en),
		.btn_fire(btn_fire),
      .x(bullet_x),
      .y(bullet_y),
		.bullet_flying(bullet_flying_Wire),
      .plot_finish(plot_Pbullet_finish)
		//.colour(bullet_colour)
		
  );
	 
	
	 bullet Alien1Bullet(
      .clk(clk),
      .resetn(resetn),
		.offset(2'b01),
      .playerXPos(cur_alien1_x),
		.playerYPos(cur_alien1_y),
      .update_xy_en(update_xy_en),
      .btn_fire(a1_fire_ready),
      .x(a1bullet_x),
      .y(a1bullet_y),
      .bullet_flying(a1bullet_flying_Wire),
      .plot_finish(a1_bullet_offset_done)
      );
	
	 onehertzdelay oh0 (
		.clk(clk),
      .resetn(resetn),
		.clkout(a1_fire_ready),
	 );

    DelayCounter dc0(
      .clk_50mhz(clk),
      .rst(rst_delay_en),
      .en(in_game),
      .clk_60hz_out(frame_cnt_out),
      .clk_15hz_out(delay_cnt_out)
    );


    // Main game
    always @(posedge clk) begin
      // By defaults...
      next_move <= 0;
		bullet_flying <= bullet_flying_Wire;
		a1bullet_flying <= a1bullet_flying_Wire;
		

      if (!resetn) begin
      // Outputs to VGA
        x_out <= 0;
        y_out <= 0;
        colour_out <= 3'b000;
        wren <= 0;

        // Outputs to control
	player_hit <= 0;
	player_lives <= 4'd3;
	aliens_eliminated <= 0;
        plot_player_done <= 0;
        plot_aliens_done <= 0;
        plot_bullet_done <= 0;
		  plot_a1bullet_done <= 0;
        next_move <= 0;
        clear_done <= 0;
        update_xy_done <= 0;

        // local params
        current_object <= 0;
        on_next_move <= 0;
        clear_x <= 0;
        clear_y <= 0;
		  alien1_hit <= 0;
		  alien2_hit <= 0;
		  alien3_hit <= 0;
		  player_score<= 0;

      end // End if (!resetn)
      else if (in_game) begin
      if (rst_xy) begin
        //
      end
		if (check_p_hit_en) begin
			if (a1bullet_x == player_x && a1bullet_y == player_y) begin
				player_hit <= 1'b1;
				player_lives <= player_lives - 4'd1;
			end	
		end
		if (check_a_hit_en) begin
			if (bullet_x == alien1_x && bullet_y == alien1_y) begin
				alien1_hit <= 1'b1;
				player_score <= player_score + 4'd3;
			end
			else if (bullet_x == alien2_x && bullet_y == alien2_y) begin
				alien2_hit <= 1'b1;
				player_score <= player_score + 4'd1;
			end
			else if (bullet_x == alien3_x && bullet_y == alien3_y) begin
				alien3_hit <= 1'b1;
				player_score <= player_score + 4'd1;
			end
			
			if (alien1_hit && alien2_hit && alien3_hit) begin
				aliens_eliminated <= 1'b1;
			end
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
		  cur_alien1_x <= alien1_x;
		  cur_alien1_y <= alien1_y;
		  if (alien1_hit) begin
		    colour_out <= 0; // Invisible
		  end else begin
			 colour_out <= 3'b100; // Red
		  end
        wren <= 1'b1;
		  plot_aliens_done <= plot_alien1_finish;
		  
		end else if (plot_alien2_en) begin
        x_out <= alien2_x;
        y_out <= alien2_y;
		  if (alien2_hit) begin
		    colour_out <= 0; // Invisible
		  end else begin
			 colour_out <= 3'b100; // Red
		  end
        wren <= 1'b1;
		  plot_aliens_done <= plot_alien2_finish;
		  
		end else if (plot_alien3_en) begin
		  x_out <= alien3_x;
        y_out <= alien3_y;
		  if (alien3_hit) begin
		    colour_out <= 0; // Invisible
		  end else begin
			 colour_out <= 3'b100; // Red
		  end
        wren <= 1'b1;
		  plot_aliens_done <= plot_alien3_finish;
      end else if (plot_bullet_en) begin
		  x_out <= bullet_x;
        y_out <= bullet_y;
		  colour_out <= 3'b111;
        wren <= 1'b1;
		  
        plot_bullet_done <= plot_Pbullet_finish;
      end else if (plot_a1bullet_en) begin
		  x_out <= a1bullet_x;
		  y_out <= a1bullet_y;
		  colour_out <= 3'b111;
		  wren <= 1'b1;	  
		  plot_a1bullet_done <= a1_bullet_offset_done;
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
  input [6:0] playerYPos,
  input [1:0] offset,
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
      y <= playerYPos;
      plot_finish <= 0;
		bullet_flying <= 1'b0;
		//colour <= 3'b000;
    end
    else begin
		if (!bullet_flying && btn_fire) begin
			bullet_flying <= 1'b1;
			y_offset <= offset;
			x <= playerXPos;
			//colour <= 3'b111;
		end
		
      if ((y == 0) || (y == 119)) begin // left btn pressed
        y_offset <= 0; // offset = -1
		  //colour <= 3'b000;
		  y <= playerYPos;
		  bullet_flying <= 0;
		end
      if (update_xy_en && bullet_flying) begin
        if (y_offset == 2'b11)
          y <= y - 1;
		  if (y_offset == 2'b01)
          y <= y + 1;
		  if (y_offset == 0)
          y <= y;
      end

      // TODO
      plot_finish <= 1'b1;
    end

  end
endmodule

module onehertzdelay(clkout, clk, resetn);

	reg [24:0] counter;
	output reg clkout;
	input clk, resetn;
	
	always @(posedge clk) begin

		if (!resetn) begin
			counter <= 24999999;
			clkout <= 0;
		end 
		if (counter == 0) begin
			counter <= 24999999;
			clkout <= ~clkout;
		end else begin
			counter <= counter -1;
		end
	end

endmodule

// generate 60 Hz from 50 MHz
module DelayCounter(clk_50mhz,rst,en,clk_60hz_out,clk_15hz_out);
  input clk_50mhz,rst,en;
  output reg clk_60hz_out; // This is approximating the 60hz rate
  output reg clk_15hz_out = 0; // This is approximating the 15hz rate

  reg [18:0] cnt_reg_60hz = 0; // Range 0-524288
  reg [3:0] cnt_reg_15hz = 0; // Range 0-15

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

  // generate 1 pulse for every 15 pulses
  always @(posedge clk_60hz_out or posedge rst) begin
   if (rst) begin
    cnt_reg_15hz <= 0;
      clk_15hz_out <= 0;
   end
   else if (en) begin
      if (cnt_reg_15hz == 7) begin
      cnt_reg_15hz <= 0;
      clk_15hz_out <= ~clk_15hz_out;
      end else begin
      cnt_reg_15hz <= cnt_reg_15hz + 1;
      end
    end
  end
endmodule

// The following modules are all keyboard-related
module keyboard(keyboard_clk, keyboard_data, clock50, resetn, read, scan_ready, scan_code);
  input keyboard_clk;
  input keyboard_data;
  input clock50; // 50 Mhz system clock
  input resetn;
  input read;
  output scan_ready;
  output [7:0] scan_code;
  reg ready_set;
  reg [7:0] scan_code;
  reg scan_ready;
  reg read_char;
  reg clock; // 25 Mhz internal clock

  reg [3:0] incnt;
  reg [8:0] shiftin;

  reg [7:0] filter;
  reg keyboard_clk_filtered;

  // scan_ready is set to 1 when scan_code is available.
  // user should set read to 1 and then to 0 to clear scan_ready

  always @ (posedge ready_set or posedge read)
  if (read == 1) scan_ready <= 0;
  else scan_ready <= 1;

  // divide-by-two 50MHz to 25MHz
  always @(posedge clock50)
	  clock <= ~clock;



  // This process filters the raw clock signal coming from the keyboard 
  // using an eight-bit shift register and two AND gates

  always @(posedge clock)
  begin
    filter <= {keyboard_clk, filter[7:1]};
    if (filter==8'b1111_1111) keyboard_clk_filtered <= 1;
    else if (filter==8'b0000_0000) keyboard_clk_filtered <= 0;
  end


  // This process reads in serial data coming from the terminal

  always @(posedge keyboard_clk_filtered)
  begin
    if (!resetn)
    begin
	incnt <= 4'b0000;
	read_char <= 0;
    end
    else if (keyboard_data==0 && read_char==0)
    begin
	  read_char <= 1;
	  ready_set <= 0;
    end
    else
    begin
	    // shift in next 8 data bits to assemble a scan code	
	    if (read_char == 1)
		  begin
		  if (incnt < 9) 
		  begin
				  incnt <= incnt + 1'b1;
				  shiftin = { keyboard_data, shiftin[8:1]};
				  ready_set <= 0;
			  end
		  else
			  begin
				  incnt <= 0;
				  scan_code <= shiftin[7:0];
				  read_char <= 0;
				  ready_set <= 1;
			  end
		  end
	  end
  end

endmodule

module oneshot(output reg pulse_out, input trigger_in, input clk);
  reg delay;

  always @ (posedge clk)
  begin
	  if (trigger_in && !delay) pulse_out <= 1'b1;
	  else pulse_out <= 1'b0;
	  delay <= trigger_in;
  end 
endmodule

module hex_7seg(hex_digit,seg);
  input [3:0] hex_digit;
  output [6:0] seg;
  reg [6:0] seg;
  // seg = {g,f,e,d,c,b,a};
  // 0 is on and 1 is off

  always @ (hex_digit)
  case (hex_digit)
		  4'h0: seg = 7'b1000000;
		  4'h1: seg = 7'b1111001; 	// ---a----
		  4'h2: seg = 7'b0100100; 	// |	  |
		  4'h3: seg = 7'b0110000; 	// f	  b
		  4'h4: seg = 7'b0011001; 	// |	  |
		  4'h5: seg = 7'b0010010; 	// ---g----
		  4'h6: seg = 7'b0000010; 	// |	  |
		  4'h7: seg = 7'b1111000; 	// e	  c
		  4'h8: seg = 7'b0000000; 	// |	  |
		  4'h9: seg = 7'b0011000; 	// ---d----
		  4'ha: seg = 7'b0001000;
		  4'hb: seg = 7'b0000011;
		  4'hc: seg = 7'b1000110;
		  4'hd: seg = 7'b0100001;
		  4'he: seg = 7'b0000110;
		  4'hf: seg = 7'b0001110;
  endcase

endmodule 

