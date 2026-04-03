`ifndef FUNCTION_CALLS_SV
`define FUNCTION_CALLS_SV

function automatic logic [31:0] twos_comp32(input logic [31:0] x);
  twos_comp32 = (~x) + 32'd1;
endfunction

`endif // DATAPATH_PIPELINED_SV
