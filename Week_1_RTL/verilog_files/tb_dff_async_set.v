#! /usr/bin/vvp
:ivl_version "12.0 (stable)";
:ivl_delay_selection "TYPICAL";
:vpi_time_precision + 0;
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_textio.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/v2005_math.vpi";
:vpi_module "/usr/lib/x86_64-linux-gnu/ivl/va_math.vpi";
S_0x6225cce8f560 .scope module, "dff_async_set" "dff_async_set" 2 3;
 .timescale 0 0;
    .port_info 0 /INPUT 1 "clk";
    .port_info 1 /INPUT 1 "async_set";
    .port_info 2 /INPUT 1 "d";
    .port_info 3 /OUTPUT 1 "q";
o0x73fa71ed0018 .functor BUFZ 1, C4<z>; HiZ drive
v0x6225cce8f780_0 .net "async_set", 0 0, o0x73fa71ed0018;  0 drivers
o0x73fa71ed0048 .functor BUFZ 1, C4<z>; HiZ drive
v0x6225cced6300_0 .net "clk", 0 0, o0x73fa71ed0048;  0 drivers
o0x73fa71ed0078 .functor BUFZ 1, C4<z>; HiZ drive
v0x6225cced63c0_0 .net "d", 0 0, o0x73fa71ed0078;  0 drivers
v0x6225cced6490_0 .var "q", 0 0;
E_0x6225cce906a0 .event posedge, v0x6225cce8f780_0, v0x6225cced6300_0;
    .scope S_0x6225cce8f560;
T_0 ;
    %wait E_0x6225cce906a0;
    %load/vec4 v0x6225cce8f780_0;
    %flag_set/vec4 8;
    %jmp/0xz  T_0.0, 8;
    %pushi/vec4 1, 0, 1;
    %assign/vec4 v0x6225cced6490_0, 0;
    %jmp T_0.1;
T_0.0 ;
    %load/vec4 v0x6225cced63c0_0;
    %assign/vec4 v0x6225cced6490_0, 0;
T_0.1 ;
    %jmp T_0;
    .thread T_0;
# The file index is used to find the file name in the following table.
:file_names 3;
    "N/A";
    "<interactive>";
    "dff_async_set.v";
