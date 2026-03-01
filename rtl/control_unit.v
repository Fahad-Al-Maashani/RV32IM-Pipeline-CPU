// control_unit.v - Decodes RV32IM instructions into control signals

`timescale 1ns/1ps
`include "defines.vh"

module control_unit (
    input  wire [31:0] instr,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         branch,
    output reg         jump,
    output reg         jalr,
    output reg         alu_src,
    output reg         op_a_pc,
    output reg  [4:0]  alu_ctrl,
    output reg  [1:0]  mem_size,
    output reg         mem_unsigned,
    output reg  [1:0]  wb_sel,
    output reg  [2:0]  branch_type,
    output reg         use_rs1,
    output reg         use_rs2
);
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;

    always @(*) begin
        // sane defaults (NOP)
        reg_write    = 1'b0;
        mem_read     = 1'b0;
        mem_write    = 1'b0;
        branch       = 1'b0;
        jump         = 1'b0;
        jalr         = 1'b0;
        alu_src      = 1'b0;
        op_a_pc      = 1'b0;
        alu_ctrl     = `ALU_ADD;
        mem_size     = 2'b10; // word
        mem_unsigned = 1'b0;
        wb_sel       = WB_ALU;
        branch_type  = 3'b000;
        use_rs1      = 1'b0;
        use_rs2      = 1'b0;

        case (opcode)
            `OPCODE_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = `ALU_PASS_B;
                wb_sel    = WB_ALU;
            end
            `OPCODE_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                op_a_pc   = 1'b1;
                alu_ctrl  = `ALU_ADD;
                wb_sel    = WB_ALU;
            end
            `OPCODE_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                wb_sel    = WB_PC4;
            end
            `OPCODE_JALR: begin
                reg_write = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = WB_PC4;
                use_rs1   = 1'b1;
            end
            `OPCODE_BRANCH: begin
                branch      = 1'b1;
                branch_type = funct3;
                use_rs1     = 1'b1;
                use_rs2     = 1'b1;
            end
            `OPCODE_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = WB_MEM;
                use_rs1   = 1'b1;
                case (funct3)
                    `FUNCT3_LB:  begin mem_size = 2'b00; mem_unsigned = 1'b0; end
                    `FUNCT3_LH:  begin mem_size = 2'b01; mem_unsigned = 1'b0; end
                    `FUNCT3_LW:  begin mem_size = 2'b10; mem_unsigned = 1'b0; end
                    `FUNCT3_LBU: begin mem_size = 2'b00; mem_unsigned = 1'b1; end
                    `FUNCT3_LHU: begin mem_size = 2'b01; mem_unsigned = 1'b1; end
                    default:     begin mem_size = 2'b10; mem_unsigned = 1'b0; end
                endcase
            end
            `OPCODE_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                case (funct3)
                    `FUNCT3_SB: mem_size = 2'b00;
                    `FUNCT3_SH: mem_size = 2'b01;
                    `FUNCT3_SW: mem_size = 2'b10;
                    default:    mem_size = 2'b10;
                endcase
            end
            `OPCODE_OPIMM: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                use_rs1   = 1'b1;
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_ctrl = `ALU_ADD;
                    `FUNCT3_SLT:     alu_ctrl = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_ctrl = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_ctrl = `ALU_XOR;
                    `FUNCT3_OR:      alu_ctrl = `ALU_OR;
                    `FUNCT3_AND:     alu_ctrl = `ALU_AND;
                    `FUNCT3_SLL:     alu_ctrl = `ALU_SLL;
                    `FUNCT3_SRL_SRA: alu_ctrl = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    default:         alu_ctrl = `ALU_ADD;
                endcase
            end
            `OPCODE_OP: begin
                reg_write = 1'b1;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                case (funct3)
                    `FUNCT3_ADD_SUB: begin
                        if (funct7 == `FUNCT7_MULDIV) begin
                            alu_ctrl = `ALU_MUL;
                        end else begin
                            alu_ctrl = (funct7 == `FUNCT7_SUB) ? `ALU_SUB : `ALU_ADD;
                        end
                    end
                    `FUNCT3_SLL: begin
                        alu_ctrl = (funct7 == `FUNCT7_MULDIV) ? `ALU_MULH : `ALU_SLL;
                    end
                    `FUNCT3_SLT: begin
                        alu_ctrl = (funct7 == `FUNCT7_MULDIV) ? `ALU_MULHSU : `ALU_SLT;
                    end
                    `FUNCT3_SLTU: begin
                        alu_ctrl = (funct7 == `FUNCT7_MULDIV) ? `ALU_MULHU : `ALU_SLTU;
                    end
                    `FUNCT3_XOR: begin
                        alu_ctrl = (funct7 == `FUNCT7_MULDIV) ? `ALU_DIV : `ALU_XOR;
                    end
                    `FUNCT3_SRL_SRA: begin
                        if (funct7 == `FUNCT7_MULDIV)
                            alu_ctrl = `ALU_DIVU;
                        else
                            alu_ctrl = (funct7 == `FUNCT7_SRA) ? `ALU_SRA : `ALU_SRL;
                    end
                    `FUNCT3_OR: begin
                        alu_ctrl = (funct7 == `FUNCT7_MULDIV) ? `ALU_REM : `ALU_OR;
                    end
                    `FUNCT3_AND: begin
                        alu_ctrl = (funct7 == `FUNCT7_MULDIV) ? `ALU_REMU : `ALU_AND;
                    end
                    default: alu_ctrl = `ALU_ADD;
                endcase
            end
            default: begin
                // treat as NOP
            end
        endcase
    end

endmodule
