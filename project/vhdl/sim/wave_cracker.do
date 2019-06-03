onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_des_cracker/aresetn
add wave -noupdate /tb_des_cracker/aclk
add wave -noupdate /tb_des_cracker/start
add wave -noupdate /tb_des_cracker/stop
add wave -noupdate -radix hexadecimal /tb_des_cracker/s0_axi_araddr
add wave -noupdate /tb_des_cracker/s0_axi_arvalid
add wave -noupdate /tb_des_cracker/s0_axi_arready
add wave -noupdate /tb_des_cracker/s0_axi_arready_ref
add wave -noupdate -radix hexadecimal /tb_des_cracker/s0_axi_awaddr
add wave -noupdate /tb_des_cracker/s0_axi_awvalid
add wave -noupdate /tb_des_cracker/s0_axi_awready
add wave -noupdate /tb_des_cracker/s0_axi_awready_ref
add wave -noupdate -radix hexadecimal /tb_des_cracker/s0_axi_wdata
add wave -noupdate /tb_des_cracker/s0_axi_wstrb
add wave -noupdate /tb_des_cracker/s0_axi_wvalid
add wave -noupdate /tb_des_cracker/s0_axi_wready
add wave -noupdate /tb_des_cracker/s0_axi_wready_ref
add wave -noupdate -radix hexadecimal /tb_des_cracker/s0_axi_rdata
add wave -noupdate -radix hexadecimal /tb_des_cracker/s0_axi_rdata_ref
add wave -noupdate /tb_des_cracker/s0_axi_rresp
add wave -noupdate /tb_des_cracker/s0_axi_rresp_ref
add wave -noupdate /tb_des_cracker/s0_axi_rvalid
add wave -noupdate /tb_des_cracker/s0_axi_rvalid_ref
add wave -noupdate /tb_des_cracker/s0_axi_rready
add wave -noupdate /tb_des_cracker/s0_axi_bresp
add wave -noupdate /tb_des_cracker/s0_axi_bresp_ref
add wave -noupdate /tb_des_cracker/s0_axi_bvalid
add wave -noupdate /tb_des_cracker/s0_axi_bvalid_ref
add wave -noupdate /tb_des_cracker/s0_axi_bready
add wave -noupdate /tb_des_cracker/irq
add wave -noupdate /tb_des_cracker/irq_ref
add wave -noupdate /tb_des_cracker/led_ref
add wave -noupdate /tb_des_cracker/led
add wave -noupdate /tb_des_cracker/writep
add wave -noupdate /tb_des_cracker/writec
add wave -noupdate -radix hexadecimal /tb_des_cracker/p
add wave -noupdate -radix hexadecimal /tb_des_cracker/c
add wave -noupdate -radix hexadecimal /tb_des_cracker/k0
add wave -noupdate -radix hexadecimal /tb_des_cracker/k_ref
add wave -noupdate /tb_des_cracker/k_freeze
add wave -noupdate -radix hexadecimal /tb_des_cracker/k1_ref
add wave -noupdate /tb_des_cracker/found_ref
add wave -noupdate /tb_des_cracker/evaluate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1055000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 264
configure wave -valuecolwidth 126
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {4200 ns}
