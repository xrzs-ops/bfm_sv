encoding system utf-8

set test_name $1

quit -sim
.main clear
if [file exists work] {
    vdel -all}

#添加仿真库
onerror {resume}


onbreak {resume}
#----------------------
# Complie
vlib work
vlog -work work -sv -timescale 1ns/1ps ../code/BFM_UART.sv
vlog -work work -sv -timescale 1ns/1ps ../code/*.sv

vsim -voptargs=+acc work.$test_name
run -all