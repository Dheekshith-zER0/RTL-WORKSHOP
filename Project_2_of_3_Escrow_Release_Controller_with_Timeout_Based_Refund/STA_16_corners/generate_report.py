#!/usr/bin/env python3
"""Generate setup WNS/TNS plots and DOCX from measured OpenSTA summary data."""
import argparse,csv,math
from pathlib import Path
def main():
 p=argparse.ArgumentParser(); p.add_argument("--csv",required=True); p.add_argument("--out-dir",required=True); a=p.parse_args()
 rows=list(csv.DictReader(open(a.csv,newline="",encoding="utf-8-sig")))
 need={"corner","setup_worst_slack_ns","setup_tns_ns","hold_worst_slack_ns","status"}
 if not rows or not need.issubset(rows[0]): raise SystemExit("CSV missing required columns: "+", ".join(sorted(need)))
 if len(rows)!=16 or len({r["corner"] for r in rows})!=16: raise SystemExit("Expected exactly 16 unique Liberty models.")
 def n(r,k):
  try: v=float(r[k])
  except (ValueError,TypeError): raise SystemExit(f"{r['corner']}: {k} missing/non-numeric; refusing to invent data.")
  if not math.isfinite(v): raise SystemExit(f"{r['corner']}: invalid {k}")
  return v
 for r in rows:
  for k in ("setup_worst_slack_ns","setup_tns_ns","hold_worst_slack_ns"): n(r,k)
 out=Path(a.out_dir); out.mkdir(parents=True,exist_ok=True)
 try:
  import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
  from docx import Document
  from docx.shared import Inches,Pt
 except ImportError as e: raise SystemExit("Install dependencies: python3 -m pip install -r requirements.txt") from e
 labels=[r["corner"].replace("sky130_fd_sc_hd__","") for r in rows]
 for vals,fn,title,ylabel in [( [n(r,"setup_worst_slack_ns") for r in rows],"setup_wns_by_corner.png","Setup WNS by SKY130HD Liberty model","Worst setup slack (ns)"),([n(r,"setup_tns_ns") for r in rows],"setup_tns_by_corner.png","Setup TNS by SKY130HD Liberty model","Total negative setup slack (ns)")]:
  fig,ax=plt.subplots(figsize=(15,6)); ax.bar(range(16),vals); ax.axhline(0,linewidth=1)
  ax.set_xticks(range(16),labels,rotation=65,ha="right",fontsize=8); ax.set_ylabel(ylabel); ax.set_title(title); ax.grid(axis="y",alpha=.25)
  fig.tight_layout(); fig.savefig(out/fn,dpi=180); plt.close(fig)
 wns=[n(r,"setup_worst_slack_ns") for r in rows]; tns=[n(r,"setup_tns_ns") for r in rows]; hold=[n(r,"hold_worst_slack_ns") for r in rows]
 doc=Document(); sec=doc.sections[0]; sec.top_margin=Inches(.65); sec.bottom_margin=Inches(.65)
 doc.styles["Normal"].font.name="Arial"; doc.styles["Normal"].font.size=Pt(9)
 doc.add_heading("Escrow Release Controller — 16-Model STA Report",0)
 doc.add_paragraph("Supplementary static timing analysis using SKY130HD standard-cell Liberty models. Preliminary analysis only; not signoff timing closure.")
 doc.add_heading("Executive summary",level=1)
 doc.add_paragraph(f"Models analyzed: 16. Worst setup slack: {min(wns):.4f} ns ({rows[wns.index(min(wns))]['corner']}). Best setup slack: {max(wns):.4f} ns ({rows[wns.index(max(wns))]['corner']}). Worst hold slack: {min(hold):.4f} ns. Every row remains REVIEW.")
 doc.add_paragraph("The same routed SPEF was reused for every Liberty model. This is a controlled timing-model comparison, not a re-route at every PVT corner. Constraint-check logs must be reviewed for unconstrained paths and ports.")
 doc.add_heading("Setup WNS by model",level=1); doc.add_picture(str(out/"setup_wns_by_corner.png"),width=Inches(6.8))
 doc.add_heading("Setup TNS by model",level=1); doc.add_picture(str(out/"setup_tns_by_corner.png"),width=Inches(6.8))
 doc.add_heading("Per-model results",level=1); tab=doc.add_table(rows=1,cols=5); tab.style="Light Shading Accent 1"
 for c,h in zip(tab.rows[0].cells,["Liberty model","Setup WNS (ns)","Setup TNS (ns)","Hold worst slack (ns)","Status"]): c.text=h
 for r in rows:
  for c,v in zip(tab.add_row().cells,[r["corner"],f"{n(r,'setup_worst_slack_ns'):.4f}",f"{n(r,'setup_tns_ns'):.4f}",f"{n(r,'hold_worst_slack_ns'):.4f}",r["status"] or "REVIEW"]): c.text=v
 doc.add_heading("Methodology",level=1)
 for s in ["One non-CCS-noise standard-cell Liberty model was loaded per run; optional macro Liberty files were loaded as configured.","The netlist, SDC and routed SPEF were loaded for each model, clocks propagated, then setup WNS/TNS, hold worst slack and check_setup -verbose were reported.","The same SPEF across all models makes this a timing-model sensitivity sweep, not a full per-corner physical implementation.","Excluded CCS-noise variants: ff_n40C_1v95_ccsnoise.lib and ss_n40C_1v60_ccsnoise.lib."]:
  doc.add_paragraph(s,style="List Bullet")
 doc.add_heading("Warnings and limitations",level=1)
 for s in ["Earlier OpenSTA output black-boxed missing sky130_fd_sc_hd__tapvpwrvgnd_1 and warned default_fanout_load = 0.0.","Review logs/ for unconstrained endpoints and ports before signoff claims.","Negative setup slack means setup timing is not closed at that model. No RTL/timing fix or signoff approval is claimed."]:
  doc.add_paragraph(s,style="List Bullet")
 doc.save(out/"STA_16_Corner_Report.docx")
 with open(out/"tns_status.csv","w",newline="",encoding="utf-8") as f:
  w=csv.writer(f); w.writerow(["metric","status","reason"]); w.writerow(["Setup TNS","CAPTURED","Measured by OpenSTA report_tns -max for all 16 Liberty models."])
 print("Generated both charts, DOCX and tns_status.csv from measured CSV values.")
if __name__=="__main__": main()
