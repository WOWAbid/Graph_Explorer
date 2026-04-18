# Repair Graph Explorer project in Vivado (re-enable sources + set tops).
# If RTL had errors (e.g. illegal empty ports in .v files), Vivado marks all
# files AutoDisabled — fix RTL first (graph_explorer_top / graph_engine), then run this.
#
# Usage (Vivado Tcl Console):
#   cd {D:/XILINX_Projects/DSD_Project}
#   source fix_graph_explorer_project.tcl
#
# Run this whenever all .v files look disabled or "No modules were found".

if { [catch {current_project}] } {
  open_project {D:/XILINX_Projects/DSD_Project/DSD_Project.xpr}
}

set src_fs [get_filesets sources_1]
set sim_fs [get_filesets sim_1]

foreach f [get_files -of_objects $src_fs] {
  catch { set_property IS_ENABLED true $f }
  set_property used_in_synthesis true $f
  set_property used_in_implementation true $f
  set_property used_in_simulation true $f
}

foreach f [get_files -of_objects $sim_fs] {
  catch { set_property IS_ENABLED true $f }
  set_property used_in_simulation true $f
}

set_property top graph_explorer_top $src_fs
set_property top tb_graph_explorer $sim_fs

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

save_project -force
puts "OK: sources enabled, tops set. Try Run Simulation again."
