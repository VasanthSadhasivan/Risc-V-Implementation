`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  J. Callenes
// 
// Create Date: 01/04/2019 04:32:12 PM
// Design Name: 
// Module Name: OTTER_CPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.10 - (Keefe Johnson, 1/14/2020) Added serial programmer.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


 module OTTER_MCU(input CLK,
                //input INTR,
                input EXT_RESET,  // CHANGED RESET TO EXT_RESET FOR PROGRAMMER
                input [31:0] IOBUS_IN,
                output [31:0] IOBUS_OUT,
                output [31:0] IOBUS_ADDR,
                output logic IOBUS_WR,
                input PROG_RX,  // ADDED PROG_RX FOR PROGRAMMER
                output PROG_TX  // ADDED PROG_TX FOR PROGRAMMER
);           

    // ************************ BEGIN PROGRAMMER ************************ 

    wire RESET;
    wire [31:0] s_prog_ram_addr;
    wire [31:0] s_prog_ram_data;
    wire s_prog_ram_we;
    wire s_prog_mcu_reset;
    
    wire [31:0] mem_addr_after_memory;

    wire [31:0] mem_data_after_memory;
    
    wire [1:0] mem_size_after_memory;
    
    wire mem_sign_after_memory;
    
    wire mem_we_after_memory;

    programmer #(.CLK_RATE(50), .BAUD(115200), .IB_TIMEOUT(200),
                 .WAIT_TIMEOUT(500))
        programmer(.clk(CLK), .rst(EXT_RESET), .srx(PROG_RX), .stx(PROG_TX),
                   .mcu_reset(s_prog_mcu_reset), .ram_addr(s_prog_ram_addr),
                   .ram_data(s_prog_ram_data), .ram_we(s_prog_ram_we));

    // ************************ END PROGRAMMER ************************ 

    // HAZARD PREVENTION //
    logic [32:0] stall = 0;
    logic pc_write_cont = 1;
    wire pc_write_data;
    logic dependency_exists;
    //********************//

    // PIPELINE REGISTERS //
    logic [63:0] fetch_to_decode = 0;
    logic [266:0] decode_to_execute = 0;
    logic [262:0] execute_to_memory = 0;
    logic [130:0] memory_to_writeback = 0;
    //********************//
    
    wire [6:0] opcode_decode;
    wire [6:0] opcode_pre_fetch;
    wire [6:0] opcode_fetch;
    wire [6:0] opcode_execute;
    wire [6:0] opcode_memory;
    wire [6:0] opcode_writeback;
    
    wire [31:0] pc_fetch;
    wire [31:0] pc_decode;
    wire [31:0] pc_execute;
    wire [31:0] pc_memory;
    wire [31:0] pc_writeback;
        
    wire [31:0] pc_value_fetch;
    
    wire [31:0] next_pc_fetch;
    
    wire [31:0] jalr_pc_execute;
    wire [31:0] jalr_pc_memory;
    
    wire [31:0] branch_pc_execute;
    wire [31:0] branch_pc_memory;
    
    wire [31:0] jump_pc_execute;
    wire [31:0] jump_pc_memory;
    
    wire [31:0] I_immed_decode;
    wire [31:0] I_immed_execute;
    
    wire [31:0] U_immed_decode;

    wire [31:0] S_immed_decode;
        
    wire [31:0] A_decode;
    wire [31:0] A_execute;
    
    
    wire [31:0] B_decode;
    wire [31:0] B_execute;
    wire [31:0] B_memory;
    
    wire [31:0] aluBin_decode;
    wire [31:0] aluBin_execute;

    wire [31:0] aluAin_decode;
    wire [31:0] aluAin_execute;
    
    wire [31:0] aluResult_execute;
    wire [31:0] aluResult_memory;
    wire [31:0] aluResult_writeback;
       
    wire [31:0] wd_writeback;
    
    wire [31:0] dout2_memory;
    wire [31:0] dout2_writeback;
    
    wire [31:0] IR_pre_fetch;
    wire [31:0] IR_fetch;
    wire [31:0] IR_decode;
    wire [31:0] IR_memory;
    wire [31:0] IR_execute;
    wire [31:0] IR_writeback;
    
    wire regWrite_decode;
    wire regWrite_memory;
    wire regWrite_execute;
    wire regWrite_writeback;
    
    wire memWrite_decode;
    wire memWrite_execute;
    wire memWrite_memory;
    
    wire memRead2_decode;
    wire memRead2_execute;
    wire memRead2_memory;
    
    wire memRead1_fetch;
    
    wire pcWrite_fetch;
    
    wire alu_srcA_decode;

    wire [1:0] alu_srcB_decode;
   
    wire [1:0] rf_wr_sel_decode;
    wire [1:0] rf_wr_sel_execute;
    wire [1:0] rf_wr_sel_memory;
    wire [1:0] rf_wr_sel_writeback;
    
    wire [1:0] pcSource_decode;
    wire [1:0] pcSource_execute;
    wire [1:0] pcSource_memory;
    
    wire [3:0] alu_fun_decode;
    wire [3:0] alu_fun_execute;
    
    logic dependency_reason = 0;
    // CONTROL HAZARD PREVENTION //
    always @(posedge CLK)
    begin
        if( IR_fetch[6:0] == 7'b1101111 || 
            IR_fetch[6:0] == 7'b1100111 ||
            IR_fetch[6:0] == 7'b1100011 ||
            dependency_exists)
            begin
                if(dependency_exists)
                    begin
                        dependency_reason = 1;
                        stall = 3;
                    end
                else
                    begin
                        dependency_reason = 0;
                        stall = 2;
                    end
                pc_write_cont = 0;
            end
        else if (stall > 1)
            begin
                stall = stall - 1;
            end
        else if (stall == 1 && pc_write_cont == 0)
            begin
                pc_write_cont = 1;
                if(dependency_reason)
                    begin
                        dependency_reason = 0;
                        stall = 0;
                    end
            end
        else
            begin
                stall = 0;
            end
    end
    
    //GENERAL HAZARD PREVENTION
    assign IR_fetch = (stall>0 || dependency_exists)? 19 : IR_pre_fetch;
    assign pcWrite_fetch = pc_write_cont && pc_write_data;
    
    // DATA HAZARD PREVENTION //
    
    assign pc_write_data = ~dependency_exists;
    
    always @*
    begin
        if(opcode_pre_fetch != 7'b0110111 && opcode_pre_fetch != 7'b0010111 && opcode_pre_fetch != 7'b1101111)
            begin
                if( opcode_decode == 7'b0110111 ||
                    opcode_decode == 7'b0010111 ||
                    opcode_decode == 7'b1101111 ||
                    opcode_decode == 7'b1100111 ||
                    opcode_decode == 7'b0000011 ||
                    opcode_decode == 7'b0010011 || 
                    opcode_decode == 7'b0110011 ||
                    opcode_execute == 7'b0110111 ||
                    opcode_execute == 7'b0010111 ||
                    opcode_execute == 7'b1101111 ||
                    opcode_execute == 7'b1100111 ||
                    opcode_execute == 7'b0000011 ||
                    opcode_execute == 7'b0010011 || 
                    opcode_execute == 7'b0110011 ||
                    opcode_memory == 7'b0110111 ||
                    opcode_memory == 7'b0010111 ||
                    opcode_memory == 7'b1101111 ||
                    opcode_memory == 7'b1100111 ||
                    opcode_memory == 7'b0000011 ||
                    opcode_memory == 7'b0010011 || 
                    opcode_memory == 7'b0110011 ||
                    opcode_writeback == 7'b0110111 ||
                    opcode_writeback == 7'b0010111 ||
                    opcode_writeback == 7'b1101111 ||
                    opcode_writeback == 7'b1100111 ||
                    opcode_writeback == 7'b0000011 ||
                    opcode_writeback == 7'b0010011 || 
                    opcode_writeback == 7'b0110011)
                    begin
                         if(opcode_pre_fetch == 7'b1100011 ||
                            opcode_pre_fetch == 7'b0100011 ||
                            opcode_pre_fetch == 7'b0110011)
                            begin
                                if( (IR_pre_fetch[24:20] == IR_decode[11:7]    && IR_pre_fetch[24:20]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_decode[11:7]    && IR_pre_fetch[19:15]  != 0)|| 
                                    (IR_pre_fetch[24:20] == IR_execute[11:7]   && IR_pre_fetch[24:20]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_execute[11:7]   && IR_pre_fetch[19:15]  != 0)|| 
                                    (IR_pre_fetch[24:20] == IR_memory[11:7]    && IR_pre_fetch[24:20]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_memory[11:7]    && IR_pre_fetch[19:15]  != 0)|| 
                                    (IR_pre_fetch[24:20] == IR_writeback[11:7] && IR_pre_fetch[24:20]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_writeback[11:7] && IR_pre_fetch[19:15]  != 0))
                                    begin
                                        dependency_exists = 1;
                                    end
                                else
                                    begin
                                        dependency_exists = 0;
                                    end
                            end
                         else
                            begin
                                if( (IR_pre_fetch[19:15] == IR_decode[11:7]    && IR_pre_fetch[19:15]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_execute[11:7]   && IR_pre_fetch[19:15]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_memory[11:7]    && IR_pre_fetch[19:15]  != 0)|| 
                                    (IR_pre_fetch[19:15] == IR_writeback[11:7] && IR_pre_fetch[19:15]  != 0))
                                    begin
                                        dependency_exists = 1;
                                    end
                                else
                                    begin
                                        dependency_exists = 0;
                                    end
                            end
                    end

                else
                    begin
                        dependency_exists = 0;
                    end
            end
        else
            begin
                dependency_exists = 0;
            end
    end

    //wire mepcWrite, csrWrite,intCLR, mie, intTaken;
    //wire [31:0] mepc, mtvec;
   
    assign opcode_decode = IR_decode[6:0]; // opcode shortcut
    assign opcode_pre_fetch = IR_pre_fetch[6:0];
    assign opcode_fetch  = IR_fetch[6:0];
    assign opcode_execute  = IR_execute[6:0];
    assign opcode_memory  = IR_memory[6:0];
    assign opcode_writeback  = IR_writeback[6:0];
    //PC is byte-addressed but our memory is word addressed 
    ProgCount PC (.PC_CLK(CLK), .PC_RST(RESET), .PC_LD(pcWrite_fetch),
                 .PC_DIN(pc_value_fetch), .PC_COUNT(pc_fetch));   
    
    // Creates a 6-to-1 multiplexor used to select the source of the next PC
    Mult4to1 PCdatasrc (next_pc_fetch, jalr_pc_memory, branch_pc_memory, jump_pc_memory, pcSource_memory, pc_value_fetch);
    // Creates a 4-to-1 multiplexor used to select the B input of the ALU
    Mult4to1 ALUBinput (B_decode, I_immed_decode, S_immed_decode, pc_decode, alu_srcB_decode, aluBin_decode);
    
    Mult2to1 ALUAinput (A_decode, U_immed_decode, alu_srcA_decode, aluAin_decode);
    // Creates a RISC-V ALU
    // Inputs are ALUCtl (the ALU control), ALU value inputs (ALUAin, ALUBin)
    // Outputs are ALUResultOut (the 64-bit output) and Zero (zero detection output)
    OTTER_ALU ALU (alu_fun_execute, aluAin_execute, aluBin_execute, aluResult_execute); // the ALU
    
    // Creates a RISC-V register file
    OTTER_registerFile RF (IR_decode[19:15], IR_decode[24:20], IR_writeback[11:7], wd_writeback, regWrite_writeback, A_decode, B_decode, CLK); // Register file
 
    //Creates 4-to-1 multiplexor used to select reg write back data
    Mult4to1 regWriteback (pc_writeback + 4,csr_reg,dout2_writeback,aluResult_writeback,rf_wr_sel_writeback,wd_writeback);
  
    //pc target calculations 
    assign next_pc_fetch = pc_fetch + 4;    //PC is byte aligned, memory is word aligned
    assign jalr_pc_execute = I_immed_execute + A_execute;
    //assign branch_pc = pc + {{21{IR[31]}},IR[7],IR[30:25],IR[11:8] ,1'b0};   //word aligned addresses
    assign branch_pc_execute = pc_execute + {{20{IR_execute[31]}},IR_execute[7],IR_execute[30:25],IR_execute[11:8],1'b0};   //byte aligned addresses
    assign jump_pc_execute = pc_execute + {{12{IR_execute[31]}}, IR_execute[19:12], IR_execute[20],IR_execute[30:21],1'b0};
    //assign int_pc = 0;
    
    logic br_lt,br_eq,br_ltu;
    //Branch Condition Generator
    always_comb
    begin
        br_lt=0; br_eq=0; br_ltu=0;
        if($signed(A_decode) < $signed(B_decode)) br_lt=1;
        if(A_decode==B_decode) br_eq=1;
        if(A_decode<B_decode) br_ltu=1;
    end
    
    // Generate immediates
    assign S_immed_decode = {{20{IR_decode[31]}},IR_decode[31:25],IR_decode[11:7]};
    assign I_immed_decode = {{20{IR_decode[31]}},IR_decode[31:20]};
    assign U_immed_decode = {IR_decode[31:12],{12{1'b0}}};

    // ************************ BEGIN PROGRAMMER ************************ 

    assign mem_addr_after_memory = s_prog_ram_we ? s_prog_ram_addr : aluResult_memory;  // 2:1 mux
    assign mem_data_after_memory = s_prog_ram_we ? s_prog_ram_data : B_memory;  // 2:1 mux
    assign mem_size_after_memory = s_prog_ram_we ? 2'b10 : IR_memory[13:12];  // 2:1 mux
    assign mem_sign_after_memory = s_prog_ram_we ? 1'b0 : IR_memory[14];  // 2:1 mux
    assign mem_we_after_memory = s_prog_ram_we | memWrite_memory;  // or gate
    assign RESET = s_prog_mcu_reset | EXT_RESET;  // or gate

    // ************************ END PROGRAMMER ************************               
                           
     OTTER_mem_byte #(14) memory  (.MEM_CLK(CLK),.MEM_ADDR1(pc_fetch),.MEM_ADDR2(mem_addr_after_memory),.MEM_DIN2(mem_data_after_memory),
                               .MEM_WRITE2(mem_we_after_memory),.MEM_READ1(memRead1_fetch),.MEM_READ2(memRead2_memory),
                               .ERR(),.MEM_DOUT1(IR_pre_fetch),.MEM_DOUT2(dout2_memory),.IO_IN(IOBUS_IN),.IO_WR(IOBUS_WR),.MEM_SIZE(mem_size_after_memory),.MEM_SIGN(mem_sign_after_memory));
    // ^ CHANGED aluResult to mem_addr_after FOR PROGRAMMER
    // ^ CHANGED B to mem_data_after FOR PROGRAMMER
    // ^ CHANGED memWrite to mem_we_after FOR PROGRAMMER
    // ^ CHANGED IR[13:12] to mem_size_after FOR PROGRAMMER
    // ^ CHANGED IR[14] to mem_sign_after FOR PROGRAMMER
     
     OTTER_CU_Decoder CU_DECODER(.CU_OPCODE(opcode_decode), .CU_FUNC3(IR_decode[14:12]),.CU_FUNC7(IR_decode[31:25]), 
             .CU_BR_EQ(br_eq),.CU_BR_LT(br_lt),.CU_BR_LTU(br_ltu),.CU_PCSOURCE(pcSource_decode),
             .CU_ALU_SRCA(alu_srcA_decode),.CU_ALU_SRCB(alu_srcB_decode),.CU_ALU_FUN(alu_fun_decode),.CU_RF_WR_SEL(rf_wr_sel_decode));//,.intTaken(intTaken));
            
     //logic prev_INT=0;
     
     OTTER_CU_FSM CU_FSM (.CU_CLK(CLK), /*.CU_INT(INTR),*/ .CU_RESET(RESET), .CU_OPCODE(opcode_decode), //.CU_OPCODE(opcode),
                     .CU_FUNC3(IR_decode[14:12]),.CU_FUNC12(IR_decode[31:20]),
                     .CU_REGWRITE(regWrite_decode), .CU_MEMWRITE(memWrite_decode), 
                     .CU_MEMREAD1(memRead1_fetch),.CU_MEMREAD2(memRead2_decode));//.CU_intTaken(intTaken),.CU_intCLR(intCLR),.CU_csrWrite(csrWrite),.CU_prevINT(prev_INT));
    
    
    
    //CSR registers and interrupt logic
     //CSR CSRs(.clk(CLK),.rst(RESET),.intTaken(intTaken),.addr(IR[31:20]),.next_pc(pc),.wd(aluResult),.wr_en(csrWrite),
     //      .rd(csr_reg),.mepc(mepc),.mtvec(mtvec),.mie(mie));
    
    /*always_ff @ (posedge CLK)
    begin
         if(INTR && mie)
            prev_INT=1'b1;
         if(intCLR || RESET)
            prev_INT=1'b0;
    end(
    */
    
    //MMIO /////////////////////////////////////////////////////           
    assign IOBUS_ADDR = mem_addr_after_memory;  // CHANGED FROM aluResult TO mem_addr_after FOR PROGRAMMER
    assign IOBUS_OUT = mem_data_after_memory;  // CHANGED FROM B TO mem_data_after FOR PROGRAMMER 
    
    // tying left hand side of wires to left side of register
    always @(posedge CLK)
    begin
        fetch_to_decode[31:0]       = pc_fetch;
        fetch_to_decode[63:32]      = IR_fetch;
        
        decode_to_execute[31:0]     = pc_decode;
        decode_to_execute[63:32]    = I_immed_decode;  
        decode_to_execute[95:64]    = A_decode;        
        decode_to_execute[127:96]   = B_decode;        
        decode_to_execute[159:128]  = aluBin_decode;   
        decode_to_execute[191:160]  = aluAin_decode;   
        decode_to_execute[223:192]  = IR_decode;       
        decode_to_execute[224:224]  = regWrite_decode; 
        decode_to_execute[225:225]  = memWrite_decode; 
        decode_to_execute[226:226]  = memRead2_decode; 
        decode_to_execute[228:227]  = rf_wr_sel_decode;
        decode_to_execute[230:229]  = pcSource_decode; 
        decode_to_execute[232:231]  = alu_fun_decode;   

        execute_to_memory[31:0]     = pc_execute;
        execute_to_memory[63:32]    = branch_pc_execute;
        execute_to_memory[95:64]    = jump_pc_execute;  
        execute_to_memory[127:96]   = B_execute;        
        execute_to_memory[159:128]  = aluResult_execute;
        execute_to_memory[191:160]  = IR_execute;       
        execute_to_memory[223:192]  = regWrite_execute; 
        execute_to_memory[224:224]  = memWrite_execute; 
        execute_to_memory[225:225]  = memRead2_execute; 
        execute_to_memory[227:226]  = rf_wr_sel_execute;
        execute_to_memory[229:228]  = pcSource_execute;
        execute_to_memory[261:230]  = jalr_pc_execute;
        
        memory_to_writeback[31:0]     = pc_memory;
        memory_to_writeback[63:32]    = aluResult_memory;
        memory_to_writeback[95:64]    = dout2_memory;
        memory_to_writeback[127:96]   = IR_memory;
        memory_to_writeback[128:128]  = regWrite_memory;
        memory_to_writeback[130:129]  = rf_wr_sel_memory;    
        
    end

// tying left hand side of wires to left side of register
    
        assign pc_decode =  fetch_to_decode[31:0];
        assign IR_decode = fetch_to_decode[63:32];
        
        assign pc_execute           = decode_to_execute[31:0];
        assign I_immed_execute      = decode_to_execute[63:32];
        assign A_execute            = decode_to_execute[95:64];
        assign B_execute            = decode_to_execute[127:96];
        assign aluBin_execute       = decode_to_execute[159:128];
        assign aluAin_execute       = decode_to_execute[191:160];
        assign IR_execute           = decode_to_execute[223:192];
        assign regWrite_execute     = decode_to_execute[224:224];
        assign memWrite_execute     = decode_to_execute[225:225];
        assign memRead2_execute     = decode_to_execute[226:226];
        assign rf_wr_sel_execute    = decode_to_execute[228:227];
        assign pcSource_execute     = decode_to_execute[230:229];
        assign alu_fun_execute      = decode_to_execute[232:231];
                
        assign jump_pc_memory = execute_to_memory[95:64];
        assign branch_pc_memory = execute_to_memory[63:32];
        assign B_memory = execute_to_memory[127:96];
        assign pc_memory = execute_to_memory[31:0];
        assign aluResult_memory = execute_to_memory[159:128];
        assign IR_memory = execute_to_memory[191:160];
        assign regWrite_memory = execute_to_memory[223:192];
        assign memWrite_memory = execute_to_memory[224:224];        
        assign memRead2_memory = execute_to_memory[225:225];        
        assign rf_wr_sel_memory = execute_to_memory[227:226];
        assign pcSource_memory = execute_to_memory[229:228];        
        assign jalr_pc_memory = execute_to_memory[261:230];
        
        assign pc_writeback = memory_to_writeback[31:0];
        assign aluResult_writeback = memory_to_writeback[63:32];
        assign dout2_writeback = memory_to_writeback[95:64];
        assign IR_writeback = memory_to_writeback[127:96];
        assign regWrite_writeback = memory_to_writeback[128:128];
        assign rf_wr_sel_writeback = memory_to_writeback[130:129];

endmodule
