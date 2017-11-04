module fmul
  (
   input         clk,
   input         reset,
   input         req,
   input [31:0]  x,
   input [31:0]  y,
   output [31:0] rslt,
   output [4:0]  flag
   );

   wire [7:0]    expx = x[30:23];
   wire [7:0]    expy = y[30:23];
   wire [9:0]    expr = expx + expy - 127;

   wire          sgnr = x[31]^y[31];

   wire [23:0]   fracx = {1'b1,x[22:0]};
   wire [23:0]   fracy = {1'b1,y[22:0]};
   wire [47:0]   fracr = fracx * fracy;

   reg [31:0]    rslt0;
   reg           rnd;

   always @(*) begin
      rslt0[31] = sgnr;
      if(fracr[47])begin
         rslt0[30:23] = expr + 1;
         rslt0[22:0] = fracr[46:24];
         rnd = (fracr[23]&(fracr[22:0]!=0))|
               (fracr[24:23]==2'b11);
      end else begin
         rslt0[30:23] = expr;
         rslt0[22:0] = fracr[45:23];
         rnd = (fracr[22]&(fracr[21:0]!=0))|
               (fracr[23:22]==2'b11);
      end
   end

   assign rslt[31] = rslt0[31];
   assign rslt[30:0] = rslt0[30:0]+rnd;

endmodule
