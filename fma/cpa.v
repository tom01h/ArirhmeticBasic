module cpa
  (
   input integer      req_command,
   input wire [63:0]  mul,
   input wire [4:0]   mulctl,
   input wire [31:0]  aln0,
   input wire [31:0]  aln1,
   input wire [31:0]  aln2,
   input wire [31:0]  aln3,
   output wire [31:0] add0,
   output wire [31:0] add1,
   output wire [31:0] add2,
   output wire [31:0] add3,
   output wire [81:0] addo
   );
   

   wire [81:0]        alnmul = (((mulctl[4]) ? {16'h0,mul[63:0]} : {mul[47:0],32'h0}) ^
                                {{34{mulctl[3]}},{16{mulctl[2]}},{16{mulctl[1]}},{16{mulctl[0]}}} );
   wire [2:0]         alnctl = (req_command==13) ? mulctl[2:0] : 3'b0;

   reg                cin0, cin1, cin2, cin3;

   wire [16:0]        sum01 = aln0[15: 0] + alnmul[63:48] + cin0;
   wire [16:0]        sum11 = aln1[15: 0] + alnmul[47:32] + cin1;
   wire [16:0]        sum21 = aln2[15: 0] + alnmul[31:16] + cin2;
   wire [16:0]        sum31 = aln3[15: 0] + alnmul[15: 0] + cin3;
   wire [17:0]        sum00 = aln0[31:16] + alnmul[81:64]   + sum01[16];
   wire [16:0]        sum10 = aln1[31:16] + {16{alnctl[2]}} + sum11[16];
   wire [16:0]        sum20 = aln2[31:16] + {16{alnctl[1]}} + sum21[16];
   wire [16:0]        sum30 = aln3[31:16] + {16{alnctl[0]}} + sum31[16];

   always @(*) begin
      if(req_command==13)begin
         cin0 = (mulctl[3]==1'b1);
         cin1 = (mulctl[2]==1'b1);
         cin2 = (mulctl[1]==1'b1);
         cin3 = (mulctl[0]==1'b1);
      end else begin
         cin0 = sum11[16];
         cin1 = sum21[16];
         cin2 = sum31[16];
         cin3 = (mulctl[0]==1'b1);
      end
   end

   assign add0 = {sum00[15:0], sum01[15:0]};
   assign add1 = {sum10[15:0], sum11[15:0]};
   assign add2 = {sum20[15:0], sum21[15:0]};
   assign add3 = {sum30[15:0], sum31[15:0]};
   assign addo = {sum00[17:0], sum01[15:0], sum11[15:0], sum21[15:0], sum31[15:0]};

//   assign add0 = alnmul[63:48] + aln0;
//   assign add1 = alnmul[47:32] + aln1;
//   assign add2 = alnmul[31:16] + aln2;
//   assign add3 = alnmul[15: 0] + aln3;
//   assign addo = alnmul + {1'b0, aln0[31:0], aln1[15:0], aln2[15:0], aln3[15:0]};

endmodule
