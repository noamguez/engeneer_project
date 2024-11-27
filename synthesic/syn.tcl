#### Template Script for RTL->Gate-Level Flow (generated from GENUS 21.14-s082_1)

if {[file exists /proc/cpuinfo]} {
  sh grep "model name" /proc/cpuinfo
  sh grep "cpu MHz"    /proc/cpuinfo
}

puts "Hostname : [info hostname]"

##############################################################################
## Preset global variables and attributes
##############################################################################

set DESIGN addapter
set GEN_EFF medium
set MAP_OPT_EFF medium
set DATE [clock format [clock seconds] -format "%b%d-%T"]
set _OUTPUTS_PATH outputs
set _REPORTS_PATH reports
set _LOG_PATH logs
##set MODUS_WORKDIR <MODUS work directory>
set_db / .init_lib_search_path {. ./LIB}
##set_db / .script_search_path {. <path>}
set_db / .init_hdl_search_path {. ./RTL}
##Uncomment and specify machine names to enable super-threading.
##set_db / .super_thread_servers {<machine names>}
##For design size of 1.5M - 5M gates, use 8 to 16 CPUs. For designs > 5M gates, use 16 to 32 CPUs
##set_db / .max_cpus_per_server 8

##Default undriven/unconnected setting is 'none'.
##set_db / .hdl_unconnected_value 0 | 1 | x | none

set_db / .information_level 7

###############################################################
## Library setup
###############################################################



read_libs { ./LIB/typical.ecsm.lib ./LIB/pll.lib  ./LIB/CDK_S128x16.lib  ./LIB/CDK_S256x16.lib  ./LIB/CDK_R512x16.lib }

read_physical -lef { ./LEF/gsclib045_tech.lef ./LEF/gsclib045_macro.lef ./LEF/pll.lef   ./LEF/CDK_S128x16.lef  ./LEF/CDK_S256x16.lef  ./LEF/CDK_R512x16.lef }
## Provide either cap_table_file or the qrc_tech_file
#set_db / .cap_table_file <file> 
##read_qrc <qrcTechFile name>
##generates <signal>_reg[<bit_width>] format
#set_db / .hdl_array_naming_style %s\[%d\] 
## 


set_db / .lp_insert_clock_gating true 

####################################################################
## Load Design
####################################################################


read_hdl -sv "addapter.v"

set_db / .auto_ungroup none
set_db / .delete_unloaded_insts false

elaborate $DESIGN
puts "Runtime & Memory after 'read_hdl'"
time_info Elaboration



check_design -unresolved

####################################################################
## Constraints Setup
####################################################################

read_sdc "syn.con.sdc"
puts "The number of exceptions is [llength [vfind "design:$DESIGN" -exception *]]"


#set_db "design:$DESIGN" .force_wireload <wireload name>

if {![file exists ${_LOG_PATH}]} {
  file mkdir ${_LOG_PATH}
  puts "Creating directory ${_LOG_PATH}"
}

if {![file exists ${_OUTPUTS_PATH}]} {
  file mkdir ${_OUTPUTS_PATH}
  puts "Creating directory ${_OUTPUTS_PATH}"
}

if {![file exists ${_REPORTS_PATH}]} {
  file mkdir ${_REPORTS_PATH}
  puts "Creating directory ${_REPORTS_PATH}"
}
check_timing_intent


###################################################################################
## Define cost groups (clock-clock, clock-output, input-clock, input-output)
###################################################################################

## Uncomment to remove already existing costgroups before creating new ones.
## delete_obj [vfind /designs/* -cost_group *]

if {[llength [all_registers]] > 0} {
  define_cost_group -name I2C -design $DESIGN
  define_cost_group -name C2O -design $DESIGN
  define_cost_group -name C2C -design $DESIGN
  path_group -from [all_registers] -to [all_registers] -group C2C -name C2C
  path_group -from [all_registers] -to [all_outputs] -group C2O -name C2O
  path_group -from [all_inputs]  -to [all_registers] -group I2C -name I2C
}

define_cost_group -name I2O -design $DESIGN
path_group -from [all_inputs]  -to [all_outputs] -group I2O -name I2O
foreach cg [vfind / -cost_group *] {
  report_timing -group [list $cg] >> $_REPORTS_PATH/${DESIGN}_pretim.rpt
}


#### To turn off sequential merging on the design
#### uncomment & use the following attributes.
##set_db / .optimize_merge_flops false
##set_db / .optimize_merge_latches false
#### For a particular instance use attribute 'optimize_merge_seqs' to turn off sequential merging.


##################################################################################################
## DFT Setup
##################################################################################################

set_db / .dft_scan_style muxed_scan

set_db / .dft_prefix DFT_
# For VDIO customers, it is recommended to set the value of the next two attributes to false.
set_db / .dft_identify_top_level_test_clocks true
set_db / .dft_identify_test_signals true

set_db / .dft_identify_internal_test_clocks false
set_db / .use_scan_seqs_for_non_dft false

set_db "design:$DESIGN" .dft_scan_map_mode tdrc_pass
set_db "design:$DESIGN" .dft_connect_shift_enable_during_mapping tie_off
set_db "design:$DESIGN" .dft_connect_scan_data_pins_during_mapping loopback
set_db "design:$DESIGN" .dft_scan_output_preference auto
set_db "design:$DESIGN" .dft_lockup_element_type preferred_level_sensitive
set_db "design:$DESIGN" .dft_mix_clock_edges_in_scan_chains true

#set_db <instance or subdesign> .dft_dont_scan true
#set_db "<from pin> <inverting|non_inverting>" .dft_controllable <to pin>

define_test_clock -name scanclk -period 12500 scan_clk
define_shift_enable -name se -active high scan_en
define_test_mode -name tm -active high test_mode

## If you intend to insert compression logic, define your compression test signals or clocks here:
## define_test_mode...  [-shared_in]
## define_test_clock...
#########################################################################
## Segments Constraints (support fixed, floating, preserved and abstract)
## only showing preserved, and abstract segments as these are most often used
#############################################################################

##define_scan_preserved_segment -name <segObject> -sdi <pin|port|subport> -sdo <pin|port|subport> -analyze
## If the block is complete from a DFT perspective, uncomment to prevent any non-scan flops from being scan-replaced
#set_db [get_db insts -if {.is_sequential==true && .dft_mapped==false}] .dft_dont_scan true
##define_scan_abstract_segment -name <segObject> <-module|-insts|-libcell> -sdi <pin> -sdo <pin> -clock_port <pin> [-rise|-fall] -shift_enable_port <pin> -active <high|low> -length <integer>
## Uncomment if abstract segments are modeled in CTL format
##read_dft_abstract_model -ctl <file>


define_scan_chain -name top_chain -sdi scan_in -sdo scan_out -shift_enable se -create_ports

## Run the DFT rule checks
check_dft_rules > $_REPORTS_PATH/${DESIGN}-tdrcs
report_scan_registers > $_REPORTS_PATH/${DESIGN}-DFTregs
report_scan_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_tdrc



#######################################################################################
## Leakage/Dynamic power/Clock Gating setup.
#######################################################################################

#set_db "design:$DESIGN" .max_leakage_power 0.0
set_db "design:$DESIGN" .lp_power_optimization_weight 0.5
#mW
set_db "design:$DESIGN" .max_dynamic_power 100



####################################################################################################
## Synthesizing to generic
####################################################################################################

set_db / .syn_generic_effort $GEN_EFF
syn_generic
puts "Runtime & Memory after 'syn_generic'"
time_info GENERIC
report_dp > $_REPORTS_PATH/generic/${DESIGN}_datapath.rpt
write_snapshot -outdir $_REPORTS_PATH -tag generic
report_summary -directory $_REPORTS_PATH





####################################################################################################
## Synthesizing to gates
####################################################################################################


set_db / .syn_map_effort $MAP_OPT_EFF
syn_map
puts "Runtime & Memory after 'syn_map'"
time_info MAPPED
write_snapshot -outdir $_REPORTS_PATH -tag map
report_summary -directory $_REPORTS_PATH
report_dp > $_REPORTS_PATH/map/${DESIGN}_datapath.rpt


foreach cg [vfind / -cost_group *] {
  report_timing -group [list $cg] > $_REPORTS_PATH/${DESIGN}_[vbasename $cg]_post_map.rpt
}


write_do_lec -revised_design fv_map -logfile ${_LOG_PATH}/rtl2intermediate.lec.log > ${_OUTPUTS_PATH}/rtl2intermediate.lec.do

## ungroup -threshold <value>

#######################################################################################################
## Optimize Netlist
#######################################################################################################

## Uncomment to remove assigns & insert tiehilo cells during Incremental synthesis
##set_db / .remove_assigns true
##set_remove_assign_options -buffer_or_inverter <libcell> -design <design|subdesign>
##set_db / .use_tiehilo_for_const <none|duplicate|unique>
set_db / .syn_opt_effort $MAP_OPT_EFF
syn_opt
write_snapshot -outdir $_REPORTS_PATH -tag syn_opt
report_summary -directory $_REPORTS_PATH

puts "Runtime & Memory after 'syn_opt'"
time_info OPT

foreach cg [vfind / -cost_group *] {
  report_timing -group [list $cg] > $_REPORTS_PATH/${DESIGN}_[vbasename $cg]_post_opt.rpt
}



######################################################################################################
## write backend file set (verilog, SDC, config, etc.)
######################################################################################################



report_dp > $_REPORTS_PATH/${DESIGN}_datapath_incr.rpt
report_messages > $_REPORTS_PATH/${DESIGN}_messages.rpt
write_snapshot -outdir $_REPORTS_PATH -tag final
report_summary -directory $_REPORTS_PATH
## write_hdl  > ${_OUTPUTS_PATH}/${DESIGN}_m.v
## write_script > ${_OUTPUTS_PATH}/${DESIGN}_m.script
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}_m.sdc
write_db spi_main -to_file ${_OUTPUTS_PATH}/${DESIGN}_design.db


#############################################
## DFT Reports
#############################################

report_scan_setup > $_REPORTS_PATH/${DESIGN}-DFTsetup_final
write_scandef > ${DESIGN}-scanDEF
write_dft_abstract_model > ${DESIGN}-scanAbstract
write_hdl -abstract > ${DESIGN}-logicAbstract
write_script -analyze_all_scan_chains > ${DESIGN}-writeScript-analyzeAllScanChains


#############################################
## Power Reports
#############################################

report_power -depth 0 > $_REPORTS_PATH/${DESIGN}_power.rpt
report_gates -power > $_REPORTS_PATH/${DESIGN}_gates_power.rpt
/

#################################
### write_do_lec
#################################


write_do_lec -golden_design fv_map -revised_design ${_OUTPUTS_PATH}/${DESIGN}_m.v -logfile  ${_LOG_PATH}/intermediate2final.lec.log > ${_OUTPUTS_PATH}/intermediate2final.lec.do
##Uncomment if the RTL is to be compared with the final netlist..
##write_do_lec -revised_design ${_OUTPUTS_PATH}/${DESIGN}_m.v -logfile ${_LOG_PATH}/rtl2final.lec.log > ${_OUTPUTS_PATH}/rtl2final.lec.do

puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"

file copy [get_db / .stdout_log] ${_LOG_PATH}/.

##quit
