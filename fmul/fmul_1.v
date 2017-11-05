module fmul
  (
   input             clk,
   input             reset,
   input             req,
   input [31:0]      x,
   input [31:0]      y,
   output reg [31:0] rslt,
   output reg [4:0]  flag
   );

   wire [7:0]    expx = x[30:23];
   wire [7:0]    expy = y[30:23];
   wire [9:0]    expr = expx + expy - 127;

   wire          sgnr = x[31]^y[31];

   wire [23:0]   fracx = {1'b1,x[22:0]};
   wire [23:0]   fracy = {1'b1,y[22:0]};
   wire [47:0]   fracr = fracx * fracy;

   reg [9:0]     expn;
   reg           rnd;

   always @(*) begin
      if(fracr[47])begin
         expn = expr + 1;
      end else begin
         expn = expr;
      end
   end
   always @(*) begin
      rslt[31] = sgnr;
      flag = 0;
      rnd = 0;
      if((x[30:23]==8'hff)&(x[22:0]!=0))begin
         rslt = x|32'h00400000;
         flag[4]=~x[22]|((y[30:23]==8'hff)&~y[22]&(y[21:0]!=0));
      end else if((y[30:23]==8'hff)&(y[22:0]!=0))begin
         rslt = y|32'h00400000;
         flag[4]=~y[22]|((x[30:23]==8'hff)&~x[22]&(x[21:0]!=0));
      end else if(x[30:23]==8'hff)begin
         if(y[30:0]==0)begin
            rslt = 32'hffc00000;
            flag[4] = 1'b1;
         end else begin
            rslt[31:0] = {x[31]^y[31],x[30:0]};
         end
      end else if(y[30:23]==8'hff)begin
         if(x[30:0]==0)begin
            rslt = 32'hffc00000;
            flag[4] = 1'b1;
         end else begin
            rslt[31:0] = {x[31]^y[31],y[30:0]};
         end
      end else if(fracr[47:0]==0)begin
         rslt[30:0] = 31'h00000000;
      end else if(expn[9])begin
         rslt[30:0] = 31'h00000000;
         flag[0] = 1'b1;
         flag[1] = 1'b1;
      end else if((expn[8:0]>=9'h0ff)&(~expn[9]))begin
         rslt[30:0] = 31'h7f800000;
         flag[0] = 1'b1;
         flag[2] = 1'b1;
      end else if(fracr[47])begin
         rnd = (fracr[23]&(fracr[22:0]!=0))|
               (fracr[24:23]==2'b11);
         rslt[30:0] = {expn,fracr[46:24]}+rnd;
         flag[0] = (fracr[23:0]!=0);
         flag[2] = {rslt[30:23]==8'hff};
      end else begin
         rnd = (fracr[22]&(fracr[21:0]!=0))|
               (fracr[23:22]==2'b11);
         rslt[30:0] = {expn,fracr[45:23]}+rnd;
         flag[0] = (fracr[22:0]!=0);
         flag[2] = {rslt[30:23]==8'hff};
      end
   end

endmodule
