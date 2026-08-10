#!/bin/bash

########################################################
# ESP CAD Environment Setup
########################################################
export ESP_ROOT=/home/espuser/esp

############################
# Vivado 2024.2
############################
echo "Loading CAD environment..."
export XILINX_VIVADO=/home/mj/CAD/Xilinx/Vivado/2024.2
source $XILINX_VIVADO/settings64.sh
# export PATH=$XILINX_VIVADO/bin:$PATH
export PATH=$PATH:$XILINX_VIVADO/bin

############################
# Vitis 2024.2
############################
export XILINX_VITIS_HLS=/home/mj/CAD/Xilinx/Vitis_HLS/2024.2
export PATH=$XILINX_VITIS_HLS/bin:$PATH
export VIVADO_HLS=$XILINX_VITIS_HLS/bin/vitis_hls
export PATH=$XILINX_VITIS_HLS/bin:$PATH
alias vivado_hls=vitis_hls

############################
# Questa FPGA Starter Edition
############################
export QUESTA_HOME=/home/mj/CAD/intelFPGA/questa_fse
export QUESTA=$QUESTA_HOME
export LM_LICENSE_FILE=/home/mj/CAD/altera/license/LR-159480_License.dat
export PATH=$QUESTA_HOME/bin:$PATH
export AMS_MODEL_TECH=$QUESTA_HOME

############################
# RISC-V toolchain
############################
export RISCV=/home/espuser/riscv
export PATH=$RISCV/bin:$PATH

export RISCV32IMC=/home/espuser/riscv32imc
export PATH=$RISCV32IMC/bin:$PATH

############################
# LEON3 toolchain
############################
export PATH=/home/espuser/leon/bin:$PATH
export PATH=/home/espuser/leon/mklinuximg:$PATH
export PATH=/home/espuser/leon/sparc-elf/bin:$PATH

############################
# Compiling Xilinx libraries for qsim
############################
alias compile_xilinx_libs="vivado -mode batch -source ~/scripts/compile_simlib.tcl"
# if [ ! -d /home/mj/CAD/xilinx_lib/secureip_ver ]; then
#   echo "Compiling Xilinx libraries..."
#   compile_xilinx_libs
# fi
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5
export QT_SCALE_FACTOR=1.5
export PATH=/home/espuser/bin:$PATH

echo "ESP CAD environment loaded."
