module stop_watch(clk_100mhz,rst,pause_button,adj,sel,CA,CB,CC,CD,CE,CF,CG,AN0,AN1,AN2,AN3);
	input clk_100mhz, rst, sel, pause_button;
	input [1:0] adj;
	output CA,CB,CC,CD,CE,CF,CG,AN0,AN1,AN2,AN3;
	wire clk_1hz, clk_2hz, tc1, tc2, tc3;
	wire [3:0] val1, val2, val3, val4;
	reg pause_state;
	reg clk1, clk2, mode; //0 is up, 1 is down
	wire pause;
	
	debouncer d(.clk_100mhz(clk_100mhz), .in(pause_button), .out(pause) ,.rst(rst));
	
	always @ (posedge pause)
	begin
		pause_state <= ~pause_state;
	end
	
	always @ (*)
	begin
		if (adj == 2'b01)
		begin
			if (sel == 1'b0)
			begin
				clk1 <= 1'b0;
				clk2 <= clk_2hz;
				mode <= 1'b0;
			end
			else if (sel == 1'b1)
			begin
				clk1 <= clk_2hz;
				clk2 <= 1'b0;
				mode <= 1'b0;
			end
		end
		else if (adj == 2'b10)
		begin
			if (sel == 1'b0)
			begin
				clk1 <= 1'b0;
				clk2 <= clk_2hz;
				mode <= 1'b1;
			end
			else if (sel == 1'b1)
			begin
				clk1 <= clk_2hz;
				clk2 <= 1'b0;
				mode <= 1'b1;
			end
		end
		else // adj == 2'b00 or 2'b11;
		begin
			clk1 <= clk_1hz;
			clk2 <= tc2;
			mode <= 1'b0;
		end
	end
	
	clock_1hz c1(.clk_100mhz(clk_100mhz),.clk_1hz(clk_1hz),.rst(rst));
	clock_2hz c2(.clk_100mhz(clk_100mhz),.clk_2hz(clk_2hz),.rst(rst));
	counter10 ctr10s(.clk(clk1),.rst(rst),.pause(pause_state),.val(val1),.tc(tc1),.mode(mode));
	counter6  ctr6s(.clk(tc1),.rst(rst),.pause(pause_state),.val(val2),.tc(tc2),.mode(mode));
	counter10 ctr10m(.clk(clk2),.rst(rst),.pause(pause_state),.val(val3),.tc(tc3),.mode(mode));
	counter6  ctr6m(.clk(tc3),.rst(rst),.pause(pause_state),.val(val4),.mode(mode));
	
	wire blink;
	assign blink = adj[1]^adj[0];
	
	display disp(.clk_100mhz(clk_100mhz),.rst(rst),.blink(blink),.part(sel),.val1(val1),.val2(val2),.val3(val3),.val4(val4),.CA(CA),.CB(CB),.CC(CC),.CD(CD),.CE(CE),.CF(CF),.CG(CG),.AN0(AN0),.AN1(AN1),.AN2(AN2),.AN3(AN3));
	
	
endmodule

//100,000,000
//100,000
module debouncer(clk_100mhz, in, out, rst);
	input clk_100mhz, in, rst;
	output reg out;
	reg [16:0] counter;
	reg clk_763hz;
	
	always @ (posedge clk_100mhz)
	begin
		if (counter == 17'b11111111111111111)
		begin
			clk_763hz <= 1'b1;
			counter <= 17'b00000000000000000;
		end
		else
		begin
			counter <= counter + 1'b1;
			clk_763hz <= 1'b0;
		end
	end
	
	reg [2:0] step_d;
	
	always @ (posedge clk_100mhz)
	begin
     if (rst)
       begin
          step_d[2:0]  <= 0;
       end
     else if (clk_763hz)
       begin
          step_d[2:0]  <= {in, step_d[2:1]};
       end
	end
	
	always @ (posedge clk_100mhz)
     if (rst)
       out <= 1'b0;
     else
       out <= ~step_d[0] & step_d[1] & clk_763hz;
	
	
endmodule

module display(clk_100mhz,rst,blink,part,val1,val2,val3,val4,CA,CB,CC,CD,CE,CF,CG,AN0,AN1,AN2,AN3);
	input clk_100mhz, rst, blink, part;
	input [3:0] val1, val2, val3, val4;
	output CA,CB,CC,CD,CE,CF,CG;
	output reg AN0,AN1,AN2,AN3;
	reg [3:0] val;
	
	decoder my_decoder(.bval(val),.CA(CA),.CB(CB),.CC(CC),.CD(CD),.CE(CE),.CF(CF),.CG(CG));
	
	wire clk_250hz;
	clock_250hz my_clock(.clk_100mhz(clk_100mhz),.clk_250hz(clk_250hz),.rst(rst));
	wire clk_4hz;
	clock_4hz my_clock1(.clk_100mhz(clk_100mhz),.clk_4hz(clk_4hz),.rst(rst));
	
	reg [1:0] counter;
	
	
	always @ (posedge clk_250hz or posedge rst)
	begin
		if(rst)
			counter <= 2'b00;
		else if (blink == 1'b0 || clk_4hz == 1'b0)
		begin
			if (counter == 2'b00)
			begin
				val <= val1;
				AN0 <= 1'b0;
				AN1 <= 1'b1;
				AN2 <= 1'b1;
				AN3 <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter == 2'b01)
			begin
				val <= val2;
				AN0 <= 1'b1;
				AN1 <= 1'b0;
				AN2 <= 1'b1;
				AN3 <= 1'b1;
				counter <= counter + 1'b1;
			end
			else if (counter == 2'b10)
			begin
				val <= val3;
				AN0 <= 1'b1;
				AN1 <= 1'b1;
				AN2 <= 1'b0;
				AN3 <= 1'b1;
				counter <= counter + 1'b1;
			end
			else
			begin
				counter <= 2'b00;
				val <= val4;
				AN0 <= 1'b1;
				AN1 <= 1'b1;
				AN2 <= 1'b1;
				AN3 <= 1'b0;
			end
		end
		else // blink == 1'b1
			if (part == 1'b0) // minute
			begin
				if (counter == 2'b00)
				begin
					val <= val1;
					AN0 <= 1'b0;
					AN1 <= 1'b1;
					AN2 <= 1'b1;
					AN3 <= 1'b1;
					counter <= counter + 1'b1;
				end
				else if (counter == 2'b01)
				begin
					val <= val2;
					AN0 <= 1'b1;
					AN1 <= 1'b0;
					AN2 <= 1'b1;
					AN3 <= 1'b1;
					counter <= counter + 1'b1;
				end
				else if (counter == 2'b10)
				begin
					val <= 4'b1111;
					AN0 <= 1'b1;
					AN1 <= 1'b1;
					AN2 <= 1'b0;
					AN3 <= 1'b1;
					counter <= counter + 1'b1;
				end
				else
				begin
					counter <= 2'b00;
					val <= 4'b1111;
					AN0 <= 1'b1;
					AN1 <= 1'b1;
					AN2 <= 1'b1;
					AN3 <= 1'b0;
				end
			end
			else // part == 1'b1, second
			begin
				if (counter == 2'b00)
				begin
					val <= 4'b1111;
					AN0 <= 1'b0;
					AN1 <= 1'b1;
					AN2 <= 1'b1;
					AN3 <= 1'b1;
					counter <= counter + 1'b1;
				end
				else if (counter == 2'b01)
				begin
					val <= 4'b1111;
					AN0 <= 1'b1;
					AN1 <= 1'b0;
					AN2 <= 1'b1;
					AN3 <= 1'b1;
					counter <= counter + 1'b1;
				end
				else if (counter == 2'b10)
				begin
					val <= val3;
					AN0 <= 1'b1;
					AN1 <= 1'b1;
					AN2 <= 1'b0;
					AN3 <= 1'b1;
					counter <= counter + 1'b1;
				end
				else
				begin
					counter <= 2'b00;
					val <= val4;
					AN0 <= 1'b1;
					AN1 <= 1'b1;
					AN2 <= 1'b1;
					AN3 <= 1'b0;
				end
			end
		end
	
endmodule



module decoder(bval,CA,CB,CC,CD,CE,CF,CG);

	input [3:0] bval;
	output reg CA,CB,CC,CD,CE,CF,CG;

	always @ (*)
	begin
	if (bval == 4'b0000)
		begin
			CA = 0;
			CB = 0;
			CC = 0;
			CD = 0; 
			CE = 0;
			CF = 0;
			CG = 1;
		end
		
		else if (bval == 4'b0001)
		begin
			CA = 1;
			CB = 0;
			CC = 0;
			CD = 1; 
			CE = 1;
			CF = 1;
			CG = 1;
		end
		
		else if (bval == 4'b0010)
		begin
			CA = 0;
			CB = 0;
			CC = 1;
			CD = 0; 
			CE = 0;
			CF = 1;
			CG = 0;
		end
		
		else if (bval == 4'b0011)
		begin
			CA = 0;
			CB = 0;
			CC = 0;
			CD = 0; 
			CE = 1;
			CF = 1;
			CG = 0;
		end
		
		else if (bval == 4'b0100)
		begin
			CA = 1;
			CB = 0;
			CC = 0;
			CD = 1; 
			CE = 1;
			CF = 0;
			CG = 0;
		end
		
		else if (bval == 4'b0101)
		begin
			CA = 0;
			CB = 1;
			CC = 0;
			CD = 0; 
			CE = 1;
			CF = 0;
			CG = 0;
		end
		
		else if (bval == 4'b0110)
		begin
			CA = 0;
			CB = 1;
			CC = 0;
			CD = 0; 
			CE = 0;
			CF = 0;
			CG = 0;
		end
		
		else if (bval == 4'b0111)
		begin
			CA = 0;
			CB = 0;
			CC = 0;
			CD = 1; 
			CE = 1;
			CF = 1;
			CG = 1;
		end
		
		else if (bval == 4'b1000)
		begin
			CA = 0;
			CB = 0;
			CC = 0;
			CD = 0; 
			CE = 0;
			CF = 0;
			CG = 0;
		end
		
		else if (bval == 4'b1001)
		begin
			CA = 0;
			CB = 0;
			CC = 0;
			CD = 1; 
			CE = 1;
			CF = 0;
			CG = 0;
		end
		
		else
		begin
			CA = 1;
			CB = 1;
			CC = 1;
			CD = 1; 
			CE = 1;
			CF = 1;
			CG = 1;
		end
	end

endmodule

// counts to 10
module counter10(clk,rst,pause,val,tc,mode);
	
	input clk, rst, pause, mode;
	output reg [3:0] val;
	output reg tc;
	
	always @ (posedge clk or posedge rst or posedge pause)
	begin
		if(rst)
		begin
			val <= 4'b0000;
			tc <= 1'b0;
		end
		else if(pause)
			val <= val;
			
		else if (mode == 1'b0)	
		begin
			if(val == 4'b1001)
			begin
				val <= 4'b0000;
				tc <= 1'b1;
			end
			else
			begin
				val <= val + 1'b1;
				tc <= 1'b0;
			end
		end 
		else  //mode == 1'b1
		begin
			if(val == 4'b0000)
			begin
				val <= 4'b1001;
				tc <= 1'b1;
			end
			else
			begin
				val <= val - 1'b1;
				tc <= 1'b0;
			end
		end
	end
	
endmodule

// counts to 6
module counter6(clk,rst,pause,val,tc,mode);
	
	input clk, rst, pause, mode;
	output reg [3:0] val;
	output reg tc;
	
	always @(posedge clk or posedge rst or posedge pause)
	begin
		if(rst)
		begin
			val <= 4'b0000;
			tc <= 1'b0;
		end
		else if(pause)
			val <= val;
		else if (mode == 1'b0)	
		begin
			if(val == 4'b0101)
			begin
				val <= 4'b0000;
				tc <= 1'b1;
			end
			else
			begin
				val <= val + 1'b1;
				tc <= 1'b0;
			end
		end 
		else  //mode == 1'b1
		begin
			if(val == 4'b0000)
			begin
				val <= 4'b0101;
				tc <= 1'b1;
			end
			else
			begin
				val <= val - 1'b1;
				tc <= 1'b0;
			end
		end
	end
	
endmodule


module clock_1hz(clk_100mhz,clk_1hz,rst);

	input clk_100mhz, rst;
	output reg clk_1hz;
	reg [25:0] a;

	always @ (posedge clk_100mhz)
	begin
		if (rst)
		begin
			a <= 26'b000000000000000000000000000;
			clk_1hz <= 1'b1;
		end
		else if (a == 26'b10111110101111000010000000)
		begin
			a <= 26'b000000000000000000000000000;
			clk_1hz <= ~clk_1hz;
		end
		else
			a <= a + 1'b1;
	end
	
endmodule 

module clock_2hz(clk_100mhz,clk_2hz,rst);

	input clk_100mhz, rst;
	output reg clk_2hz;
	reg [24:0] a;

	always @ (posedge clk_100mhz)
	begin
		if (rst)
		begin
			a <= 25'b00000000000000000000000000;
			clk_2hz <= 1'b1;
		end
		else if (a == 25'b1011111010111100001000000)
		begin
			a <= 25'b00000000000000000000000000;
			clk_2hz <= ~clk_2hz;
		end
		else
			a <= a + 1'b1;
	end
	
endmodule 

module clock_4hz(clk_100mhz,clk_4hz,rst);

	input clk_100mhz, rst;
	output reg clk_4hz;
	reg [23:0] a;

	always @ (posedge clk_100mhz)
	begin
		if (rst)
		begin
			a <= 24'b0000000000000000000000000;
			clk_4hz <= 1'b1;
		end
		else if (a == 24'b101111101011110000100000)
		begin
			a <= 24'b0000000000000000000000000;
			clk_4hz <= ~clk_4hz;
		end
		else
			a <= a + 1'b1;
	end
	
endmodule 

module clock_250hz(clk_100mhz,clk_250hz,rst);

	input clk_100mhz, rst;
	output reg clk_250hz;
	reg [17:0] a;
	always @ (posedge clk_100mhz)
	begin
		if (rst)
		begin
			a <= 18'b0000000000000000000;
			clk_250hz <= 1'b1;
		end
		else if (a == 18'b110000110101000000)
		begin
			a <= 18'b0000000000000000000;
			clk_250hz <= ~clk_250hz;
		end
		else
			a <= a + 1'b1;
	end
	
endmodule 