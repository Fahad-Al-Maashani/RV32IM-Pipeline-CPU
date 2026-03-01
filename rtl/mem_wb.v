// mem_wb.v - MEM/WB pipeline register

`timescale 1ns/1ps

module mem_wb (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_data_in,
    input  wire [31:0] pc4_in,
    input  wire [4:0]  rd_addr_in,
    input  wire        reg_write_in,
    input  wire [1:0]  wb_sel_in,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_data_out,
    output reg  [31:0] pc4_out,
    output reg  [4:0]  rd_addr_out,
    output reg         reg_write_out,
    output reg  [1:0]  wb_sel_out
);
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            alu_result_out <= 32'b0;
            mem_data_out   <= 32'b0;
            pc4_out        <= 32'b0;
            rd_addr_out    <= 5'b0;
            reg_write_out  <= 1'b0;
            wb_sel_out     <= 2'b0;
        end else begin
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            pc4_out        <= pc4_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            wb_sel_out     <= wb_sel_in;
        end
    end
endmodule
