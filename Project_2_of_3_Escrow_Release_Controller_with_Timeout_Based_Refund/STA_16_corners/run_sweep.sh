#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPENSTA="${OPENSTA:-sta}"; LIB_DIR="${LIB_DIR:-}"
STA_NETLIST="${STA_NETLIST:-}"; STA_SDC="${STA_SDC:-}"; STA_SPEF="${STA_SPEF:-}"
STA_DESIGN="${STA_DESIGN:-escrow_release_controller}"; MACRO_LIBS="${MACRO_LIBS:-}"
OUT_DIR="${OUT_DIR:-$HERE/logs}"; SUMMARY="$HERE/summary.csv"
die(){ echo "ERROR: $*" >&2; exit 2; }
command -v "$OPENSTA" >/dev/null 2>&1 || die "OpenSTA executable '$OPENSTA' not found."
[[ -n "$LIB_DIR" && -d "$LIB_DIR" ]] || die "Set LIB_DIR to the directory containing the 16 Liberty models."
for v in STA_NETLIST STA_SDC STA_SPEF; do [[ -n "${!v}" && -r "${!v}" ]] || die "Set $v to a readable file; see README.md."; done
mkdir -p "$OUT_DIR"
mapfile -t LIBS < <(find "$LIB_DIR" -maxdepth 1 -type f -name 'sky130_fd_sc_hd__*.lib' ! -iname '*ccsnoise*' -print | sort)
[[ "${#LIBS[@]}" -eq 16 ]] || die "Expected 16 non-CCS-noise standard-cell Liberty models in $LIB_DIR; found ${#LIBS[@]}."
TMP="$OUT_DIR/.run_corner.tcl"
printf 'corner,setup_worst_slack_ns,setup_tns_ns,hold_worst_slack_ns,status\n' > "$SUMMARY"
for lib in "${LIBS[@]}"; do
  corner="$(basename "$lib" .lib)"; log="$OUT_DIR/$corner.log"
  export CORNER_LIB="$lib" STA_NETLIST STA_SDC STA_SPEF STA_DESIGN MACRO_LIBS
  python3 - "$TMP" <<'PY'
import os,sys
def q(s):
    if any(c in s for c in "{}"): raise SystemExit("Path contains braces unsupported by Tcl quoting: "+s)
    return "{"+s+"}"
lines=["read_liberty "+q(os.environ["CORNER_LIB"])]
for p in filter(None,os.environ.get("MACRO_LIBS","").split(":")): lines.append("read_liberty "+q(p))
lines += ["read_verilog "+q(os.environ["STA_NETLIST"]),
"link_design "+q(os.environ["STA_DESIGN"]),
"read_sdc "+q(os.environ["STA_SDC"]),
"read_spef "+q(os.environ["STA_SPEF"]),
"set_propagated_clock [all_clocks]",
'puts "### SETUP_WNS ###"',"report_worst_slack -max",
'puts "### SETUP_TNS ###"',"report_tns -max",
'puts "### HOLD_WORST_SLACK ###"',"report_worst_slack -min",
'puts "### CONSTRAINT_CHECK_BEGIN ###"',"check_setup -verbose",
'puts "### CONSTRAINT_CHECK_END ###"',"exit"]
open(sys.argv[1],"w").write("\n".join(lines)+"\n")
PY
  echo "Running $corner ..."
  if ! "$OPENSTA" -exit "$TMP" > "$log" 2>&1; then echo "OpenSTA failed for $corner; inspect $log" >&2; exit 1; fi
  python3 - "$log" "$corner" "$SUMMARY" <<'PY'
import re,sys,csv
log,corner,out=sys.argv[1:]; text=open(log,errors="replace").read()
def sect(name,next_name):
    start=text.find("### "+name+" ###")
    if start<0: raise SystemExit(f"{corner}: missing report marker {name}; inspect {log}")
    start+=len("### "+name+" ###"); end=text.find("### "+next_name+" ###",start)
    return text[start:end if end>=0 else len(text)]
def get(name,next_name,label):
    s=sect(name,next_name)
    m=re.search(r"(?im)^\s*"+re.escape(label)+r"\s*[:=]?\s*(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*$",s)
    if not m: m=re.search(r"(?i)\b"+re.escape(label)+r"\b\s+(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",s)
    if not m: raise SystemExit(f"{corner}: could not parse {label} in {name}; inspect {log}. No value fabricated.")
    return float(m.group(1))
wns=get("SETUP_WNS","SETUP_TNS","worst slack")
tns=get("SETUP_TNS","HOLD_WORST_SLACK","tns")
hold=get("HOLD_WORST_SLACK","CONSTRAINT_CHECK_BEGIN","worst slack")
with open(out,"a",newline="") as f: csv.writer(f).writerow([corner,f"{wns:.4f}",f"{tns:.4f}",f"{hold:.4f}","REVIEW"])
PY
done
python3 "$HERE/generate_report.py" --csv "$SUMMARY" --out-dir "$HERE"
echo "Complete: $SUMMARY ; inspect logs in $OUT_DIR and regenerated DOCX/graphs before submission."
