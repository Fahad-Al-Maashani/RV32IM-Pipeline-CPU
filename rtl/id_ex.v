// id_ex.v - ID/EX pipeline register

`timescale 1ns/1ps

module id_ex (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] pc4_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [4:0]  alu_ctrl_in,
    input  wire        alu_src_in,
    input  wire        op_a_pc_in,
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  mem_size_in,
    input  wire        mem_unsigned_in,
    input  wire [1:0]  wb_sel_in,
    input  wire        branch_in,
    input  wire [2:0]  branch_type_in,
    input  wire        jump_in,
    input  wire        jalr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] pc4_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_addr_out,
    output reg  [4:0]  alu_ctrl_out,
    output reg         alu_src_out,
    output reg         op_a_pc_out,
    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg  [1:0]  mem_size_out,
    output reg         mem_unsigned_out,
    output reg  [1:0]  wb_sel_out,
    output reg         branch_out,
    output reg  [2:0]  branch_type_out,
    output reg         jump_out,
    output reg         jalr_out
);
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            pc_out           <= 32'b0;
            pc4_out          <= 32'b0;
            rs1_data_out     <= 32'b0;
            rs2_data_out     <= 32'b0;
            imm_out          <= 32'b0;
            rs1_addr_out     <= 5'b0;
            rs2_addr_out     <= 5'b0;
            rd_addr_out      <= 5'b0;
            alu_ctrl_out     <= 5'b0;
            alu_src_out      <= 1'b0;
            op_a_pc_out      <= 1'b0;
            reg_write_out    <= 1'b0;
            mem_read_out     <= 1'b0;
            mem_write_out    <= 1'b0;
            mem_size_out     <= 2'b0;
            mem_unsigned_out <= 1'b0;
            wb_sel_out       <= 2'b0;
            branch_out       <= 1'b0;
            branch_type_out  <= 3'b0;
            jump_out         <= 1'b0;
            jalr_out         <= 1'b0;
        end else if (flush) begin
            pc_out           <= 32'b0;
            pc4_out          <= 32'b0;
            rs1_data_out     <= 32'b0;
            rs2_data_out     <= 32'b0;
            imm_out          <= 32'b0;
            rs1_addr_out     <= 5'b0;
            rs2_addr_out     <= 5'b0;
            rd_addr_out      <= 5'b0;
            alu_ctrl_out     <= 5'b0;
            alu_src_out      <= 1'b0;
            op_a_pc_out      <= 1'b0;
            reg_write_out    <= 1'b0;
            mem_read_out     <= 1'b0;
            mem_write_out    <= 1'b0;
            mem_size_out     <= 2'b0;
            mem_unsigned_out <= 1'b0;
            wb_sel_out       <= 2'b0;
            branch_out       <= 1'b0;
            branch_type_out  <= 3'b0;
            jump_out         <= 1'b0;
            jalr_out         <= 1'b0;
        end else begin
            pc_out           <= pc_in;
            pc4_out          <= pc4_in;
            rs1_data_out     <= rs1_data_in;
            rs2_data_out     <= rs2_data_in;
            imm_out          <= imm_in;
            rs1_addr_out     <= rs1_addr_in;
            rs2_addr_out     <= rs2_addr_in;
            rd_addr_out      <= rd_addr_in;
            alu_ctrl_out     <= alu_ctrl_in;
            alu_src_out      <= alu_src_in;
            op_a_pc_out      <= op_a_pc_in;
            reg_write_out    <= reg_write_in;
            mem_read_out     <= mem_read_in;
            mem_write_out    <= mem_write_in;
            mem_size_out     <= mem_size_in;
            mem_unsigned_out <= mem_unsigned_in;
            wb_sel_out       <= wb_sel_in;
            branch_out       <= branch_in;
            branch_type_out  <= branch_type_in;
            jump_out         <= jump_in;
            jalr_out         <= jalr_in;
        end
    end
endmodule
