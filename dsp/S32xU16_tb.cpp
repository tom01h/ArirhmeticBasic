#include "unistd.h"
#include "getopt.h"
#include "Vdsp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

#define VCD_PATH_LENGTH 256

int main(int argc, char **argv, char **env) {
  
  int32_t x, y;
  char vcdfile[VCD_PATH_LENGTH];

  int64_t mc, mv;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vdsp* verilator_top = new Vdsp;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  verilator_top->req_command = 4;

  for(int i=0; i<1000; i++){
    x = rand()&0x0000ffff;
    y = (rand()^(rand()<<1));

    verilator_top->req_in_1 = x;
    verilator_top->req_in_2 = y;

    verilator_top->eval();

    mv = verilator_top->resp_result;
    if(mv&0x0000800000000000){mv|=0xffff000000000000;}
    mc = (int64_t)x*(int64_t)y;
    if(mc==mv){
      printf("PASSED %04d : %08x * %08x = %08x_%08x\n",i,x,y,(int)(mv>>32),(int)mv);
    }else{
      printf("FAILED %04d : %08x * %08x = %08x_%08x != %08x_%08x\n",i,x,y,
             (int)(mc>>32),(int)mc,(int)(mv>>32),(int)mv);
    }

    tfp->dump(main_time);
    main_time += 100;
  }

  delete verilator_top;
  tfp->close();
  
  exit(0);
}
