`timescale 1ns/1ps

module EVChargingController_tb;

// Testbench signals
reg clk;
reg reset;
reg [15:0] current;
reg [15:0] voltage;
reg [15:0] temperature;
wire charging;
wire [3:0] state;
wire [3:0] slot_id;
wire [3:0] assigned_slot_id;
wire [31:0] charging_time;
wire [7:0] fault_code;

// Clock generation
always #5 clk = ~clk; // 100MHz clock

// Instantiate the EV Charging Controller
EVChargingController uut (
    .clk(clk),
    .reset(reset),
    .current(current),
    .voltage(voltage),
    .temperature(temperature),
    .charging(charging),
    .state(state),
    .slot_id(slot_id),
    .assigned_slot_id(assigned_slot_id),
    .charging_time(charging_time),
    .fault_code(fault_code)
);

// Initialize the inputs
initial begin
    // Monitor important signals
    $monitor($time, " state=%b, slot_id=%d, assigned_slot_id=%d, charging_time=%d, fault_code=%b",
             state, slot_id, assigned_slot_id, charging_time, fault_code);

    // Initialize signals
    clk = 0;
    reset = 1;
    current = 16'd0;
    voltage = 16'd0;
    temperature = 16'd0;
	 
	 #50 current = 16'd50;  // Normal current
#100 current = 16'd500; // Over-current scenario
#50 current = 16'd20;  // Low current


    // Reset the system
    #10 reset = 0;

    // Apply test vectors
    #10 voltage = 16'd1100; // Start charging
    #100 voltage = 16'd3500; // Still charging
    #100 voltage = 16'd4500; // Full charge
    #100 voltage = 16'd0; // Back to idle

    #10 temperature = 16'd90; // Over-temperature fault
    #100 temperature = 16'd70; // Normal temperature

    // Simulate additional charging cycles
    #50 voltage = 16'd1200; // Start charging
    #100 voltage = 16'd3700; // Still charging
    #100 voltage = 16'd4600; // Full charge
    #100 voltage = 16'd0; // Back to idle

    // End simulation
    #500 $finish;
end

endmodule
