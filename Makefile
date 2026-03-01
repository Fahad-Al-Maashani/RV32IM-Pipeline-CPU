IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

BUILD_DIR := build
SIM_OUT := $(BUILD_DIR)/riscv_core_tb.out
RTL_SRCS := $(wildcard rtl/*.v)
TB_SRCS := tb/tb_riscv_core.v
DEFINES := rtl/defines.vh

.PHONY: all sim run wave clean program

all: run

$(SIM_OUT): $(RTL_SRCS) $(TB_SRCS) $(DEFINES) mem/program.hex | $(BUILD_DIR)
	$(IVERILOG) -g2012 -I rtl -o $@ $(TB_SRCS) $(RTL_SRCS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sim: $(SIM_OUT)

run: sim
	$(VVP) $(SIM_OUT)

wave: run
	$(GTKWAVE) cpu_wave.vcd

mem/program.hex: mem/gen_program.py
	python3 $<

program: mem/gen_program.py
	python3 $<

clean:
	rm -rf $(BUILD_DIR) cpu_wave.vcd
