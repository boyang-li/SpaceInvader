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

  // This is just a test     -------------------------------------------------
  reg CLOCK_25, slow_clk;
  // Generate a 25MHz clock from the on-board 50MHz clock
  always @(posedge CLOCK_50)
    CLOCK_25 <= ~CLOCK_25;
  reg [31:0] slow_counter;
  always @(posedge CLOCK_50) // 1000Hz
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

  // x,y counters traverse all pixels line by line @25MHz
  wire [7:0] localX;
  wire [6:0] localY;
  wire line,frame;
  assign line = (localX==159);
  assign frame = (localY==119);
  assign wren = ((localY>9 && localY<129) && (localX>36 && localX<196));
  assign colour = (wren) ? shipRGB : 0;
  assign wren = ((localY>9 && localY<129) && (localX>36 && localX<196));
  assign x = (wren) ? (localX - 36) : 0;
  assign y = (wren) ? (localY - 9) : 0;

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
