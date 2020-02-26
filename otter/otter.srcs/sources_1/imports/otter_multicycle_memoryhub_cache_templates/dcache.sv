`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Keefe Johnson
// 
// Create Date: 02/06/2020 06:40:37 PM
// Updated Date: 02/13/2020 11:00:00 AM
// Design Name: 
// Module Name: dcache
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


import memory_bus_sizes::*;

module dcache(
    input clk,
    i_mhub_to_dcache.device mhub, //output waddr, be, en, we, flush, din, input  dout, hold
    i_dcache_to_ram.controller ram
    );
    
    parameter int TAG_MSB = 31;
    parameter int TAG_LSB = 12;
    parameter int BLOCK_INDEX_MSB = 11;
    parameter int BLOCK_INDEX_LSB = 4;
    parameter int WORD_INDEX_MSB = 3;
    parameter int WORD_INDEX_LSB = 2;
    parameter int idle = 0;
    parameter int write_to_ram = 1;
    parameter int read_from_ram = 2;
    parameter int store_and_output = 3;
    
     typedef logic [127:0] cache_data_type;

    logic [2:0] state=0;
    
    cache_data_type cache_mem[255:0];
    
    typedef struct packed{
        logic valid;
        logic dirty;
        logic [TAG_MSB:TAG_LSB] tag;
    }cache_tag_type;
    //typedef logic[21:0] cache_tag_type;
    cache_tag_type tag_mem[255:0]; 
    
    wire [BLOCK_INDEX_MSB: BLOCK_INDEX_LSB] block_index = mhub.waddr[BLOCK_INDEX_MSB: BLOCK_INDEX_LSB];
    wire [WORD_INDEX_MSB: WORD_INDEX_LSB] word_index = mhub.waddr[WORD_INDEX_MSB: WORD_INDEX_LSB];
    
    wire hit = (tag_mem[block_index].tag == mhub.waddr[TAG_MSB:TAG_LSB] && tag_mem[block_index].valid);

    initial begin
        for (int i = 0; i < 256; i++) begin
            tag_mem[i].dirty = 0;
            tag_mem[i].valid = 0;
            tag_mem[i].tag = 0;
        end
    end
    //FSM
    always @(posedge(clk))
    begin

        case (state) 
            idle            :begin
                                if(!mhub.en)
                                    state <= idle;
                                else if(mhub.en && hit && !mhub.we)
                                begin
                                    mhub.dout <= cache_mem[block_index][word_index*32+:32];
                                    state <= idle;
                                end 
                                else if(mhub.en && hit && mhub.we)
                                begin
                                    if(mhub.be[0])
                                        cache_mem[block_index][word_index*32+:8] <= mhub.din[7:0];
                                    if(mhub.be[1])
                                        cache_mem[block_index][word_index*32+8+:8] <= mhub.din[15:8];
                                    if(mhub.be[2])
                                        cache_mem[block_index][word_index*32+16+:8] <= mhub.din[23:16];
                                    if(mhub.be[3])
                                        cache_mem[block_index][word_index*32+24+:8] <= mhub.din[31:24];
                                    
                                    /*cache_mem[block_index][word_index*32+:8] <= ~({mhub.be[0], mhub.be[0], mhub.be[0], mhub.be[0], mhub.be[0], mhub.be[0], mhub.be[0], mhub.be[0]} & ~); 
                                    cache_mem[block_index][word_index*32+8+:8] <= ~({mhub.be[1], mhub.be[1], mhub.be[1], mhub.be[1], mhub.be[1], mhub.be[1], mhub.be[1], mhub.be[1]} & ~mhub.din[15:8]); 
                                    cache_mem[block_index][word_index*32+16+:8] <= ~({mhub.be[2], mhub.be[2], mhub.be[2], mhub.be[2], mhub.be[2], mhub.be[2], mhub.be[2], mhub.be[2]} & ~mhub.din[23:16]); 
                                    cache_mem[block_index][word_index*32+24+:8] <= ~({mhub.be[3], mhub.be[3], mhub.be[3], mhub.be[3], mhub.be[3], mhub.be[3], mhub.be[3], mhub.be[3]} & ~mhub.din[31:24]); */
                                    tag_mem[block_index].dirty = 1;
                                    state <= idle;
                                end
                                else if(mhub.en && !hit && tag_mem[block_index].dirty)
                                begin
                                    ram.din <= cache_mem[block_index];
                                    state <= write_to_ram;
                                end
                                else if(!hit && !tag_mem[block_index].dirty && mhub.en)
                                    state <= read_from_ram;
                                else
                                    state <= idle;
                             end
            write_to_ram    :begin
                                if(!ram.hold)
                                begin
                                    state <= read_from_ram;
                                    tag_mem[block_index].dirty <= 0;
                                end
                                else
                                    state <= write_to_ram;
                             end
            read_from_ram   :begin
                                if(!ram.hold)
                                    state <= store_and_output;
                                else
                                    state <= read_from_ram;
                             end
            store_and_output:begin
                                state <= idle;
                                cache_mem[block_index] <= ram.dout;
                                tag_mem[block_index].dirty <= 0;
                                tag_mem[block_index].valid <= 1;
                                tag_mem[block_index].tag = mhub.waddr[TAG_MSB:TAG_LSB];
                             end
            default         : state <= idle;
        endcase
        
    end
    
    always_comb
    begin
        if(state == idle)
        begin
            mhub.hold = mhub.en && !hit;
            ram.en = 0;
        end
        else if(state == write_to_ram)
        begin
            mhub.hold = 1;
            ram.en = 1;
            ram.we = 1;
            ram.baddr[TAG_MSB:BLOCK_INDEX_LSB] = {tag_mem[block_index].tag[TAG_MSB:TAG_LSB], block_index};
        end
        else if(state == read_from_ram)
        begin
            mhub.hold = 1;
            ram.en = 1;
            ram.we = 0;
            ram.baddr[TAG_MSB:BLOCK_INDEX_LSB] = mhub.waddr[TAG_MSB:BLOCK_INDEX_LSB];
        end
        else if(state == store_and_output)
        begin
            mhub.hold = 1;
            ram.en = 0;
        end
    end
    
endmodule
