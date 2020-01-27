# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set_msg_config -id {Common 17-41} -limit 10000000
create_project -in_memory -part xc7a35tcpg236-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.cache/wt [current_project]
set_property parent.project_path C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo c:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_mem C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/otter_memory.mem
read_verilog -library xil_defaultlib -sv {
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/ArithLogicUnit.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/BCD.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/CU_Decoder.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/CathodeDriver.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/ControlUnit.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/Mult4to1.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/OTTER_CPU.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/ProgCount.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/SevSegDisp.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/bram_dualport.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/debounce_one_shot.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/programmer.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/registerFile.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/uart_rx.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/uart_rx_word.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/uart_tx.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/uart_tx_word.sv
  C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/sources_1/imports/OTTER-multicyle-baseline-programmable/OTTER_Wrapper.sv
}
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/constrs_1/imports/OTTER-multicyle-baseline-programmable/Basys-3-Master.xdc
set_property used_in_implementation false [get_files C:/Users/VasanthSadhasivan/CalPoly/CPE333/OTTER/OTTER_RISC_V_ARCH/otter/otter.srcs/constrs_1/imports/OTTER-multicyle-baseline-programmable/Basys-3-Master.xdc]

set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top OTTER_Wrapper_Programmable -part xc7a35tcpg236-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef OTTER_Wrapper_Programmable.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file OTTER_Wrapper_Programmable_utilization_synth.rpt -pb OTTER_Wrapper_Programmable_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
