`timescale 1ns / 1ps

module keyboard_sim;

	// Inputs
	reg clk;
	reg rstn;
	reg [15:0] SW;
	reg PS2_CLK;
	reg PS2_DATA;

	// Outputs
	wire hs;
	wire vs;
	wire [3:0] r;
	wire [3:0] g;
	wire [3:0] b;
	wire SEGLED_CLK;
	wire SEGLED_CLR;
	wire SEGLED_DO;
	wire SEGLED_PEN;
	wire LED_CLK;
	wire LED_CLR;
	wire LED_DO;
	wire LED_PEN;
	wire buzzer;
	wire [11:0] color;

	// Bidirs
	wire [4:0] BTN_X;
	wire [3:0] BTN_Y;

	// Instantiate the Unit Under Test (UUT)
	Top uut (
		.clk(clk), 
		.rstn(rstn), 
		.SW(SW), 
		.PS2_CLK(PS2_CLK), 
		.PS2_DATA(PS2_DATA), 
		.hs(hs), 
		.vs(vs), 
		.r(r), 
		.g(g), 
		.b(b), 
		.SEGLED_CLK(SEGLED_CLK), 
		.SEGLED_CLR(SEGLED_CLR), 
		.SEGLED_DO(SEGLED_DO), 
		.SEGLED_PEN(SEGLED_PEN), 
		.LED_CLK(LED_CLK), 
		.LED_CLR(LED_CLR), 
		.LED_DO(LED_DO), 
		.LED_PEN(LED_PEN), 
		.BTN_X(BTN_X), 
		.BTN_Y(BTN_Y), 
		.buzzer(buzzer)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rstn = 0;
		SW = 0;
		PS2_CLK = 0;
		PS2_DATA = 0;

		#200;
		PS2_DATA = 10'b0010001110;
		
		#200;
		PS2_DATA = 8'h1C;
		
		#200;
		PS2_DATA = 8'h1D;
		
		#200;
		PS2_DATA = 8'h1B;

	end
	
	always @* begin
		#50;
		clk = ~clk;
	end
		
	always @* begin
		#100;
		PS2_CLK = ~PS2_CLK;
	end
      
endmodule

