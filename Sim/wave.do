# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in sync_counter.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ps/1ps SpaceInvaderSim.v

# Load simulation using sync_counter as the top level simulation module.
vsim SpaceInvader -t 1ps

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# Set input values using the force command, signal names need to be in {} brackets.
force {CLOCK_50} 0 0ps, 1 1ps -r 2
force {KEY[0]} 0 0ps, 1 3ps
force {KEY[1]} 0
force {KEY[2]} 0
force {KEY[3]} 0 0ps, 1 200ps
force {SW[0]} 1
run 50000000ps
