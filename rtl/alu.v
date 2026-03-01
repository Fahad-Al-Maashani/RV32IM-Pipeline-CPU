// alu.v - Arithmetic Logic Unit for RV32IM core
// Implements RV32I arithmetic/logical operations plus RV32M multiply/divide

`timescale 1ns/1ps
`include "defines.vh"

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    // ALU control encodings
    wire [63:0] mul_signed_signed = $signed(a) * $signed(b);
    wire [63:0] mul_signed_unsigned = $signed(a) * {1'b0, b};
    wire [63:0] mul_unsigned = {1'b0, a} * {1'b0, b};

    wire div_by_zero = (b == 32'b0);
    wire [31:0] div_q_signed = div_by_zero ? 32'hFFFF_FFFF : $signed(a) / $signed(b);
    wire [31:0] div_q_unsigned = div_by_zero ? 32'hFFFF_FFFF : a / b;
    wire [31:0] div_r_signed = div_by_zero ? a : $signed(a) % $signed(b);
    wire [31:0] div_r_unsigned = div_by_zero ? a : a % b;

    always @(*) begin
        case (alu_ctrl)
            `ALU_ADD:    result = a + b;
            `ALU_SUB:    result = a - b;
            `ALU_AND:    result = a & b;
            `ALU_OR:     result = a | b;
            `ALU_XOR:    result = a ^ b;
            `ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            `ALU_SLL:    result = a << b[4:0];
            `ALU_SRL:    result = a >> b[4:0];
            `ALU_SRA:    result = $signed(a) >>> b[4:0];
            `ALU_PASS_B: result = b;
            `ALU_PASS_A: result = a;
            `ALU_MUL:    result = mul_signed_signed[31:0];
            `ALU_MULH:   result = mul_signed_signed[63:32];
            `ALU_MULHSU: result = mul_signed_unsigned[63:32];
            `ALU_MULHU:  result = mul_unsigned[63:32];
            `ALU_DIV:    result = div_q_signed;
            `ALU_DIVU:   result = div_q_unsigned;
            `ALU_REM:    result = div_r_signed;
            `ALU_REMU:   result = div_r_unsigned;
            default:    result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
