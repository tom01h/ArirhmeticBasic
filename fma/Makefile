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
fmad.v \

VERILATOR_CPP_TB = fmad_tb.cpp

default: $(SIM_DIR)/Vfmad

sim: $(SIM_DIR)/Vfmad

$(SIM_DIR)/Vfmad: $(DESIGN_SRCS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vfmad.mk Vfmad__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vfmad.mk Vfmad

clean:
	rm -rf sim/ tmp.vcd

.PHONY:
