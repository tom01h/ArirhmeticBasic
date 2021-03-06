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
   input                    clk,
   input                    reset,
   input                    req,
   input integer            req_command,
   input [31:0]             x,
   input [31:0]             y,
   input [31:0]             z,
   input [31:0]             w,
   output reg signed [31:0] acc0, acc1, acc2, acc3, //BF16
   output reg signed [ 9:0] exp0, exp1, exp2, exp3, //BF16
   output reg [31:0]        rslt,                   //FP32
   output reg [4:0]         flag                    //FP32
   );

   reg               en0, en1;

   always @ (*) begin
      if(reset)begin
         en0 = 1'b0;
      end else begin
         en0 = req;
      end
   end
   always @ (posedge clk) begin
      if(reset)begin
         en1 <= 1'b0;
      end else begin
         en1 <= en0;
      end
   end

   wire[4:0]         flag0i;                   //FP32
   wire [31:0]       rslt0i;                   //FP32
   reg [4:0]         flag0, flag1;             //FP32
   reg [31:0]        rslt0, rslt1;             //FP32

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
         if(req_command==1)begin
            flag0 <= flag0i;
            rslt0 <= rslt0i;
         end else begin
            flag0 <= 0;
         end
      end
      if(en1)begin
         flag1 <= flag0;
         rslt1 <= rslt0;
      end
   end

   wire [23:0]       fracx = {(x[30:23]!=8'h00),x[22:0]};                   //FP32
   wire [23:0]       fracy = {(y[30:23]!=8'h00),y[22:0]};                   //FP32
   wire [31:0]       fracz = {(z[30:23]!=8'h00),z[22:0],8'h0};              //FP32

   wire [7:0]        expx =       (x[30:23]==8'h00) ? 8'h01 : x[30:23];     //FP32
   wire [7:0]        expy =       (y[30:23]==8'h00) ? 8'h01 : y[30:23];     //FP32
   wire signed [8:0] expz = {1'b0,(z[30:23]==8'h00) ? 8'h01 : z[30:23]};    //FP32
   wire signed [9:0] expm = expx+expy-127+1;                                //FP32
   wire signed [9:0] expd = expm-expz;                                      //FP32

   wire [63:0]       muli;

   wire [31:0]       req_in_1 = ((req_command == 1) ? {8'h0,fracx[23:0]}
                                 :                    {1'b1,x[6:0],  1'b1,y[6:0],  1'b1,z[6:0],  1'b1,w[6:0]});
   wire [31:0]       req_in_2 = ((req_command == 1) ? {8'h0,fracy[23:0]}
                                 :                    {1'b1,x[22:16],1'b1,y[22:16],1'b1,z[22:16],1'b1,w[22:16]});

   mulary mulary
     (
      .clk(clk),
      .reset(reset),
      .req_command(req_command),
      .req_in_1(req_in_1),
      .req_in_2(req_in_2),
      .resp_result(muli)
   );

   reg [5:0]         sfti;

   always @ (*) begin
      if(expd>=55)begin
         sfti = 55;
      end else if(expd>=0)begin
         sfti = expd;
      end else if(expd>=-32)begin
         sfti = expd+32;
      end else begin
         sfti = 0;
      end
   end

   reg [5:0]         sft0, sft1, sft2, sft3;

   reg [8:0]         expa;                                                              //FP32
   reg               sgnz;                                                              //FP32

   wire signed [9:0] exp0p = {1'b0,x[30:23]} + {1'b0,x[14:7]};                          //BF16
   wire signed [9:0] exp1p = {1'b0,y[30:23]} + {1'b0,y[14:7]};                          //BF16
   wire signed [9:0] exp2p = {1'b0,z[30:23]} + {1'b0,z[14:7]};                          //BF16
   wire signed [9:0] exp3p = {1'b0,w[30:23]} + {1'b0,w[14:7]};                          //BF16

   reg signed [9:0]  exp0l, exp1l, exp2l, exp3l;                                        //BF16

   wire sftout0 = ((exp0l==0) | (aln0[48:30]!={19{1'b0}}) & (aln0[48:30]!={19{1'b1}})); //BF16
   wire sftout1 = ((exp1l==0) | (aln1[48:30]!={19{1'b0}}) & (aln1[48:30]!={19{1'b1}})); //BF16
   wire sftout2 = ((exp2l==0) | (aln2[48:30]!={19{1'b0}}) & (aln2[48:30]!={19{1'b1}})); //BF16
   wire sftout3 = ((exp3l==0) | (aln3[48:30]!={19{1'b0}}) & (aln3[48:30]!={19{1'b1}})); //BF16

   wire signed [9:0] exp0i = (!sftout0) ? exp0 : exp0l;                                 //BF16
   wire signed [9:0] exp1i = (!sftout1) ? exp1 : exp1l;                                 //BF16
   wire signed [9:0] exp2i = (!sftout2) ? exp2 : exp2l;                                 //BF16
   wire signed [9:0] exp3i = (!sftout3) ? exp3 : exp3l;                                 //BF16

   wire signed [9:0] exd0 = exp0p - exp0i + 16;                                         //BF16
   wire signed [9:0] exd1 = exp1p - exp1i + 16;                                         //BF16
   wire signed [9:0] exd2 = exp2p - exp2i + 16;                                         //BF16
   wire signed [9:0] exd3 = exp3p - exp3i + 16;                                         //BF16

   reg [63:0]        mul;
   reg [4:0]         mulctl;

   reg [48:0]        aln0, aln1, aln2, aln3;
   wire [31:0]       add0, add1, add2, add3;

   always @ (posedge clk) begin
      if(en0)begin
         if(req_command==13)begin
            if((x[30:23]==0)|(x[14:7]==0)|(exd0<0))  exp0l <= 0;
            else                                     exp0l <= exp0p;
            if((y[30:23]==0)|(y[14:7]==0)|(exd1<0))  exp1l <= 0;
            else                                     exp1l <= exp1p;
            if((z[30:23]==0)|(z[14:7]==0)|(exd2<0))  exp2l <= 0;
            else                                     exp2l <= exp2p;
            if((w[30:23]==0)|(w[14:7]==0)|(exd3<0))  exp3l <= 0;
            else                                     exp3l <= exp3p;
         end

         if(req_command==13)begin
            mul <= muli;
         end else begin
            mul <= {16'h0,muli[47:0]};
         end

         if(req_command==1)begin
            sgnz <= z[31];
            if(expd>=0)begin
               expa <= expm;
            end else if(expd>=-32)begin
               expa <= expm+32;
            end else begin
               expa <= expz;
            end
         end

         if(req_command==13)begin
            mulctl <= {1'b1,x[31]^x[15], y[31]^y[15], z[31]^z[15], w[31]^w[15]};
         end else begin
            if(expd>=0) mulctl <= {1'b0,{4{(x[31]^y[31]^z[31])}}};
            else        mulctl <= {1'b1,{4{(x[31]^y[31]^z[31])}}};
         end

         if(req_command==13)begin
            if(exd0[9:6]!=0) sft0 <= 63;
            else             sft0 <= exd0;
            if(exd1[9:6]!=0) sft1 <= 63;
            else             sft1 <= exd1;
            if(exd2[9:6]!=0) sft2 <= 63;
            else             sft2 <= exd2;
            if(exd3[9:6]!=0) sft3 <= 63;
            else             sft3 <= exd3;
         end else begin
            if(sfti>=48)begin
               acc0 <= 0;            acc1 <= fracz;            acc2 <= fracz;            acc3 <= fracz;
               sft0 <= 0;            sft1 <= sfti;             sft2 <= sfti-16;          sft3 <= sfti-32;
            end else if(sfti>=32)begin
               acc0 <= fracz;        acc1 <= fracz;            acc2 <= fracz;            acc3 <= {fracz,16'h0};
               sft0 <= sfti+16;      sft1 <= sfti;             sft2 <= sfti-16;          sft3 <= sfti-16;
            end else if(sfti>=16)begin
               acc0 <= fracz;        acc1 <= fracz;            acc2 <= {fracz,16'h0};    acc3 <= 0;
               sft0 <= sfti+16;      sft1 <= sfti;             sft2 <= sfti;             sft3 <= 0;
            end else begin
               acc0 <= fracz;        acc1 <= {fracz,16'h0};    acc2 <= 0;                acc3 <= 0;
               sft0 <= sfti+16;      sft1 <= sfti+16;          sft2 <= 0;                sft3 <= 0;
            end
         end
      end

      if(reset)begin
         exp0 <= 0;
         acc0 <= 0;
         exp1 <= 0;
         acc1 <= 0;
         exp2 <= 0;
         acc2 <= 0;
         exp3 <= 0;
         acc3 <= 0;
      end else if((req_command==13)&(en1))begin //FIX ME (req_command)
         if(!sftout0)begin
            exp0 <= exp0l;
            acc0 <= add0;
         end
         if(!sftout1)begin
            exp1 <= exp1l;
            acc1 <= add1;
         end
         if(!sftout2)begin
            exp2 <= exp2l;
            acc2 <= add2;
         end
         if(!sftout3)begin
            exp3 <= exp3l;
            acc3 <= add3;
         end
      end
   end

   always @ (*) begin
      if(req_command==1)begin //FIX ME (req_command)
         aln0 = {acc0,16'h0}>>sft0;
         aln1 = {acc1,16'h0}>>sft1;
         aln2 = {acc2,16'h0}>>sft2;
         aln3 = {acc3,16'h0}>>sft3;
      end else begin
         aln0 = $signed({acc0,16'h0})>>>sft0;
         aln1 = $signed({acc1,16'h0})>>>sft1;
         aln2 = $signed({acc2,16'h0})>>>sft2;
         aln3 = $signed({acc3,16'h0})>>>sft3;
      end
   end

   wire [81:0]       addi;

   cpa cpa
     (
      .req_command(req_command),  //FIX ME (req_command)
      .mul(mul),
      .mulctl(mulctl),
      .aln0(aln0),      .aln1(aln1),      .aln2(aln2),      .aln3(aln3),
      .add0(add0),      .add1(add1),      .add2(add2),      .add3(add3),
      .addo(addi)
   );

   reg [81:0]        add;
   reg [8:0]         expr;
   reg               sgnr;

   always @ (posedge clk) begin
      if(en1 & flag0[0])begin
         add[81:0] <= addi;
         sgnr <= sgnz;
         expr <= expa;
      end
   end

   wire [64:0]   nrmi,nrm0,nrm1,nrm2,nrm3,nrm4,nrm5;
   wire [1:0]    ssn;

   wire [5:0]    nrmsft;                                // expr >= nrmsft : subnormal output
   assign nrmsft[5] = (~(|nrmi[64:32])|(&nrmi[64:32]))& (expr[8:5]!=4'h0);
   assign nrmsft[4] = (~(|nrm5[64:48])|(&nrm5[64:48]))&((expr[8:4]&{3'h7,~nrmsft[5],  1'b1})!=5'h00);
   assign nrmsft[3] = (~(|nrm4[64:56])|(&nrm4[64:56]))&((expr[8:3]&{3'h7,~nrmsft[5:4],1'b1})!=6'h00);
   assign nrmsft[2] = (~(|nrm3[64:60])|(&nrm3[64:60]))&((expr[8:2]&{3'h7,~nrmsft[5:3],1'b1})!=7'h00);
   assign nrmsft[1] = (~(|nrm2[64:62])|(&nrm2[64:62]))&((expr[8:1]&{3'h7,~nrmsft[5:2],1'b1})!=8'h00);
   assign nrmsft[0] = (~(|nrm1[64:63])|(&nrm1[64:63]))&((expr[8:0]&{3'h7,~nrmsft[5:1],1'b1})!=9'h000);

   assign nrmi = {add[81:18],(|add[17:0])};
   assign nrm5 = (~nrmsft[5]) ? nrmi : {add[49:0], 15'h0};
   assign nrm4 = (~nrmsft[4]) ? nrm5 : {nrm5[48:0], 16'h0000};
   assign nrm3 = (~nrmsft[3]) ? nrm4 : {nrm4[56:0], 8'h00};
   assign nrm2 = (~nrmsft[2]) ? nrm3 : {nrm3[60:0], 4'h0};
   assign nrm1 = (~nrmsft[1]) ? nrm2 : {nrm2[62:0], 2'b00};
   assign nrm0 = (~nrmsft[0]) ? nrm1 : {nrm1[63:0], 1'b0};
   assign ssn = {nrm0[38],(|nrm0[37:0])};

   wire [2:0]    grsn = {nrm0[40:39],(|ssn)};
   wire          rnd = (~nrmi[64]) ? (grsn[1:0]==2'b11)|(grsn[2:1]==2'b11)
                                   : ((grsn[1:0]==2'b00)|                          // inc
                                      ((grsn[1]^grsn[0])     &(grsn[0]))|          // rs=11
                                      ((grsn[2]^(|grsn[1:0]))&(grsn[1]^grsn[0]))); // gr=11
   wire [9:0]    expn = expr-nrmsft+{1'b0,(nrm0[64]^nrm0[63])}; // subnormal(+0) or normal(+1)

   wire [30:0]   rsltr = (~nrm0[64]) ? {expn,nrm0[62:40]}+rnd : {expn,~nrm0[62:40]}+rnd;

   always @ (*) begin
      rslt[31] = sgnr^add[81];
      flag = 0;
      if(flag1[0] == 1'b0)begin
         rslt = rslt1;
         flag = flag1;
      end else if(nrmi==0)begin
         rslt[31:0] = 32'h00000000;
      end else if(expn[9])begin
         rslt[30:0] = 31'h00000000;
         flag[0] = 1'b1;
         flag[1] = 1'b1;
      end else if((expn[8:0]>=9'h0ff)&(~expn[9]))begin
         rslt[30:0] = 31'h7f800000;
         flag[0] = 1'b1;
         flag[2] = 1'b1;
      end else if(~nrm0[64])begin
         rslt[30:0] = rsltr[30:0];
         flag[0] = |grsn[1:0] | (rsltr[30:23]==8'hff);
         flag[1] = ((rsltr[30:23]==8'h00)|((expn[7:0]==8'h00)&~ssn[1]))&(|grsn[1:0]);
         flag[2] = (rsltr[30:23]==8'hff);
      end else begin
         rslt[30:0] = rsltr[30:0];
         flag[0] = |grsn[1:0] | (rsltr[30:23]==8'hff);
         flag[1] = ((rsltr[30:23]==8'h00)|((expn[7:0]==8'h00)&((~ssn[1]&~ssn[0])|(ssn[1]&ssn[0])) ))&(|grsn[1:0]);
         flag[2] = (rsltr[30:23]==8'hff);
      end
   end

endmodule
