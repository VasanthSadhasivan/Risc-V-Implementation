`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  J. Callenes
// 
// Create Date: 01/05/2019 12:17:57 AM
// Design Name: 
// Module Name: registerFile
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


module OTTER_registerFile(Read1,Read2,WriteReg,WriteData,RegWrite,Data1,Data2,clock, s_stall);
    input [4:0] Read1,Read2,WriteReg; //the register numbers to read or write
    input [31:0] WriteData; //data to write
    input RegWrite, //the write control
        clock;  // the clock to trigger write
    input s_stall;
    output logic [31:0] Data1, Data2; // the register values read
    logic [31:0] RF [31:0]; //32 registers each 32 bits long
    integer i;
    initial 
        begin
            for (i=0;i<=31;i=i+1)
                RF[i] = 0;
        end
    //assign Data1 = RF[Read1];
    //assign Data2 = RF[Read2];
    always_comb
        if(Read1==0) Data1 =0;
        else Data1 = RF[Read1];
    always_comb
        if(Read2==0) Data2 =0;
        else Data2 = RF[Read2];

    always@(posedge clock) begin // write the register with the new value if Regwrite is high
        if(!s_stall)
        begin
        if(RegWrite && WriteReg!=0) RF[WriteReg] <= WriteData;
        end
    end
 endmodule

