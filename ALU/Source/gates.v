module word_xor#(
    parameter w = 16
  )(
    input [w-1:0]x,
    input [w-1:0]y,
    output [w-1:0]z
  );
  genvar i;
  generate
    for(i = 0; i < w; i = i+1) begin
      assign z[i] = x[i] ^ y[i];
    end
  endgenerate
endmodule

module word_and#(
    parameter w = 16
  )(
    input [w-1:0]x,
    input [w-1:0]y,
    output [w-1:0]z
  );
  genvar i;
  generate
    for(i = 0; i < w; i = i+1) begin
      assign z[i] = x[i] & y[i];
    end
  endgenerate
endmodule

module word_or#(
    parameter w = 16
  )(
    input [w-1:0]x,
    input [w-1:0]y,
    output [w-1:0]z
  );
  genvar i;
  generate
    for(i = 0; i < w; i = i+1) begin
      assign z[i] = x[i] | y[i];
    end
  endgenerate
endmodule