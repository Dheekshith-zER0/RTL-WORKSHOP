read_liberty /home/vsduser/Desktop/work/tools/openlane_working_dir/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_100C_1v80.lib
read_verilog runs/09-10_22-08/results/synthesis/escrow_release_controller.synthesis_cts.v
link_design escrow_release_controller

create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 2.0 -clock clk [get_ports {rst start buyer_approve seller_approve arbiter_approve}]
set_output_delay 2.0 -clock clk [get_ports {release_to_seller refund_to_buyer busy done}]

read_spef runs/09-10_22-08/results/routing/escrow_release_controller.spef
set_propagated_clock [all_clocks]

puts "RESULT_SETUP_WNS_BEGIN"
report_worst_slack -max
puts "RESULT_SETUP_TNS_BEGIN"
report_tns
puts "RESULT_HOLD_WNS_BEGIN"
report_worst_slack -min
exit
