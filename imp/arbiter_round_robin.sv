//-----------------------------------------------------------------------------
// Title         : A generic round-robin arbiter
// Project       : Verilog Utilities
//-----------------------------------------------------------------------------
// File          : arbiter_round_robin.sv
// Author        : Wei Song  <wsong83@gmail.com>
// Created       : 28.08.2015
// Last modified : 28.08.2015
//-----------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Major modification history :
// 28.08.2015 : created
//-----------------------------------------------------------------------------

module arbiter_round_robin
  #(
    Port = 2,                   // number of port
    Width = 32                  // data width of ports
    )
   (
    input logic clk, rstn,
    input logic [Port-1:0] in_valid,
    input logic [Port-1:0][Width-1:0] in_data,
    output logic [Port-1:0] in_ready,
    output logic [Port-1:0] out_valid,
    output logic [Width-1:0] out_data,
    input logic [Port-1:0] out_ready
    );

   logic [Port*2-1:0]     valid_state;  // current valid state from inputs
   logic [Port*2-1:0]     valid_enable; // picking the valid that can be granted
   logic [Port*2-1:0]     valid_avail;  // picking the valid that can be granted and current outstanding
   logic [Port*2-1:0]     valid_sel;    // picking up the valid with the highest priority 
   logic [Port*2-1:0]     last_grant;   // the port being granted last time
   logic [Port-1:0]       grant;        // the current grant
   logic                  hold;         // hold the current stat
   
   genvar                 i, j;

   assign valid_state = {in_valid, in_valid};
   assign valid_avail = valid_state & valid_enable;
   
   generate for (i=0; i<Port*2; i++) begin
      assign valid_enable[i] = i == 0 ? 0 : (valid_enable[i-1] || last_grant[i-1]);
      assign valid_sel[i] = i == 0 ? 0 : valid_avail[i] && ~|valid_avail[i-1:0];
   end
   endgenerate

   always_ff @(posedge clk or negedge rstn)
      if(!rstn)
        hold <= 0;
      else if(out_valid)
        hold <= !out_ready;

   always_ff @(posedge clk or negedge rstn)
      if(!rstn)
        last_grant <= 0;
      else if(out_valid)
        last_grant <= {{{Port}{1'b0}}, grant};

   assign grant = hold ? last_grant : valid_sel[2*Port-1:Port] | valid_sel[Port-1:0];

   logic [Port-1:0][Width-1:0] data_ord;
   logic [Width-1:0][Port-1:0] data_shuffle;
   
   generate 
      for (i=0; i<Port*2; i++) begin
         assign data_ord[i] = grant[i] ? 0 : in_data[i];
         assign in_ready[i] = grant[i] && out_ready;
         for (j=0; j<Width; j++) begin
            assign data_shuffle[j][i] = data_ord[i][j];
         end
      end
      for (j=0; j<Width; j++) begin
         assign out_data[j] = |data_shuffle[j];
      end
   endgenerate

   assign out_valid = |grant;

endmodule // arbiter_round_robin
