`timescale 1 ns / 1 ps

module testbench;
    reg clk = 1;
    reg resetn = 0;
    wire trap;

    always #5 clk = ~clk;

    initial begin
        repeat (10) @(posedge clk);
        resetn <= 1;
    end

    // UART output handling
    reg [7:0] uart_tx_data;
    reg uart_tx_valid = 0;
    
    // File for UART output
    integer uart_output_file;

    initial begin
        // Create output file for UART data
        uart_output_file = $fopen("uart_output.txt", "w");
        if (uart_output_file == 0) begin
            $display("Error: Could not open uart_output.txt for writing");
            $finish;
        end
    end

    always @(posedge clk) begin
        if (uart_tx_valid) begin
            // Print character to console
            $write("%c", uart_tx_data);
            $fflush();
            
            // Write to file
            $fwrite(uart_output_file, "%c", uart_tx_data);
            $fflush(uart_output_file);
            
            uart_tx_valid <= 0; // Clear after processing
        end
    end

    // Memory parameters
    parameter MEM_SIZE = 65536; // 64K
    parameter MEM_WORDS = MEM_SIZE / 4;
    
    // Memory
    reg [31:0] memory [0:MEM_WORDS-1];
    
    // Initialize memory with the firmware
    initial begin
        integer i;
        // Initialize all memory to zero
        for (i = 0; i < MEM_WORDS; i = i + 1)
            memory[i] = 32'h0;
        
        // Read hex file - use system task to avoid warnings about file size
        $display("Loading program.hex into memory...");
        $readmemh("program.hex", memory);
        $display("Memory initialization complete");
    end

    // PicoRV32 memory interface
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;
    wire        mem_valid;
    reg         mem_ready;

    // Simple memory controller
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            if (mem_addr[31:24] == 8'h02) begin
                // UART at 0x02000000
                if (|mem_wstrb) begin
                    uart_tx_data <= mem_wdata[7:0];
                    uart_tx_valid <= 1;
                end
                mem_ready <= 1;
            end else begin
                // RAM at 0x00000000
                if (|mem_wstrb) begin
                    if (mem_wstrb[0]) memory[mem_addr[23:2]][7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) memory[mem_addr[23:2]][15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) memory[mem_addr[23:2]][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[mem_addr[23:2]][31:24] <= mem_wdata[31:24];
                end else begin
                    mem_rdata <= memory[mem_addr[23:2]];
                end
                mem_ready <= 1;
            end
        end

        if (!resetn) begin
            uart_tx_valid <= 0;
        end
    end

    // Instantiate PicoRV32 core
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .PROGADDR_RESET(32'h00000000),
        .STACKADDR(32'h00010000)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // Simulation control
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("testbench.vcd");
            $dumpvars(0, testbench);
        end
        
        // Run simulation for a fixed number of cycles
        repeat (10000) @(posedge clk);
        
        // Close UART output file
        $fclose(uart_output_file);
        
        $display("Simulation complete");
        $finish;
    end
endmodule
