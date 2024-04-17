Notes:
In documentation, it should be parameter w = 2^n, not 2n.

The state diagram of the control unit is formed by overlapping all other described states and adding "& (op == the_state_opearation_number )",   in code there are comments saying if an operation has a different use for a state than its name suggests

 In the multiplication state diagram from the documentation the arrow pointing from q_out to wait has been forgotten, the condition is: */await_op.

Documentatia este in ALU.pdf

Pentru a da run: do run_alu.txt
Pentru run cu starea la fiecare clk: do run_detailed.txt