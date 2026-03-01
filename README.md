# RV32IM Pipeline CPU

A teaching-scale, five-stage RISC-V RV32IM core that demonstrates forwarding, load-use stall insertion, and simple Harvard instruction/data interfaces. This repository contains synthesizable RTL, a self-checking Verilog testbench, a Fibonacci program generator, waveform dumps, and companion documentation so you can explore classic pipeline behavior end-to-end.

## Key Capabilities
- RV32I base ISA plus RV32M multiply/divide/remainder instructions executed in an IF/ID/EX/MEM/WB pipeline.
- Deterministic hazard management: EX/MEM + MEM/WB forwarding, automatic load-use stall injection, and branch/jump flushes.
- Minimal external dependencies—only Python 3, Icarus Verilog (`iverilog` + `vvp`), and optionally GTKWave.
- Makefile-driven flow that regenerates demo software, compiles RTL, runs the testbench, and emits `cpu_wave.vcd` for debugging.

## Prerequisites
| Requirement | Install / Verify |
| --- | --- |
| Python 3.8+ | `python3 --version` (macOS: `brew install python`; Ubuntu: `sudo apt install python3`). |
| Icarus Verilog (iverilog + vvp) | macOS: `brew install icarus-verilog`; Ubuntu: `sudo apt install iverilog`. |
| GTKWave (optional for viewing VCDs) | macOS: `brew install gtkwave`; Ubuntu: `sudo apt install gtkwave`. |
| Make | Included on macOS/Linux by default (Xcode CLT on macOS). |

Add the installed binaries (`python3`, `iverilog`, `vvp`, `gtkwave`) to your `PATH`. Reopen your terminal after installation so new PATH entries take effect.

## Quick Start
```sh
git clone https://github.com/<your-handle>/cpu_5pipeline.git
cd cpu_5pipeline
make run
```
A PASS message at the end of `make run` confirms the Fibonacci workload completed correctly.

## Step-by-Step Simulation Guide
1. **Clone**
   ```sh
   git clone https://github.com/<your-handle>/cpu_5pipeline.git
   cd cpu_5pipeline
   ```
2. **Confirm toolchain**
   ```sh
   python3 --version
   iverilog -V
   vvp -V
   gtkwave --version   # optional
   ```
   Install missing tools using the commands in the prerequisites table.
3. **(Optional) regenerate the program ROM**
   ```sh
   make program
   ```
   This runs `python3 mem/gen_program.py` to rebuild `mem/program.hex`. Do this whenever you edit the generator.
4. **Compile RTL + testbench**
   ```sh
   make sim
   ```
   - Produces `build/riscv_core_tb.out` using all sources under `rtl/` and `tb/`.
   - Re-run automatically if any RTL/testbench files change.
5. **Run the simulation**
   ```sh
   make run
   ```
   - Executes `vvp build/riscv_core_tb.out`.
   - Console prints PASS when the first ten Fibonacci numbers stored in memory match expectation.
   - Always regenerates `cpu_wave.vcd` in the repo root.
6. **Inspect the waveform (optional)**
   ```sh
   make wave
   ```
   Launches GTKWave with `cpu_wave.vcd`. Follow the signal grouping suggestions in `WAVEFORM.md` to debug the pipeline.
7. **Clean build artifacts**
   ```sh
   make clean
   ```
   Removes `build/` and `cpu_wave.vcd` so you can start fresh.

### Tip: one-liner workflow
```sh
make program && make sim && make run
```
This ensures the program image, simulator build, and run are always in sync.

## Troubleshooting
| Symptom | Fix |
| --- | --- |
| `make: iverilog: No such file or directory` | Install Icarus Verilog (`brew install icarus-verilog` or `sudo apt install iverilog`). |
| `vvp: command not found` | Ensure Icarus Verilog runtime (`vvp`) is on PATH; same installation as above. |
| `Module tb_riscv_core ... $readmemh` cannot open file | Re-run `make program` to recreate `mem/program.hex`, or ensure you run from repo root. |
| `PASS` never prints / simulation hangs | Inspect `cpu_wave.vcd` with `make wave` to check for stuck PC or misconfigured hazards; confirm you did not edit `mem/program.hex` manually. |
| GTKWave fails to open | Install GTKWave or open the VCD with any compatible viewer; `make wave` simply invokes `$GTKWAVE cpu_wave.vcd`. |

## Extending the Core
- Add instructions by editing `rtl/defines.vh`, `rtl/control_unit.v`, `rtl/alu.v`, and any required signals inside `rtl/riscv_core.v`.
- Update `rtl/hazard_unit.v` whenever you introduce multi-cycle units or new operand uses, so stalls/forwarding stay correct.
- Drop new workload generators into `mem/` (mirroring `gen_program.py`) and point the testbench to their output hex files.

## Additional Documentation
- `ARCHITECTURE_SOP.md` – standard operating procedure plus architectural overview.
- `PIPELINE.md` – plain-language explanation of stage behavior, hazards, and debugging advice.
- `WAVEFORM.md` – step-by-step instructions for inspecting `cpu_wave.vcd`.
- `GLOSSARY.md` – definitions for every signal and acronym referenced in RTL/testbench files.

Armed with these docs and the scripted flow, you can clone the repo, install dependencies, and reproduce the full RV32IM pipeline simulation without surprises.
