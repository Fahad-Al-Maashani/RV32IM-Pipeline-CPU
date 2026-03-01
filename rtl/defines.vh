// Global parameter definitions for RV32IM core

`ifndef DEFINES_VH
`define DEFINES_VH

// Opcodes
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011
`define OPCODE_OPIMM    7'b0010011
`define OPCODE_OP       7'b0110011
`define OPCODE_MISC_MEM 7'b0001111
`define OPCODE_SYSTEM   7'b1110011

// Funct3 encodings
`define FUNCT3_ADD_SUB  3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_SLT      3'b010
`define FUNCT3_SLTU     3'b011
`define FUNCT3_XOR      3'b100
`define FUNCT3_SRL_SRA  3'b101
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111

// Branch funct3
`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001
`define FUNCT3_BLT      3'b100
`define FUNCT3_BGE      3'b101
`define FUNCT3_BLTU     3'b110
`define FUNCT3_BGEU     3'b111

// Load/store sizes
`define FUNCT3_LB       3'b000
`define FUNCT3_LH       3'b001
`define FUNCT3_LW       3'b010
`define FUNCT3_LBU      3'b100
`define FUNCT3_LHU      3'b101

`define FUNCT3_SB       3'b000
`define FUNCT3_SH       3'b001
`define FUNCT3_SW       3'b010

// Funct7 encodings
`define FUNCT7_ADD      7'b0000000
`define FUNCT7_SUB      7'b0100000
`define FUNCT7_SRA      7'b0100000
`define FUNCT7_MULDIV   7'b0000001

// ALU control codes
`define ALU_ADD     5'd0
`define ALU_SUB     5'd1
`define ALU_AND     5'd2
`define ALU_OR      5'd3
`define ALU_XOR     5'd4
`define ALU_SLT     5'd5
`define ALU_SLTU    5'd6
`define ALU_SLL     5'd7
`define ALU_SRL     5'd8
`define ALU_SRA     5'd9
`define ALU_PASS_B  5'd10
`define ALU_PASS_A  5'd11
`define ALU_MUL     5'd12
`define ALU_MULH    5'd13
`define ALU_MULHSU  5'd14
`define ALU_MULHU   5'd15
`define ALU_DIV     5'd16
`define ALU_DIVU    5'd17
`define ALU_REM     5'd18
`define ALU_REMU    5'd19

`endif
