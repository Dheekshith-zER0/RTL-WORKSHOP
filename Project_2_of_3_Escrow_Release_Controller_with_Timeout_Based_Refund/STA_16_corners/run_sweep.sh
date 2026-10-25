#!/usr/bin/env bash
set -euo pipefail

# Run from the project root in the configured Linux VM.

PDK_ROOT="${PDK_ROOT:-/home/vsduser/Desktop/work/tools/openlane_working_dir/pdks}"
LIBDIR="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib"

NETLIST="runs/09-10_22-08/results/synthesis/escrow_release_controller.synthesis_cts.v"
SPEF="runs/09-10_22-08/results/routing/escrow_release_controller.spef"

OUT="reports/sta_16_corners"
SUBMISSION="submission/sta_16_corners"
SUMMARY="$OUT/summary.csv"
TMP_SUMMARY="$OUT/summary_tns.tmp.csv"

mkdir -p "$OUT" "$SUBMISSION"

[[ -f "$NETLIST" ]] || { echo "ERROR: Netlist not found: $NETLIST"; exit 1; }
[[ -f "$SPEF" ]] || { echo "ERROR: SPEF not found: $SPEF"; exit 1; }
[[ -d "$LIBDIR" ]] || { echo "ERROR: Liberty directory not found: $LIBDIR"; exit 1; }
[[ -x /usr/bin/sta ]] || { echo "ERROR: /usr/bin/sta is not executable."; exit 1; }

mapfile -t LIBS < <(
find "$LIBDIR" -maxdepth 1 -type f -name 'sky130_fd_sc_hd__*.lib' 
! -iname '*ccsnoise*' | sort
)

if [[ "${#LIBS[@]}" -ne 16 ]]; then
echo "ERROR: Expected 16 Liberty files; found ${#LIBS[@]}."
exit 1
fi

# Keep the previous summary intact until all 16 runs succeed.

printf 'corner,setup_worst_slack_ns,setup_tns_ns,hold_worst_slack_ns,status\n' > "$TMP_SUMMARY"

for LIB in "${LIBS[@]}"; do
NAME="$(basename "$LIB" .lib)"
LOG="$OUT/${NAME}_tns.log"
TCL="$OUT/${NAME}_tns.tcl"

```
cat > "$TCL" <<TCL_EOF
```

read_liberty $LIB
read_verilog $NETLIST
link_design escrow_release_controller

create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 2.0 -clock clk [get_ports {rst start buyer_approve seller_approve arbiter_approve}]
set_output_delay 2.0 -clock clk [get_ports {release_to_seller refund_to_buyer busy done}]

read_spef $SPEF
set_propagated_clock [all_clocks]

puts "RESULT_SETUP_WNS_BEGIN"
report_worst_slack -max
puts "RESULT_SETUP_TNS_BEGIN"
report_tns
puts "RESULT_HOLD_WNS_BEGIN"
report_worst_slack -min
exit
TCL_EOF

```
echo "Running $NAME ..."

if /usr/bin/sta -no_splash -exit "$TCL" > "$LOG" 2>&1; then
    SETUP="$(awk '/RESULT_SETUP_WNS_BEGIN/{s=1;next}/RESULT_SETUP_TNS_BEGIN/{s=0}s&&/^worst slack /{print $3;exit}' "$LOG")"
    TNS="$(awk '/RESULT_SETUP_TNS_BEGIN/{s=1;next}/RESULT_HOLD_WNS_BEGIN/{s=0}s&&/^tns /{print $2;exit}' "$LOG")"
    HOLD="$(awk '/RESULT_HOLD_WNS_BEGIN/{s=1;next}s&&/^worst slack /{print $3;exit}' "$LOG")"

    if [[ -n "$SETUP" && -n "$TNS" && -n "$HOLD" ]]; then
        printf '%s,%s,%s,%s,REVIEW\n' "$NAME" "$SETUP" "$TNS" "$HOLD" >> "$TMP_SUMMARY"
        echo "  WNS=$SETUP ns | TNS=$TNS ns | Hold=$HOLD ns"
    else
        echo "ERROR: Could not parse metrics for $NAME; see $LOG"
        exit 1
    fi
else
    echo "ERROR: OpenSTA failed for $NAME; see $LOG"
    exit 1
fi
```

done

if [[ "$(wc -l < "$TMP_SUMMARY")" -ne 17 ]]; then
echo "ERROR: Expected 16 valid corner rows."
exit 1
fi

if grep -Eq ',NA,|,PARSE_ERROR$|,STA_ERROR$' "$TMP_SUMMARY"; then
echo "ERROR: Invalid metrics detected; previous summary preserved."
exit 1
fi

mv "$TMP_SUMMARY" "$SUMMARY"
cp "$SUMMARY" "$SUBMISSION/summary.csv"

echo "SUCCESS: All 16 corners produced WNS, TNS, and hold slack."
echo "Updated: $SUMMARY"
echo "Updated: $SUBMISSION/summary.csv"
