#!/bin/bash
set -e
mkdir -p sim/build
iverilog -g2012 -o sim/build/escrow_tb src/escrow_release_controller.v src/tb_escrow_release_controller.v
vvp sim/build/escrow_tb
