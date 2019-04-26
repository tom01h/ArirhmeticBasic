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
dsp.v \

TB = U24x24_tb.cpp

default: $(SIM_DIR)/Vdsp

sim: $(SIM_DIR)/Vdsp

$(SIM_DIR)/Vdsp: $(DESIGN_SRCS) $(TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(DESIGN_SRCS) --exe ../$(TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vdsp.mk Vdsp__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vdsp.mk Vdsp

clean:
	rm -rf sim/ tmp.vcd

.PHONY:
