`timescale 1ns / 1ps
// Portal 2D
module Top(
	input clk, // Clock
	input rstn, // Reset
	input [15:0] SW, // Switchs
	input PS2_CLK, // PS2
	input PS2_DATA,
	output hs, // VGA
	output vs,
	output [3:0] r,
	output [3:0] g,
	output [3:0] b,
	output SEGLED_CLK, // SEG7
	output SEGLED_CLR,
	output SEGLED_DO,
	output SEGLED_PEN,
	output LED_CLK, // LED
	output LED_CLR,
	output LED_DO,
	output LED_PEN,
	inout [4:0] BTN_X, // BTN
	inout [3:0] BTN_Y,
	output buzzer // Buzzer
	);

	// wire [15:0] addr = y * 640 + x;
	// wire [11:0] map0_data;
	// map0_rom ROM(.a(addr), ,spo(map0_data));

	wire blue = SW_OK[15];
	always @(posedge clk) begin
		if (blue) vga_data <= 12'h0AE;
		else vga_data <= 12'hE12;
	end
	
/////////////////////////////////////////////////////////////////
	reg [31:0] clkdiv; // Clock Division
	always @(posedge clk) begin
		clkdiv <= clkdiv + 1'b1;
	end

	assign buzzer = 1'b1; // Mute Buzzer

	wire [15:0] SW_OK; // AntiJit
	AntiJitter #(4) a0[15:0](.clk(clkdiv[15]), .I(SW), .O(SW_OK));

	wire [4:0] keyCode; // Button Array
	wire keyReady;
	Keypad k0(.clk(clkdiv[15]), .keyX(BTN_Y), .keyY(BTN_X), .keyCode(keyCode), .ready(keyReady));

 	//wire [7:0] ps2Out;
 	//ps2_keyboard k1(.clk(clkdiv[3]), .ps2_clk(PS2_CLK), .ps2_data(PS2_DATA), .rdn(1'b0), .data(ps2Out), .ready(ps2Ready), .overflow());

	wire [31:0] segTestData; // Seg7LED
	wire [3:0] sout;
	Seg7Device segDevice(.clkIO(clkdiv[3]), .clkScan(clkdiv[15:14]), .clkBlink(clkdiv[25]),
						.data(segTestData), .point(8'h0), .LES(8'h0),
						.sout(sout));
	assign SEGLED_CLK = sout[3];
	assign SEGLED_DO = sout[2];
	assign SEGLED_PEN = sout[1];
	assign SEGLED_CLR = sout[0];

	wire [9:0] x; // horizontal counter
	wire [8:0] y; // vertical counter
 	reg [11:0] vga_data; // VGA input
	vgac v0 (.vga_clk(clkdiv[1]), .clrn(SW_OK[0]), .d_in(vga_data), // input
			.row_addr(y), .col_addr(x), // output
			.r(r), .g(g), .b(b), .hs(hs), .vs(vs));
	
	assign segTestData = {7'b0, x, 8'b0, y};
	wire [15:0] ledData;
	assign ledData = SW_OK;
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), .pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));

endmodule
