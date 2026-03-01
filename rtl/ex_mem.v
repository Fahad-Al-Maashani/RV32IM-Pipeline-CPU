// ex_mem.v - EX/MEM pipeline register

`timescale 1ns/1ps

module ex_mem (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] pc4_in,
    input  wire [4:0]  rd_addr_in,
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  mem_size_in,
    input  wire        mem_unsigned_in,
    input  wire [1:0]  wb_sel_in,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] pc4_out,
    output reg  [4:0]  rd_addr_out,
    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg  [1:0]  mem_size_out,
    output reg         mem_unsigned_out,
    output reg  [1:0]  wb_sel_out
);
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            alu_result_out   <= 32'b0;
            rs2_data_out     <= 32'b0;
            pc4_out          <= 32'b0;
            rd_addr_out      <= 5'b0;
            reg_write_out    <= 1'b0;
            mem_read_out     <= 1'b0;
            mem_write_out    <= 1'b0;
            mem_size_out     <= 2'b0;
            mem_unsigned_out <= 1'b0;
            wb_sel_out       <= 2'b0;
        end else begin
            alu_result_out   <= alu_result_in;
            rs2_data_out     <= rs2_data_in;
            pc4_out          <= pc4_in;
            rd_addr_out      <= rd_addr_in;
            reg_write_out    <= reg_write_in;
            mem_read_out     <= mem_read_in;
            mem_write_out    <= mem_write_in;
            mem_size_out     <= mem_size_in;
            mem_unsigned_out <= mem_unsigned_in;
            wb_sel_out       <= wb_sel_in;
        end
    end
endmodule
