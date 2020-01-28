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


module SIM(
     );
    
      logic  BTNL, BTNC, RX, TX;
      logic [15:0] SWITCHES, LEDS;
      logic [7:0] CATHODES;
      logic [3:0] ANODES;
      logic CLK;
      
    OTTER_Wrapper_Programmable OTTER_Wrapper_Programmable(
        .CLK(CLK),
        .BTNL(BTNL),
        .BTNC(BTNC),
        .SWITCHES(SWITCHES),
        .RX(RX),
        .TX(TX),
        .LEDS(LEDS),
        .CATHODES(CATHODES),
        .ANODES(ANODES)
    ); 

    initial begin
      CLK = 0;
      BTNL = 0;
      BTNC = 0;
      RX = 0;
      SWITCHES = 0;
    end
    
   always  
      #5  CLK =  ! CLK;

endmodule