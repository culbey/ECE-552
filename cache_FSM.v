module cache_FSM(

    input clk,
    input rst,

    input rw,       // 0 for read, 1 for write
    input check,    // will be used as fetch for instr and MemRead/Write for data
    input mem_data_valid,
    input filled,

    input [15:0] addr,
    input [15:0] write_data,

    output miss,
    output hit,
    output [15:0] data_out

    // needs the address
    // needs to know if this is instr read or data read

    // need to output I_cache_stall and Mem_cache_stall
    // need to output mem/cache data if this is a mem read
    
);


/*
SHARED INSTR AND DATA MEM

Because the memory is shared we need to implement a buffer
- probably 1 slot for each instruction and data requests
- probably service data requests as first priority and then instruction
- need to stall based off if that stage has a memory request in the buffer
    - if there are 2 requests in parallel
        - service data request first since it is the furthest down the pipeline. If instruction goes first then the new data will have no where to go. Would have to wait at entrance to pipeline while data mem goes
        - if data mem goes first then, everything beyond fetch is ready to move to next stage. If there is a instr mem request, need to NOP the decode stage
*/

 /*
Insert cache and cache FSM and cache check

Instrstruction MEM:
addr/pc: stored in "pc"
instruction output from mem: store in "instr"

*/

/* GLOBAL SIGNALS */
wire even_hit, odd_hit;


/* STATE TRANSITION */
localparam IDLE  = 2'b00,
           CHECK  = 2'b01,
           MISS = 2'b10;

wire [1:0] state, nxt_state; // 0 - IDLE, 1 - LOAD

assign nxt_state =  ((state == IDLE) & check)       ?   CHECK    :   // in idle and detect a miss go to load
                    ((state == CHECK) & miss)       ?   MISS     :   // in load and we detect all chunks are loaded go to idle
                    ((state == MISS) & filled)      ?   CHECK    :   // in load and we detect all chunks are loaded go to idle
                    ((state == CHECK) & (hit))      ?   IDLE     :   // in load and we detect all chunks are loaded go to idle
                    state;                                                       // else stay in same state


dff state_ff[1:0] (.q(state), .d(nxt_state), .wen(1'b1), .clk(clk), .rst(rst));



/* CACHE */
wire [5:0] set, tag;
wire [3:0] block_offset;

assign tag = addr[15:10];
assign set = addr[9:4];
assign block_offset = addr[3:0];

wire [63:0] block_enable;
one_hot_encoder_64 set_encoder (
    .Shift_Val(set),
    .Shift_Out(block_enable)
);


wire [7:0] word_enable;
one_hot_encoder_8 block_encoder (
    .Shift_Val(block_offset[3:1]),  // last bit is for byte addressability
    .Shift_Out(word_enable)
);


// wire [63:0] curr_LRU, nxt_LRU;
// dff LRU_bits[63:0] (.q(curr_LRU), .d(nxt_LRU), .wen(en), .clk(clk), .rst(rst));

wire [7:0] even_meta_in, odd_meta_in, even_meta_out, odd_meta_out;
wire write_meta_even, write_meta_odd;

MetaDataArray even_metadata (
    .clk(clk),
    .rst(rst),
    .DataIn(even_meta_in),
    .Write(write_meta_even),
    .BlockEnable(block_enable),
    .DataOut(even_meta_out)
);

MetaDataArray odd_metadata (
    .clk(clk),
    .rst(rst),
    .DataIn(odd_meta_in),
    .Write(write_meta_odd),
    .BlockEnable(block_enable),
    .DataOut(odd_meta_out)
);


wire [15:0] even_data_in, odd_data_in, even_data_out, odd_data_out;
wire write_data_even, write_data_odd;

DataArray even_DataArray (
    .clk(clk),                  // Clock
    .rst(rst),                  // Reset
    .DataIn(even_data_in),            // Input data
    .Write(write_data_even),              // Write enable
    .BlockEnable(block_enable),  // Block enable signal
    .WordEnable(word_enable),    // Word enable signal
    .DataOut(even_data_out)       // Output data from even DataArray
);

// Instantiate the odd DataArray
DataArray odd_DataArray (
    .clk(clk),                  // Clock
    .rst(rst),                  // Reset
    .DataIn(odd_data_in),            // Input data
    .Write(write_data_odd),              // Write enable
    .BlockEnable(block_enable),  // Block enable signal
    .WordEnable(word_enable),    // Word enable signal
    .DataOut(odd_data_out)        // Output data from odd DataArray
);


assign even_hit = (state == CHECK) & (even_meta_out[7:2] === tag) & even_meta_out[1];
assign odd_hit = (state == CHECK) & (odd_meta_out[7:2] === tag) & odd_meta_out[1];

assign hit = (even_hit | odd_hit);
assign miss = ( ((state == CHECK) & ~hit) | (state == MISS));

assign write_meta_even = hit | filled;
assign write_meta_odd = (odd_hit & rw) | ((state == MISS) & filled & even_meta_out[0]);


assign even_meta_in =   ((rw & even_hit) | (filled & ~even_meta_out[0]))     ?   {tag, 1'b1, 1'b1}               :       // if the hit was even then ensure to update LRU bit and write the new tag
                        (~rw & even_hit)      ?   {even_meta_out[7:1], 1'b1}      :      // if the hit was even then update LRU and keep everything else the same
                        (odd_hit | (filled & even_meta_out[0]))              ?    {even_meta_out[7:1], 1'b0}      :
                        {8'h00};                                      // if the hit was odd then update LRU and keep everything else the same

assign odd_meta_in =    {tag, 1'b1, 1'b0};


assign write_data_even = (rw & even_hit) | ((state == MISS) & mem_data_valid & ~even_meta_out[0]);
assign write_data_odd = (rw & odd_hit) | ((state == MISS) & mem_data_valid & even_meta_out[0]);

assign even_data_in = write_data;
assign odd_data_in = write_data;

assign data_out = (even_hit) ? even_data_out : odd_data_out;


endmodule