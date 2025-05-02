module cache_fill_FSM(
    input clk,
    input rst,

    input dmiss,
    input imiss,

    input [15:0] miss_address,
    input memory_data_valid,

    output I_busy,
    output D_busy,

    output I_write_data,
    output D_write_data,

    output I_filled,
    output D_filled,

    output [15:0] memory_in_address,
    output [15:0] memory_out_address,

    output all_mem_sent

);

/* STATE TRANSITION */
localparam IDLE  = 2'b00,
           FILL_I  = 2'b01,
           FILL_D = 2'b10;

wire [1:0] state, nxt_state; // 0 - IDLE, 1 - LOAD

assign nxt_state =  ((state == IDLE) & dmiss)       ?   FILL_D    :   // in idle and detect a miss go to load
                    ((state == IDLE) & imiss)       ?   FILL_I    :   // in load and we detect all chunks are loaded go to idle
                    ((state == FILL_D) & D_filled)  ?   IDLE      :   // in load and we detect all chunks are loaded go to idle
                    ((state == FILL_I) & I_filled)  ?   IDLE      :   // in load and we detect all chunks are loaded go to idle
                    state;                                                       // else stay in same state


dff state_ff[1:0] (.q(state), .d(nxt_state), .wen(1'b1), .clk(clk), .rst(rst));



/* Mem Addr Incrementer */
wire count_full_addr, increment_addr, all_mem_recieved;
wire [3:0] counter_val_addr, inc_counter_addr;

assign count_full_addr = (counter_val_addr[3]) ;  // clear the counter on a reset or if the counter is at 7 and we have our last valid data
assign increment_addr = ((state == FILL_D) | (state == FILL_I)) & ~count_full_addr;  // increment the counter when we have valid mem data and we are in the load state;

CLA_4bit incrementer1(.A(counter_val_addr), .B(4'h1), .Cin(1'b0), .Sum(inc_counter_addr), .Cout(/* UNCONNECTED */), .overflow( /* UNCONNECTED */ ));
dff inc_ff[3:0] (.q(counter_val_addr), .d(inc_counter_addr), .wen(increment_addr), .clk(clk), .rst(all_mem_recieved | rst));


/* Valid Memory Data Counter */
wire increment;
wire [3:0] counter_val, inc_counter;

assign all_mem_recieved = (&counter_val[2:0] & memory_data_valid);  // clear the counter on a reset or if the counter is at 7 and we have our last valid data
assign increment = ((state == FILL_D) | (state == FILL_I)) & memory_data_valid;  // increment the counter when we have valid mem data and we are in the load state;

CLA_4bit incrementer2(.A(counter_val), .B(4'h1), .Cin(1'b0), .Sum(inc_counter), .Cout(/* UNCONNECTED */), .overflow( /* UNCONNECTED */ ));
dff inc_ff2[3:0] (.q(counter_val), .d(inc_counter), .wen(increment), .clk(clk), .rst(all_mem_recieved | rst));






assign memory_in_address = {miss_address[15:4], counter_val_addr[2:0], 1'b0}; // block # + counter * 2
assign memory_out_address = {miss_address[15:4], counter_val[2:0], 1'b0}; // block # + counter * 2


assign I_busy = state == FILL_I;                 // fsm is busy while we are in the load state
assign D_busy = state == FILL_D;                 // fsm is busy while we are in the load state

assign I_write_data = (state == FILL_I) & (memory_data_valid);
assign D_write_data = (state == FILL_D) & (memory_data_valid);

assign I_filled = (state == FILL_I) & (all_mem_recieved);
assign D_filled = (state == FILL_D) & (all_mem_recieved);

assign all_mem_sent = (state != IDLE) & count_full_addr;


endmodule