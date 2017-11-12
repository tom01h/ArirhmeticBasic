SHELL = /bin/bash

SIM_DIR = sim

VERILATOR = verilator

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	--cc \
	+1364-2001ext+v \
	-Wno-fatal \
	--Mdir sim \
	--trace \

VERILATOR_MAKE_OPTS = OPT_FAST="-O3"

DESIGN_SRCS = \
fmul_2.v

VERILATOR_CPP_TB = fmul_tb.cpp

default: $(SIM_DIR)/Vfmul_2

sim: $(SIM_DIR)/Vfmul_2

$(SIM_DIR)/Vfmul_2: $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vfmul_2.mk Vfmul_2__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vfmul_2.mk Vfmul_2

clean:
	rm -rf sim/ tmp.vcd

.PHONY:
