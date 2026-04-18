# Fix "AutoDisabled" / "No modules found" — run with Vivado CLOSED, from OS shell:
#   vivado -mode batch -source D:/XILINX_Projects/DSD_Project/vivado_fix_and_reload.tcl
#
# Or in Vivado Tcl Console (project may be open):
#   source {D:/XILINX_Projects/DSD_Project/vivado_fix_and_reload.tcl}

set _root {D:/XILINX_Projects/DSD_Project}

proc _open_proj {} {
  global _root
  if { [catch {current_project}] } {
    open_project ${_root}/DSD_Project.xpr
  }
}

_open_proj

# Prevent Vivado from auto-disabling RTL when analysis hiccups (Vivado 2019+)
if { ! [catch { set_property source_mgmt_mode None [current_project] } err] } {
  puts "source_mgmt_mode None on project OK"
} elseif { ! [catch { set_property SOURCE_MGMT_MODE None [current_project] } err2] } {
  puts "SOURCE_MGMT_MODE None on project OK"
} else {
  puts "Note: could not set source_mgmt_mode (may be OK): $err"
}

set fs_src [get_filesets sources_1]
set fs_sim [get_filesets sim_1]

foreach f [get_files -of_objects $fs_src] {
  catch { set_property IS_ENABLED true $f }
  set_property used_in_synthesis         true $f
  set_property used_in_implementation    true $f
  set_property used_in_simulation        true $f
}

foreach f [get_files -of_objects $fs_sim] {
  catch { set_property IS_ENABLED true $f }
  set_property used_in_simulation        true $f
}

set_property top graph_explorer_top $fs_src
set_property top tb_graph_explorer  $fs_sim

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

save_project -force
puts "Done. Re-open project if you ran batch mode, then Run Simulation."
