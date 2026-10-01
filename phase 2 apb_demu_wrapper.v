`timescale 1ns / 1ps

module apb_demu_wrapper (
    // =========================================
    // APB Bus Interface (From Processor/System)
    // =========================================
    input  wire        pclk,
    input  wire        presetn,      // Active low reset
    input  wire        psel,         // Peripheral Select
    input  wire        penable,      // Enable signal
    input  wire        pwrite,       // 1=Write, 0=Read
    input  wire [31:0] paddr,        // Address bus
    input  wire [31:0] pwdata,       // Data to write
    output reg  [31:0] prdata,       // Data read by CPU
    output wire        pready,       // Always 1 (No wait states)
    output wire        pslverr,      // Always 0 (No errors)

    // =========================================
    // External Hardware Pins (Outside the Chip)
    // =========================================
    input  wire [7:0] sensor_data,   // Live sensor input
    output wire       alarm_output   // Physical alarm pin
);

    // =========================================
    // 1. Internal Wires & Registers
    // =========================================
    reg [7:0] threshold_reg;
    reg       monitor_enable_reg;
    reg       data_mode_reg;
    reg       sw_ack_reg;
    
    wire [7:0] fault_capture_wire;
    
    // APB Handshaking
    assign pready  = 1'b1; // Single-cycle APB transfer
    assign pslverr = 1'b0; 

    // =========================================
    // 2. APB Write Logic (CPU -> DEMU)
    // =========================================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            threshold_reg    <= 8'd0;
            monitor_enable_reg <= 1'b0;
            data_mode_reg    <= 1'b0;
            sw_ack_reg       <= 1'b0;
        end else begin
            // Default: clear the ack after 1 clock cycle (Auto-clear logic)
            sw_ack_reg <= 1'b0; 
            
            // APB Write Condition: Setup + Access phase
            if (psel && penable && pwrite) begin
                case (paddr)
                    32'h00: threshold_reg    <= pwdata[7:0];
                    32'h04: begin
                                monitor_enable_reg <= pwdata[0];
                                data_mode_reg      <= pwdata[1];
                            end
                    32'h08: sw_ack_reg       <= pwdata[0]; // CPU writes 1 to ack
                    default: ; // Do nothing
                endcase
            end
        end
    end

    // =========================================
    // 3. APB Read Logic (DEMU -> CPU)
    // =========================================
    always @(*) begin
        prdata = 32'd0; // Default read value
        if (psel && penable && !pwrite) begin
            case (paddr)
                32'h00: prdata = {24'd0, threshold_reg};
                32'h04: prdata = {30'd0, data_mode_reg, monitor_enable_reg};
                32'h0C: prdata = {24'd0, sensor_data};    // Read live sensor
                32'h10: prdata = {24'd0, fault_capture_wire, alarm_output}; // Read status
                default: prdata = 32'd0;
            endcase
        end
    end

    // =========================================
    // 4. Instantiate the Original DEMU Core
    // =========================================
    data_monitor demu_core_inst (
        .clock                  (pclk),
        .reset                  (presetn),
        
        .threshold_value        (threshold_reg),
        .monitor_enable         (monitor_enable_reg),
        .data_mode              (data_mode_reg),
        
        .sensor_data            (sensor_data),
        .software_acknowledgement(sw_ack_reg),
        
        .alarm_output           (alarm_output),
        .fault_capture          (fault_capture_wire)
    );

endmodule