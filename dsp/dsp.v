module dsp
  (
   input wire        clk,
   input wire        reset,
   input integer     req_command,
   input wire [31:0] req_in_1,
   input wire [31:0] req_in_2,
   output reg [63:0] resp_result
   );

   reg           y_signed, y_signed1;
   reg           x_;
   reg [15:0]    x0, x1, y1, y2;
   reg [23:0]    y0, y3;

   wire [2:0]    br00 = {x0[1:0],1'b0};
   wire [2:0]    br01 = x0[3:1];
   wire [2:0]    br02 = x0[5:3];
   wire [2:0]    br03 = x0[7:5];
   wire [2:0]    br04 = x0[9:7];
   wire [2:0]    br05 = x0[11:9];
   wire [2:0]    br06 = x0[13:11];
   wire [2:0]    br07 = x0[15:13];

   wire [2:0]    br10 = {x1[1:0],x_};
   wire [2:0]    br11 = x1[3:1];
   wire [2:0]    br12 = x1[5:3];
   wire [2:0]    br13 = x1[7:5];
   wire [2:0]    br14 = x1[9:7];
   wire [2:0]    br15 = x1[11:9];
   wire [2:0]    br16 = x1[13:11];
   wire [2:0]    br17 = x1[15:13];

   reg           ng00, ng01, ng02, ng03, ng04, ng05, ng06, ng07;
   reg           ng10, ng11, ng12, ng13, ng14, ng15, ng16, ng17;

   always @(*)begin
      ng00 = (br00[2:1]==2'b10)|(br00[2:0]==3'b110);
      ng01 = (br01[2:1]==2'b10)|(br01[2:0]==3'b110);
      ng02 = (br02[2:1]==2'b10)|(br02[2:0]==3'b110);
      ng03 = (br03[2:1]==2'b10)|(br03[2:0]==3'b110);
      ng04 = (br04[2:1]==2'b10)|(br04[2:0]==3'b110);
      ng05 = (br05[2:1]==2'b10)|(br05[2:0]==3'b110);
      ng06 = (br06[2:1]==2'b10)|(br06[2:0]==3'b110);
      ng07 = (br07[2:1]==2'b10)|(br07[2:0]==3'b110);

      ng14 = (br14[2:1]==2'b10)|(br14[2:0]==3'b110);
      ng15 = (br15[2:1]==2'b10)|(br15[2:0]==3'b110);
      ng16 = (br16[2:1]==2'b10)|(br16[2:0]==3'b110);
      ng17 = (br17[2:1]==2'b10)|(br17[2:0]==3'b110);
      case(req_command)
        0,
        2:begin
           y_signed = 1'b0;
           y_signed1 = 1'b0;
        end
        3:begin
           y_signed = 1'b1;
           y_signed1 = 1'b0;
        end
      endcase
      case(req_command)
        0:begin
           x0[15:0] = req_in_1[15:0];
           x_       = req_in_1[7];
           x1[15:0] = req_in_1[23:8];
           y0[23:0] = req_in_2[23:0];
           y1[15:0] = req_in_2[15:0];
           y2[15:0] = req_in_2[23:8];
           y3[23:0] = req_in_2[23:0];

           ng10 = 1'b0;
           ng11 = 1'b0;
           ng12 = 1'b0;
           ng13 = 1'b0;
        end
        2,
        3:begin
           x0[15:0] = req_in_1[15:0];
           x_       = 1'b0;
           x1[15:0] = req_in_1[15:0];
           y0[23:0] = {8'h0,req_in_2[15:0]};
           y1[15:0] = req_in_2[15:0];
           y2[15:0] = req_in_2[31:16];
           y3[23:0] = {req_in_2[31:16],8'h0};

           ng10 = (br10[2:1]==2'b10)|(br10[2:0]==3'b110);
           ng11 = (br11[2:1]==2'b10)|(br11[2:0]==3'b110);
           ng12 = (br12[2:1]==2'b10)|(br12[2:0]==3'b110);
           ng13 = (br13[2:1]==2'b10)|(br13[2:0]==3'b110);
        end
      endcase
   end

   always @(*)
     case(req_command)
       0:begin
          resp_result[47:0] = result0 + (result1<<8) + (((x1[15])? req_in_2[23:0] : 0) <<24);
          resp_result[63:48] = 0;
       end
       2:begin
          resp_result[47:0] = (48'hfffe_00000000
                               +( (result0 + (((x0[15])? req_in_2[15:0]  : 0) <<16))    )
                               +( (result1 + (((x1[15])? req_in_2[31:16] : 0) <<24)) <<8)  );
       end
       3:begin
          resp_result[47:0] = (48'hfffe_00000000
                               +(result0     )
                               +(result1 << 8));
      end
     endcase


   wire [27:0]   by00, by01, by02, by03, by04, by05, by06, by07;
   wire [27:0]   by10, by11, by12, by13, by14, by15, by16, by17;

   booth0 booth00(.i(0), .y_signed(y_signed), .br(br00), .y(y0), .by(by00), .com(req_command));
   booth0 booth01(.i(1), .y_signed(y_signed), .br(br01), .y(y0), .by(by01), .com(req_command));
   booth0 booth02(.i(1), .y_signed(y_signed), .br(br02), .y(y0), .by(by02), .com(req_command));
   booth0 booth03(.i(1), .y_signed(y_signed), .br(br03), .y(y0), .by(by03), .com(req_command));

   booth1 booth04(.i(1), .y_signed(y_signed1), .br(br04), .y(y1), .by(by04), .com(req_command));
   booth1 booth05(.i(1), .y_signed(y_signed1), .br(br05), .y(y1), .by(by05), .com(req_command));
   booth1 booth06(.i(1), .y_signed(y_signed1), .br(br06), .y(y1), .by(by06), .com(req_command));
   booth1 booth07(.i(1), .y_signed(y_signed1), .br(br07), .y(y1), .by(by07), .com(req_command));

   booth2 booth10(.i(0), .y_signed(y_signed), .br(br10), .y(y2), .by(by10), .com(req_command));
   booth2 booth11(.i(1), .y_signed(y_signed), .br(br11), .y(y2), .by(by11), .com(req_command));
   booth2 booth12(.i(1), .y_signed(y_signed), .br(br12), .y(y2), .by(by12), .com(req_command));
   booth2 booth13(.i(1), .y_signed(y_signed), .br(br13), .y(y2), .by(by13), .com(req_command));

   booth3 booth14(.i(1), .y_signed(y_signed), .br(br14), .y(y3), .by(by14));
   booth3 booth15(.i(1), .y_signed(y_signed), .br(br15), .y(y3), .by(by15));
   booth3 booth16(.i(1), .y_signed(y_signed), .br(br16), .y(y3), .by(by16));
   booth3 booth17(.i(1), .y_signed(y_signed), .br(br17), .y(y3), .by(by17));

   wire [63:0]   result0 = ((({1'b0,by00}+ng00)) +
                            (({1'b0,by01}+ng01)<<2) +
                            (({1'b0,by02}+ng02)<<4) +
                            (({1'b0,by03}+ng03)<<6) +
                            (({1'b0,by04}+ng04)<<8) +
                            (({1'b0,by05}+ng05)<<10) +
                            (({1'b0,by06}+ng06)<<12) +
                            (({1'b0,by07}+ng07)<<14) );

   wire [63:0]   result1 = ((({1'b0,by10}+(ng10<<8))) +
                            (({1'b0,by11}+(ng11<<8))<<2) +
                            (({1'b0,by12}+(ng12<<8))<<4) +
                            (({1'b0,by13}+(ng13<<8))<<6) +
                            (({1'b0,by14}+ng14)<<8) +
                            (({1'b0,by15}+ng15)<<10) +
                            (({1'b0,by16}+ng16)<<12) +
                            (({1'b0,by17}+ng17)<<14) );

endmodule

module booth0
  (
   input             i,
   input             y_signed,
   input [2:0]       br,
   input [23:0]      y,
   input integer     com,
   output reg [27:0] by
   );

   wire              S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (y[23]&y_signed)^br[2] ;

   always @(*) begin
      case(br)
        3'b000: by[16:0] =  {17{1'b0}};
        3'b001: by[16:0] =  {y[16:0]};
        3'b010: by[16:0] =  {y[16:0]};
        3'b011: by[16:0] =  {y[15:0],1'b0};
        3'b100: by[16:0] = ~{y[15:0],1'b0};
        3'b101: by[16:0] = ~{y[16:0]};
        3'b110: by[16:0] = ~{y[16:0]};
        3'b111: by[16:0] =  {17{1'b0}};
      endcase
      if(com==0)begin
         case(br)
           3'b000: by[24:17] =  {8{1'b0}};
           3'b001: by[24:17] =  {y[23]&y_signed,y[23:17]};
           3'b010: by[24:17] =  {y[23]&y_signed,y[23:17]};
           3'b011: by[24:17] =  {y[23:16]};
           3'b100: by[24:17] = ~{y[23:16]};
           3'b101: by[24:17] = ~{y[23]&y_signed,y[23:17]};
           3'b110: by[24:17] = ~{y[23]&y_signed,y[23:17]};
           3'b111: by[24:17] =  {8{1'b0}};
         endcase
         if(i) by[27:25] = {2'b01,~S};
         else  by[27:25] = {~S,S,S};
      end else begin
         if(i) by[27:17] = {8'h0,2'b01,~S};
         else  by[27:17] = {8'h0,~S,S,S};
      end
   end
endmodule

module booth1
  (
   input             i,
   input             y_signed,
   input [2:0]       br,
   input [15:0]      y,
   input integer     com,
   output reg [27:0] by
   );

   wire              S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (y[15]&y_signed)^br[2] ;
   reg               y_;

   always @(*) begin
      case(com)
        0: begin
           y_ = 1'b0;
           by[27:17] = 0;
        end
        2,
        3: begin
           y_ = 1'b1;
           by[27:17] = {8'h0,2'b01,~S};
        end
      endcase
      case(br)
        3'b000: by[16:0] =  {16{1'b0}};
        3'b001: by[16:0] =  {1'b0,y[15:0]};
        3'b010: by[16:0] =  {1'b0,y[15:0]};
        3'b011: by[16:0] =  {y[15:0],1'b0};
        3'b100: by[16:0] = {~y[15:0],1'b1};
        3'b101: by[16:0] = {y_,~y[15:0]};
        3'b110: by[16:0] = {y_,~y[15:0]};
        3'b111: by[16:0] =  {16{1'b0}};
      endcase
   end
endmodule

module booth2
  (
   input             i,
   input             y_signed,
   input [2:0]       br,
   input [15:0]      y,
   input integer     com,
   output reg [27:0] by
   );

   wire              S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (y[15]&y_signed)^br[2] ;
   reg               y_;

   always @(*) begin
      case(com)
        0: begin
           y_ = 1'b0;
           by[27:25] = {2'b01,~S};
        end
        2,
        3: begin
           y_ = br[2]^y[7];
           if(i) by[27:25] = {2'b01,~S};
           else  by[27:25] = {~S,S,S};
        end
      endcase
      case(br)
        3'b000: by[24:16] =  {9{1'b0}};
        3'b001: by[24:16] =  {y[15]&y_signed,y[15:8]};
        3'b010: by[24:16] =  {y[15]&y_signed,y[15:8]};
        3'b011: by[24:16] =  {y[15:8],y_};
        3'b100: by[24:16] = {~y[15:8],y_};
        3'b101: by[24:16] = ~{y[15]&y_signed,y[15:8]};
        3'b110: by[24:16] = ~{y[15]&y_signed,y[15:8]};
        3'b111: by[24:16] =  {9{1'b0}};
      endcase
      if(com==0)begin
         by[15:0] = ({16{1'b0}});
      end else begin
         case(br)
           3'b000: by[15:8] =  {8{1'b0}};
           3'b001: by[15:8] =   y[7:0];
           3'b010: by[15:8] =   y[7:0];
           3'b011: by[15:8] =  {y[6:0],1'b0};
           3'b100: by[15:8] = {~y[6:0],1'b1};
           3'b101: by[15:8] =  ~y[7:0];
           3'b110: by[15:8] =  ~y[7:0];
           3'b111: by[15:8] =  {8{1'b0}};
         endcase
         by[7:0] = 0;
      end
   end
endmodule

module booth3
  (
   input             i,
   input             y_signed,
   input [2:0]       br,
   input [23:0]      y,
   output reg [27:0] by
   );

   wire              S = ((br==3'b000)|(br==3'b111)) ? 1'b0 : (y[23]&y_signed)^br[2] ;

   always @(*) begin
      case(br)
        3'b000: by[24:0] =  {25{1'b0}};
        3'b001: by[24:0] =  {y[23]&y_signed,y[23:0]};
        3'b010: by[24:0] =  {y[23]&y_signed,y[23:0]};
        3'b011: by[24:0] =  {y[23:0],1'b0};
        3'b100: by[24:0] = ~{y[23:0],1'b0};
        3'b101: by[24:0] = ~{y[23]&y_signed,y[23:0]};
        3'b110: by[24:0] = ~{y[23]&y_signed,y[23:0]};
        3'b111: by[24:0] =  {25{1'b0}};
      endcase
      if(i) by[27:25] = {2'b01,~S};
      else  by[27:25] = {~S,S,S};
   end
endmodule

