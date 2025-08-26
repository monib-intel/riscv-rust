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
    
    // Test-related variables
    integer test_output_file;
    reg [7:0] uart_output_buffer [0:1023];  // Buffer to store UART output
    integer uart_output_index = 0;
    reg test_passed = 1;  // Assume test passes by default

    initial begin
        // Create output file for test results
        test_output_file = $fopen("uart_output.txt", "w");
        if (test_output_file == 0) begin
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
            $fwrite(test_output_file, "%c", uart_tx_data);
            $fflush(test_output_file);
            
            // Store in buffer for later verification
            if (uart_output_index < 1024) begin
                uart_output_buffer[uart_output_index] = uart_tx_data;
                uart_output_index = uart_output_index + 1;
            end
            
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
    integer found_hello;
    integer i;
    integer test_result_file;
    
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("testbench.vcd");
            $dumpvars(0, testbench);
        end
        
        // Run simulation for timeout cycles or until test completes
        repeat (10000) @(posedge clk);
        
        // Test verification
        if (uart_output_index > 0) begin
            $display("\n--- Test Results ---");
            $display("UART output captured: %0d characters", uart_output_index);
            
            // Check if the output contains the expected message
            found_hello = 0;
            
            for (i = 0; i < uart_output_index - 5; i = i + 1) begin
                if (uart_output_buffer[i] == "H" &&
                    uart_output_buffer[i+1] == "e" &&
                    uart_output_buffer[i+2] == "l" &&
                    uart_output_buffer[i+3] == "l" &&
                    uart_output_buffer[i+4] == "o") begin
                    found_hello = 1;
                end
            end
            
            if (found_hello) begin
                $display("✅ TEST PASSED: Found 'Hello' in the output");
                test_passed = 1;
            end else begin
                $display("❌ TEST FAILED: Did not find 'Hello' in the output");
                test_passed = 0;
            end
            
            // Write test result to a special file for the build system
            test_result_file = $fopen("test_result.txt", "w");
            if (test_result_file != 0) begin
                if (test_passed)
                    $fwrite(test_result_file, "PASS\n");
                else
                    $fwrite(test_result_file, "FAIL\n");
                $fclose(test_result_file);
            end
        end else begin
            $display("\n--- Test Results ---");
            $display("❌ TEST FAILED: No UART output captured");
            test_passed = 0;
            
            // Write test result to a special file for the build system
            test_result_file = $fopen("test_result.txt", "w");
            if (test_result_file != 0) begin
                $fwrite(test_result_file, "FAIL\n");
                $fclose(test_result_file);
            end
        end
        
        // Close UART output file
        $fclose(test_output_file);
        
        $display("TIMEOUT");
        $finish;
    end
endmodule
