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
  
  uint32_t x, y;
  char vcdfile[VCD_PATH_LENGTH];

  int64_t mc0, mc1, mc2, mc3, mv;

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);
  srand((unsigned)time(NULL));

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vdsp* verilator_top = new Vdsp;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);
  vluint64_t main_time = 0;
  verilator_top->req_command = 12;

  for(int i=0; i<1000; i++){
    x = (rand()^(rand()<<1));
    y = (rand()^(rand()<<1));

    verilator_top->req_in_1 = x;
    verilator_top->req_in_2 = y;

    verilator_top->eval();

    mv = verilator_top->resp_result;
    mc0 = (int64_t)((x&0x000000ff)    )*(int64_t)((y&0x000000ff)    );
    mc1 = (int64_t)((x&0x0000ff00)>>8 )*(int64_t)((y&0x0000ff00)>>8 );
    mc2 = (int64_t)((x&0x00ff0000)>>16)*(int64_t)((y&0x00ff0000)>>16);
    mc3 = (int64_t)((x&0xff000000)>>24)*(int64_t)((y&0xff000000)>>24);
    if(((int32_t)mc0==(int32_t)((mv    )&0x0000ffff))&&
       ((int32_t)mc1==(int32_t)((mv>>16)&0x0000ffff))&&
       ((int32_t)mc2==(int32_t)((mv>>32)&0x0000ffff))&&
       ((int32_t)mc3==(int32_t)((mv>>48)&0x0000ffff))){
      printf("PASSED %04d : %08x * %08x = %08x_%08x\n",i,x,y,(int)(mv>>32),(int)mv);
    }else{
      printf("FAILED %04d : %08x * %08x = %08x_%08x != %08x_%08x\n",i,x,y,
             (int)(mc3*0x10000+mc2),(int)(mc1*0x10000+mc0),(int)(mv>>32),(int)mv);
    }

    tfp->dump(main_time);
    main_time += 100;
  }

  delete verilator_top;
  tfp->close();
  
  exit(0);
}
