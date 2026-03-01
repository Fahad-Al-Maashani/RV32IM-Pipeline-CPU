# Waveform Interpretation Guide

This companion explains which signals to probe in `cpu_wave.vcd`, how to add new ones, and how to reason about the behavioral log produced during simulation.

## 1. Generating the Waveform
- `make run` automatically emits `cpu_wave.vcd` because the testbench calls `$dumpfile("cpu_wave.vcd")` and `$dumpvars(0, tb_riscv_core)`.
- `make wave` launches GTKWave (or your viewer) and opens the VCD for inspection.

## 2. Key Signal Groups to Add in GTKWave
When you first open the VCD, organize the following groups so you can read the pipeline at a glance:

### 2.1 Global Control
- `tb_riscv_core.clk` / `rst_n`: confirm reset release and clock edges.
- `tb_riscv_core.dut.pc`: top-level program counter.
- `tb_riscv_core.dut.branch_taken_ex`: pulses indicate branch/jump redirects.
- `tb_riscv_core.dut.stall`, `pc_write`, `if_id_write`: visualize load-use stalls.

### 2.2 Pipeline Registers
- IF/ID: `if_id_pc`, `if_id_instr`.
- ID/EX: `id_ex_rs1_data`, `id_ex_rs2_data`, `id_ex_imm`, `id_ex_alu_ctrl`, `id_ex_branch`, `id_ex_mem_read`, `id_ex_mem_write`.
- EX/MEM: `ex_mem_alu_result`, `ex_mem_rs2_data`, `ex_mem_mem_read`, `ex_mem_mem_write`.
- MEM/WB: `mem_wb_alu_result`, `mem_wb_mem_data`, `mem_wb_pc4`, `mem_wb_wb_sel`.

### 2.3 Forwarding & Hazards
- `forward_a`, `forward_b`: show which source feeds each operand (00=ID/EX, 01=MEM/WB, 10=EX/MEM).
- `hazard_id_ex_flush`: bubble insertion due to load-use or branch flush.

### 2.4 Memory Interfaces
- Instruction: `imem_addr`, `imem_read_data` to confirm fetch addresses.
- Data: `dmem_addr`, `dmem_write_data`, `dmem_read_data`, `dmem_we`, `dmem_re`, `dmem_size`, `dmem_unsigned`.

### 2.5 Register File & WB
- `wb_rd_addr`, `wb_data`, `wb_reg_write`: final writes entering the regfile.

Add signals by right-clicking in GTKWave’s tree view, choosing “Insert” to the waveform pane, and optionally grouping them into folders (e.g., “IF”, “EX”, “MEM”).

## 3. Reading Behavior from Waveforms
1. **Fetch sequence**: Track `pc` and `imem_read_data`. A monotonic `pc` indicates sequential fetch; sudden jumps with simultaneous `branch_taken_ex` pulses mark taken branches or jumps.
2. **Instruction identity**: The 32-bit value in `if_id_instr` matches the instruction hex in `mem/program.hex`. Compare bits (opcode/funct) while stepping through stages to verify decoding.
3. **Forwarding confirmation**: When `forward_a=2'b10`, the EX stage takes operand A from EX/MEM; verify that the value equals `ex_mem_forward_data` rather than `id_ex_rs1_data`.
4. **Load-use stall**: Look for `stall=1` and `pc_write=0`. During that cycle, `if_id_instr` holds steady, `id_ex` becomes zeroed (bubble), and EX executes a harmless NOP.
5. **Memory operations**: For stores, `dmem_we=1` and `dmem_addr` points to the write location; confirm `dmem_size` matches byte/half/word. For loads, follow `dmem_read_data` -> `load_data_ext` -> `mem_wb_mem_data` -> `wb_data` to see the value enter the register file.
6. **Branch flush**: After `branch_taken_ex=1`, `if_id_instr` should show `0x00000000` (bubble) for the next cycle due to IF/ID flush, then the pipeline refills from the branch target PC.

## 4. Logging & Console Output
- The testbench prints only the final PASS/FAIL message plus any mismatch logs from the scoreboard loop. Use these prints to correlate with waveform events (e.g., if a mismatch occurs, locate the cycle where the store went wrong).
- `$finish` occurs after 400 cycles; ensure you inspect waves within that window.

## 5. Adding More Signals to the VCD
To dump additional signals:
1. Open `tb/tb_riscv_core.v`.
2. After the DUT instantiation, add statements like `initial begin $dumpvars(0, tb_riscv_core.dut.hazard_unit); end` or `$dumpvars(0, tb_riscv_core.dut.some_signal);` for precise nodes.
3. Re-run `make run` to regenerate `cpu_wave.vcd` with the new probes.

## 6. Checklist for Understanding “Every Bit”
- Watch the pipeline registers moving instruction opcodes each cycle.
- Ensure `forward_a/b` match your mental dependency graph.
- Confirm that `dmem_*` handshake lines correspond to the load/store instructions you expect.
- Track `wb_data` and `wb_rd_addr` to verify register updates align with the instruction stream.
- Keep the glossary (`GLOSSARY.md`) nearby; signal names are consistent across RTL, pipeline, and waveform docs.

By grouping signals logically and correlating them with console logs, you can quickly diagnose hazards, verify data paths, and understand the pipeline’s behavior cycle by cycle.
