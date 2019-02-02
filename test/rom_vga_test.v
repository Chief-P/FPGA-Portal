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

	reg [1:0] life; // life
	reg level; // level
	reg [9:0] player_x; // player position
	reg [8:0] player_y;
	reg red_portal_en; // red portal
	reg [9:0] red_portal_x;
	reg [8:0] red_portal_y;
	reg blue_portal_en; // blue portal
	reg [9:0] blue_portal_x;
	reg [8:0] blue_portal_y;
	reg [9:0] exit_x; // exit position
	reg [8:0] exit_y;
	// reg [9:0] robot_x; // robot position
	// reg [8:0] robot_y;
	reg [1:0] direction; // portal gun direction

	reg [9:0] player_vx; // player velocity
	reg [8:0] player_vy;
	reg red_bullet_en; // bullet velocity
	reg [9:0] red_bullet_vx;
	reg [8:0] red_bullet_vy;
	reg blue_bullet_en;
	reg [9:0] blue_bullet_vx;
	reg [8:0] blue_bullet_vy;

/////////////////////////////////////////////////////////////////

	// wire map1
	// wire map2
	// wire map3

/////////////////////////////////////////////////////////////////
	parameter start0_x = 10'd1, start0_y = 9'd1;
	parameter start1_x = 10'd1, start1_y = 9'd1;
	wire start_x = level ? start1_x : start0_x;
	wire start_y = level ? start1_y : start0_y;

	always @(posedge clk or negedge rstn) begin // Restart
		if (~rstn) begin
			life <= 2'd3;
			direction <= right;
			red_portal_en <= 1'b0;
			blue_portal_en <= 1'b0;
			red_bullet_en <= 1'b0;
			blue_bullet_en <= 1'b0;
			level <= SW_OK[15];
			player_x <= start_x;
			player_y <= start_y;
		end
	end

	// always @(SW_OK[15]) begin // Async Level Select & Initialize
	// 	life <= 2'd3;
	// 	direction <= right;
	// 	red_portal_en <= 1'b0;
	// 	blue_portal_en <= 1'b0;
	// 	red_bullet_en <= 1'b0;
	// 	blue_bullet_en <= 1'b0;
	// 	level <= SW_OK[15];
	// 	player_x <= start_x;
	// 	player_y <= start_y;
		// case (level)
		// 	1'd0: begin player_x <= start0_x; player_y <= start0_y; end
		// 	1'd1: begin player_x <= start1_x; player_y <= start1_y; end 
		// endcase
	// end

	initial begin // Initialize
		life <= 2'd3;
		direction <= right;
		red_portal_en <= 1'b0;
		blue_portal_en <= 1'b0;
		red_bullet_en <= 1'b0;
		blue_bullet_en <= 1'b0;
		level <= SW_OK[15];
		player_x <= start_x;
		player_y <= start_y;
		// case (level)
		// 	1'd0: begin player_x <= start0_x; player_y <= start0_y; end
		// 	1'd1: begin player_x <= start1_x; player_y <= start1_y; end 
		// endcase
	end

/////////////////////////////////////////////////////////////////
	parameter right = 2'd0, left = 2'd1, up = 2'd2, down = 2'd3;
	always @(posedge clk) begin // Player Action
		case (keyCode)
			5'd14: begin // D Right
				player_vx <= 1;
				direction <= right;
				player_data <= right_data;
			end
			8'd12: begin // A Left
				player_vx <= -1;
				direction <= left;
				player_data <= left_data;
			end
			8'd9: begin // W Up
				direction <= up;
				player_data <= up_data;
			end
			8'd17: begin // S Down
				direction <= down;
				player_data <= down_data;
			end
			8'd8: begin // J Red Portal
				red_bullet_en <= 1'b1;
				case (direction)
					right: begin red_bullet_x <= player_x + half_width; red_bullet_y <= player_y; red_bullet_vx <= 3; red_bullet_vy <= 0; end
					left: begin red_bullet_x <= player_x - half_width; red_bullet_y <= player_y; red_bullet_vx <= -3; red_bullet_vy <= 0; end
					up: begin red_bullet_x <= player_x; red_bullet_y <= player_y + half_height; red_bullet_vx <= 0; red_bullet_vy <= -3; end
					down: begin red_bullet_x <= player_x; red_bullet_y <= player_y - half_height; red_bullet_vx <= 0; red_bullet_vy <= 3; end
				endcase
			end
			8'd10: begin // K Blue Portal
				blue_bullet_en <= 1'b1;
				case (direction)
					right: begin blue_bullet_x <= player_x + half_width; blue_bullet_y <= player_y; blue_bullet_vx <= 3; blue_bullet_vy <= 0; end
					left: begin blue_bullet_x <= player_x - half_width; blue_bullet_y <= player_y; blue_bullet_vx <= -3; blue_bullet_vy <= 0; end
					up: begin blue_bullet_x <= player_x; blue_bullet_y <= player_y + half_height; blue_bullet_vx <= 0; blue_bullet_vy <= -3; end
					down: begin blue_bullet_x <= player_x; blue_bullet_y <= player_y - half_height; blue_bullet_vx <= 0; blue_bullet_vy <= 3; end
				endcase
			end
			8'd13: begin // Space Jump
				player_vy <= -9;
			end
		endcase
	end

/////////////////////////////////////////////////////////////////
	parameter gravity = 1; // Motion Control
	wire boundary = map;
	wire player_collision_x = 0;
	wire player_collision_y = 0;
	always @(posedge clk) begin // TODO: assume long press can give divided signals, if not, add vx
		if (!player_collision_x) player_x <= player_x + player_vx;
		player_vx <= 0;
	end

	always @(posedge clk) begin
		if (!player_collision_y) begin
			player_y <= player_y + player_vy;
			player_vy <= player_vy + gravity;
		end
		else player_vy <= 0;
	end

	always @(posedge clk) begin
		if (red_bullet_en) begin
			red_bullet_x <= red_bullet_x + red_bullet_vx;
			red_bullet_y <= red_bullet_y + red_bullet_vy;
		end
	end

	always @(posedge clk) begin
		if (blue_bullet_en) begin
			blue_bullet_x <= blue_bullet_x + blue_bullet_vx;
			blue_bullet_y <= blue_bullet_y + blue_bullet_vy;
		end
	end

	// always @(posedge clk) begin

	// end

/////////////////////////////////////////////////////////////////
	// win_rom ROM0(.clk(clkdiv[1]), .row(y), .col(x), .color_data(win_data)); // ROMs
	// over_rom ROM1(.clk(clkdiv[1]), .row(y), .col(x), .color_data(over_data));
	// map0_rom ROM2(.clk(clkdiv[1]), .row(y), .col(x), .color_data(map0_data));
	// map1_rom ROM3(.clk(clkdiv[1]), .row(y), .col(x), .color_data(map1_data));
	// player_right_rom ROM4(.clk(clkdiv[1]), .row(y), .col(x), .color_data(right_data));
	// player_left_rom ROM5(.clk(clkdiv[1]), .row(y), .col(x), .color_data(left_data));
	// player_up_rom ROM6(.clk(clkdiv[1]), .row(y), .col(x), .color_data(up_data));
	// player_down_rom ROM7(.clk(clkdiv[1]), .row(y), .col(x), .color_data(down_data));


/////////////////////////////////////////////////////////////////
	parameter half_width = 10'd17;
	parameter half_height = 9'd34;
	parameter portal_half_width = 10'd4;
	parameter portal_half_height = 9'd34;
	parameter bullet_half_width = 10'd3;
	parameter bullet_half_height = 9'd1;
	reg win = player & exit;
	wire over = !life;
	wire player = y >= player_y - half_height & y <= player_y + half_height & // player block 35*69
					x >= player_x - half_width & x <= player_x + half_width;
	wire red_portal = y >= red_portal_y - half_height & y <= red_portal_y + half_height & // red portal block 9*69
					x >= red_portal_x - portal_half_width & x <= red_portal_x + portal_half_width;
	wire blue_portal = y >= blue_portal_y - half_height & y <= blue_portal_y + half_height & // blue portal block 9*69
					x >= blue_portal_x - portal_half_width & x <= blue_portal_x + portal_half_width;
	wire red_bullet = x >= red_bullet_x - bullet_half_width & x <= red_bullet_x + bullet_half_width & // bullet block 7 * 3
					y >= red_bullet_y - bullet_half_height & y <= red_bullet_y + bullet_half_height;
	wire blue_bullet = x >= blue_bullet_x - bullet_half_width & x <= blue_bullet_x + bullet_half_width & // bullet block 7 * 3
					y >= blue_bullet_y - bullet_half_height & y <= blue_bullet_y + bullet_half_height;
	wire map0 = x < 10'd25 | x >= 10'd615 | y < 9'd150 | // map0 blocks
				(y >= 9'd375 & x < 10'd190) | (y >= 9'd350 & x >= 10'd275 & x < 10'd490) |
				(y < 9'd325 & x >= 10'd355 & x < 10'd430) | (y >= 9'd425 & x >= 10'd490);
	wire exit0 = y >= 9'd356 & y < 9'd425 & x >= 10'd481 & x < 10'd490; // exit0 block 9*69
	wire map1 = x < 10'd25 | x >= 10'd615 | y < 9'd25 | y >= 10'd455;
	wire exit1 = y >= 9'd356 & y < 9'd425 & x >= 10'd481 & x < 10'd490;
	// wire map1 = ;
	// wire exit1 = ;
	wire map = level ? map1 : map0;
	wire exit = level ? exit1 : exit0;
	// wire [11:0] main_data = level ? map1_data : map0_data;

	always @(posedge clk) begin // VGA display and Covering priority
		if (over) vga_data <= 12'h000; // over
		else if (win) vga_data <= 12'hE12; // win
		else if (red_bullet_en & red_bullet) vga_data <= 12'hE12;
		else if (blue_bullet_en & blue_bullet) vga_data <= 12'h0AE;
		else if (player) vga_data <= 12'h0AE; // player
		else if (red_portal_en & red_portal) vga_data <= 12'hE12; // red portal
		else if (blue_portal_en & blue_portal) vga_data <= 12'h0AE; // blue portal
		else if (map) vga_data <= 12'h000; // background
		else vga_data <= 12'hFFF;
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
	
	assign segTestData = {30'b0, life};
	wire [15:0] ledData;
	assign ledData = SW_OK;
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), .pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));

endmodule
