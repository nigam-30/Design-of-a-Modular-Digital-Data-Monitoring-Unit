`timescale 1ns / 1ps

module tb_apb_wrapper;

    // APB Bus Signals
    reg        pclk;
    reg        presetn;
    reg        psel;
    reg        penable;
    reg        pwrite;
    reg [31:0] paddr;
    reg [31:0] pwdata;
    wire [31:0] prdata;
    wire       pready;
    wire       pslverr;

    // External Hardware Pins
    reg [7:0]  sensor_data;
    wire       alarm_output;

    // Instantiate the Wrapper
    apb_demu_wrapper uut (
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),
        
        .sensor_data(sensor_data),
        .alarm_output(alarm_output)
    );

    // Clock Generation
    always #5 pclk = ~pclk;

    // ==========================================
    // APB WRITE TASK (Processor writes to DEMU)
    // ==========================================
    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge pclk);
            // SETUP Phase
            psel    <= 1'b1;
            pwrite  <= 1'b1;
            paddr   <= addr;
            pwdata  <= data;
            
            @(posedge pclk);
            // ACCESS Phase
            penable <= 1'b1;
            
            @(posedge pclk);
            // Finish Transaction
            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
        end
    endtask

    // ==========================================
    // APB READ TASK (Processor reads from DEMU)
    // ==========================================
    task apb_read;
        input [31:0] addr;
        begin
            @(posedge pclk);
            // SETUP Phase
            psel    <= 1'b1;
            pwrite  <= 1'b0;
            paddr   <= addr;
            
            @(posedge pclk);
            // ACCESS Phase
            penable <= 1'b1;
            
            @(posedge pclk);
            // Finish Transaction
            psel    <= 1'b0;
            penable <= 1'b0;
            
            // Display Read Data
            $display("[%t] APB READ from Addr %h: Data = %h", $time, addr, prdata);
        end
    endtask

    // ==========================================
    // Main Stimulus
    // ==========================================
    initial begin
        // Dump file for Waveform
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_apb_wrapper);

        // Initialize
        pclk = 0; presetn = 0; psel = 0; penable = 0; 
        pwrite = 0; paddr = 0; pwdata = 0; sensor_data = 0;

        // Reset
        #20 presetn = 1;
        
        $display("---- APB Wrapper Simulation Started ----");

        // 1. Set Threshold to 80 via APB
        $display("[%t] Setting Threshold to 80", $time);
        apb_write(32'h00, 32'd80);

        // 2. Enable Monitor and set Unsigned Mode (data_mode=0, monitor_enable=1)
        $display("[%t] Enabling Monitor in Unsigned Mode", $time);
        apb_write(32'h04, 32'h01); // pwdata[0]=1 (enable), pwdata[1]=0 (unsigned)

        // 3. Provide normal sensor data
        sensor_data = 50;
        #50;

        // 4. Trigger the alarm (Sensor data > Threshold)
        $display("[%t] Sensor Spike! Setting sensor_data to 90", $time);
        sensor_data = 90;
        #40;

        // 5. Read Alarm Status Register to see if alarm went off
        apb_read(32'h10);

        // 6. Send Software Acknowledgement via APB
        $display("[%t] Sending SW Acknowledge", $time);
        apb_write(32'h08, 32'h01); // Write 1 to ack

        // 7. Bring sensor down to clear cooldown
        sensor_data = 50;
        #50;

        $display("---- APB Wrapper Simulation Ended ----");
        $finish;
    end

endmodule