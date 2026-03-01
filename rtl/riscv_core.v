// riscv_core.v - Top-level 5-stage pipelined RV32IM processor core
// Implements forwarding, hazard detection, and static not-taken branch prediction

`timescale 1ns/1ps
`include "defines.vh"

module riscv_core (
    input  wire        clk,
    input  wire        rst_n,
    // Instruction memory interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_read_data,
    output wire        imem_en,
    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_write_data,
    input  wire [31:0] dmem_read_data,
    output wire        dmem_we,
    output wire        dmem_re,
    output wire [1:0]  dmem_size
);
    // ------------------------------------------------------------------
    // Program counter and fetch stage
    // ------------------------------------------------------------------
    reg [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;

    wire pc_write;
    wire branch_taken_ex;
    wire [31:0] redirect_target;
    wire pc_update_en = branch_taken_ex ? 1'b1 : pc_write;
    wire [31:0] pc_next = branch_taken_ex ? redirect_target : pc_plus4;

    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            pc <= 32'b0;
        end else if (pc_update_en) begin
            pc <= pc_next;
        end
    end

    assign imem_addr = pc;
    assign imem_en   = 1'b1;

    // IF/ID register wires
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;
    wire        if_id_write;
    wire        hazard_id_ex_flush;
    wire        stall;
    wire        if_id_flush = branch_taken_ex; // flush on any redirect

    if_id u_if_id (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(if_id_write),
        .flush(if_id_flush),
        .pc_in(pc),
        .instr_in(imem_read_data),
        .pc_out(if_id_pc),
        .instr_out(if_id_instr)
    );

    // ------------------------------------------------------------------
    // Decode stage
    // ------------------------------------------------------------------
    wire [4:0] id_rs1 = if_id_instr[19:15];
    wire [4:0] id_rs2 = if_id_instr[24:20];
    wire [4:0] id_rd  = if_id_instr[11:7];
    wire [31:0] id_pc4 = if_id_pc + 32'd4;

    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_branch;
    wire        id_jump;
    wire        id_jalr;
    wire        id_alu_src;
    wire        id_op_a_pc;
    wire [4:0]  id_alu_ctrl;
    wire [1:0]  id_mem_size;
    wire        id_mem_unsigned;
    wire [1:0]  id_wb_sel;
    wire [2:0]  id_branch_type;
    wire        id_use_rs1;
    wire        id_use_rs2;

    control_unit u_control (
        .instr(if_id_instr),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .branch(id_branch),
        .jump(id_jump),
        .jalr(id_jalr),
        .alu_src(id_alu_src),
        .op_a_pc(id_op_a_pc),
        .alu_ctrl(id_alu_ctrl),
        .mem_size(id_mem_size),
        .mem_unsigned(id_mem_unsigned),
        .wb_sel(id_wb_sel),
        .branch_type(id_branch_type),
        .use_rs1(id_use_rs1),
        .use_rs2(id_use_rs2)
    );

    wire [31:0] imm_id;
    imm_gen u_imm (
        .instr(if_id_instr),
        .imm_out(imm_id)
    );

    // Write-back stage wires (declared later) feed the register file
    wire [31:0] wb_data;
    wire        wb_reg_write;
    wire [4:0]  wb_rd_addr;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(wb_reg_write),
        .rs1_addr(id_rs1),
        .rs2_addr(id_rs2),
        .rd_addr(wb_rd_addr),
        .rd_data(wb_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ID/EX pipeline register
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_pc4;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_imm;
    wire [4:0]  id_ex_rs1_addr;
    wire [4:0]  id_ex_rs2_addr;
    wire [4:0]  id_ex_rd_addr;
    wire [4:0]  id_ex_alu_ctrl;
    wire        id_ex_alu_src;
    wire        id_ex_op_a_pc;
    wire        id_ex_reg_write;
    wire        id_ex_mem_read;
    wire        id_ex_mem_write;
    wire [1:0]  id_ex_mem_size;
    wire        id_ex_mem_unsigned;
    wire [1:0]  id_ex_wb_sel;
    wire        id_ex_branch;
    wire [2:0]  id_ex_branch_type;
    wire        id_ex_jump;
    wire        id_ex_jalr;

    wire flush_id_ex;
    assign flush_id_ex = hazard_id_ex_flush | branch_taken_ex;

    id_ex u_id_ex (
        .clk(clk),
        .rst_n(rst_n),
        .flush(flush_id_ex),
        .pc_in(if_id_pc),
        .pc4_in(id_pc4),
        .rs1_data_in(rs1_data),
        .rs2_data_in(rs2_data),
        .imm_in(imm_id),
        .rs1_addr_in(id_rs1),
        .rs2_addr_in(id_rs2),
        .rd_addr_in(id_rd),
        .alu_ctrl_in(id_alu_ctrl),
        .alu_src_in(id_alu_src),
        .op_a_pc_in(id_op_a_pc),
        .reg_write_in(id_reg_write),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .mem_size_in(id_mem_size),
        .mem_unsigned_in(id_mem_unsigned),
        .wb_sel_in(id_wb_sel),
        .branch_in(id_branch),
        .branch_type_in(id_branch_type),
        .jump_in(id_jump),
        .jalr_in(id_jalr),
        .pc_out(id_ex_pc),
        .pc4_out(id_ex_pc4),
        .rs1_data_out(id_ex_rs1_data),
        .rs2_data_out(id_ex_rs2_data),
        .imm_out(id_ex_imm),
        .rs1_addr_out(id_ex_rs1_addr),
        .rs2_addr_out(id_ex_rs2_addr),
        .rd_addr_out(id_ex_rd_addr),
        .alu_ctrl_out(id_ex_alu_ctrl),
        .alu_src_out(id_ex_alu_src),
        .op_a_pc_out(id_ex_op_a_pc),
        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .mem_size_out(id_ex_mem_size),
        .mem_unsigned_out(id_ex_mem_unsigned),
        .wb_sel_out(id_ex_wb_sel),
        .branch_out(id_ex_branch),
        .branch_type_out(id_ex_branch_type),
        .jump_out(id_ex_jump),
        .jalr_out(id_ex_jalr)
    );

    // ------------------------------------------------------------------
    // Hazard detection and forwarding controls
    // ------------------------------------------------------------------
    // Forwarding bus wires declared early for hazard/forward network
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data;
    wire [31:0] ex_mem_pc4;
    wire [4:0]  ex_mem_rd_addr;
    wire        ex_mem_reg_write;
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire [1:0]  ex_mem_mem_size;
    wire        ex_mem_mem_unsigned;
    wire [1:0]  ex_mem_wb_sel;

    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;
    wire [31:0] mem_wb_pc4;
    wire [4:0]  mem_wb_rd_addr;
    wire        mem_wb_reg_write;
    wire [1:0]  mem_wb_wb_sel;

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    hazard_unit u_hazard (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd_addr),
        .id_ex_rs1(id_ex_rs1_addr),
        .id_ex_rs2(id_ex_rs2_addr),
        .id_use_rs1(id_use_rs1),
        .id_use_rs2(id_use_rs2),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_rd(ex_mem_rd_addr),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd(mem_wb_rd_addr),
        .stall(stall),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .id_ex_flush(hazard_id_ex_flush),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ------------------------------------------------------------------
    // Execute stage
    // ------------------------------------------------------------------
    wire [31:0] mem_wb_forward_data;
    wire [31:0] ex_mem_forward_data;

    // MEM/WB forward data defined later once mem_wb signals exist

    wire [31:0] forward_a_data;
    wire [31:0] forward_b_data;

    assign forward_a_data = (forward_a == 2'b10) ? ex_mem_forward_data :
                            (forward_a == 2'b01) ? mem_wb_forward_data :
                            id_ex_rs1_data;

    assign forward_b_data = (forward_b == 2'b10) ? ex_mem_forward_data :
                            (forward_b == 2'b01) ? mem_wb_forward_data :
                            id_ex_rs2_data;

    wire [31:0] operand_a = id_ex_op_a_pc ? id_ex_pc : forward_a_data;
    wire [31:0] operand_b = id_ex_alu_src ? id_ex_imm : forward_b_data;

    wire [31:0] alu_result;
    wire        alu_zero;
    alu u_alu (
        .a(operand_a),
        .b(operand_b),
        .alu_ctrl(id_ex_alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Branch compare uses forwarded register data directly
    reg branch_cond;
    always @(*) begin
        case (id_ex_branch_type)
            `FUNCT3_BEQ:  branch_cond = (forward_a_data == forward_b_data);
            `FUNCT3_BNE:  branch_cond = (forward_a_data != forward_b_data);
            `FUNCT3_BLT:  branch_cond = ($signed(forward_a_data) < $signed(forward_b_data));
            `FUNCT3_BGE:  branch_cond = ($signed(forward_a_data) >= $signed(forward_b_data));
            `FUNCT3_BLTU: branch_cond = (forward_a_data < forward_b_data);
            `FUNCT3_BGEU: branch_cond = (forward_a_data >= forward_b_data);
            default:      branch_cond = 1'b0;
        endcase
    end

    wire [31:0] branch_target = id_ex_pc + id_ex_imm;
    wire [31:0] jalr_target = (forward_a_data + id_ex_imm) & 32'hFFFF_FFFE;

    wire branch_taken = id_ex_branch && branch_cond;
    assign branch_taken_ex = branch_taken | id_ex_jump | id_ex_jalr;
    assign redirect_target = id_ex_jalr ? jalr_target : branch_target;

    // ------------------------------------------------------------------
    // EX/MEM pipeline register
    // ------------------------------------------------------------------
    ex_mem u_ex_mem (
        .clk(clk),
        .rst_n(rst_n),
        .alu_result_in(alu_result),
        .rs2_data_in(forward_b_data),
        .pc4_in(id_ex_pc4),
        .rd_addr_in(id_ex_rd_addr),
        .reg_write_in(id_ex_reg_write),
        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),
        .mem_size_in(id_ex_mem_size),
        .mem_unsigned_in(id_ex_mem_unsigned),
        .wb_sel_in(id_ex_wb_sel),
        .alu_result_out(ex_mem_alu_result),
        .rs2_data_out(ex_mem_rs2_data),
        .pc4_out(ex_mem_pc4),
        .rd_addr_out(ex_mem_rd_addr),
        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_size_out(ex_mem_mem_size),
        .mem_unsigned_out(ex_mem_mem_unsigned),
        .wb_sel_out(ex_mem_wb_sel)
    );

    assign ex_mem_forward_data = (ex_mem_wb_sel == 2'b10) ? ex_mem_pc4 : ex_mem_alu_result;

    // ------------------------------------------------------------------
    // Memory stage
    // ------------------------------------------------------------------
    assign dmem_addr       = ex_mem_alu_result;
    assign dmem_write_data = ex_mem_rs2_data;
    assign dmem_we         = ex_mem_mem_write;
    assign dmem_re         = ex_mem_mem_read;
    assign dmem_size       = ex_mem_mem_size;

    wire [31:0] load_data_ext;
    wire [1:0]  addr_low = ex_mem_alu_result[1:0];
    wire [7:0]  load_byte = (addr_low == 2'b00) ? dmem_read_data[7:0]  :
                            (addr_low == 2'b01) ? dmem_read_data[15:8] :
                            (addr_low == 2'b10) ? dmem_read_data[23:16]:
                                                 dmem_read_data[31:24];
    wire [15:0] load_half = addr_low[1] ? dmem_read_data[31:16] : dmem_read_data[15:0];

    reg [31:0] load_data_raw;
    always @(*) begin
        case (ex_mem_mem_size)
            2'b00: load_data_raw = {{24{load_byte[7]}}, load_byte};
            2'b01: load_data_raw = {{16{load_half[15]}}, load_half};
            default: load_data_raw = dmem_read_data;
        endcase
    end

    assign load_data_ext = ex_mem_mem_unsigned ?
                            (ex_mem_mem_size == 2'b00 ? {24'b0, load_byte} :
                             ex_mem_mem_size == 2'b01 ? {16'b0, load_half} :
                             dmem_read_data) :
                            load_data_raw;

    // ------------------------------------------------------------------
    // MEM/WB pipeline register
    // ------------------------------------------------------------------
    mem_wb u_mem_wb (
        .clk(clk),
        .rst_n(rst_n),
        .alu_result_in(ex_mem_alu_result),
        .mem_data_in(load_data_ext),
        .pc4_in(ex_mem_pc4),
        .rd_addr_in(ex_mem_rd_addr),
        .reg_write_in(ex_mem_reg_write),
        .wb_sel_in(ex_mem_wb_sel),
        .alu_result_out(mem_wb_alu_result),
        .mem_data_out(mem_wb_mem_data),
        .pc4_out(mem_wb_pc4),
        .rd_addr_out(mem_wb_rd_addr),
        .reg_write_out(mem_wb_reg_write),
        .wb_sel_out(mem_wb_wb_sel)
    );

    assign wb_rd_addr  = mem_wb_rd_addr;
    assign wb_reg_write = mem_wb_reg_write;

    reg [31:0] wb_data_r;
    always @(*) begin
        case (mem_wb_wb_sel)
            2'b01: wb_data_r = mem_wb_mem_data;
            2'b10: wb_data_r = mem_wb_pc4;
            default: wb_data_r = mem_wb_alu_result;
        endcase
    end
    assign wb_data = wb_data_r;

    assign mem_wb_forward_data = wb_data_r;

endmodule
