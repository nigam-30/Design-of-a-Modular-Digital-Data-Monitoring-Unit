// Code your testbench here
// or browse Examples

module tb_data_monitor;
  
  // 1. devlare simulation signals
  reg clock;
  reg reset;
  reg [7:0] threshold_value;
  reg monitor_enable;
  reg data_mode;
  reg [7:0] sensor_data;
  reg software_acknowledgement;
  
  //outputs
  wire alarm_output;
  wire [7:0] fault_capture;
  
  // 2. instantiate
  data_monitor dut(
    .clock(clock),
    .reset(reset),
    .threshold_value(threshold_value),      
    .monitor_enable(monitor_enable),        
    .data_mode(data_mode),                  
    .sensor_data(sensor_data),              
    .software_acknowledgement(software_acknowledgement),
    .alarm_output(alarm_output),            
    .fault_capture(fault_capture)           
    );
  // 3. clock generation
   always #5 clock = ~clock;
  
  //4. main sequence 
  initial begin 
    clock = 0;
    reset = 0;
    threshold_value = 0;
    monitor_enable = 0;
    data_mode = 0;
    sensor_data = 0;
    software_acknowledgement = 0;
    
    //dump file
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_data_monitor);
    
    //reset sequence
    #20 reset = 1; 
    
    $display("===========================================");
    $display("STARTING FULL APPLICATION VERIFICATION");
    $display("===========================================");

    // --- CALLING ALL TASKS ---
    test_industrial_automation();
    test_automotive_ev();
    test_consumer_electronics();
    test_robotics();
    test_medical();
    test_environmental();
    test_audio_processing();
    test_security_safety();

    $display("===========================================");
    $display("ALL APPLICATION TESTS COMPLETED");
    $display("===========================================");
    $finish;
    
  end
  
      // ======================================================
    // TASK 1: INDUSTRIAL AUTOMATION (Unsigned)
    // Application: Motor Overheat Protection
    // ======================================================
    task test_industrial_automation;
        begin
            // 1. DELAY
            #50;
            
            // 2. PRINT MESSAGE
            $display("[%t] TITLE 1: INDUSTRIAL - Motor Overheat", $time);
            
            // 3. SETUP 
            data_mode = 0;          
            threshold_value = 80;   
            monitor_enable = 1;    
            sensor_data = 50;      
            
            // 4. WAIT FOR STABILITY
       
            repeat(5) @(posedge clock); 

            // 5. TRIGGER THE FAULT
            $display("[%t] Event: Motor Temp spikes to 90C", $time);
            sensor_data = 90;      
            
            // 6. WAIT FOR CAPTURE
            
            repeat(3) @(posedge clock); 

            // 7. CHECK THE RESULT
           
            if (fault_capture == 90) 
                $display("[%t] PASS: Fault Captured (90)", $time);
            else 
                $display("[%t] FAIL: Wrong Capture", $time);

            // 8. CLEAR THE ALARM (ACKNOWLEDGE)
            sensor_data = 50;       
            
            software_acknowledgement = 1; 
            @(posedge clock);       
            software_acknowledgement = 0;
            
            // 9. END TASK
        end
    endtask
  
      // ======================================================
    // TASK 2: AUTOMOTIVE / EV (Unsigned)
    // Application: Battery Overcharge Protection
    // ======================================================
  
    task test_automotive_ev;
        begin
            #50;
            $display("[%t] TITLE 2: AUTOMOTIVE - Battery Overcharge", $time);
            
            threshold_value = 90;
            monitor_enable = 1;
            sensor_data = 85;
            repeat(5) @(posedge clock);

            // Trigger Fault (Overcharge)
            $display("[%t] Event: Battery hits 95%", $time);
            sensor_data = 95;
            repeat(3) @(posedge clock);

            if (fault_capture == 95) $display("[%t] PASS: Battery Level Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 80; 
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask

    // ======================================================
    // TASK 3: CONSUMER ELECTRONICS (Unsigned)
    // Application: Smart Thermostat
    // ======================================================
  
    task test_consumer_electronics;
        begin
            $display("[%t] TITLE 3: CONSUMER - Smart Thermostat", $time);
            
            threshold_value = 30;
            monitor_enable = 1;
            sensor_data = 25; 
            repeat(5) @(posedge clock);

            // Trigger Fault (Hot room)
            sensor_data = 35;
            repeat(3) @(posedge clock);

            if (fault_capture == 35) $display("[%t] PASS: High Temp Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 25;
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask

    // ======================================================
    // TASK 4: ROBOTICS (Unsigned)
    // Application: Collision Detection (Current Surge)
    // ======================================================
  
    task test_robotics;
        begin
            $display("[%t] TITLE 4: ROBOTICS - Arm Collision", $time);
            
            threshold_value = 100;
            monitor_enable = 1;
            sensor_data = 50; 
            repeat(5) @(posedge clock);

            // Trigger Fault 
            $display("[%t] Event: Robot Arm crashes into wall", $time);
            sensor_data = 180;
            repeat(3) @(posedge clock);

            if (fault_capture == 180) $display("[%t] PASS: Surge Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 0; 
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask

    // ======================================================
    // TASK 5: MEDICAL (SIGNED MODE)
    // Application: Fever Detection
    // ======================================================
  
    task test_medical;
        begin
            $display("[%t] TITLE 5: MEDICAL - Fever Detection", $time);
            
            data_mode = 1; 
            threshold_value = 40; 
            monitor_enable = 1;
            sensor_data = 37;
            repeat(5) @(posedge clock);

            // Trigger Fault (Fever Spike)
          $display("[%t] Event: Patient Fever Spikes to 60C", $time);
            sensor_data = 60; 
            repeat(3) @(posedge clock);

            if (fault_capture == 60) $display("[%t] PASS: Fever Value Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 37; 
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask

    // ======================================================
    // TASK 6: ENVIRONMENTAL (Unsigned)
    // Application: Flood Warning System
    // ======================================================
  
    task test_environmental;
        begin
            $display("[%t] TITLE 6: ENVIRONMENTAL - Flood Warning", $time);
            
            data_mode = 0; 
            threshold_value = 6;
            monitor_enable = 1;
            sensor_data = 2; 
            repeat(5) @(posedge clock);

            // Trigger Fault 
          $display("[%t] Event: River Level rises to 8", $time);
            sensor_data = 8;
            repeat(3) @(posedge clock);

          if (fault_capture == 8) $display("[%t] PASS: Flood Level Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 3;
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask

    // ======================================================
    // TASK 7: AUDIO PROCESSING (SIGNED MODE)
    // Application: Audio Clipping Detection
    // ======================================================
  
    task test_audio_processing;
        begin
            $display("[%t] TITLE 7: AUDIO - Clipping Detection", $time);
            
            data_mode = 1; 
            threshold_value = 10; 
            monitor_enable = 1;
            sensor_data = 5; 
            repeat(5) @(posedge clock);

            // Trigger Fault 
            $display("[%t] Event: Audio spikes to +20 (Clip!)", $time);
            sensor_data = 20; 
            repeat(3) @(posedge clock);

            if (fault_capture == 20) $display("[%t] PASS: Clip Level Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 5;
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask

    // ======================================================
    // TASK 8: SECURITY (Unsigned)
    // Application: Intruder Motion Detection
    // ======================================================
  
    task test_security_safety;
        begin
            $display("[%t] TITLE 8: SECURITY - Intruder Detected", $time);
            
            data_mode = 0;
            threshold_value = 100; 
            monitor_enable = 1;
            sensor_data = 50; 
            repeat(5) @(posedge clock);

            // Trigger Fault 
            $display("[%t] Event: Intruder motion detected (Energy 150)", $time);
            sensor_data = 150; 
            repeat(3) @(posedge clock);

            if (fault_capture == 150) $display("[%t] PASS: Intruder Data Captured", $time);
            else $display("[%t] FAIL: Wrong Capture", $time);

            // ACK
            sensor_data = 50;
            software_acknowledgement = 1; @(posedge clock); software_acknowledgement = 0;
        end
    endtask
endmodule
