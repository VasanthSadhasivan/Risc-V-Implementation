`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2018 08:37:20 AM
// Design Name: 
// Module Name: simTemplate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module simTemplate(
     );
    
      reg  a, b;
      wire out;
      
    otter OTTER_Wrapper_Programmable(
        .BTNL(BTNL),
        .BTNC(BTNC),
        .SWITCHES(SWITCHES),
        .RX(RX),
        .TX(TX),
        .LEDS(LEDS),
        .CATHODES(CATHODES),
        .ANODES(ANODES)
    );
   
    myComponent DUT (
      .a(a),
      .b(b),
      .clk.(clk)
      .out(out)
    );
 
   always  
      #5  clk =  ! clk; 

    initial begin
      a = 1'b0;
      b = 1'b0;
      #20
      a = 1'b0;
      b = 1'b1;
      #20
      a = 1'b1;
      b = 1'b0;
      #20
      a = 1'b1;
      b = 1'b1;
      #20
      $finish;
    end
endmodule