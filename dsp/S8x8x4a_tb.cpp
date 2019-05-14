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

  int32_t x0, x1, x2, x3, y0, y1, y2, y3;
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
  verilator_top->req_command = 11;

  for(int i=0; i<1000; i++){
    x = (rand()^(rand()<<1));
    y = (rand()^(rand()<<1));

    verilator_top->req_in_1 = x;
    verilator_top->req_in_2 = y;

    verilator_top->eval();

    x0 = (int64_t)((x&0x000000ff)    );
    if(x0&0x00000080){x0|=0xffffff00;}
    x1 = (int64_t)((x&0x0000ff00)>>8 );
    if(x1&0x00000080){x1|=0xffffff00;}
    x2 = (int64_t)((x&0x00ff0000)>>16);
    if(x2&0x00000080){x2|=0xffffff00;}
    x3 = (int64_t)((x&0xff000000)>>24);
    if(x3&0x00000080){x3|=0xffffff00;}

    y0 = (int64_t)((y&0x000000ff)    );
    if(y0&0x00000080){y0|=0xffffff00;}
    y1 = (int64_t)((y&0x0000ff00)>>8 );
    if(y1&0x00000080){y1|=0xffffff00;}
    y2 = (int64_t)((y&0x00ff0000)>>16);
    if(y2&0x00000080){y2|=0xffffff00;}
    y3 = (int64_t)((y&0xff000000)>>24);
    if(y3&0x00000080){y3|=0xffffff00;}

    mv = ((int64_t)(verilator_top->resp_result))>>16;
    mc = (x0*y0) + (x1*y1) + (x2*y2) + (x3*y3);
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
