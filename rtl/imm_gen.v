// imm_gen.v - Immediate generator for RV32I formats

`timescale 1ns/1ps
`include "defines.vh"

module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm_out
);
    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            `OPCODE_LUI,
            `OPCODE_AUIPC: begin
                imm_out = {instr[31:12], 12'b0};
            end
            `OPCODE_JAL: begin
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            `OPCODE_BRANCH: begin
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            `OPCODE_LOAD,
            `OPCODE_OPIMM,
            `OPCODE_JALR: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end
            `OPCODE_STORE: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            default: begin
                imm_out = 32'b0;
            end
        endcase
    end

endmodule
