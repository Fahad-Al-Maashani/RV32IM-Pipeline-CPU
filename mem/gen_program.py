#!/usr/bin/env python3
"""Generate a simple Fibonacci program for the RV32I core."""

from pathlib import Path

OPCODE_OP = 0x33
OPCODE_OPIMM = 0x13
OPCODE_LOAD = 0x03
OPCODE_STORE = 0x23
OPCODE_BRANCH = 0x63
OPCODE_JAL = 0x6F


def mask(value, bits):
    return value & ((1 << bits) - 1)


def encode_r(funct7, rs2, rs1, funct3, rd, opcode=OPCODE_OP):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) \
           | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_i(imm, rs1, funct3, rd, opcode=OPCODE_OPIMM):
    imm &= 0xFFF
    return (imm << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) \
           | ((rd & 0x1F) << 7) | (opcode & 0x7F)


def encode_s(imm, rs2, rs1, funct3, opcode=OPCODE_STORE):
    imm &= 0xFFF
    imm_hi = (imm >> 5) & 0x7F
    imm_lo = imm & 0x1F
    return (imm_hi << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) \
           | ((funct3 & 0x7) << 12) | (imm_lo << 7) | (opcode & 0x7F)


def encode_b(imm, rs2, rs1, funct3, opcode=OPCODE_BRANCH):
    imm &= 0x1FFF
    bit12 = (imm >> 12) & 0x1
    bit10_5 = (imm >> 5) & 0x3F
    bit4_1 = (imm >> 1) & 0xF
    bit11 = (imm >> 11) & 0x1
    return (bit12 << 31) | (bit10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) \
           | ((funct3 & 0x7) << 12) | (bit4_1 << 8) | (bit11 << 7) | (opcode & 0x7F)


def encode_j(imm, rd, opcode=OPCODE_JAL):
    imm &= 0x1FFFFF
    bit20 = (imm >> 20) & 0x1
    bit10_1 = (imm >> 1) & 0x3FF
    bit11 = (imm >> 11) & 0x1
    bit19_12 = (imm >> 12) & 0xFF
    return (bit20 << 31) | (bit19_12 << 12) | (bit11 << 20) | (bit10_1 << 21) \
           | ((rd & 0x1F) << 7) | (opcode & 0x7F)


# Convenience helpers -------------------------------------------------------

def add(rd, rs1, rs2):
    return encode_r(0x00, rs2, rs1, 0x0, rd)


def addi(rd, rs1, imm):
    imm &= 0xFFF if imm >= 0 else ((1 << 12) + imm)
    return encode_i(imm, rs1, 0x0, rd)


def slli(rd, rs1, shamt):
    imm = (shamt & 0x1F) | (0x00 << 5)
    return encode_i(imm, rs1, 0x1, rd)


def lw(rd, rs1, imm):
    val = imm & 0xFFF if imm >= 0 else ((1 << 12) + imm)
    return encode_i(val, rs1, 0x2, rd, OPCODE_LOAD)


def sw(rs2, rs1, imm):
    val = imm & 0xFFF if imm >= 0 else ((1 << 12) + imm)
    return encode_s(val, rs2, rs1, 0x2)


def blt(rs1, rs2, imm):
    # Branch immediates are multiples of 2, so ensure encoding handles negatives
    val = imm & 0x1FFF if imm >= 0 else ((1 << 13) + imm)
    return encode_b(val, rs2, rs1, 0x4)


def jal(rd, imm):
    val = imm & 0x1FFFFF if imm >= 0 else ((1 << 21) + imm)
    return encode_j(val, rd)


def main():
    instructions = []
    # Initialize registers
    instructions.append(addi(1, 0, 0))   # x1 = 0
    instructions.append(addi(2, 0, 1))   # x2 = 1
    instructions.append(addi(3, 0, 2))   # loop index
    instructions.append(addi(4, 0, 10))  # limit N=10
    instructions.append(addi(5, 0, 0))   # base address 0
    instructions.append(sw(1, 5, 0))     # store F0
    instructions.append(sw(2, 5, 4))     # store F1
    # loop label at PC = 7 * 4 = 28
    instructions.append(add(6, 1, 2))    # x6 = x1 + x2
    instructions.append(add(10, 6, 0))   # x10 = x6 (forwarding)
    instructions.append(slli(7, 3, 2))   # offset = i << 2
    instructions.append(add(7, 5, 7))    # address = base + offset
    instructions.append(sw(6, 7, 0))     # store fib[i]
    instructions.append(lw(8, 7, 0))     # load stored value
    instructions.append(add(9, 8, 0))    # immediate use (load-use hazard)
    instructions.append(add(1, 2, 0))    # x1 = x2
    instructions.append(add(2, 6, 0))    # x2 = x6
    instructions.append(addi(3, 3, 1))   # i++
    branch_offset = (7 * 4) - (17 * 4)  # target_pc - current_pc
    instructions.append(blt(3, 4, branch_offset))
    instructions.append(jal(0, 0))       # halt

    program_path = Path(__file__).with_name('program.hex')
    imem_depth = 256
    with program_path.open('w', encoding='ascii') as fh:
        for instr in instructions:
            fh.write(f"{instr:08x}\n")
        for _ in range(len(instructions), imem_depth):
            fh.write("00000013\n")  # NOP padding

    print(f"Wrote {len(instructions)} instructions to {program_path}")


if __name__ == "__main__":
    main()
