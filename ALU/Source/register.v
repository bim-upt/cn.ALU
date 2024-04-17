module rgst_no_shift #(
    parameter w=16
)(
    input clk,
    input rst_b, 
    input clr,
    input [w-1:0] d,
    output wire [w-1:0] q
);
    genvar i;
    generate
      for (i = 0; i < w; i = i + 1) begin
        bist bist(
          .clk(clk),
          .rst_b(rst_b),
          .clr(clr),
          .d(d[i]),
          .q(q[i])
        );
      end 
    endgenerate
endmodule



module mux_4 #(
  parameter w=16
)(
  input [w-1:0]d0,
  input [w-1:0]d1,
  input [w-1:0]d2,
  input [w-1:0]d3,
  input [1:0]s,
  output [w-1:0]q
  );
  assign q = ( ~s[1] & ~s[0]) ? d0: {w{1'bz}};
  assign q = ( ~s[1] & s[0]) ? d1: {w{1'bz}};
  assign q = ( s[1] & ~s[0]) ? d2: {w{1'bz}};
  assign q = ( s[1] & s[0]) ? d3: {w{1'bz}};
endmodule

//at each clk load in output what was in input, clr => output is 0 and has priority over normal operation
//rst_b is asyncron reset, rst_b == 0 => reset
module bist(
  input clk,
  input rst_b,
  input clr,
  input d,
  output reg q);
  
  always @ (posedge clk, negedge rst_b)
        if (!rst_b)                 q <= 0;
        else if (clr)               q <= 0;
        else                        q <= d;
endmodule

module bist_load(
  input clk,
  input rst_b,
  input clr,
  input ld,
  input d,
  output reg q);
  
  always @ (posedge clk, negedge rst_b)
        if (!rst_b)                 q <= 0;
        else if (clr)               q <= 0;
        else if (ld)                q <= d;
endmodule


module rgst #(
    parameter w=16
)(
    input clk,
    input rst_b, 
    input ld, 
    input clr,
    input ls,
    input rs,
    input shift_in, //what padding to use
    input [w-1:0] d,
    output wire [w-1:0] q
);
    wire [w-1:0]bist_out;
    wire [w-1:0]mux_out;
    genvar i;
    //00 = load from yourself
    //01 = load from previous (ls)
    //10 = load from next (rs)
    //11 = load q = d
    //only one of ld, rs, or ld must be active at a time, multiple means 00, so nothing changes
    //clr has priority
    generate
      for (i = 0; i < w; i = i + 1) begin
        bist bist(
          .clk(clk),
          .rst_b(rst_b),
          .clr(clr),
          .d(mux_out[i]),
          .q(bist_out[i])
        );
      end 
    endgenerate
    
    mux_4 #(.w(1)) mux_init (
          .d0(bist_out[0]),
          .d1(shift_in),
          .d2(bist_out[1]),
          .d3(d[0]),
          .q(mux_out[0]),
          .s({~ld&~ls&rs|ld&~ls&~rs, ~ld&ls&~rs|ld&~ls&~rs})
          );
    generate
      for (i = 1; i < w - 1; i = i + 1) begin
        mux_4 #(.w(1)) mux (
          .d0(bist_out[i]),
          .d1(bist_out[i-1]),
          .d2(bist_out[i+1]),
          .d3(d[i]),
          .q(mux_out[i]),
          .s({~ld&~ls&rs|ld&~ls&~rs, ~ld&ls&~rs|ld&~ls&~rs})
          );
      end 
    endgenerate
     mux_4 #(.w(1)) mux_final (
          .d0(bist_out[w-1]),
          .d1(bist_out[w-2]),
          .d2(shift_in),
          .d3(d[w-1]),
          .q(mux_out[w-1]),
          .s({~ld&~ls&rs|ld&~ls&~rs, ~ld&ls&~rs|ld&~ls&~rs})
          );
    assign q = bist_out;
endmodule

module register_tb;
  reg clk;
  reg rst_b;
  reg ld;
  reg clr;
  reg ls;
  reg rs;
  reg shift_in; //what padding to use
  reg [15:0] d;
  wire [15:0] q;
  
  rgst #(.w(16) ) rgst_tb (
    .clk(clk),
    .rst_b(rst_b),
    .ld(ld),
    .ls(ls),
    .clr(clr),
    .rs(rs),
    .shift_in(shift_in),
    .d(d),
    .q(q)
  );
  localparam CYCLES = 100, PERIOD = 100;
  initial begin
    rst_b = 0;
    ld = 0;
    rs = 0;
    ls = 0;
    clr = 0;
    #25
    rst_b = 1;
  end
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
      $display("%b %b %b %b %b | %b\n", ld, ls, rs, clr, d, q);
    end
  end
  initial begin
    $display("ld ls rs clr d | q\n");    
    #(PERIOD)
    d = 150;
    //shift_in = 0;
    ld = 1;
    #(PERIOD)
    ld = 0;
    d = 2;
    rs = 1;
    #(PERIOD)
    rs = 0;
    ls = 1;
    #(PERIOD)
    ld = 1;
    ls = 0;
    shift_in = 1;
    #(PERIOD)
    ld = 0;
    ls = 1;
    rs = 0;
    #(PERIOD)
    ls = 0;
    ld = 1;
    d = 65000;
    #(PERIOD)
    ld = 0;
    rs = 0;
    ls = 1;
  end
endmodule



