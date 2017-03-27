# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in sync_counter.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns lab7_part3.v

# Load simulation using sync_counter as the top level simulation module.
vsim control

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

# Set input values using the force command, signal names need to be in {} brackets.
force {clk} 0 0ns, 1 1ns -r 2
force {go} 0
force {draw_finish} 0
force {erase_finish} 0
force {next_move} 0
# Run simulation for a few ns.
run 15ns

force {go} 1
run 3ns

force {go} 0
run 30ns

force {draw_finish} 1
run 3ns

force {draw_finish} 0
run 30ns