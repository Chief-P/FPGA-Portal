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


	reg [7:0] life; // life
	wire level = SW_OK[15]; // level
	reg [9:0] exit_x; // exit position
	reg [8:0] exit_y;
	// reg [9:0] robot_x; // robot position
	// reg [8:0] robot_y;

	reg [9:0] player_x; // player
	reg [9:0] player_vx;
	reg [8:0] player_y;
	reg [8:0] player_vy;
	reg [1:0] direction; // portal gun direction

	reg red_bullet_en; // bullets
	reg [1:0] red_bullet_direction;
	reg [9:0] red_bullet_x;
	reg [8:0] red_bullet_y;
	reg [9:0] red_bullet_vx;
	reg [8:0] red_bullet_vy;
	reg blue_bullet_en;
	reg [1:0] blue_bullet_direction;
	reg [9:0] blue_bullet_x;
	reg [8:0] blue_bullet_y;
	reg [9:0] blue_bullet_vx;
	reg [8:0] blue_bullet_vy;

	reg red_portal_en; // red portal
	reg red_bullet_init;
	reg [1:0] red_portal_direction;
	reg [9:0] red_portal_x;
	reg [8:0] red_portal_y;
	reg blue_portal_en; // blue portal
	reg blue_bullet_init;
	reg [1:0] blue_portal_direction;
	reg [9:0] blue_portal_x;
	reg [8:0] blue_portal_y;

/////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////
	reg welcome;
	initial begin // Initialize
		over <= 1'b0;
		win <= 1'b0;
		welcome <= 1'b1;
		life <= 8'hFF;
	end

/////////////////////////////////////////////////////////////////
	parameter right = 2'b00, left = 2'b11, up = 2'b01, down = 2'b10;
	parameter player_speed = 1, bullet_speed = 1;
	parameter bullet_portal_shift = portal_half_width + bullet_half_width - 5; // 3 is good, convex on the wall
	parameter player_portal_shift = portal_half_width + player_half_width + 15; // shift away from the portal
	parameter start0_x = 10'd100, start0_y = 9'd250;
	parameter start1_x = 10'd200, start1_y = 9'd300;
	wire [9:0] start_x = level ? start1_x : start0_x;
	wire [8:0] start_y = level ? start1_y : start0_y;

	// Status
	wire reset = x == 10'd10 && y == 9'd10;
	reg win;
	always @(posedge clk) begin
		if (~rstn) win <= 1'b0;
		if (player & exit) win <= 1'b1;
	end

	always @(posedge clkdiv[26]) begin // 1s counter
		if (~rstn) life <= 8'hFF;
		if (life) life <= life - 8'd1;
	end

	reg over;
	always @(posedge clk) begin
		if (reset) over <= 1'b0;
		else if (!life) over <= 1'b1;
	end

	reg inRedPortal;
	always @(posedge clk) begin
		if (reset) inRedPortal <= 1'b0;
		else if (red_portal_en & blue_portal_en & player & red_portal) inRedPortal <= 1'b1;
	end

	reg inBluePortal;
	always @(posedge clk) begin
		if (reset) inBluePortal <= 1'b0;
		else if (blue_portal_en & blue_portal_en & player & blue_portal) inBluePortal <= 1'b1;
	end

	reg redHit;
	always @(posedge clk) begin
		if (reset) redHit <= 1'b0;
		else if (red_bullet_en & red_bullet & map) redHit <= 1'b1;
	end

	reg blueHit;
	always @(posedge clk) begin
		if (reset) blueHit <= 1'b0;
		else if (blue_bullet_en & blue_bullet & map) blueHit <= 1'b1;
	end

	reg collision;
	always @(posedge clk) begin
		if (reset) collision <= 1'b0;
		else if (map & player) collision <= 1'b1;
	end

/////////////////////////////////////////////////////////////////
	wire refresh = x == 10'd0 && y == 9'd0; // refresh signal
	always @(posedge clk) begin // Main Control Block
		if (~rstn) begin // Reset
			welcome <= 1'b0;
			player_x <= start_x;
			player_y <= start_y;
			// player_color <= yellow;
			player_vx <= 10'd0;
			player_vy <= 9'd0;
			direction <= right;
			red_portal_en <= 1'b0;
			blue_portal_en <= 1'b0;
			red_bullet_en <= 1'b0;
			blue_bullet_en <= 1'b0;
			red_bullet_x <= start_x;
			red_bullet_y <= start_y;
			blue_bullet_x <= start_x;
			blue_bullet_y <= start_y;
		end

		case (keyCode)
			5'd14: begin // D Right
				// player_x <= player_x + 10'd1;
				player_vx <= player_speed;
				player_vy <= 9'd0;
				direction <= right;
				//player_data <= right_data;
			end
			5'd12: begin // A Left
				// player_x <= player_x - 10'd1;
				player_vx <= -player_speed;
				player_vy <= 9'd0;
				direction <= left;
				//player_data <= left_data;
			end
			5'd9: begin // W Up
				// player_y <= player_y - 9'd1;
				player_vx <= 10'd0;
				player_vy <= -player_speed;
				direction <= up;
				//player_data <= up_data;
			end
			5'd17: begin // S Down
				// player_y <= player_y + 9'd1;
				player_vx <= 10'd0;
				player_vy <= player_speed;
				direction <= down;
				//player_data <= down_data;
			end
			5'd8: begin // J Red Portal
				red_bullet_en <= 1'b1;
				red_bullet_init <= 1'b0;
				red_portal_en <= 1'b0;
				case (direction)
					right: begin
						red_bullet_vx <= bullet_speed;
						red_bullet_vy <= 9'd0;
						red_bullet_direction <= right;
					end
					left: begin
						red_bullet_vx <= -bullet_speed;
						red_bullet_vy <= 9'd0;
						red_bullet_direction <= left;
					end
					up: begin
						red_bullet_vx <= 10'd0;
						red_bullet_vy <= -bullet_speed; 
						red_bullet_direction <= up;
					end
					down: begin
						red_bullet_vx <= 10'd0;
						red_bullet_vy <= bullet_speed;
						red_bullet_direction <= down;
					end
				endcase
			end
			5'd10: begin // K Blue Portal
				blue_bullet_en <= 1'b1;
				blue_bullet_init <= 1'b0;
				blue_portal_en <= 1'b0;
				case (direction)
					right: begin
						blue_bullet_vx <= bullet_speed;
						blue_bullet_vy <= 9'd0;
						blue_bullet_direction <= right;
					end
					left: begin
						blue_bullet_vx <= -bullet_speed;
						blue_bullet_vy <= 9'd0;
						blue_bullet_direction <= left;
					end
					up: begin
						blue_bullet_vx <= 10'd0;
						blue_bullet_vy <= -bullet_speed; 
						blue_bullet_direction <= up;
					end
					down: begin
						blue_bullet_vx <= 10'd0;
						blue_bullet_vy <= bullet_speed;
						blue_bullet_direction <= down;
					end
				endcase
			end
			// 5'd13: begin // Space Jump
				// player_y <= player_y - 100;
			// end
			default: begin // No action
				player_vx <= 10'd0;
				player_vy <= 9'd0;
			end
		endcase

		if (refresh) begin // Position update
			// if (~red_bullet_en) begin // bullet position
			// 	red_bullet_x <= player_x;
			// 	red_bullet_y <= player_y;
			// end
			// if (~blue_bullet_en) begin
			// 	blue_bullet_x <= player_x;
			// 	blue_bullet_y <= player_y;
			// end

			if (collision) begin // Player position
				case (direction)
					right: player_x <= player_x - 1;
					left: player_x <= player_x + 1;
					up: player_y <= player_y + 1;
					down: player_y <= player_y - 1;
				endcase
			end
			else if (inRedPortal) begin
				case (blue_portal_direction) // Teleport
					left: begin
						player_x <= blue_portal_x - player_portal_shift;
						player_y <= blue_portal_y;
					end
					right: begin
						player_x <= blue_portal_x + player_portal_shift;
						player_y <= blue_portal_y;
					end
					down: begin
						player_x <= blue_portal_x;
						player_y <= blue_portal_y + player_portal_shift;
					end
					up: begin
						player_x <= blue_portal_x;
						player_y <= blue_portal_y - player_portal_shift;
					end
				endcase
			end
			else if (inBluePortal) begin // else is to avoid conflictions
				case (red_portal_direction) // Teleport
					left: begin
						player_x <= red_portal_x - player_portal_shift;
						player_y <= red_portal_y;
					end
					right: begin
						player_x <= red_portal_x + player_portal_shift;
						player_y <= red_portal_y;
					end
					down: begin
						player_x <= red_portal_x;
						player_y <= red_portal_y + player_portal_shift;
					end
					up: begin
						player_x <= red_portal_x;
						player_y <= red_portal_y - player_portal_shift;
					end
				endcase
			end
			else begin
				// player_color <= yellow;
				player_x <= player_x + player_vx;
				player_y <= player_y + player_vy;
			end

			if (redHit) begin
				red_bullet_en <= 1'b0;
				red_portal_en <= 1'b1;
				red_portal_direction <= ~red_bullet_direction; // Normal vector
				case (red_portal_direction)
					left: begin
						// red_portal <= red_portal_vertical;
						red_portal_x <= red_bullet_x + bullet_portal_shift;
						red_portal_y <= red_bullet_y;
					end
					right: begin
						// red_portal <= red_portal_vertical;
						red_portal_x <= red_bullet_x - bullet_portal_shift;
						red_portal_y <= red_bullet_y;
					end
					down: begin
						// red_portal <= red_portal_horizontal;
						red_portal_x <= red_bullet_x;
						red_portal_y <= red_bullet_y - bullet_portal_shift;
					end
					up: begin
						// red_portal <= red_portal_horizontal;
						red_portal_x <= red_bullet_x;
						red_portal_y <= red_bullet_y + bullet_portal_shift;
					end
				endcase
			end

			if (blueHit) begin
				blue_bullet_en <= 1'b0;
				blue_portal_en <= 1'b1;
				blue_portal_direction <= ~blue_bullet_direction; // Normal vector
				case (blue_portal_direction)
					left: begin
						// blue_portal <= blue_portal_vertical;
						blue_portal_x <= blue_bullet_x + bullet_portal_shift;
						blue_portal_y <= blue_bullet_y;
					end
					right: begin
						// blue_portal <= blue_portal_vertical;
						blue_portal_x <= blue_bullet_x - bullet_portal_shift;
						blue_portal_y <= blue_bullet_y;
					end
					down: begin
						// blue_portal <= blue_portal_horizontal;
						blue_portal_x <= blue_bullet_x;
						blue_portal_y <= blue_bullet_y - bullet_portal_shift;
					end
					up: begin
						// blue_portal <= blue_portal_horizontal;
						blue_portal_x <= blue_bullet_x;
						blue_portal_y <= blue_bullet_y + bullet_portal_shift;
					end
				endcase
			end

			if (~red_bullet_init) begin
				red_bullet_x <= player_x;
				red_bullet_y <= player_y;
				red_bullet_init <= 1'b1;
			end
			else if (red_bullet_en) begin // Red Bullet
				red_bullet_x <= red_bullet_x + red_bullet_vx;
				red_bullet_y <= red_bullet_y + red_bullet_vy;
			end

			if (~blue_bullet_init) begin
				blue_bullet_x <= player_x;
				blue_bullet_y <= player_y;
				blue_bullet_init <= 1'b1;
			end
			else if (blue_bullet_en) begin // Blue Bullet
				blue_bullet_x <= blue_bullet_x + blue_bullet_vx;
				blue_bullet_y <= blue_bullet_y + blue_bullet_vy;
			end
		end
	end

/////////////////////////////////////////////////////////////////
	// parameter gravity = 1; // Motion Control
	// wire boundary = map;
	// wire player_collision_x = 0;
	// wire player_collision_y = 0;

	// always @(posedge clk) begin
	// 	if (red_bullet_en) begin
	// 		case (red_bullet_direction)
	// 			right: red_bullet_x <= red_portal_x + 1;
	// 			left: red_bullet_x <= red_bullet_x - 1;
	// 			up: red_bullet_y <= red_bullet_y - 1;
	// 			down: red_bullet_y <= red_bullet_y + 1;
	// 		endcase
	// 	end
	// end

	// always @(posedge clk) begin
	// 	if (blue_bullet_en) begin
	// 		case (blue_bullet_direction)
	// 			right: blue_bullet_x <= blue_portal_x + 1;
	// 			left: blue_bullet_x <= blue_bullet_x - 1;
	// 			up: blue_bullet_y <= blue_bullet_y - 1;
	// 			down: blue_bullet_y <= blue_bullet_y + 1;
	// 		endcase
	// 	end
	// end

	// always @(posedge clk) begin

	// end

/////////////////////////////////////////////////////////////////
	wire [15:0] welcome_addr = (x >= 220 & x < 420 & y >= 140 & y < 340) ? (y - 140) * 200 + (x - 220) : 16'b0;
	wire [11:0] welcome_data;
	welcome_rom rom0(.a(welcome_addr), .spo(welcome_data)); // 200 * 200 -> 200 * 200

	wire [14:0] win_addr = y * 40 + x >> 2;
	wire [11:0] win_data;
	win_rom rom1(.a(win_addr), .spo(win_data)); // 160 * 120 -> 640 * 480

	wire [14:0] over_addr = y * 40 + x >> 2;
	wire [11:0] over_data;
	over_rom rom2(.a(over_addr), .spo(over_data)); // 160 * 120 -> 640 * 480

	wire [10:0] player_addr = (y - player_y + player_half_height) * 35 + (x - player_x + player_half_width);
	wire [11:0] player_right_data, player_left_data, player_up_data, player_down_data;
	player_right_rom rom3(.a(player_addr), .spo(player_right_data));
	player_left_rom rom4(.a(player_addr), .spo(player_left_data));
	player_up_rom rom5(.a(player_addr), .spo(player_up_data));
	player_down_rom rom6(.a(player_addr), .spo(player_down_data));
	wire [11:0] player_data = (direction == right) ? player_right_data :
							   ((direction == left) ? player_left_data : 
							       ((direction == up) ? player_up_data : player_down_data));

	wire [11:0] map_addr = y % 64 * 64 + x % 64;
	wire [11:0] map_data;
	map_rom rom7(.a(map_addr), .spo(map_data)); // 64 * 64
	// win_rom ROM0(.clk(clkdiv[1]), .row(y), .col(x), .color_data(win_data)); // ROMs
	// over_rom ROM1(.clk(clkdiv[1]), .row(y), .col(x), .color_data(over_data));
	// map0_rom ROM2(.clk(clkdiv[1]), .row(y), .col(x), .color_data(map0_data));
	// map1_rom ROM3(.clk(clkdiv[1]), .row(y), .col(x), .color_data(map1_data));
	// player_right_rom ROM4(.clk(clkdiv[1]), .row(y), .col(x), .color_data(right_data));
	// player_left_rom ROM5(.clk(clkdiv[1]), .row(y), .col(x), .color_data(left_data));
	// player_up_rom ROM6(.clk(clkdiv[1]), .row(y), .col(x), .color_data(up_data));
	// player_down_rom ROM7(.clk(clkdiv[1]), .row(y), .col(x), .color_data(down_data));


/////////////////////////////////////////////////////////////////
	parameter player_half_width = 17;
	parameter player_half_height = 17;
	parameter portal_half_width = 4;
	parameter portal_half_height = 34;
	parameter bullet_half_width = 2;
	parameter bullet_half_height = 2;
	wire player = y >= (player_y - player_half_height) & y <= (player_y + player_half_height) & // player block 35*35
					x >= (player_x - player_half_width) & x <= (player_x + player_half_width);
	wire red_portal_horizontal = y >= red_portal_y - portal_half_width & y <= red_portal_y + portal_half_width & // red portal block 69*9
							x >= red_portal_x - portal_half_height & x <= red_portal_x + portal_half_height;
	wire blue_portal_horizontal = y >= blue_portal_y - portal_half_width & y <= blue_portal_y + portal_half_width & // blue portal block 69*9
							x >= blue_portal_x - portal_half_height & x <= blue_portal_x + portal_half_height;
	wire red_portal_vertical = y >= red_portal_y - portal_half_height & y <= red_portal_y + portal_half_height & // red portal block 9*69
							x >= red_portal_x - portal_half_width & x <= red_portal_x + portal_half_width;
	wire blue_portal_vertical = y >= blue_portal_y - portal_half_height & y <= blue_portal_y + portal_half_height & // blue portal block 9*69
							x >= blue_portal_x - portal_half_width & x <= blue_portal_x + portal_half_width;
	wire red_portal = (red_portal_direction == right | red_portal_direction == left) ? red_portal_vertical : red_portal_horizontal;
	wire blue_portal = (blue_portal_direction == right | blue_portal_direction == left) ? blue_portal_vertical : blue_portal_horizontal;
	wire red_bullet = x >= red_bullet_x - bullet_half_width & x <= red_bullet_x + bullet_half_width & // bullet block 5 * 5
					y >= red_bullet_y - bullet_half_height & y <= red_bullet_y + bullet_half_height;
	wire blue_bullet = x >= blue_bullet_x - bullet_half_width & x <= blue_bullet_x + bullet_half_width & // bullet block 5 * 5
					y >= blue_bullet_y - bullet_half_height & y <= blue_bullet_y + bullet_half_height;
	wire map0 = x < 10'd25 | x >= 10'd615 | y < 9'd150 | y >= 9'd465 | // map0 blocks
				(y >= 9'd375 & x < 10'd190) | (y >= 9'd350 & x >= 10'd275 & x < 10'd490 & ~exit0) |
				(y < 9'd325 & x >= 10'd355 & x < 10'd430) | (y >= 9'd425 & x >= 10'd490);
	wire exit0 = y >= 9'd356 & y < 9'd425 & x >= 10'd481 & x < 10'd490; // exit0 block 9*69
	wire map1 = x < 10'd25 | x >= 10'd615 | y < 9'd25 | y >= 10'd455 | // gap 25
				(x >= 230 & x < 285 & y >= 195 & y < 425 & ~exit1) | (x >= 285 & x < 585 & y >= 285 & y < 335) |
				(x >= 355 & x < 405 & y >= 55 & y < 325) | (x < 325 & y >= 155 & y < 205);
	wire exit1 = y >= 9'd205 & y < 9'd285 & x >= 10'd276 & x < 10'd285;
	wire map = level ? map1 : map0;
	wire exit = level ? exit1 : exit0;

	parameter red = 12'hE12, green = 12'hBE1, blue = 12'h0AE, yellow = 12'hFF0, // blue in fact
			black = 12'h000, white = 12'hFFF;
	always @(posedge clk) begin // VGA display and Covering priority
		if (welcome) vga_data <= welcome_data;
		else if (over) vga_data <= over_data; // over
		else if (win) vga_data <= green; // win
		else if (red_bullet_en & red_bullet) vga_data <= red; // red bullet
		else if (blue_bullet_en & blue_bullet) vga_data <= blue; // blue bullet
		else if (player) vga_data <= player_data; // player
		else if (exit) vga_data <= green; // green exit
		else if (~map) vga_data <= white; // cover portal sides
		else if (red_portal_en & red_portal) vga_data <= red; // red portal
		else if (blue_portal_en & blue_portal) vga_data <= blue; // blue portal
		else if (map) vga_data <= map_data; // map
		else vga_data <= white; // background
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
	
	assign segTestData = {2'b0, player_x, 3'b0, player_y, 2'b0, direction, life}; // x, y, direction, life
	wire [15:0] ledData;
	assign ledData = SW_OK;
	ShiftReg #(.WIDTH(16)) ledDevice (.clk(clkdiv[3]), .pdata(~ledData), .sout({LED_CLK,LED_DO,LED_PEN,LED_CLR}));

endmodule
