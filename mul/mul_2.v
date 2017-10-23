module mul
  (
   input         clk,
   input         reset,
   input         req_valid,
   input         req_in_1_signed,
   input         req_in_2_signed,
   input [31:0]  req_in_1,
   input [31:0]  req_in_2,
   output [63:0] resp_result
   );

   reg           y_signed;
   reg [32:0]    x;
   reg [31:0]    y;
   reg [67:0]    result;

   reg [4:0]     i;

   wire [2:0]    br0 = {x[1:0],1'b0};
   wire [2:0]    br1 = x[3:1];
   wire [2:0]    br2 = x[5:3];

   wire          ng0 = (br0[2:1]==2'b10)|(br0[2:0]==3'b110);
   wire          ng1 = (br1[2:1]==2'b10)|(br1[2:0]==3'b110);
   wire          ng2 = (br2[2:1]==2'b10)|(br2[2:0]==3'b110);
   reg           ng2l;

   wire [35:0]   by0, by1, by2;

   booth booth0(.i(0), .y_signed(y_signed), .br(br0), .y(y), .by(by0));
   booth booth1(.i(1), .y_signed(y_signed), .br(br1), .y(y), .by(by1));
   booth booth2(.i(1), .y_signed(y_signed), .br(br2), .y(y), .by(by2));

   assign resp_result = result[63:0];

   always @(posedge clk) begin
      if(req_valid) begin
         y_signed <= req_in_2_signed;
         x <= {req_in_1_signed&req_in_1[31],req_in_1};
         y <= req_in_2;
         i <= 5'h08;
      end else if(i==5'h08)begin
         result <= ({1'b0,by0} + {1'b0,by1,1'b0,ng0} + {1'b0,by2,1'b0,ng1,2'b00})<<28;
         x <= {{4{x[32]}},x[32:4]};
         ng2l <= ng2;
         i <= i-1;
      end else if(i!=0)begin
         result <= (result>>4) + (({1'b0,by1,1'b0,ng2l} + {1'b0,by2,1'b0,ng1,2'b00})<<28);
         x <= {{4{x[32]}},x[32:4]};
         ng2l <= ng2;
         i <= i-1;
      end
   end

endmodule

module booth
  (
   input             i,
   input             y_signed,
   input [2:0]       br,
   input [31:0]      y,
   output reg [35:0] by
   );

   wire              S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (y[31]&y_signed)^br[2] ;

   always @(*) begin
      case(br)
        3'b000: by[32:0] =  {33{1'b0}};
        3'b001: by[32:0] =  {y[31]&y_signed,y[31:0]};
        3'b010: by[32:0] =  {y[31]&y_signed,y[31:0]};
        3'b011: by[32:0] =  {y[31:0],1'b0};
        3'b100: by[32:0] = ~{y[31:0],1'b0};
        3'b101: by[32:0] = ~{y[31]&y_signed,y[31:0]};
        3'b110: by[32:0] = ~{y[31]&y_signed,y[31:0]};
        3'b111: by[32:0] =  {33{1'b0}};
      endcase
      if(i) by[35:33] = {2'b01,~S};
      else  by[35:33] = {~S,S,S};
   end
endmodule
