module fac(
  input cin,
  input x,
  input y,
  output z,
  output cout
  );
  assign cout = x&y | x&cin | y&cin;
  assign z = x ^ y ^ cin;
endmodule

module rca #(
  parameter w = 16
)(
  input [w-1:0]x,
  input [w-1:0]y,
  input cin,
  output [w-1:0]z,
  output overflow,
  output cout
  );
  assign overflow = ~x[w-1]&~y[w-1]&z[w-1] | x[w-1]&y[w-1]&~z[w-1];
  wire [w-1:0]fac_cout;
  fac fac_init(
    .x(x[0]),
    .y(y[0]),
    .z(z[0]),
    .cin(cin),
    .cout(fac_cout[0])
    );
  genvar i;
  generate
      for (i = 1; i < w; i = i + 1) begin
        fac fac(
          .x(x[i]),
          .y(y[i]),
          .z(z[i]),
          .cin(fac_cout[i-1]),
          .cout(fac_cout[i])
        );
      end 
  endgenerate
  assign cout = fac_cout[w-1];
endmodule

module rca_tb;
  reg clk;
  reg [15:0] x;
  reg [15:0] y;
  reg cin;
  wire overflow;
  wire [15:0] z;
  wire cout;
  
  rca #(.w(16) ) rca_tb (
    .x(x),
    .y(y),
    .z(z),
    .cout(cout),
    .cin(cin),
    .overflow(overflow)
  );
  localparam CYCLES = 30, PERIOD = 100;
  initial begin
    clk = 0;
    repeat(CYCLES*2) begin
      #(PERIOD/2) 
      clk = ~clk;
      
    end
  end
  initial begin
    repeat(CYCLES) begin
      #(PERIOD)
      $display("%b %b %b | %b %b %b\n", x, y, cin, cout, z, overflow);
      $display("%d %d %d | %d %d %d\n\n", x, y, cin,cout, z, overflow);
    end
  end
  initial begin
    $display("x y cin | cout z overflow\n");
    cin = 0; 
    #(PERIOD)
    x = 50;
    y = 32;
    #(PERIOD)
    x = 14;
    y = 23;
    #(PERIOD)
    x = 1;
    y = 2;
    #(PERIOD)
    x = 256;
    y = 65535;
    
  end
endmodule