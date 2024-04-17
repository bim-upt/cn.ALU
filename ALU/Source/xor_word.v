//invert x if y
module xor_word #(
  parameter w = 16
  )(
  input [w-1:0]x,
  input y,
  output [w-1:0]z
  );
  genvar i;
  generate
    for(i = 0; i < w; i = i +1) begin
      assign z[i] = x[i]^y;
    end
  endgenerate
endmodule

module xor_word_tb;
  reg [15:0]x;
  reg y;
  wire [15:0]z;
  xor_word #(.w(16)) xor_word (
    .x(x),
    .y(y),
    .z(z)
    );
  initial begin
    $display("x y | z\n");
    x = 50;
    y = 0;
    #30
    $display("%b %b | %b\n", x, y, z);
    y = 1;
    x = 13;
    #30
    $display("%b %b | %b\n", x, y, z);
    x = 2;
    y = 0;
    #30
    $display("%b %b | %b\n", x, y, z);
  end
endmodule