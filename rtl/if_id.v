// if_id.v - IF/ID pipeline register

`timescale 1ns/1ps

module if_id (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        write_en,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            pc_out    <= 32'b0;
            instr_out <= 32'b0;
        end else if (flush) begin
            pc_out    <= 32'b0;
            instr_out <= 32'b0; // bubble
        end else if (write_en) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end
endmodule
