# Pipeline Deep Dive

This note explains the pipeline behavior, hazards, and supporting logic in plain language so you can follow waveforms or tweak the RTL with confidence.

## 1. Why Pipeline?
A pipeline breaks instruction execution into smaller steps so multiple instructions overlap:
1. **IF** (Instruction Fetch)
2. **ID** (Instruction Decode + register read)
3. **EX** (Execute / ALU / branch resolution)
4. **MEM** (Data memory access)
5. **WB** (Write-back to registers)

Each step completes in one cycle, so up to five instructions can be “in flight” at once. Throughput ≈ 1 instruction per cycle after the pipeline fills, assuming no hazards.

## 2. Stage-by-Stage Roles
- **IF**: Reads instruction memory at the current PC. Normally PC increments by 4; on branch/jump resolution the EX stage can override the PC with a new target.
- **ID**: Decodes opcodes, generates immediates, and grabs source registers from the regfile. Control signals for later stages are bundled into the ID/EX register.
- **EX**: Performs arithmetic or logical operations, calculates branch targets, and decides whether branches/jumps are taken. Forwarding logic lives here, choosing operands from the newest available source.
- **MEM**: Handles loads/stores through the data memory interface. Stores push bytes/halfwords/words out, while loads capture raw data and align/sign-extend it.
- **WB**: Selects between ALU result, memory data, or PC+4 (for JAL/JALR) and writes the chosen value into the destination register.

## 3. Pipeline Registers
Dedicated modules (`if_id`, `id_ex`, `ex_mem`, `mem_wb`) isolate stages so every cycle’s inputs are stable. Flushing (writing zeros) inserts bubbles, while stalling holds a register’s contents constant.

## 4. Hazards
### 4.1 Data Hazards
When an instruction needs a value that a previous instruction has not written yet.
- **Forwarding (Bypassing)**: Instead of waiting for WB, EX stage can take results directly from EX/MEM or MEM/WB. Signals `forward_a`/`forward_b` select the proper source.
- **Load-Use Hazard**: Loads produce data at the end of MEM, so the very next instruction cannot forward from EX/MEM (value isn’t ready). The hazard unit detects this situation (ID uses RS1/RS2 == load’s RD) and:
  - Freezes PC and IF/ID for one cycle (`pc_write=0`, `if_id_write=0`).
  - Flushes ID/EX, inserting a bubble so EX stage has harmless work during that cycle.

### 4.2 Control Hazards
Branches and jumps change PC. The core predicts “not taken” by default. When EX decides the branch is taken (or a JAL/JALR occurs), it:
- Asserts `branch_taken_ex` to redirect the PC.
- Flushes IF/ID and ID/EX so instructions that were fetched speculatively are discarded. This produces a one-cycle penalty for every taken control transfer.

### 4.3 Structural Hazards
The Harvard architecture (separate instruction/data ports) and single-issue design eliminate resource conflicts, so structural hazards do not appear here.

## 5. Hazard Detection & Control Signals
- **`hazard_unit`**: Central brain that inspects pipeline register contents each cycle. Outputs include:
  - `stall`: general indicator of a load-use hazard.
  - `pc_write`, `if_id_write`: gating signals that freeze the program counter and IF/ID register.
  - `id_ex_flush`: injects a bubble into the ID/EX register when needed.
  - `forward_a`, `forward_b`: select lines for operand muxes in EX.
- **Branch flush**: independent from load-use detection; any taken branch/jump forces `if_id_flush` and `flush_id_ex` in `riscv_core.v`.

## 6. Tips for Debugging Hazards
1. **Look at pipeline registers**: Confirm that the instruction you expect is sitting in each stage when a stall or flush happens.
2. **Watch `forward_a/b`**: Values `2'b10` mean EX/MEM bypass, `2'b01` select MEM/WB, `2'b00` indicates original operand.
3. **Check `pc_write` and `if_id_write`**: When they drop to 0, the core is holding fetch/decode steady for a cycle.
4. **Trace `branch_taken_ex`**: High pulses correspond to pipeline flushes. Verify that the next instruction executed matches the branch target.

## 7. Extending the Pipeline
- Adding new instructions usually means updating decode tables and ALU functions; ensure new instructions also set `use_rs1/use_rs2` correctly so hazards stay accurate.
- Multi-cycle units (e.g., multiplier) would require additional handshakes or pipeline stages; this design currently assumes single-cycle ALU operations (including MUL/DIV modeled as combinational for simplicity).

Keep this guide nearby when reading waveforms or modifying control logic—the terms and behaviors here match the RTL and glossary entries.
