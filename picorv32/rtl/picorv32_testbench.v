module picorv32_testbench_custom (
    input clk,
    input resetn
);
    parameter MEM_SIZE = 65536;
    
    reg mem_valid;
    reg mem_instr;
    wire mem_ready;
    
    reg [31:0] mem_addr;
    reg [31:0] mem_wdata;
    reg [ 3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    
    wire mem_la_read;
    wire mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [ 3:0] mem_la_wstrb;
    
    // PicoRV32 core
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .LATCHED_MEM_RDATA(0),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1),
        .ENABLE_PCPI(0),
        .ENABLE_MUL(0),
        .ENABLE_FAST_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
        .ENABLE_TRACE(0),
        .REGS_INIT_ZERO(0),
        .MASKED_IRQ(32'h 0000_0000),
        .LATCHED_IRQ(32'h ffff_ffff),
        .PROGADDR_RESET(32'h 0000_0000),
        .PROGADDR_IRQ(32'h 0000_0010),
        .STACKADDR(32'h 0001_0000)
    ) uut (
        .clk         (clk        ),
        .resetn      (resetn     ),
        .mem_valid   (mem_valid  ),
        .mem_instr   (mem_instr  ),
        .mem_ready   (mem_ready  ),
        .mem_addr    (mem_addr   ),
        .mem_wdata   (mem_wdata  ),
        .mem_wstrb   (mem_wstrb  ),
        .mem_rdata   (mem_rdata  ),
        .mem_la_read (mem_la_read ),
        .mem_la_write(mem_la_write),
        .mem_la_addr (mem_la_addr ),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb)
    );
    
    // Memory model
    reg [31:0] memory [0:MEM_SIZE/4-1];
    reg [31:0] m_read_data;
    reg m_read_en;
    
    // UART output handling
    localparam UART_TX_ADDR = 32'h0200_0000;
    
    always @(posedge clk) begin
        if (mem_la_write && mem_la_addr == UART_TX_ADDR) begin
            // UART write detected
            $write("%c", mem_la_wdata[7:0]);
            $fflush();
        end
    end
    
    // Memory handling
    assign mem_ready = 1;
    assign mem_rdata = m_read_data;
    
    always @(posedge clk) begin
        m_read_en <= 0;
        
        if (mem_la_read) begin
            if (mem_la_addr != UART_TX_ADDR) begin
                // Regular memory read
                m_read_en <= 1;
                m_read_data <= memory[mem_la_addr[31:2]];
            end
        end
        
        if (mem_la_write) begin
            if (mem_la_addr != UART_TX_ADDR) begin
                // Regular memory write
                if (mem_la_wstrb[0]) memory[mem_la_addr[31:2]][ 7: 0] <= mem_la_wdata[ 7: 0];
                if (mem_la_wstrb[1]) memory[mem_la_addr[31:2]][15: 8] <= mem_la_wdata[15: 8];
                if (mem_la_wstrb[2]) memory[mem_la_addr[31:2]][23:16] <= mem_la_wdata[23:16];
                if (mem_la_wstrb[3]) memory[mem_la_addr[31:2]][31:24] <= mem_la_wdata[31:24];
            end
        end
    end
    
    // Initialize memory with program
    initial begin
        // Load the compiled Rust program here
        $readmemh("../rust-hello-world/hello_world.hex", memory);
    end
    
    // Simple test bench to monitor simulation
    initial begin
        $display("Starting PicoRV32 simulation with Rust hello-world program");
        
        // Run for a reasonable amount of time
        #10000;
        
        $display("Simulation complete");
        $finish;
    end
    
endmodule

module testbench();
    reg clk = 0;
    reg resetn = 0;
    
    always #5 clk = ~clk;
    
    initial begin
        repeat (10) @(posedge clk);
        resetn <= 1;
    end
    
    picorv32_testbench_custom dut (
        .clk(clk),
        .resetn(resetn)
    );
    
    // Generate VCD trace
    initial begin
        $dumpfile("picorv32_rust.vcd");
        $dumpvars(0, testbench);
    end
endmodule
