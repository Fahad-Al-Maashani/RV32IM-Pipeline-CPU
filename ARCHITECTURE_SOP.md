# RV32IM CPU Architecture & SOP

## 1. Architectural Overview
- **ISA**: Implements the RISC-V RV32I base set with RV32M multiply/divide operations. All instructions are 32-bit wide with 32-bit general-purpose registers and address space.
- **Pipeline**: Classic 5-stage (IF, ID, EX, MEM, WB) with Harvard instruction/data interfaces. Each stage is isolated by explicit pipeline registers (`if_id`, `id_ex`, `ex_mem`, `mem_wb`).
- **Branch Strategy**: Static predict-not-taken. When a branch, JAL, or JALR resolves in EX, the IF/ID and ID/EX stages flush and the PC redirects to the computed target.
- **Hazard Handling**:
  - **Data hazards**: Forwarding paths from EX/MEM and MEM/WB into ALU operands; MEM results are eligible for bypass once available. Load-use hazards automatically stall IF/ID, freeze PC, and inject a bubble into ID/EX for one cycle.
  - **Control hazards**: Fixed one-cycle penalty for taken branches/jumps via pipeline flush.
- **Functional Units**:
  - `alu`: Supports ADD/SUB, logic, shifts, SLT/SLTU, and all RV32M ops (MUL*, DIV*, REM*). Division-by-zero returns RV32-spec results.
  - `regfile`: 32×32b, dual asynchronous read, synchronous write (x0 hard-wired to zero).
  - `control_unit`: Generates ALU control, memory enables, WB mux selects, branch type, and source-usage hints in one combinational block.
  - `imm_gen`: Produces sign/zero-extended immediates for I/S/B/U/J formats.
  - `hazard_unit`: Centralizes stall, flush, PC gating, and forwarding select calculations.
- **Memory Interface**:
  - Instruction: `imem_addr`, `imem_read_data`, `imem_en` (always asserted).
  - Data: `dmem_addr`, `dmem_write_data`, `dmem_read_data`, byte enables via `dmem_size`, plus `dmem_we`/`dmem_re`. Byte/halfword loads are aligned in the MEM stage according to `dmem_size` and `mem_unsigned`.

## 2. Microarchitectural Dataflow
1. **IF**: Program counter increments by 4. On redirect, PC loads jump/branch targets (`redirect_target`). IF/ID register captures PC and fetched instruction unless stalled.
2. **ID**: Control logic decodes opcode/funct bits, register operands are read, and immediates are generated. Signals governing ALU source selection, branch classification, memory operations, and WB paths traverse the ID/EX register.
3. **EX**: Forwarding muxes choose among original operands, EX/MEM result, or WB data. The ALU executes arithmetic/logic and resolves branch conditions. Jump/branch decisions feed back to the PC network, enforcing flushes when prediction fails.
4. **MEM**: Addresses and store data drive the external data bus. Load data is realigned/sign-extended before entering MEM/WB.
5. **WB**: Results from ALU, memory, or PC+4 are multiplexed and written back to the register file.

## 3. Module Summary
| Module | Responsibility |
| --- | --- |
| `riscv_core` | Top-level pipeline composition, PC logic, forwarding, and memory interface handling. |
| `alu` | Implements RV32I/M arithmetic/logical functions with proper shift and division semantics. |
| `regfile` | Dual read, single write register file preserving x0 semantics. |
| `control_unit` | Decodes instructions into control signals, including ALU op selection and branch metadata. |
| `imm_gen` | Generates immediates for I, S, B, U, and J type instructions. |
| `if_id`, `id_ex`, `ex_mem`, `mem_wb` | Pipeline registers encapsulating all stage signals. |
| `hazard_unit` | Detects load-use hazards, produces stall/flush enables, and selects forwarding paths. |

## 4. Verification Environment
- **Testbench**: `tb/tb_riscv_core.v` instantiates the core, provides simple synchronous memories, and loads `mem/program.hex` (Fibonacci program) via `$readmemh`.
- **Program ROM**: `mem/gen_program.py` emits a demonstration RV32I program that exercises forwarding, load-use stalls, and branch redirection.
- **Waveforms**: `$dumpfile("cpu_wave.vcd")` and `$dumpvars` are embedded for GTKWave analysis.

## 5. SOP (Standard Operating Procedure)
### 5.1 Prerequisites
- macOS/Linux shell with `python3`, `iverilog`, `vvp`, and optionally `gtkwave` available in `PATH`.

### 5.2 Build & Run
1. **Regenerate Program (optional)**: `make program` – re-create `mem/program.hex` if the Fibonacci assembler changes.
2. **Compile RTL + TB**: `make sim` – runs `iverilog -g2012`, producing `build/riscv_core_tb.out`.
3. **Execute Simulation**: `make run` – launches `vvp build/riscv_core_tb.out`; the console reports PASS/FAIL. A PASS indicates the computed Fibonacci numbers (10 entries) matched expectations and that hazard logic worked under the scripted scenario.

### 5.3 Waveform Debug
- `make wave` after a successful run to open `cpu_wave.vcd` in GTKWave. Key probes: `pc`, `if_id_instr`, `forward_a/b`, `dmem_*`, and pipeline register outputs for tracing hazards and control flow.

### 5.4 File Maintenance
- `make clean` removes the `build/` directory and waveform file.
- Modify RTL under `rtl/`, testbench under `tb/`, and regenerate the ROM via `mem/gen_program.py` whenever instruction sequences change.

### 5.5 Extension Guidelines
- To add instructions or features, update `defines.vh`, `control_unit.v`, and (if needed) `alu.v` plus any pipeline plumbing in `riscv_core.v`.
- For new software workloads, author additional assembly/hex generators inside `mem/` and adjust the testbench scoreboard accordingly.
