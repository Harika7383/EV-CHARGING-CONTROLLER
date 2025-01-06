module EVChargingController (
    input wire clk,
    input wire reset,
    input wire [15:0] current,
    input wire [15:0] voltage,
    input wire [15:0] temperature,
    output reg charging,
    output reg [3:0] state,
    output reg [3:0] slot_id,
    output reg [3:0] assigned_slot_id,
    output reg [31:0] charging_time,
    output reg [7:0] fault_code
);

// State encoding
localparam IDLE = 4'b0001, CHARGING = 4'b0010, FULL = 4'b0100, ERROR = 4'b1000;

// State register
reg [3:0] current_state, next_state;

// Charging time calculation
reg [31:0] start_time;

// Assign slot logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        slot_id <= 4'b0000;
        assigned_slot_id <= 4'b0000;
    end else if (current_state == CHARGING) begin
        slot_id <= slot_id + 1;
        assigned_slot_id <= slot_id;
    end
end

// State transition
always @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// Next state logic
always @(*) begin
    case (current_state)
        IDLE: begin
            next_state = (voltage > 1000) ? CHARGING : IDLE;
        end
        CHARGING: begin
            if (voltage >= 4000) 
                next_state = FULL;
            else if (fault_code != 8'b00000000) // Fault detected
                next_state = ERROR;
            else 
                next_state = CHARGING;
        end
        FULL: next_state = IDLE;
        ERROR: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// Charging time tracking
always @(posedge clk or posedge reset) begin
    if (reset) begin
        charging_time <= 0;
        start_time <= 0;
    end
    else if (current_state == CHARGING) begin
        if (start_time == 0)
            start_time <= charging_time;
        charging_time <= charging_time + 1;
    end
end

// Fault detection
always @(posedge clk or posedge reset) begin
    if (reset)
        fault_code <= 8'b00000000;
    else if (temperature > 80)
        fault_code <= 8'b00000001; // Over-temperature fault
    else
        fault_code <= 8'b00000000; // No fault
end

// Output logic
always @(*) begin
    case (current_state)
        IDLE: charging = 1'b0;
        CHARGING: charging = 1'b1;
        FULL: charging = 1'b0;
        ERROR: charging = 1'b0;
    endcase
end

// State update
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= IDLE;
    else if (fault_code != 8'b00000000) // Immediate transition to ERROR if fault
        state <= ERROR;
    else
        state <= next_state;
end

endmodule
