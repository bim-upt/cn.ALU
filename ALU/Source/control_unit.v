module control_unit(
  input [3:0]op, //what do
  input Q0,
  input Q,
  input cnt7,
  input clk,
  input rst_b,
  input clr,
  input q_and_m,
  input q_or_m,
  input q_xor_m,
  input same_init_sign,
  input prev_sign,
  input Qw,
  input Mw,
  input Aw,
  input a0,
  
  output set_q,
  output rst_q,
  output negate_q,
  output load_init_sign,
  output load_prev_sign,
  output select_xor_gate,
  output select_and_gate,
  output select_or_gate,
  output load_inverted_a, 
  output awaiting_op,
  output load_m_from_in,
  output load_q_from_in,
  output substract_m,
  output rst_cnt,
  output load_a_from_rca,
  output rs,
  output cnt,
  output write_a,
  output write_q,
  output rst_a,
  output ls,
  //output [7:0]state,
  //output [7:0]nxt_state,
  //output l,
  //output r,
  output operate_on_q,
  output invert_a,
  output result_ready
  );
  
  
  
  
  reg [8:0]q;
  wire [8:0]nxt;
  localparam WAIT = 0;
  localparam INIT = 1;
  localparam SUM = 2;
  localparam DIF = 3;
  localparam LSS = 4;
  localparam RSS = 5; //for division acts as negate A
  localparam OUT_A = 6;
  localparam OUT_Q = 7; //used as negate_a in AND, OR, XOR //used as load_gate for bAND,  bOR, bXOR
  localparam NEG_Q = 8;
  assign state = q;
  assign nxt_state = nxt;
  
  //op: 0 = nothing, 1 = sum, 2 = diff, 3 = multiplication, 4 = division, 5 = ls, 6 = rs, 7 = AND, 8 = OR, 9 = XOR, 10 = bAND, 11 = bOR, 12 = bXOR 
  
  //first line of assign: multiplication
  //second line of assign: addition
  //third line of assign: substract
  //fourth: ls
  //rs
  //and
  //xor
  //bAND
  //bOR
  //bXOR
  //div
  
  assign nxt[WAIT] = ((q[WAIT]&((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))) | (~op[3]&~op[2]&op[1]&op[0])&(q[OUT_Q])) //mult
                      | (~op[3]&~op[2]&~op[1]&op[0])&q[OUT_A] //sum
                      | (~op[3]&~op[2]&op[1]&~op[0])&q[OUT_A] //diff
                      | (~op[3]&op[2]&~op[1]&op[0])&q[OUT_Q]  //ls
                      | (~op[3]&op[2]&op[1]&~op[0])&q[OUT_Q]  //rs
                      | (~op[3]&op[2]&op[1]&op[0])&q[OUT_A]   //AND
                      | (op[3]&~op[2]&~op[1]&~op[0])&q[OUT_A] //OR
                      | (op[3]&~op[2]&~op[1]&op[0])&q[OUT_A]  //OR
                      | (op[3]&~op[2]&op[1]&~op[0])&q[OUT_A]  //bAND
                      | (op[3]&~op[2]&op[1]&op[0])&q[OUT_A]   //bOR
                      | (op[3]&op[2]&~op[1]&~op[0])&q[OUT_A]  //bXOR
                      | (~op[3]&op[2]&~op[1]&~op[0])&q[OUT_A];//div
                      
                      
  assign nxt[INIT] = (q[WAIT]&~((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))); //common
  
  
  assign nxt[RSS] = (~op[3]&~op[2]&op[1]&op[0])&((q[INIT]&~(~Q0&Q | Q0&~Q)) | (q[RSS]&~(~Q0&Q | Q0&~Q)&~cnt7) | (q[DIF]) | q[SUM]) //mult
                    | (~op[3]&op[2]&op[1]&~op[0])&q[INIT] //rs
                    | (~op[3]&op[2]&~op[1]&~op[0])&q[INIT]&Qw;  //div
  
  
  assign nxt[DIF] = (~op[3]&~op[2]&op[1]&op[0])&((q[INIT]&Q0&~Q) | q[RSS]&~cnt7&Q0&~Q)  //mult
                    | (~op[3]&~op[2]&op[1]&~op[0])&q[INIT]                              //dif
                    | (~op[3]&op[2]&~op[1]&~op[0])&(q[LSS]&~(Aw^Mw) | q[SUM]&(prev_sign^Aw)&~a0); //div
  
  
  assign nxt[SUM] = (~op[3]&~op[2]&op[1]&op[0])&((q[INIT]&~Q0&Q) | q[RSS]&~cnt7&~Q0&Q)            //mult
                    | (~op[3]&~op[2]&~op[1]&op[0])&q[INIT]                                        //sum
                    | (~op[3]&op[2]&~op[1]&~op[0])&(q[LSS]&(Aw^Mw) | q[DIF]&(prev_sign^Aw)&~a0);  //div
  
  
  assign nxt[OUT_A] = (~op[3]&~op[2]&op[1]&op[0])&(q[RSS]&cnt7)       //mult
                    | (~op[3]&~op[2]&~op[1]&op[0])&q[SUM]             //sum
                    | (~op[3]&~op[2]&op[1]&~op[0])&q[DIF]             //dif
                    | (~op[3]&op[2]&op[1]&op[0])&q[OUT_Q]             //and
                    | (op[3]&~op[2]&~op[1]&~op[0])&q[OUT_Q]           //or
                    | (op[3]&~op[2]&~op[1]&op[0])&q[OUT_Q]            //xor
                    | (op[3]&~op[2]&op[1]&~op[0])&q[OUT_Q]            //band
                    | (op[3]&~op[2]&op[1]&op[0])&q[OUT_Q]             //bor
                    | (op[3]&op[2]&~op[1]&~op[0])&q[OUT_Q]            //bxor
                    | (~op[3]&op[2]&~op[1]&~op[0])&q[OUT_Q];          //div
                    
                    
  assign nxt[OUT_Q] = (~op[3]&~op[2]&op[1]&op[0])&(q[OUT_A])          //mult
                      | (~op[3]&op[2]&~op[1]&op[0])&q[LSS]            //ls
                      | (~op[3]&op[2]&op[1]&~op[0])&q[RSS]            //rs
                      | (~op[3]&op[2]&op[1]&op[0])&q[INIT]            //and
                      | (op[3]&~op[2]&~op[1]&~op[0])&q[INIT]          //or
                      | (op[3]&~op[2]&~op[1]&op[0])&q[INIT]           //xor
                      | (op[3]&~op[2]&op[1]&~op[0])&q[INIT]           //band
                      | (op[3]&~op[2]&op[1]&op[0])&q[INIT]            //bor
                      | (op[3]&op[2]&~op[1]&~op[0])&q[INIT]           //bxor
                      | (~op[3]&op[2]&~op[1]&~op[0])&(q[NEG_Q] | q[SUM]&same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[DIF]&same_init_sign&cnt7&(~(prev_sign^Aw) | a0));  //div
                      
                      
  assign nxt[LSS] = (~op[3]&op[2]&~op[1]&op[0])&q[INIT] //ls
                    | (~op[3]&op[2]&~op[1]&~op[0])&(q[INIT]&~Qw | q[DIF]&(~(prev_sign^Aw) | a0)&~cnt7 | q[SUM]&(~(prev_sign^Aw) | a0)&~cnt7 | q[RSS]); //div
  
  
  assign nxt[NEG_Q] = (~op[3]&op[2]&~op[1]&~op[0])&(q[SUM]&~same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[DIF]&~same_init_sign&cnt7&(~(prev_sign^Aw) | a0)); //div
  
  
  assign rst_a = (q[WAIT]&~((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))); //common
  
  assign load_m_from_in = (q[WAIT]&~((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))); //common
  
  assign load_q_from_in = (q[WAIT]&~((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))); //common
  
  assign rst_cnt = (q[WAIT]&~((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))); //common
  
  assign substract_m = (~op[3]&~op[2]&op[1]&op[0])&((q[INIT]&Q0&~Q) | q[RSS]&~cnt7&Q0&~Q) //mult
                        | (~op[3]&~op[2]&op[1]&~op[0])&q[INIT]      //dif
                        | (~op[3]&op[2]&~op[1]&~op[0])&(q[LSS]&~(Aw^Mw) | q[SUM]&(prev_sign^Aw)&~a0); //div
  
  assign rs = (~op[3]&~op[2]&op[1]&op[0])&((q[INIT]&~(~Q0&Q | Q0&~Q)) | (q[RSS]&~(~Q0&Q | Q0&~Q)&~cnt7) | (q[DIF]) | q[SUM]) //mult
              | (~op[3]&op[2]&op[1]&~op[0])&q[INIT];  //div
  
  assign awaiting_op = ((q[WAIT]&((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))) //common
                      | (~op[3]&~op[2]&op[1]&op[0])&(q[OUT_Q])) //mult
                      | (~op[3]&~op[2]&~op[1]&op[0])&q[OUT_A] //sum
                      | (~op[3]&~op[2]&op[1]&~op[0])&q[OUT_A] //dif
                      | (~op[3]&op[2]&~op[1]&op[0])&q[OUT_Q]  //ls
                      | (~op[3]&op[2]&op[1]&~op[0])&q[OUT_Q]  //rs
                      | (~op[3]&op[2]&op[1]&op[0])&q[OUT_A]   //and
                      | (op[3]&~op[2]&~op[1]&~op[0])&q[OUT_A] //or
                      | (op[3]&~op[2]&~op[1]&op[0])&q[OUT_A]  //xor
                      | (op[3]&~op[2]&op[1]&~op[0])&q[OUT_A]  //band
                      | (op[3]&~op[2]&op[1]&op[0])&q[OUT_A]   //bor
                      | (op[3]&op[2]&~op[1]&~op[0])&q[OUT_A]  //bxor
                      | (~op[3]&op[2]&~op[1]&~op[0])&q[OUT_A]; //div
  
  assign write_a = (~op[3]&~op[2]&op[1]&op[0])&(q[RSS]&cnt7)  //mult
                      | (~op[3]&~op[2]&~op[1]&op[0])&q[SUM] //sum
                      | (~op[3]&~op[2]&op[1]&~op[0])&q[DIF] //dif
                      | (~op[3]&op[2]&op[1]&op[0])&q[OUT_Q] //and
                      | (op[3]&~op[2]&~op[1]&~op[0])&q[OUT_Q] //or
                      | (op[3]&~op[2]&~op[1]&op[0])&q[OUT_Q]  //xor
                      | (op[3]&~op[2]&op[1]&~op[0])&q[OUT_Q]  //band
                      | (op[3]&~op[2]&op[1]&op[0])&q[OUT_Q]   //bor
                      | (op[3]&op[2]&~op[1]&~op[0])&q[OUT_Q]  //bxor
                      | (~op[3]&op[2]&~op[1]&~op[0])&q[OUT_Q];  //div
  
  assign write_q = (~op[3]&~op[2]&op[1]&op[0])&(q[OUT_A]) //mult
                      | (~op[3]&op[2]&~op[1]&op[0])&q[LSS]  //ls
                      | (~op[3]&op[2]&op[1]&~op[0])&q[RSS]  //rs
                      | (~op[3]&op[2]&~op[1]&~op[0])&(q[NEG_Q] | q[SUM]&same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[DIF]&same_init_sign&cnt7&(~(prev_sign^Aw) | a0));  //div
  
  assign result_ready = (~op[3]&~op[2]&op[1]&op[0])&(q[RSS]&cnt7 | q[OUT_A])  //mult
                      | (~op[3]&~op[2]&~op[1]&op[0])&q[SUM] //sum
                      | (~op[3]&~op[2]&op[1]&~op[0])&q[DIF] //dif
                      | (~op[3]&op[2]&~op[1]&op[0])&q[LSS]  //ls
                      | (~op[3]&op[2]&op[1]&~op[0])&q[RSS]  //rs
                      | (~op[3]&op[2]&op[1]&op[0])&q[OUT_Q]  //and
                      | (op[3]&~op[2]&~op[1]&~op[0])&q[OUT_Q] //or
                      | (op[3]&~op[2]&~op[1]&op[0])&q[OUT_Q]  //xor
                      | (op[3]&~op[2]&op[1]&~op[0])&q[OUT_Q]  //band
                      | (op[3]&~op[2]&op[1]&op[0])&q[OUT_Q]   //bor
                      | (op[3]&op[2]&~op[1]&~op[0])&q[OUT_Q]  //bxor
                      | (~op[3]&op[2]&~op[1]&~op[0])&(q[NEG_Q] | q[SUM]&same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[DIF]&same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[OUT_Q]); //div
  
  
  assign load_a_from_rca = (~op[3]&~op[2]&op[1]&op[0])&(((q[INIT]&Q0&~Q) | q[RSS]&~cnt7&Q0&~Q) | ((q[INIT]&~Q0&Q) | q[RSS]&~cnt7&~Q0&Q))  //mult
                      | (~op[3]&~op[2]&~op[1]&op[0])&q[INIT]  //sum
                      | (~op[3]&~op[2]&op[1]&~op[0])&q[INIT]  //dif
                      | (~op[3]&op[2]&~op[1]&~op[0])&(q[LSS] | q[SUM]&(prev_sign^Aw)&~a0 | q[DIF]&(prev_sign^Aw)&~a0);  //div
  
  assign ls = (~op[3]&op[2]&~op[1]&op[0])&q[INIT]   //ls
              | (~op[3]&op[2]&~op[1]&~op[0])&(q[INIT]&~Qw | q[DIF]&(~(prev_sign^Aw) | a0)&~cnt7 | q[SUM]&(~(prev_sign^Aw) | a0)&~cnt7 | q[RSS]);  //div
              
  assign cnt = (~op[3]&~op[2]&op[1]&op[0])&((q[INIT]&~(~Q0&Q | Q0&~Q)) | (q[RSS]&~(~Q0&Q | Q0&~Q)&~cnt7) | (q[DIF]) | q[SUM]) //mult
              | (~op[3]&op[2]&~op[1]&~op[0])&(q[INIT]&~Qw | q[DIF]&(~(prev_sign^Aw) | a0)&~cnt7 | q[SUM]&(~(prev_sign^Aw) | a0)&~cnt7 | q[RSS]);  //div
              
  assign operate_on_q = (~op[3]&~op[2]&~op[1]&op[0])&q[INIT] | (~op[3]&~op[2]&op[1]&~op[0])&q[INIT] //sum/dif
                        | (~op[3]&op[2]&~op[1]&~op[0])&(q[SUM]&~same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[DIF]&~same_init_sign&cnt7&(~(prev_sign^Aw) | a0)); //div
  
  
  
  assign invert_a = (~op[3]&op[2]&op[1]&op[0])&q[INIT]&q_and_m  //and
                  | (op[3]&~op[2]&~op[1]&~op[0])&q[INIT]&q_or_m   //or
                  | (op[3]&~op[2]&~op[1]&op[0])&q[INIT]&q_xor_m   //xor
                  | (~op[3]&op[2]&~op[1]&~op[0])&q[INIT]&Qw;    //div
                  
                  
  assign load_inverted_a = (~op[3]&op[2]&op[1]&op[0])&q[INIT]&q_and_m   //and
                          | (op[3]&~op[2]&~op[1]&~op[0])&q[INIT]&q_or_m //or
                          | (op[3]&~op[2]&~op[1]&op[0])&q[INIT]&q_xor_m   //xor
                          | (~op[3]&op[2]&~op[1]&~op[0])&q[INIT]&Qw;    //div
  
  
  assign select_or_gate = (op[3]&~op[2]&op[1]&op[0])&q[INIT]; //or
  
  assign select_xor_gate = (op[3]&op[2]&~op[1]&~op[0])&q[INIT]; //xor
  
  assign select_and_gate = (op[3]&~op[2]&op[1]&~op[0])&q[INIT]; //and
  
  assign negate_q = (~op[3]&op[2]&~op[1]&~op[0])&(q[SUM]&~same_init_sign&cnt7&(~(prev_sign^Aw) | a0) | q[DIF]&~same_init_sign&cnt7&(~(prev_sign^Aw) | a0)); //div
  
  assign load_init_sign = (q[WAIT]&~((~op[3]&~op[2]&~op[1]&~op[0]) | (op[3]&op[2]&~op[1]&op[0]) | (op[3]&op[2]&op[1]&~op[0]) | (op[3]&op[2]&op[1]&op[0]))); //div
  
  assign load_prev_sign = (~op[3]&op[2]&~op[1]&~op[0])&(q[INIT]&~Qw | q[DIF]&(~(prev_sign^Aw) | a0)&~cnt7 | q[SUM]&(~(prev_sign^Aw) | a0) &~cnt7 | q[RSS]); //div
  
  assign set_q = (~op[3]&op[2]&~op[1]&~op[0])&(q[LSS]); //div
  
  assign rst_q = (~op[3]&op[2]&~op[1]&~op[0])&((q[DIF]&(prev_sign^Aw)&~a0) | q[SUM]&(prev_sign^Aw)&~a0);  //div
  
  always @ (posedge clk, negedge rst_b) begin
    if(rst_b == 0 || clr) begin
      q <= 0;
      q[WAIT] <=1;
    end else
      q <= nxt;
  end
  
endmodule
  
  
module alu#(
  parameter w = 16,
  parameter cnt7size = 4
  )(
    input [w-1:0]x,
    input [w-1:0]y,
    input [3:0]op_in,
    input clk,
    input rst_b,
    
    
    //output [7:0]state,
    //output [7:0]nxt_state,
    output [w-1:-1]q_cur,
    output [w-1:0]m_cur,
    //output [3:0]op_cur,
    output [w-1:0]a_cur,
    //output cnt7_cur,
    //output l,
    //output r,
    //output [cnt7size:0]count,
    //output ini,
    
    output [w-1:0]z,
    output status
    //output overflow
  );
  
  wire [3:0]op;
  
  wire [w-1:0]m;
  wire [w-1:-1]q;
  wire [w-1:0]a;
  wire [cnt7size:0]cnt;
  
  wire negate_q;
  wire load_inverted_a;
  wire awaiting_op;
  wire load_m_from_in;
  wire load_q_from_in;
  wire substract_m;
  wire rst_cnt;
  wire load_a_from_rca;
  wire rs;
  wire ls;
  wire cnt_increment;
  wire write_a;
  wire write_q;
  wire rst_a;
  wire result_ready;
  wire [w-1:0]m_xor;
  wire cnt7;
  
  //assign l = ls;
  //assign r = rs;
  //assign count = cnt;
  
  wire same_init_sign;
  wire load_init_sign;
  assign ini = same_init_sign;
  bist_load same_init_sign_mod(
    .d(~(x[w-1]^y[w-1])),
    .clk(clk),
    .clr(),
    .ld(load_init_sign),
    .rst_b(rst_b),
    .q(same_init_sign)
  );
  
  wire prev_sign;
  wire load_prev_sign;
  bist_load prev_sign_mod(
    .d(a[w-1]),
    .clk(clk),
    .clr(),
    .ld(load_prev_sign),
    .rst_b(rst_b),
    .q(prev_sign)
  );
  
  
  wire select_xor_gate;
  wire select_and_gate;
  wire select_or_gate;
  wire [w-1:0]or_word;
  word_or #(.w(w)) or_word_mod(
    .x(q[w-1:0]),
    .y(m),
    .z(or_word)
  );
  
  wire [w-1:0]and_word;
  word_and #(.w(w)) and_word_mod(
    .x(q[w-1:0]),
    .y(m),
    .z(and_word)
  );
  
  wire [w-1:0]xor_word;
  word_xor #(.w(w)) xor_word_mod(
    .x(q[w-1:0]),
    .y(m),
    .z(xor_word)
  );
  
  wire [w-1:0]word_gates;
  mux_4 #(.w(w)) gates_mux(
    .d0(or_word),
    .d1(and_word),
    .d2(xor_word),
    .d3(),
    .s({select_xor_gate,select_and_gate}),
    .q(word_gates)
  );
  wire q_true;
  or_tree #(.w(w)) q_true_mod(
    .x(q[w-1:0]),
    .out(q_true)
  );
  
  wire a_true;
  or_tree #(.w(w)) a_true_mod(
    .x(a[w-1:0]),
    .out(a_true)
  );
  
  wire m_true;
  or_tree #(.w(w)) m_true_mod(
    .x(m),
    .out(m_true)
  );

  counter #(.w(cnt7size+1)) counter (
    .clk(clk),
    .incr(cnt_increment),
    .rst_b(rst_b),
    .clr(rst_cnt),
    .out(cnt)
  );
  
  mux_2 #(.w(w)) z_outmux (
    .d0(a),
    .d1(q[w-1:0]),
    .s(write_q),
    .q(z)
  );
  
  wire operate_on_q;
  wire [w-1:0]rca_a_q;
  mux_2 #(.w(w)) sum_input_a_q (
    .d0(a),
    .d1(q[w-1:0]),
    .s(operate_on_q),
    .q(rca_a_q)
  );
  
  wire [w-1:0]zero_or_a_q;
  mux_2 #(.w(w)) zero_or_a_q_mod(
    .d0(rca_a_q),
    .d1({w{1'b0}}),
    .s(negate_q),
    .q(zero_or_a_q)
    );
    
  wire [w-1:0]rca_out;
  rca #(.w(w)) rca(
    .x(zero_or_a_q),
    .y(m_xor),
    .z(rca_out),
    .cout(cout),
    .cin(substract_m | negate_q),
    .overflow()
  );
  
  //save current operation
  rgst #(.w(4)) op_mod(
    .clk(clk),
    .rst_b(rst_b),
    .ld(awaiting_op),
    .d(op_in),
    .q(op),
    .ls(1'b0),
    .rs(1'b0),
    .shift_in(1'b0),
    .clr(1'b0)
  );
  
  wire [w-1:0]m_q_inversion_input;
  mux_2 #(.w(w)) mux_m_q(
    .d0(m),
    .d1(q[w-1:0]),
    .s(negate_q),
    .q(m_q_inversion_input)
  );
  
  
  //invert m if substract_m
  xor_word #(.w(w)) inverter (
    .x(m_q_inversion_input),
    .y(substract_m | negate_q),
    .z(m_xor)
  );
  wire [w-1:0]a_xor;
  xor_word #(.w(w)) inverter_a (
    .x(a),
    .y(1'b1),
    .z(a_xor)
  );
  
  wire invert_a;
  wire [w-1:0]rca_inverted_a;
  mux_2 #(.w(w)) mux_rca_out_inverted_a(
    .d0(rca_out),
    .d1(a_xor),
    .s(invert_a),
    .q(rca_inverted_a)
  );
  
  wire [w-1:0]rca_inverted_gate_a;
  mux_2 #(.w(w)) mux_rca_out_inverted_gate_a(
    .d0(rca_inverted_a),
    .d1(word_gates),
    .s(select_xor_gate | select_or_gate | select_and_gate),
    .q(rca_inverted_gate_a)
  );
  
  //assign cnt7_cur = cnt7;
  assign cnt7 = cnt[cnt7size];
  
  
  rgst #(.w(w)) a_mod (
    .clk(clk),
    .rst_b(rst_b),
    .ld(load_a_from_rca | load_inverted_a | select_xor_gate | select_or_gate | select_and_gate),
    .ls(ls),
    .clr(rst_a),
    .rs(rs),
    .shift_in(a[w-1]&rs | q[w-1]&ls),
    .d(rca_inverted_gate_a),
    .q(a)
  );
  
  wire [w-1:-1]q_input;
  mux_4 #(.w(w+1)) q_input_mod(
    .d0({x,1'b0}),
    .d1({q[w-1:1],2'b00}),
    .d2({q[w-1:1],2'b10}),
    .d3({rca_out, 1'b0}),
    .s({set_q | negate_q, rst_q | negate_q}),
    .q(q_input)
    );
  
  
  
  rgst #(.w(w+1)) q_mod(
    .clk(clk),
    .rst_b(rst_b),
    .ld(load_q_from_in | set_q | rst_q | negate_q),
    .clr(1'b0),
    .d(q_input),
    .q(q),
    .ls(ls),
    .rs(rs),
    .shift_in(rs&a[0])
  );
  
  
  rgst #(.w(w)) m_mod (
    .clk(clk),
    .rst_b(rst_b), 
    .ld(1'b1), 
    .clr(1'b0),
    .d(y),
    .q(m),
    .ls(1'b0),
    .rs(1'b0),
    .shift_in(1'b0)
    );
    
    assign q_cur = q;
    assign m_cur = m;
    assign op_cur = op;
    assign a_cur = a;
    
  
  control_unit cu(
  .op(op),
  .clk(clk),
  .rst_b(rst_b),
  .clr(1'b0),
  .Q(q[-1]),
  .Q0(q[0]),
  .cnt7(cnt7),
  //.l(l),
  //.r(r),
  .operate_on_q(operate_on_q),
  .load_inverted_a(load_inverted_a),
  .invert_a(invert_a),
  //.state(state),
  //.nxt_state(nxt_state),
  .q_and_m(q_true & m_true),
  .q_or_m(q_true | m_true),
  .q_xor_m(q_true ^ m_true),
  .select_xor_gate(select_xor_gate),
  .select_or_gate(select_or_gate),
  .select_and_gate(select_and_gate),
  .same_init_sign(same_init_sign),
  .prev_sign(prev_sign),
  .Qw(q[w-1]),
  .load_init_sign(load_init_sign),
  .load_prev_sign(load_prev_sign),
  .Aw(a[w-1]),
  .Mw(m[w-1]),
  .negate_q(negate_q),
  .a0(~a_true),
  .set_q(set_q),
  .rst_q(rst_q),
  
  .awaiting_op(awaiting_op),
  .load_m_from_in(load_m_from_in),
  .load_q_from_in(load_q_from_in),
  .substract_m(substract_m),
  .rst_cnt(rst_cnt),
  .load_a_from_rca(load_a_from_rca),
  .rs(rs),
  .cnt(cnt_increment),
  .write_a(write_a),
  .write_q(write_q),
  .rst_a(rst_a),
  .result_ready(status),
  .ls(ls)
  ); 
  
  
endmodule

module alu_tb;
  localparam w = 16;
  localparam cnt7size = 4;
  reg [w-1:0]x;
  reg [w-1:0]y;
  reg [3:0]op_in;
  reg clk;
  reg rst_b;
    
  wire [w-1:0]z;
  wire status;
  //wire overflow;
  
  //wire cnt7;
 // wire ls, rs;
  //wire [7:0]state;
  //wire [7:0]nxt_state;
  wire [w:0]q;
  wire [w-1:0]a;
  wire [w-1:0]m;
  //wire [3:0]op;
  //wire [4:0]count;
  //wire ini;sim:/alu_tb
  
  alu #(.w(w), .cnt7size(cnt7size)) alu_uut(
    //.state(state),
    //.nxt_state(nxt_state),
    .q_cur(q),
    .a_cur(a),
    .m_cur(m),
    //.op_cur(op),
    //.l(ls),
    //.ini(ini),
    //.r(rs),
    //.cnt7_cur(cnt7),
    //.count(count),
    
    .x(x),
    .y(y),
    .op_in(op_in),
    .clk(clk),
    .rst_b(rst_b),
    .z(z),
    .status(status)
    //.overflow(overflow)
    );
  initial begin
    rst_b = 0;
    #20
    rst_b = 1;
  end
  localparam CYCLES = 30, PERIOD = 200;
  /*
  initial begin
    clk = 0;
    repeat(CYCLES*2) begin
      #(PERIOD/2) 
      clk = ~clk;
      
      
    end
  end
  initial begin
    repeat(CYCLES * 2)begin
      #(PERIOD)
      //$display("%b %b %b %b %b %b %b %b | %b %b | %b\n", count, cnt7, ls, rs, op, a, q, m, state, nxt_state, z);
      if(status) begin
        $display("%b %b | %b\n", x, y, z);
        $display("%d %d | %d\n", x, y, z);
      end
    end
  end
  initial begin
    op_in = 1;
    #(PERIOD)
    x = 30;
    y = 20;
    op_in = 6;
    
  end*/ 
  reg [63:0]i = 0;
  reg [64:0]progress = 0;
  
  initial begin
    rst_b = 0;
    clk = 0;
    op_in = 0;
    #20
    rst_b = 1;
    #(PERIOD)
    x = 30;
    y = 20;
  end
  initial begin
      while(progress < 14) begin
        #(PERIOD/2) 
        clk = ~clk;
      end      
  end
  initial begin
    while(progress < 14) begin
      #(PERIOD)
      i = i + 1;
      //$display("%b %b %b %b %b %b %b %b | %b %b | %b %b\n", count, cnt7, ls, rs, op, a, q, m, state, nxt_state, ini, z);
      //$display("%d %d %d \n", i, progress, op_in);
      if(progress == 0)
        op_in = 1;
      else if(progress == 1)
        op_in = 2;
      else if(progress == 2)
        op_in = 3;
      else if(progress == 4)
        op_in = 5;
      else if(progress == 5)
        op_in = 6;
      else if(progress == 6) begin op_in = 7; x = 4; y = 1; end
      else if(progress == 7) begin op_in = 8; x = 0; y = 0; end
      else if(progress == 8) begin op_in = 9; x = 4; y = 1; end
      else if(progress == 9) begin op_in = 10; x = 12; y = 255; end
      else if(progress == 10) begin op_in = 11; x = 16; y = 7; end
      else if(progress == 11) begin op_in = 12; x = 12; y = 255; end
        else if(progress == 12) begin op_in = 4; x = 65529; y = 2; end
      if(status) begin
        $display("%b %b %b | %b\n", a,q, m, z);
        $display("%d %d | %d\n", x, y, z);
        progress = progress + 1;
      end
    end
  end 
  
 
endmodule
  
  
  