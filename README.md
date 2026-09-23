# Thesis Work – ESP + GEMM Accelerator

This repository contains the setup and source code used for my master's thesis on integrating a GEMM hardware accelerator into the **Embedded Scalable Platforms (ESP)** framework.

## Setup

Clone the repository including the ESP submodule:

```bash
git clone --recursive https://github.com/marijennb/thesis-work.git
cd thesis-work
```

If you already cloned it without the submodule:

```bash
git submodule update --init --recursive
```

Build the Docker environment:

```bash
docker compose build
```

Start the container:

```bash
docker compose up -d
docker compose exec esp bash
```

## External Tools

The Docker image does **not** include the FPGA and simulation tools. These need to be installed separately and mounted into the container.

The versions used during the thesis were:

* Vivado 2024.2
* Vitis HLS 2024.2
* QuestaSim 2023.3
* RISC-V GCC toolchain

The paths may need to be updated in `docker-compose.yaml` and in the environment scripts under:

```text
esp-workspace/scripts/
```

## ESP Workspace

The ESP source code is located in:

```text
esp-workspace/esp/
```

The thesis configuration uses:

* Ibex 32-bit RISC-V processor
* GEMM accelerator
* ESP NoC
* DMA-based accelerator communication
* Xilinx VC707 configuration

The GEMM accelerator uses:

```text
N = 32
SHIFT = 8
Accelerator ID = 0x04A
```

## Running the Simulation

The main verification method used during the thesis was full-system RTL simulation with QuestaSim.

The bare-metal GEMM test can be built with:

```bash
make mmult_vivado-baremetal
```

The simulation can then be started with:

```bash
make qsim-gui \
    TEST_PROGRAM="$PWD/soft-build/ibex/drivers/mmult_vivado/baremetal/mmult.exe"
```

## Notes

ESP was originally designed for older versions of some FPGA tools, so a few compatibility changes were required.

In particular:

* CentOS 7 repositories were changed to `vault.centos.org`
* some ESP scripts were changed from `vivado_hls` to `vitis_hls`
* external CAD tools are mounted from the host into Docker
* the VC707 target may require a Vivado edition that includes Virtex-7 device support

If something does not work, I recommend first checking that the Docker environment, tool paths, and ESP baseline work before debugging the accelerator itself.

## References

ESP:
https://www.esp.cs.columbia.edu/

Original ESP repository:
https://github.com/sld-columbia/esp

Modified ESP repository used for this thesis:
https://github.com/marijennb/esp
