# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in sync_counter.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ps/1ps lab7_part3.v

# Load simulation using sync_counter as the top level simulation module.
vsim DelayCounter -t 1ps

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# Set input values using the force command, signal names need to be in {} brackets.
force {clk_50mhz} 1 0ps, 0 1ps -r 2
force {rst} 1 0ps, 0 3ps
force {en} 1
run 100000003ps