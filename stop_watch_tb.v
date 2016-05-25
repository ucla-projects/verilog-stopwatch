`include "stop_watch.v"
`timescale 10ns/1ps
module stop_watch_tb;
	reg clk_100mhz, rst, pause, sw1, sw2;
	wire CA,CB,CC,CD,CE,CF,CG,AN0,AN1,AN2,AN3;
	stop_watch a(clk_100mhz,rst,pause,sw1,sw2,CA,CB,CC,CD,CE,CF,CG,AN0,AN1,AN2,AN3);
	
	initial
	begin
		clk_100mhz <= 1'b0;
		rst <= 1'b1;
		pause <= 1'b0; 
		sw1<= 1'b0; 
		sw2<= 1'b0;
		
		#10 rst <= 1'b0;
	end
	
	always
	begin
	#1 clk_100mhz <= ~clk_100mhz;
	end
	
endmodule
