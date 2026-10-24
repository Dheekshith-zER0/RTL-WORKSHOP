# Escrow Release Controller — 16-Liberty-Model STA Assessment

## Contents
- `STA_16_Corner_Report.docx`: formatted report with WNS chart and results table.
- `summary.csv`: supplied WNS and hold worst-slack results; TNS is blank because it was not captured.
- `setup_wns_by_corner.png`: WNS graph.
- `tns_status.csv`: explains why TNS is unavailable.

## Findings
- Worst setup slack: -5.86 ns at `sky130_fd_sc_hd__ss_n40C_1v28`.
- Best setup slack: +7.26 ns at `sky130_fd_sc_hd__ff_100C_1v95`.
- Hold worst-slack values are positive across all 16 rows (+0.30 ns to +1.69 ns).
- Every row remains `REVIEW`; this is not signoff timing closure.
- Clock period: 10 ns; input and output delays: 2 ns; propagated clocks enabled.
- The same routed SPEF was reused for all 16 Liberty models. This is preliminary analysis, not a signoff-validated PVT matrix.
- Excluded CCS-noise variants: `sky130_fd_sc_hd__ff_n40C_1v95_ccsnoise.lib` and `sky130_fd_sc_hd__ss_n40C_1v60_ccsnoise.lib`. These are model variants, not additional PVT corners.
- OpenSTA warned that `sky130_fd_sc_hd__tapvpwrvgnd_1` was unavailable and black-boxed PHY_28; Liberty also warned `default_fanout_load = 0.0`.
- TNS was not present in the supplied output. It is not represented as zero. Rerun the sweep with TNS reporting to complete a WNS/TNS graph.
