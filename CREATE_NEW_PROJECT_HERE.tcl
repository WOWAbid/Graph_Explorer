# =============================================================================
# Creates a NEW Vivado project with all Graph Explorer RTL (fixes "no files").
#
# STEP 1 — Close Vivado completely.
# STEP 2 — If your path differs, edit ROOT below.
# STEP 3 — Run from CMD / PowerShell (Vivado in PATH):
#   vivado -mode batch -source D:/XILINX_Projects/DSD_Project/CREATE_NEW_PROJECT_HERE.tcl
#
# STEP 4 — Open in Vivado:
#   D:/XILINX_Projects/DSD_Project/DSD_GraphExplorer/DSD_GraphExplorer.xpr
#
# Then: Run Simulation -> Behavioral (top = tb_graph_explorer)
# =============================================================================

set ROOT {D:/XILINX_Projects/DSD_Project}
set RTL_DIR  ${ROOT}/DSD_Project.srcs/sources_1/new
set TB_FILE  ${ROOT}/DSD_Project.srcs/sim_1/new/tb_graph_explorer.v
set XDC_FILE ${ROOT}/DSD_Project.srcs/constrs_1/new/basys3_pins.xdc
set PROJ_DIR ${ROOT}/DSD_GraphExplorer

file mkdir $PROJ_DIR

create_project -force DSD_GraphExplorer $PROJ_DIR -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]

catch { set_property board_part digilentinc.com:basys3:part0:1.2 [current_project] }
catch { set_property source_mgmt_mode None [current_project] }

set vlist [glob -nocomplain ${RTL_DIR}/*.v]
if { [llength $vlist] == 0 } {
  puts "ERROR: No .v files in $RTL_DIR"
  puts "Your RTL must live there (same tree as Cursor project)."
  exit 1
}

add_files -fileset sources_1 $vlist

foreach f [get_files -of_objects [get_filesets sources_1]] {
  set_property used_in_synthesis true $f
  set_property used_in_implementation true $f
  set_property used_in_simulation true $f
}

set_property top graph_explorer_top [get_filesets sources_1]

if { ! [file exists $TB_FILE] } {
  puts "ERROR: Testbench not found: $TB_FILE"
  exit 1
}
add_files -fileset sim_1 $TB_FILE
foreach f [get_files -of_objects [get_filesets sim_1]] {
  set_property used_in_simulation true $f
}
set_property top tb_graph_explorer [get_filesets sim_1]

if { [file exists $XDC_FILE] } {
  add_files -fileset constrs_1 $XDC_FILE
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

save_project -force

puts "\nSUCCESS: Open this project in Vivado:"
puts "  $PROJ_DIR/DSD_GraphExplorer.xpr\n"
