onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_des_ctrl/ref/clk
add wave -noupdate -color Green -itemcolor Green /tb_des_ctrl/start
add wave -noupdate -color {Orange Red} -itemcolor {Orange Red} /tb_des_ctrl/stop
add wave -noupdate -color Goldenrod -itemcolor Goldenrod /tb_des_ctrl/found
add wave -noupdate -radix hexadecimal /tb_des_ctrl/ref/p
add wave -noupdate -radix hexadecimal /tb_des_ctrl/ref/c
add wave -noupdate -radix hexadecimal /tb_des_ctrl/ref/k0
add wave -noupdate -radix hexadecimal /tb_des_ctrl/ref/k
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/k
add wave -noupdate /tb_des_ctrl/dut/c_state
add wave -noupdate /tb_des_ctrl/dut/n_state
add wave -noupdate -color Cyan -itemcolor Cyan -radix hexadecimal /tb_des_ctrl/ref/k1
add wave -noupdate -color Cyan -itemcolor Cyan -radix hexadecimal /tb_des_ctrl/dut/k1
add wave -noupdate -radix hexadecimal /tb_des_ctrl/ref/key
add wave -noupdate -radix hexadecimal /tb_des_ctrl/ref/p_out
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/key
add wave -noupdate /tb_des_ctrl/dut/inc_count
add wave -noupdate /tb_des_ctrl/dut/end_count
add wave -noupdate /tb_des_ctrl/dut/found_local
add wave -noupdate /tb_des_ctrl/dut/found_array
add wave -noupdate /tb_des_ctrl/dut/key_inc
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/p_out_array
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/p_out_array_s
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/cd16
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/cd16_s
add wave -noupdate -radix hexadecimal /tb_des_ctrl/dut/cd16_mux
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5755385 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 351
configure wave -valuecolwidth 145
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
WaveRestoreZoom {0 ps} {6300 ns}
