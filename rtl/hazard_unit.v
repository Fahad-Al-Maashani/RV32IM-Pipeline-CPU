// hazard_unit.v - Detects load-use hazards and supplies forwarding controls

`timescale 1ns/1ps

module hazard_unit (
    input  wire        id_ex_mem_read,
    input  wire [4:0]  id_ex_rd,
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire        id_use_rs1,
    input  wire        id_use_rs2,
    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,
    input  wire        ex_mem_reg_write,
    input  wire        ex_mem_mem_read,
    input  wire [4:0]  ex_mem_rd,
    input  wire        mem_wb_reg_write,
    input  wire [4:0]  mem_wb_rd,
    output wire        stall,
    output wire        pc_write,
    output wire        if_id_write,
    output wire        id_ex_flush,
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);
    wire load_use_hazard = id_ex_mem_read && (id_ex_rd != 5'd0) &&
        ((id_use_rs1 && (id_ex_rd == if_id_rs1)) || (id_use_rs2 && (id_ex_rd == if_id_rs2)));

    assign stall      = load_use_hazard;
    assign pc_write   = ~load_use_hazard;
    assign if_id_write = ~load_use_hazard;
    assign id_ex_flush = load_use_hazard;

    always @(*) begin
        // default: no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (ex_mem_reg_write && !ex_mem_mem_read && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10; // EX/MEM bypass
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01; // MEM/WB bypass
        end

        if (ex_mem_reg_write && !ex_mem_mem_read && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end

endmodule
