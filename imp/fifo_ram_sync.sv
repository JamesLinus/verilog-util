//-----------------------------------------------------------------------------
// Title         : A generic FIFO use RAM as storage
// Project       : Verilog Utilities
//-----------------------------------------------------------------------------
// File          : fifo_ram_sync.sv
// Author        : Wei Song  <wsong83@gmail.com>
// Created       : 28.08.2015
// Last modified : 28.08.2015
//-----------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Major modification history :
// 28.08.2015 : created
//-----------------------------------------------------------------------------

module fifo_ram_sync
  #(
    Depth = 16,                 // depth of the FIFO
    Width = 32                  // data width of the item being stored
    )
   (
    input logic clk, rstn,
    input logic write_valid,
    input logic [Width-1:0] write_data,
    output logic write_ready,
    output logic read_valid,
    output logic [Width-1:0] write_data,
    input logic read_ready
    );

   localparam DWidth = $clog2(Depth); // the width for read and write pointers

   // checking parameters
   initial begin
      assert(Depth == 2 ** DWidth, "Error: FIFO depth must be power of 2!");
   end

   // the RAM storage
   reg [Width-1:0] ram [Depth-1:0];
   logic [DWidth-1:0] read_pointer, write_pointer;
   
   // write control
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       write_pointer <= 0;
     else if(write_valid && write_ready) begin
        write_pointer <= write_pointer + 1;
        ram[write_pointer] <= write_data;
     end

   assign write_ready = write_valid && (write_pointer + 1 != read_pointer);

   // read control
   always_ff @(posedge clk or negedge rstn)
     if(!rstn)
       read_pointer <= 0;
     else if(read_valid && read_ready)
       read_pointer <= read_pointer + 1;

   assign read_data = ram[read_pointer];
   assign read_valid = write_pointer != read_pointer;
   
endmodule
