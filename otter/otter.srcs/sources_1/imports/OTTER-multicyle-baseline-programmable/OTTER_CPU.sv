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
                i_mhub_to_mmio.controller MMIO,
                input PROG_RX,  // ADDED PROG_RX FOR PROGRAMMER
                output PROG_TX,  // ADDED PROG_TX FOR PROGRAMMER
                //DEBUG OUTPUTS
                output [31:0]DEBUG
);           

    // ************************ BEGIN PROGRAMMER ************************ 
    
    logic [31:0] counter = 0;
    
    wire RESET;
    wire [31:0] s_prog_ram_addr;
    wire [31:0] s_prog_ram_data;
    wire s_prog_ram_we;
    wire s_prog_mcu_reset;
    
    wire [31:0] mem_addr_after_memory;
    wire [31:0] mem_addr_after_writeback;

    wire [31:0] mem_data_after_memory;
    
    wire [1:0] mem_size_after_memory;
    
    wire mem_sign_after_memory;
    
    wire mem_we_after_memory;

    // HAZARD PREVENTION //
    logic [32:0] stall = 0;
    logic pc_write_cont = 1;
    wire pc_write_data;
    logic pc_write_dep = 1;
    logic was_dependency = 0;
    logic dependency_exists = 0;
    //********************//

    // PIPELINE REGISTERS //
    logic [31:0] delayed_pc_fetch = 0;
    wire [31:0] pc_fetch;
    logic [235:0] decode_to_execute = 0;
    logic [262:0] execute_to_memory = 0;
    logic [133:0] memory_to_writeback = 0;
    //********************//
    wire [6:0] opcode_pre_decode;
    wire [6:0] opcode_decode;
    wire [6:0] opcode_execute;
    wire [6:0] opcode_memory;
    wire [6:0] opcode_writeback;
    
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
    logic [31:0] dout2_memory_delayed = 0;    
    wire [31:0] dout2_writeback;
    
    wire [31:0] IR_pre_decode;
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
    wire memRead1_fetch_data;
    logic memRead1_fetch_dep = 1;
    logic memRead1_fetch_cont=1;
    
    
    wire pcWrite_fetch;
    
    wire alu_srcA_decode;

    wire [1:0] alu_srcB_decode;
   
    wire [1:0] rf_wr_sel_decode;
    wire [1:0] rf_wr_sel_execute;
    wire [1:0] rf_wr_sel_memory;
    wire [1:0] rf_wr_sel_writeback;
    
    wire [2:0] pcSource_decode;
    wire [2:0] pcSource_execute;
    wire [2:0] pcSource_memory;
    wire [2:0] pcSource_writeback;
    
    wire [3:0] alu_fun_decode;
    wire [3:0] alu_fun_execute;
    //DEBUG DECLARATIONS
    assign DEBUG = pc_decode;
    logic dependency_reason = 0;
    logic jump_reason = 0;
    logic branch_reason = 0;
    
    // CONTROL HAZARD PREVENTION //
    always @(posedge CLK)
    begin
        if(!s_stall)
        begin
        
        if( IR_decode[6:0] == 7'b1101111 || 
            IR_decode[6:0] == 7'b1100111 ||
            IR_decode[6:0] == 7'b1100011 ||
            dependency_exists)
            begin
                memRead1_fetch_dep = 0;
                pc_write_dep = 0;              
                memRead1_fetch_cont <= 0;
                pc_write_cont <= 0;
                    
                if(dependency_exists)
                    begin
                        was_dependency <= 1;
                        stall <= 1; //3
                    end
                else
                    begin
                        stall <= 2;
                    end
            end
        else if (stall > 2)
            begin
                stall <= stall - 1;
            end
        else if (stall == 2 && !was_dependency)
            begin
                pc_write_cont <= 1;
                stall <= 1;
            end
        else if (stall == 2 && was_dependency)
            begin
                stall <= 1;
            end            
        else if (stall == 1 && !was_dependency)
            begin
                memRead1_fetch_cont <= 1;
                stall <= 0;
            end
        else if(stall == 1 && was_dependency)
            begin
                memRead1_fetch_cont <= 1;
                pc_write_cont <= 1;
                stall <= 0;
                was_dependency <= 0;
                memRead1_fetch_dep = 1;
                pc_write_dep = 1;
            end
        else
            begin
                memRead1_fetch_dep = 0;
                pc_write_dep = 0;            
                stall <= 0;
            end
        end
    end
    
    //GENERAL HAZARD PREVENTION
    assign IR_decode = (stall>0 || dependency_exists || pcSource_writeback != 0)? 19 : IR_pre_decode;
    assign pcWrite_fetch = pc_write_dep || (pc_write_cont && pc_write_data);
    assign opcode_pre_decode = IR_pre_decode[6:0];
    // DATA HAZARD PREVENTION //
    
    assign pc_write_data = ~dependency_exists &&
                                  !(opcode_decode == 7'b1101111 ||
                                    opcode_decode == 7'b1100111 ||
                                    opcode_decode == 7'b1100011);
                                  
    assign memRead1_fetch_data = ~dependency_exists &&
                                  !(opcode_decode == 7'b1101111 ||
                                    opcode_decode == 7'b1100111 ||
                                    opcode_decode == 7'b1100011);
    
    assign memRead1_fetch = (memRead1_fetch_data && memRead1_fetch_cont ) || memRead1_fetch_dep;
    always @*
    begin
        if(opcode_pre_decode != 7'b0110111 && opcode_pre_decode != 7'b0010111 && opcode_pre_decode != 7'b1101111)
            begin
                if( opcode_execute == 7'b0110111 ||
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
                         if(opcode_pre_decode == 7'b1100011 ||
                            opcode_pre_decode == 7'b0100011 ||
                            opcode_pre_decode == 7'b0110011)
                            begin
                                if( (IR_pre_decode[24:20] == IR_execute[11:7]   && IR_pre_decode[24:20]  != 0)|| 
                                    (IR_pre_decode[19:15] == IR_execute[11:7]   && IR_pre_decode[19:15]  != 0)|| 
                                    (IR_pre_decode[24:20] == IR_memory[11:7]    && IR_pre_decode[24:20]  != 0)|| 
                                    (IR_pre_decode[19:15] == IR_memory[11:7]    && IR_pre_decode[19:15]  != 0)|| 
                                    (IR_pre_decode[24:20] == IR_writeback[11:7] && IR_pre_decode[24:20]  != 0)|| 
                                    (IR_pre_decode[19:15] == IR_writeback[11:7] && IR_pre_decode[19:15]  != 0))
                                    begin
                                        dependency_exists <= 1;
                                    end
                                else
                                    begin
                                        dependency_exists <= 0;
                                    end
                            end
                         else
                            begin
                                if( (IR_pre_decode[19:15] == IR_execute[11:7]   && IR_pre_decode[19:15]  != 0)|| 
                                    (IR_pre_decode[19:15] == IR_memory[11:7]    && IR_pre_decode[19:15]  != 0)|| 
                                    (IR_pre_decode[19:15] == IR_writeback[11:7] && IR_pre_decode[19:15]  != 0))
                                    begin
                                        dependency_exists <= 1;
                                    end
                                else
                                    begin
                                        dependency_exists <= 0;
                                    end
                            end
                    end

                else
                    begin
                        dependency_exists <= 0;
                    end
            end
        else
            begin
                dependency_exists <= 0;
            end
    end

    //wire mepcWrite, csrWrite,intCLR, mie, intTaken;
    //wire [31:0] mepc, mtvec;
       
    assign opcode_decode = IR_decode[6:0]; // opcode shortcut
    assign opcode_execute  = IR_execute[6:0];
    assign opcode_memory  = IR_memory[6:0];
    assign opcode_writeback  = IR_writeback[6:0];
    //PC is byte-addressed but our memory is word addressed 
    ProgCount PC (.PC_CLK(CLK), .PC_RST(RESET), .PC_LD(pcWrite_fetch),
                 .PC_DIN(pc_value_fetch), .PC_COUNT(pc_fetch), .s_stall(s_stall));   
    
    // Creates a 5-to-1 multiplexor used to select the source of the next PC
    Mult5to1 PCdatasrc (next_pc_fetch, jalr_pc_memory, branch_pc_memory, jump_pc_memory, pc_memory+4, pcSource_memory, pc_value_fetch);
    // Creates a 4-to-1 multiplexor used to select the B input of the ALU
    Mult4to1 ALUBinput (B_decode, I_immed_decode, S_immed_decode, pc_decode, alu_srcB_decode, aluBin_decode);
    
    Mult2to1 ALUAinput (A_decode, U_immed_decode, alu_srcA_decode, aluAin_decode);
    // Creates a RISC-V ALU
    // Inputs are ALUCtl (the ALU control), ALU value inputs (ALUAin, ALUBin)
    // Outputs are ALUResultOut (the 64-bit output) and Zero (zero detection output)
    OTTER_ALU ALU (alu_fun_execute, aluAin_execute, aluBin_execute, aluResult_execute); // the ALU
    
    // Creates a RISC-V register file
    OTTER_registerFile RF (IR_decode[19:15], IR_decode[24:20], IR_writeback[11:7], wd_writeback, regWrite_writeback, A_decode, B_decode, CLK, s_stall); // Register file
 
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

    assign mem_addr_after_memory = /*s_prog_ram_we ? s_prog_ram_addr : */aluResult_memory;  // 2:1 mux
    assign mem_data_after_memory = /*s_prog_ram_we ? s_prog_ram_data : */B_memory;  // 2:1 mux
    assign mem_size_after_memory =/* s_prog_ram_we ? 2'b10 : */IR_memory[13:12];  // 2:1 mux
    assign mem_sign_after_memory =/* s_prog_ram_we ? 1'b0 : */IR_memory[14];  // 2:1 mux
    assign mem_we_after_memory =/* s_prog_ram_we | */memWrite_memory;  // or gate
    assign RESET = s_prog_mcu_reset | EXT_RESET;  // or gate

    // ************************ END PROGRAMMER ************************               
     
     OTTER_CU_Decoder CU_DECODER(.CU_OPCODE(opcode_decode), .CU_FUNC3(IR_decode[14:12]),.CU_FUNC7(IR_decode[31:25]), 
             .CU_BR_EQ(br_eq),.CU_BR_LT(br_lt),.CU_BR_LTU(br_ltu),.CU_PCSOURCE(pcSource_decode),
             .CU_ALU_SRCA(alu_srcA_decode),.CU_ALU_SRCB(alu_srcB_decode),.CU_ALU_FUN(alu_fun_decode),.CU_RF_WR_SEL(rf_wr_sel_decode));//,.intTaken(intTaken));
            
     //logic prev_INT=0;
     
     OTTER_CU_FSM CU_FSM (/*.CU_CLK(CLK),.CU_INT(INTR),*/ .CU_RESET(RESET), .CU_OPCODE(opcode_decode), //.CU_OPCODE(opcode),
                     .CU_FUNC3(IR_decode[14:12]),.CU_FUNC12(IR_decode[31:20]),
                     .CU_REGWRITE(regWrite_decode), .CU_MEMWRITE(memWrite_decode), 
                     .CU_MEMREAD2(memRead2_decode));//.CU_intTaken(intTaken),.CU_intCLR(intCLR),.CU_csrWrite(csrWrite),.CU_prevINT(prev_INT));
    
    
    
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
        if(!s_stall)
        begin
        
        counter <= counter + 1;
        dout2_memory_delayed <= dout2_memory;
        if(memRead1_fetch)
            delayed_pc_fetch <= pc_fetch;
        
        decode_to_execute[31:0]     <= pc_decode;
        decode_to_execute[63:32]    <= I_immed_decode;  
        decode_to_execute[95:64]    <= A_decode;        
        decode_to_execute[127:96]   <= B_decode;        
        decode_to_execute[159:128]  <= aluBin_decode;   
        decode_to_execute[191:160]  <= aluAin_decode;   
        decode_to_execute[223:192]  <= IR_decode;       
        decode_to_execute[224:224]  <= regWrite_decode; 
        decode_to_execute[225:225]  <= memWrite_decode; 
        decode_to_execute[226:226]  <= memRead2_decode; 
        decode_to_execute[228:227]  <= rf_wr_sel_decode;
        decode_to_execute[231:229]  <= pcSource_decode; 
        decode_to_execute[235:232]  <= alu_fun_decode;   

        execute_to_memory[31:0]     <= pc_execute;
        execute_to_memory[63:32]    <= branch_pc_execute;
        execute_to_memory[95:64]    <= jump_pc_execute;  
        execute_to_memory[127:96]   <= B_execute;        
        execute_to_memory[159:128]  <= aluResult_execute;
        execute_to_memory[191:160]  <= IR_execute;       
        execute_to_memory[223:192]  <= regWrite_execute; 
        execute_to_memory[224:224]  <= memWrite_execute; 
        execute_to_memory[225:225]  <= memRead2_execute; 
        execute_to_memory[227:226]  <= rf_wr_sel_execute;
        execute_to_memory[230:228]  <= pcSource_execute;
        execute_to_memory[262:231]  <= jalr_pc_execute;
        
        memory_to_writeback[31:0]     <= pc_memory;
        memory_to_writeback[63:32]    <= aluResult_memory;
        memory_to_writeback[95:64]   <= IR_memory;
        memory_to_writeback[96:96]  <= regWrite_memory;
        memory_to_writeback[98:97]  <= rf_wr_sel_memory;
        memory_to_writeback[101:99]  <= pcSource_memory;
        memory_to_writeback[133:102]  <= mem_addr_after_memory;
                //memory_to_writeback[165:134]<= dout2_memory;
        end
    end
    
    always_comb
    begin
    end
// tying left hand side of wires to left side of register
    
        assign pc_decode =  delayed_pc_fetch;
                
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
        assign pcSource_execute     = decode_to_execute[231:229];
        assign alu_fun_execute      = decode_to_execute[235:232];
                
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
        assign pcSource_memory = execute_to_memory[230:228];        
        assign jalr_pc_memory = execute_to_memory[262:231];
        
        assign pc_writeback = memory_to_writeback[31:0];
        assign aluResult_writeback = memory_to_writeback[63:32];
        assign IR_writeback = memory_to_writeback[95:64];
        assign regWrite_writeback = memory_to_writeback[96:96];
        assign rf_wr_sel_writeback = memory_to_writeback[98:97];
        assign pcSource_writeback = memory_to_writeback[101:99];
        assign mem_addr_after_writeback = memory_to_writeback[133:102];
        assign dout2_writeback = dout2_memory;
        
        
        
        // ADDED NEW VLM SYSTEM BELOW         
                           
        /*OTTER_mem_byte #(14) memory  (.MEM_CLK(CLK),.MEM_ADDR1(pc_fetch),.MEM_ADDR2(mem_addr_after_memory),.MEM_DIN2(mem_data_after_memory),
                                   .MEM_WRITE2(mem_we_after_memory),.MEM_READ1(memRead1_fetch),.MEM_READ2(memRead2_memory),
                                   .ERR(),.MEM_DOUT1(IR_pre_decode),.MEM_DOUT2(dout2_memory),.IO_IN(IOBUS_IN),.IO_WR(IOBUS_WR),.MEM_SIZE(mem_size_after_memory),.MEM_SIGN(mem_sign_after_memory));*/
        // ^ CHANGED aluResult to mem_addr_after FOR PROGRAMMER
        // ^ CHANGED B to mem_data_after FOR PROGRAMMER
        // ^ CHANGED memWrite to mem_we_after FOR PROGRAMMER
        // ^ CHANGED IR[13:12] to mem_size_after FOR PROGRAMMER
        // ^ CHANGED IR[14] to mem_sign_after FOR PROGRAMMER
        
        /*programmer #(.CLK_RATE(50), .BAUD(115200), .IB_TIMEOUT(200),
                 .WAIT_TIMEOUT(500))
        programmer(.clk(CLK), .rst(EXT_RESET), .srx(PROG_RX), .stx(PROG_TX),
                   .mcu_reset(s_prog_mcu_reset), .ram_addr(s_prog_ram_addr),
                   .ram_data(s_prog_ram_data), .ram_we(s_prog_ram_we));*/

        // ************************ END PROGRAMMER ************************ 

        i_cpui_to_mhub s_cpui();
        i_cpud_to_mhub s_cpud();
        i_prog_to_mhub s_prog();
        i_mhub_to_mmio s_mmio();
        i_mhub_to_icache s_mhub_to_icache();
        i_mhub_to_dcache s_mhub_to_dcache();
        i_icache_to_ram s_icache_to_ram();
        i_dcache_to_ram s_dcache_to_ram();
        
        programmer #(
            .CLK_RATE(50), .BAUD(115200), .IB_TIMEOUT(200), .WAIT_TIMEOUT(500)
        ) programmer (
            .clk(CLK), .rst(EXT_RESET), .srx(PROG_RX), .stx(PROG_TX),
            .mcu_reset(s_prog_mcu_reset), .mhub(s_prog)
        );
        memory_hub mhub(
            .clk(CLK), .err(), .cpui(s_cpui), .cpud(s_cpud), .prog(s_prog),
            .mmio(MMIO), .icache(s_mhub_to_icache), .dcache(s_mhub_to_dcache)
        );
        icache icache(
            .clk(CLK), .mhub(s_mhub_to_icache), .ram(s_icache_to_ram)
        );
        dcache dcache(
            .clk(CLK), .mhub(s_mhub_to_dcache), .ram(s_dcache_to_ram)
        );
        slow_ram #(
            .RAM_DEPTH(2**12),  // 4096 blocks * 16 bytes/block = 64KiB 
            .INIT_FILENAME("otter_memory_blocks.mem")  // load 16-byte blocks
        ) ram (
            .clk(CLK), .icache(s_icache_to_ram), .dcache(s_dcache_to_ram)
        );
        
        assign s_cpui.addr = pc_fetch;
        assign s_cpui.en = memRead1_fetch;
        assign IR_pre_decode = s_cpui.dout;
        
        assign s_cpud.addr = mem_addr_after_memory;
        assign s_cpud.size = mem_size_after_memory;
        assign s_cpud.lu = mem_sign_after_memory;
        assign s_cpud.en = memRead2_memory || mem_we_after_memory;
        assign s_cpud.we = mem_we_after_memory;
        assign s_cpud.din = mem_data_after_memory;
        assign dout2_writeback = s_cpud.dout;
        
        assign s_stall = s_cpui.hold || s_cpud.hold;
        
endmodule
