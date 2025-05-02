module cache(

input clk,
input rst,

input [15:0] addr,
input [15:0] data_in,
input write,

output [15:0] data,
output hit

);










// turn into state machine where right after valid read we need to update 
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




wire [63:0] curr_LRU, nxt_LRU;
dff LRU_bits[63:0] (.q(curr_LRU), .d(nxt_LRU), .wen(en), .clk(clk), .rst(rst));



MetaDataArray even_metadata (
    .clk(clk),
    .rst(rst),
    .DataIn(DataIn_even),
    .Write(Write_even),
    .BlockEnable(BlockEnable_even),
    .DataOut(DataOut_even)
);

MetaDataArray odd_metadata (
    .clk(clk),
    .rst(rst),
    .DataIn(DataIn_odd),
    .Write(Write_odd),
    .BlockEnable(BlockEnable_odd),
    .DataOut(DataOut_odd)
);

MetaDataArray(input clk, input rst, input [7:0] DataIn, input Write, input [63:0] BlockEnable, output [7:0] DataOut);

DataArray even_DataArray (
    .clk(clk),                  // Clock
    .rst(rst),                  // Reset
    .DataIn(DataIn),            // Input data
    .Write(Write),              // Write enable
    .BlockEnable(BlockEnable),  // Block enable signal
    .WordEnable(WordEnable),    // Word enable signal
    .DataOut(EvenDataOut)       // Output data from even DataArray
);

// Instantiate the odd DataArray
DataArray odd_DataArray (
    .clk(clk),                  // Clock
    .rst(rst),                  // Reset
    .DataIn(DataIn),            // Input data
    .Write(Write),              // Write enable
    .BlockEnable(BlockEnable),  // Block enable signal
    .WordEnable(WordEnable),    // Word enable signal
    .DataOut(OddDataOut)        // Output data from odd DataArray
);

DataArray(input clk, input rst, input [15:0] DataIn, input Write, input [63:0] BlockEnable, input [7:0] WordEnable, output [15:0] DataOut);


endmodule