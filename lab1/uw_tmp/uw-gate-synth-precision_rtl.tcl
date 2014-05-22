set_results_dir uw_tmp
setup_design \
  -manufacturer Altera \
  -family {Cyclone II} \
  -part EP2C35F672C \
  -speed 7 
setup_design -frequency 250
setup_design -design add2
# setup_design -architecture DESIGN_ARCH
setup_design -generics {  }

foreach file [concat {  } { sum.vhd carry.vhd fulladder.vhd add2.vhd }] {
  add_input_file $file
}

compile
set clocks [ find_clocks ] 
if { [ llength $clocks ] != 0 } { 
  set clock [ lindex $clocks 0 ] 
  set_input_delay 0 [ all_inputs ] -clock $clock
  set_output_delay 0 [ all_outputs ] -clock $clock
}
auto_write uw_tmp/add2_gate.vhd

puts "*** synthesis to generic gates succeeded ***"

if { "False" != "True" } {
  exit
}
