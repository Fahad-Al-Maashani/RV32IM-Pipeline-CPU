// tb_riscv_core.v - Self-checking testbench for the RV32IM pipeline core

`timescale 1ns/1ps

module tb_riscv_core;
    reg clk;
    reg rst_n;

    // Core interfaces
    wire [31:0] imem_addr;
    wire [31:0] imem_read_data;
    wire        imem_en;

    wire [31:0] dmem_addr;
    wire [31:0] dmem_write_data;
    wire [31:0] dmem_read_data;
    wire        dmem_we;
    wire        dmem_re;
    wire [1:0]  dmem_size;

    // Instantiate DUT
    riscv_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_read_data(imem_read_data),
        .imem_en(imem_en),
        .dmem_addr(dmem_addr),
        .dmem_write_data(dmem_write_data),
        .dmem_read_data(dmem_read_data),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re),
        .dmem_size(dmem_size)
    );

    // ------------------------------------------------------------------
    // Simple Harvard memories
    // ------------------------------------------------------------------
    reg [31:0] imem [0:255];
    reg [7:0]  dmem [0:4095];

    assign imem_read_data = imem[imem_addr[9:2]];

    assign dmem_read_data = {dmem[{dmem_addr[11:2], 2'b11}] ,
                             dmem[{dmem_addr[11:2], 2'b10}] ,
                             dmem[{dmem_addr[11:2], 2'b01}] ,
                             dmem[{dmem_addr[11:2], 2'b00}] };

    integer idx;
    initial begin
        $readmemh("mem/program.hex", imem);
        for (idx = 0; idx < 4096; idx = idx + 1) begin
            dmem[idx] = 8'b0;
        end
    end

    // Clock and reset
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100 MHz
    end

    initial begin
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end

    // Data memory write behaviour with size control
    always @(posedge clk) begin
        if (dmem_we) begin
            case (dmem_size)
                2'b00: dmem[dmem_addr[11:0]] <= dmem_write_data[7:0];
                2'b01: begin
                    dmem[{dmem_addr[11:1], 1'b0}]     <= dmem_write_data[7:0];
                    dmem[{dmem_addr[11:1], 1'b1}]     <= dmem_write_data[15:8];
                end
                default: begin
                    dmem[{dmem_addr[11:2], 2'b00}] <= dmem_write_data[7:0];
                    dmem[{dmem_addr[11:2], 2'b01}] <= dmem_write_data[15:8];
                    dmem[{dmem_addr[11:2], 2'b10}] <= dmem_write_data[23:16];
                    dmem[{dmem_addr[11:2], 2'b11}] <= dmem_write_data[31:24];
                end
            endcase
        end
    end

    // Self-checking logic
    reg [31:0] expected [0:9];
    initial begin
        expected[0] = 32'd0;
        expected[1] = 32'd1;
        expected[2] = 32'd1;
        expected[3] = 32'd2;
        expected[4] = 32'd3;
        expected[5] = 32'd5;
        expected[6] = 32'd8;
        expected[7] = 32'd13;
        expected[8] = 32'd21;
        expected[9] = 32'd34;
    end

    function [31:0] load_word;
        input [31:0] addr;
        begin
            load_word = {dmem[addr+3], dmem[addr+2], dmem[addr+1], dmem[addr]};
        end
    endfunction

    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, tb_riscv_core);

        repeat (400) @(posedge clk);

        for (idx = 0; idx < 10; idx = idx + 1) begin
            if (load_word(idx * 4) !== expected[idx]) begin
                $display("[TB] ERROR: memory[%0d] expected %0d got %0d", idx, expected[idx], load_word(idx * 4));
                $finish;
            end
        end

        $display("[TB] PASS: Fibonacci sequence is correct");
        $finish;
    end

endmodule
