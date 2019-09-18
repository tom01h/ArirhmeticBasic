module fmad_check
  (
   input [31:0]      x,
   input [31:0]      y,
   input [31:0]      z,
   output reg [31:0] rslt,
   output reg [4:0]  flag
   );

   always @ (x or y or z) begin
      rslt = {32{1'bx}};
      flag = 5'h0;
      if((x[30:23]==8'hff)&(x[22:0]!=0))begin
         rslt    = x|32'h00400000;
         flag[4] = ~x[22]|((y[30:23]==8'hff)&~y[22]&(y[21:0]!=0))|((z[30:23]==8'hff)&~z[22]&(z[21:0]!=0));
      end else if((y[30:23]==8'hff)&(y[22:0]!=0))begin
         rslt    = y|32'h00400000;
         flag[4] = ~y[22]|((x[30:23]==8'hff)&~x[22]&(x[21:0]!=0))|((z[30:23]==8'hff)&~z[22]&(z[21:0]!=0));
      end else if(((x[30:23]==8'hff)&(y[30:0]==0))|((y[30:23]==8'hff)&(x[30:0]==0)))begin
         rslt    = 32'hffc00000;
         flag[4] = 1'b1;
      end else if((z[30:23]==8'hff)&(z[22:0]!=0))begin
         rslt    = z|32'h00400000;
         flag[4] = ~z[22]|((x[30:23]==8'hff)&~x[22]&(x[21:0]!=0))|((y[30:23]==8'hff)&~y[22]&(y[21:0]!=0));
      end else if(((x[30:23]==8'hff)|(y[30:23]==8'hff))&((z[30:23]==8'hff)))begin
         if((x[31]^y[31])==z[31])begin
            rslt    = z[31:0];
         end else begin
            rslt    = 32'hffc00000;
            flag[4] = 1'b1;
         end
      end else if(x[30:23]==8'hff)begin
         rslt = {x[31]^y[31],x[30:0]};
      end else if(y[30:23]==8'hff)begin
         rslt = {x[31]^y[31],y[30:0]};
      end else if(z[30:23]==8'hff)begin
         rslt = z[31:0];
      end else if((x[30:0]==0)|(y[30:0]==0))begin
         if(z[30:0]==0)
           rslt = {z[31]&(x[31]^y[31]),z[30:0]};
         else
           rslt = z;
      end else begin
         flag[0] = 1'b1;
      end
   end

endmodule

module fmad
  (
   input             clk,
   input             reset,
   input             req,
   input [31:0]      x,
   input [31:0]      y,
   input [31:0]      z,
   output reg [31:0] rslt,
   output reg [4:0]  flag
   );

   reg               en0, en1, en2;

   always @ (posedge clk) begin
      if(reset)begin
         en0 <= 1'b0;
         en1 <= 1'b0;
         en2 <= 1'b0;
      end else begin
         en0 <= req;
         en1 <= en0;
         en2 <= en1;
      end
   end

   wire[4:0]         flag0i;
   wire [31:0]       rslt0i;
   reg [4:0]         flag0, flag1;
   reg [31:0]        rslt0, rslt1;

   fmad_check fmad_check
     (
      .x(x),
      .y(y),
      .z(z),
      .rslt(rslt0i),
      .flag(flag0i)
   );

   always @ (posedge clk) begin
      if(en0) begin
         flag0 <= flag0i;
         rslt0 <= rslt0i;
      end
      if(en1)begin
         flag1 <= flag0;
         rslt1 <= rslt0;
      end
   end

   wire [23:0]       fracx = {(x[30:23]!=8'h00),x[22:0]};
   wire [23:0]       fracy = {(y[30:23]!=8'h00),y[22:0]};

   wire [7:0]        expx = (x[30:23]==8'h00) ? 8'h01 : x[30:23];
   wire [7:0]        expy = (y[30:23]==8'h00) ? 8'h01 : y[30:23];
   wire signed [8:0] expz = {1'b0,(z[30:23]==8'h00) ? 8'h01 : z[30:23]};
   wire signed [9:0] expm = expx+expy-127+1;

   reg [47:0]        mul;
   reg [23:0]        fracz;

   reg [8:0]         expd;
   reg [8:0]         expa;

   reg               sgnm;
   reg               sgnz;

   reg               sftmul;

   reg [63:0]        muli;

   mulary mulary
     (
      .clk(clk),
      .reset(reset),
      .req_command(0),
      .req_in_1({8'h0,fracx[23:0]}),
      .req_in_2({8'h0,fracy[23:0]}),
      .resp_result(muli)
   );


   always @ (posedge clk) begin
      if(en0 & flag0i[0])begin
//         mul <= {32'h0,fracx}*{32'h0,fracy};
         mul <= muli[47:0];
         fracz <= {(z[30:23]!=8'h00),z[22:0]};
         sgnm <= x[31]^y[31];
         sgnz <= z[31];
         if(expm>expz)begin
            expa = expm;
            expd = expm-expz;
            sftmul <= 1'b0;
         end else begin
            expa = expz;
            expd = expz-expm;
            sftmul <= 1'b1;
         end
      end
   end

   reg [81:0]        add;
   reg [8:0]         expr;
   reg               sgnr;

   always @ (posedge clk) begin
      if(en1 & flag0[0])begin
         if(~sftmul)begin
            sgnr <= sgnm;
            if(expd>=55)
              if(sgnm^sgnz) add[81:0] <= {mul[47:0],32'h0}-({fracz[23:0],56'h0}>>55);
              else          add[81:0] <= {mul[47:0],32'h0}+({fracz[23:0],56'h0}>>55);
            else
              if(sgnm^sgnz) add[81:0] <= {mul[47:0],32'h0}-({fracz[23:0],56'h0}>>expd);
              else          add[81:0] <= {mul[47:0],32'h0}+({fracz[23:0],56'h0}>>expd);
         end else begin
            sgnr <= sgnz;
            if(expd>=27)
              if(sgnm^sgnz) add[81:0] <= {fracz[23:0],56'h0}-({mul[47:0],32'h0}>>27);
              else          add[81:0] <= {fracz[23:0],56'h0}+({mul[47:0],32'h0}>>27);
            else
              if(sgnm^sgnz) add[81:0] <= {fracz[23:0],56'h0}-({mul[47:0],32'h0}>>expd);
              else          add[81:0] <= {fracz[23:0],56'h0}+({mul[47:0],32'h0}>>expd);
         end
         expr <= expa;
      end
   end

   wire [56:0]   nrmi,nrm0,nrm1,nrm2,nrm3,nrm4,nrm5;
   wire [1:0]    ssn;

   wire [5:0]    nrmsft;                                // expr >= nrmsft : subnormal output
   assign nrmsft[5] = (~(|nrmi[56:24])|(&nrmi[56:24]))& (expr[8:5]!=4'h0);
   assign nrmsft[4] = (~(|nrm5[56:40])|(&nrm5[56:40]))&((expr[8:4]&{3'h7,~nrmsft[5],  1'b1})!=5'h00);
   assign nrmsft[3] = (~(|nrm4[56:48])|(&nrm4[56:48]))&((expr[8:3]&{3'h7,~nrmsft[5:4],1'b1})!=6'h00);
   assign nrmsft[2] = (~(|nrm3[56:52])|(&nrm3[56:52]))&((expr[8:2]&{3'h7,~nrmsft[5:3],1'b1})!=7'h00);
   assign nrmsft[1] = (~(|nrm2[56:54])|(&nrm2[56:54]))&((expr[8:1]&{3'h7,~nrmsft[5:2],1'b1})!=8'h00);
   assign nrmsft[0] = (~(|nrm1[56:55])|(&nrm1[56:55]))&((expr[8:0]&{3'h7,~nrmsft[5:1],1'b1})!=9'h000);

   assign nrmi = {add[81:26],(|add[25:0])};
   assign nrm5 = (~nrmsft[5]) ? nrmi : {nrmi[24:0], 32'h0000};
   assign nrm4 = (~nrmsft[4]) ? nrm5 : {nrm5[40:0], 16'h0000};
   assign nrm3 = (~nrmsft[3]) ? nrm4 : {nrm4[48:0], 8'h00};
   assign nrm2 = (~nrmsft[2]) ? nrm3 : {nrm3[52:0], 4'h0};
   assign nrm1 = (~nrmsft[1]) ? nrm2 : {nrm2[54:0], 2'b00};
   assign nrm0 = (~nrmsft[0]) ? nrm1 : {nrm1[55:0], 1'b0};
   assign ssn = {nrm0[30],(|nrm0[29:0])};

   wire [2:0]    grsn = {nrm0[32:31],(|ssn)};
   wire          rnd = (~nrmi[56]) ? (grsn[1:0]==2'b11)|(grsn[2:1]==2'b11)
                                   : ((grsn[1:0]==2'b00)|                          // inc
                                      ((grsn[1]^grsn[0])     &(grsn[0]))|          // rs=11
                                      ((grsn[2]^(|grsn[1:0]))&(grsn[1]^grsn[0]))); // gr=11
   wire [9:0]    expn = expr-nrmsft+{1'b0,(nrm0[56]^nrm0[55])}; // subnormal(+0) or normal(+1)

   wire [30:0]   rsltr = (~nrm0[56]) ? {expn,nrm0[54:32]}+rnd : {expn,~nrm0[54:32]}+rnd;

   always @ (posedge clk) begin
      if(en2) begin
         rslt[31] <= sgnr^add[81];
         flag <= 0;
         if(flag1[0] == 1'b0)begin
            rslt <= rslt1;
            flag <= flag1;
         end else if(nrmi==0)begin
            rslt[31:0] <= 32'h00000000;
         end else if(expn[9])begin
            rslt[30:0] <= 31'h00000000;
            flag[0] <= 1'b1;
            flag[1] <= 1'b1;
         end else if((expn[8:0]>=9'h0ff)&(~expn[9]))begin
            rslt[30:0] <= 31'h7f800000;
            flag[0] <= 1'b1;
            flag[2] <= 1'b1;
         end else if(~nrm0[56])begin
            rslt[30:0] <= rsltr[30:0];
            flag[0] <= |grsn[1:0];
            flag[1] <= ((rsltr[30:23]==8'h00)|((expn[7:0]==8'h00)&~ssn[1]))&(|grsn[1:0]);
            flag[2] <= (rsltr[30:23]==8'hff);
         end else begin
            rslt[30:0] <= rsltr[30:0];
            flag[0] <= |grsn[1:0];
            flag[1] <= ((rsltr[30:23]==8'h00)|((expn[7:0]==8'h00)&((~ssn[1]&~ssn[0])|(ssn[1]&ssn[0])) ))&(|grsn[1:0]);
         end
      end
   end

endmodule
