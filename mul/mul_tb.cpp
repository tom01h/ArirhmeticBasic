#include "unistd.h"
#include "getopt.h"
#include "Vmul_1.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#define VCD_PATH_LENGTH 256

int main(int argc, char **argv, char **env) {
  
  int32_t x, y;
  int i, nloop;
  char vcdfile[VCD_PATH_LENGTH];

  int64_t mc, mv;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));
  i=0;

  if(argc==3){
    x = atoi(argv[1]);
    y = atoi(argv[2]);
    nloop=1;
  }else{
    x = (rand()<<1)^rand();
    y = (rand()<<1)^rand();
    if(argc==2){
      nloop = atoi(argv[1]);
    }else{
      nloop = 1000;
    }
  }
  
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vmul_1* verilator_top = new Vmul_1;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  verilator_top->req_in_1_signed = 1;
  verilator_top->req_in_2_signed = 1;
  verilator_top->req_in_1 = x;
  verilator_top->req_in_2 = y;

  while (i<nloop) {
    verilator_top->req_valid = ((main_time%1000) < 200) ? 1 : 0;
    if((main_time>0)&((main_time%1000)==0)){
      mv = verilator_top->resp_result;
      mc = (int64_t)x*(int64_t)y;
      if(mc==mv){
        printf("PASSED %04d : %08x * %08x = %08x_%08x\n",i,x,y,(int)(mv>>32),(int)mv);
      }else{
        printf("FAILED %04d : %08x * %08x = %08x_%08x != %08x_%08x\n",i,x,y,
               (int)(mc>>32),(int)mc,(int)(mv>>32),(int)mv);
      }
      x = (rand()<<1)^rand();
      y = (rand()<<1)^rand();
      verilator_top->req_in_1 = x;
      verilator_top->req_in_2 = y;
      i++;
    }
    if (main_time % 100 == 0)
      verilator_top->clk = 0;
    if (main_time % 100 == 50)
      verilator_top->clk = 1;
    verilator_top->eval();
    tfp->dump(main_time);
    main_time += 50;
  }
  delete verilator_top;
  tfp->close();

  
  exit(0);
}
