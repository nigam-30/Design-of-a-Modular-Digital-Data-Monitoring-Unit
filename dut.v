// Code your design here
module data_monitor (
  //1. system controls
  input wire clock,//---------------------clk
  input wire reset,//---------------------rst_n
  
  //2. configuration inputs
  input wire [7:0] threshold_value,
  input wire monitor_enable,
  input wire data_mode,
  
  //3. sensor input
  input wire [7:0] sensor_data,
  
  //4. control input
  input wire software_acknowledgement,//---sw_ack
  
  //5. outputs
  output reg alarm_output,
  output reg [7:0] fault_capture
  
);
    //state definations
  parameter idle_state     = 2'b00;
  parameter alarm_state    = 2'b01;
  parameter cooldown_state = 2'b10;
  
  reg [1:0] state;
  reg [1:0] next_state;
  
  // Create comparison wires using bitwise operators only
  wire unsigned_gt;
  wire signed_gt;
  wire unsigned_lt;
  wire signed_lt;
  
  // Unsigned greater than: sensor_data > threshold_value
  // Implemented as: (sensor_data >= threshold_value) AND (sensor_data != threshold_value)
  wire [7:0] unsigned_diff = sensor_data - threshold_value;
  wire unsigned_ge = ~unsigned_diff[7];  // sensor_data >= threshold_value (MSB=0)
  wire unsigned_ne;
  
  // Check if any bit is 1 using bitwise OR (not logical OR)
  assign unsigned_ne = unsigned_diff[0] | unsigned_diff[1] | unsigned_diff[2] | unsigned_diff[3] |
                       unsigned_diff[4] | unsigned_diff[5] | unsigned_diff[6] | unsigned_diff[7];
  
  assign unsigned_gt = unsigned_ge & unsigned_ne;  // Use bitwise AND
  
  // Unsigned less than: sensor_data < threshold_value  
  assign unsigned_lt = unsigned_diff[7] & unsigned_ne;  // Use bitwise AND
  
  // Signed greater than: $signed(sensor_data) > $signed(threshold_value)
  // For signed comparison, we need to handle the sign bit
  wire sensor_sign = sensor_data[7];
  wire thresh_sign = threshold_value[7];
  
  // When signs are different
  wire diff_sign_gt = (~sensor_sign) & thresh_sign;  // sensor+, threshold-
  wire diff_sign_le = sensor_sign & (~thresh_sign);  // sensor-, threshold+
  
  // When signs are same, compare magnitude
  wire [6:0] sensor_mag = sensor_data[6:0];
  wire [6:0] thresh_mag = threshold_value[6:0];
  wire [6:0] signed_mag_diff = sensor_mag - thresh_mag;
  wire same_sign_gt;
  
  // For same sign comparison (both positive or both negative)
  // If both positive: sensor_mag > thresh_mag
  // If both negative: sensor_mag < thresh_mag (because -5 > -10)
  wire both_positive = (~sensor_sign) & (~thresh_sign);
  wire both_negative = sensor_sign & thresh_sign;
  
  // Compare magnitudes
  wire mag_gt = ~signed_mag_diff[6];  // sensor_mag >= thresh_mag
  wire mag_ne;
  
  // Check magnitude difference using bitwise OR
  assign mag_ne = signed_mag_diff[0] | signed_mag_diff[1] | signed_mag_diff[2] | signed_mag_diff[3] |
                  signed_mag_diff[4] | signed_mag_diff[5] | signed_mag_diff[6];
  
  wire mag_gt_ne = mag_gt & mag_ne;  // sensor_mag > thresh_mag
  
  // For negative numbers: we need reverse comparison
  wire mag_lt_ne = signed_mag_diff[6] & mag_ne;  // sensor_mag < thresh_mag
  
  // Same sign greater than logic
  assign same_sign_gt = (both_positive & mag_gt_ne) | (both_negative & mag_lt_ne);
  
  // Final signed greater than
  assign signed_gt = diff_sign_gt | same_sign_gt;  // Use bitwise OR
  
  // Signed less than: $signed(sensor_data) < $signed(threshold_value)
  wire same_sign_lt;
  assign same_sign_lt = (both_positive & mag_lt_ne) | (both_negative & mag_gt_ne);
  assign signed_lt = diff_sign_le | same_sign_lt;  // Use bitwise OR
  
  //State Register Sequential Logic
  always @(posedge clock or negedge reset) begin
    if(!reset) begin
      state <= idle_state;
    end else begin
      state <= next_state;
    end
  end
  
  //Next State Logic Combinational Logic
  always @(*) begin
    next_state = state;
    
    case (state)
      //1. idle_state
      idle_state: begin
        if (monitor_enable) begin
          if (data_mode == 1'b0) begin
            if (unsigned_gt) begin
              next_state = alarm_state;
            end
          end else begin
            if (signed_gt) begin
              next_state = alarm_state;
            end
          end
        end
      end
      
      //2. alarm state
      alarm_state: begin
        if (software_acknowledgement) begin
          next_state = cooldown_state;
        end
      end
      
      //3. cooldown state
      cooldown_state: begin
        if (data_mode == 1'b0) begin
          if (unsigned_lt) next_state = idle_state;
        end else begin
          if (signed_lt) next_state = idle_state;
        end
      end
    endcase
  end
  
  //Output logic Sequencial Action
  always @(posedge clock or negedge reset) begin
    if(!reset) begin
      alarm_output <= 1'b0;
      fault_capture <= 8'd0;
    end else begin
      case(state)
        idle_state:begin
          alarm_output <= 1'b0;
        end
        alarm_state: begin
          alarm_output <= 1'b1;
          fault_capture <= sensor_data;
        end
        cooldown_state: begin
          alarm_output <= 1'b0;
        end
      endcase
    end
  end
endmodule
