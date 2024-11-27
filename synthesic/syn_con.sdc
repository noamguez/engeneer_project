# SDC File for Verilog Design

# Define clock and set its period
create_clock -name "clk" -period 12.5 [get_ports clk]

# Set input delay and output delay for specific input and output ports
#set_input_delay -clock [get_clocks clk] 0.5 [get_ports inputs_from_sensors*]
#set_input_delay -clock [get_clocks clk] 0.5 [get_ports MOSI]
#set_input_delay -clock [get_clocks clk] 0.5 [get_ports reset]
#set_input_delay -clock [get_clocks clk] 0.5 [get_ports ss]

#set_output_delay -clock [get_clocks clk] 0.5 [get_ports reg_r_w_out*]
#set_output_delay -clock [get_clocks clk] 0.5 [get_ports MISO]

# Set false paths and multi-cycle paths if needed
# Example: Set false path from async_reset to all other signals
# set_false_path -from [get_ports async_reset]

# Example: Set multi-cycle path from register1/Q to register2/D with setup time 2 ns and hold time 1 ns
# set_multicycle_path -setup 2 -hold 1 -from [get_ports {register1/Q}] -to [get_ports {register2/D}]

# Save the SDC file
# write_sdc /path/to/save/design_constraints.sdc
