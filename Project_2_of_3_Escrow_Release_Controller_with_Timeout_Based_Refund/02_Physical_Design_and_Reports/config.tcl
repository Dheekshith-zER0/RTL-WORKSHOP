# OpenLane configuration for the 2-of-3 Escrow Release Controller.
# Adjust VERILOG_FILES if your OpenLane installation expects a different path.

set ::env(DESIGN_NAME) "escrow_release_controller"
set ::env(VERILOG_FILES) "$::env(DESIGN_DIR)/src/escrow_release_controller.v"
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10.0"
set ::env(FP_CORE_UTIL) 40
set ::env(PL_TARGET_DENSITY) 0.50

# Conservative pad configuration for a small educational design.
set ::env(CELL_PAD) 4
