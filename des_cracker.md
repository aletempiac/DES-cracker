<!-- MASTER-ONLY: DO NOT MODIFY THIS FILE-->

# A hardware DES cracker

* [Introduction](#introduction)
* [Interface](#interface)
* [Architecture](#architecture)
* [Validation](#validation)
* [Synthesis and test](#synthesis-and-test)
* [Linux software driver](#linux-software-driver)

## Introduction

This project aims at estimating as accurately as possible the time it would take to crack the DES (Data Encryption Standard) encryption algorithm using Zybo boards. You will design a hardware DES encryption engine, code it in VHDL, validate it and synthesize it for the FPGA part of the zynq core of your Zybo board. Based on the performance results that you will get (resources usage and maximum reachable clock frequency), you will then design a cracking machine by instantiating as many DES encryption engines as you can and by distributing the computation effort among them.

The cracking machine will be given a plaintext $`P`$, a ciphertext $`C`$, 64 bits each, and a 56-bits starting secret key $`K_0`$. It will try to encrypt $`P`$ with all possible 56-bits keys $`K\ge K_0`$ until the result equals $`C`$. When the match will have been found the cracking machine will store the corresponding secret key $`K_1`$ in a register and raise an interrupt to inform the software stack that runs on the ARM CPU of the Zynq core.

The cracking machine will communicate with the CPU using the same AXI4 lite interface we used for the DHT11 controller (12 bits addresses, 32 bits data).

## Interface

You can use as many VHDL source files as you wish (provided that they are clearly listed in your report, with a brief explanation of their content), but the top-level of your design (entity and architecture) must be coded in the file named `des_cracker.vhd`. Edit it and code an entity named `des_cracker` with the following input-output ports:

| Name             | Type                             | Direction | Description                                                                                                            |
| :----            | :----                            | :----     | :----                                                                                                                  |
| `aclk`           | `std_ulogic`                     | in        | master clock from CPU part of Zynq core, the design is synchronized on the rising edge of `aclk`                       |
| `aresetn`        | `std_ulogic`                     | in        | **synchronous** active **low** reset from CPU part of Zynq core (the leading _a_ means AXI, not asynchronous)          |
| `s0_axi_araddr`  | `std_ulogic_vector(11 downto 0)` | in        | read address from CPU (12 bits = 4kB)                                                                                  |
| `s0_axi_arvalid` | `std_ulogic`                     | in        | read address valid from CPU                                                                                            |
| `s0_axi_arready` | `std_ulogic`                     | out       | read address acknowledge to CPU                                                                                        |
| `s0_axi_awaddr`  | `std_ulogic_vector(11 downto 0)` | in        | write address from CPU (12 bits = 4kB)                                                                                 |
| `s0_axi_awvalid` | `std_ulogic`                     | in        | write address valid flag from CPU                                                                                      |
| `s0_axi_awready` | `std_ulogic`                     | out       | write address acknowledge to CPU                                                                                       |
| `s0_axi_wdata`   | `std_ulogic_vector(31 downto 0)` | in        | write data from CPU                                                                                                    |
| `s0_axi_wstrb`   | `std_ulogic_vector(3 downto 0)`  | in        | write byte enables from CPU                                                                                            |
| `s0_axi_wvalid`  | `std_ulogic`                     | in        | write data and byte enables valid from CPU                                                                             |
| `s0_axi_wready`  | `std_ulogic`                     | out       | write data and byte enables acknowledge to CPU                                                                         |
| `s0_axi_rdata`   | `std_ulogic_vector(31 downto 0)` | out       | read data response to CPU                                                                                              |
| `s0_axi_rresp`   | `std_ulogic_vector(1 downto 0)`  | out       | read status response (OKAY, EXOKAY, SLVERR or DECERR) to CPU                                                           |
| `s0_axi_rvalid`  | `std_ulogic`                     | out       | read data and status response valid flag to CPU                                                                        |
| `s0_axi_rready`  | `std_ulogic`                     | in        | read response acknowledge from CPU                                                                                     |
| `s0_axi_bresp`   | `std_ulogic_vector(1 downto 0)`  | out       | write status response (OKAY, EXOKAY, SLVERR or DECERR) to CPU                                                          |
| `s0_axi_bvalid`  | `std_ulogic`                     | out       | write status response valid to CPU                                                                                     |
| `s0_axi_bready`  | `std_ulogic`                     | in        | write response acknowledge from CPU                                                                                    |
| `irq`            | `std_ulogic`                     | out       | interrupt request to CPU                                                                                               |
| `led`            | `std_ulogic_vector(3 downto 0)`  | out       | wired to the four user LEDs                                                                                            |

## Architecture

In the same VHDL source file add an architecture named `rtl` and code it according the following specifications.

### Internal registers

In the architecture body add one or several synchronous processes to implement several internal registers, synchronized on the rising edges of `aclk`, all forced to zero on rising edges of `aclk` where `aresetn` is low. Declare the following internal signals to model the outputs of the registers, and write your synchronous processes according the specified behavior:

| Name  | Type                             | Behavior                | Base address |
| :---- | :----                            | :---                    | :---         |
| `p`   | `std_ulogic_vector(63 downto 0)` | the plaintext           | `0x000`      |
| `c`   | `std_ulogic_vector(63 downto 0)` | the ciphertext          | `0x008`      |
| `k0`  | `std_ulogic_vector(55 downto 0)` | the starting secret key | `0x010`      |
| `k`   | `std_ulogic_vector(55 downto 0)` | the current secret key  | `0x018`      |
| `k1`  | `std_ulogic_vector(55 downto 0)` | the found secret key    | `0x020`      |

`p` and `c` are regular read-write registers without side effect. `k1` is a regular read-only register without side effect.

`k0` is a regular read-write register but it has a side effect: the DES cracker machine starts when its most significant word (`[0x014..0x017]`) is written and stops when the least significant word (`[0x010..0x013]`) is written. Note that, for proper operations, `p`, `c` must be written first, then the least significant word of `k0`, then its most significant word. The cracking machine is idle after reset. It starts only after the most significant word of `k0` is written.

`k` is a regular read-only register but it has a side effect. During normal cracking operation, `k` is constantly updated with the largest secret key that has already been totally processed. This how the software running on the ARM processor can observe the progress of the cracking operation. In order to guarantee a correct 64-bits read, in two consecutive 32-bits reads, `k` is frozen when its least significant word is read. Its regular update resumes only after the most significant word is read. Note that, for proper read of `k`, the least significant word must be read first. Else, the two halves of the 64-bits read value could come from two different consecutive values of `k`.

Bits `k(33 downto 30)` drive the `led` output.

When the correct secret key has been found, it is stored in register `k1`, the `irq` output is asserted high during one clock period and the cracking machine stops until a new starting key is provided. If the largest key has been reached before the correct key has been found, the key wraps around zero and continues until the correct key has been found.

### AXI4 lite machinery

Add concurrent signal assignments, combinatorial processes and synchronous processes to implement the slave side of the AXI4 lite protocol with the following constraints:

1. We do not make any hypothesis about the behavior of the CPU:

   * The processor can assert its ready flags (`s0_axi_rready` and `s0_axi_bready`) high by default.
   * The processor can submit read and write requests simultaneously and if it does so they must be served simultaneously.

1. In the 4kB address range that our peripheral sees, we map only the ten first 32-bits words (40 bytes, `[0x000..0x027]`). Bytes `[0x000..0x017]` are read-write. Bytes `[0x018..0x027]` are read-only.
1. We ignore the alignment of accesses, that is, we ignore the 2 least significant bits of the address buses. The CPU receives the same response for accesses at addresses `0x000`, `0x001`, `0x002` or `0x003`.
1. Read accesses at mapped addresses return the `OKAY` response status and the read data corresponding to the accessed internal register. The most significant byte of the three 56-bits registers always reads as zero.
1. Read accesses at other addresses return the `DECERR` (DECode ERRor) response status and the all-zero read data.
1. Write accesses to the `[0x000..0x017]` range return the `OKAY` response status and the write data is stored in the target register. When writing to register `k0` the most significant byte is ignored.
1. Write accesses to the `[0x018..0x027]` range return a `SLVERR` (SLaVe ERRor) response status because the `k` and `k1` registers are read-only. 
1. Write accesses at other addresses return the `DECERR` (DECode ERRor) response status.
1. The peripheral groups write address and write data requests: it waits until both are pending before acknowledging both and responding.
1. The read and write acknowledges (`arready`, `awready`, `wready`) are not asserted high by default. They are asserted only after the rising edge of the clock for which valid request flags are asserted high.
1. Read and write requests are served as soon as possible: when a valid request is pending on a rising edge `N` of clock, the acknowledge(s) is(are) asserted high, and the response is submitted. After the next (`N+1`) rising edge of the clock the acknowledge(s) is(are) de-asserted. If the microprocessor acknowledges the response on the same rising edge, the response is also de-asserted. Else the response is maintained until a rising edge of the clock where the microprocessor acknowledges the response.
1. New read (write) requests are ignored as long as a pending read (write) response has not been acknowledged.
1. The `s0_axi_rdata`, `s0_axi_rresp` and `s0_axi_bresp` outputs of the wrapper are outputs of dedicated internal registers: they are assigned in a synchronous process. They are not targets of concurrent signal assignments (even with registered right-hand sides). This is mandatory to fulfill all requirements of the AXI4 lite protocol. Note that if `s0_axi_rdata`, for instance, was assigned by a concurrent signal assignment, there would be a possibility that its value changes while `s0_axi_rvalid` is asserted high, which is strictly forbidden by the protocol: `s0_axi_rdata` and `s0_axi_rresp` **must** be assigned a value when `s0_axi_rvalid` is asserted high to respond a read request, and they **must** remain unmodified until the response is acknowledged by the master (with `s0_axi_rready`). Same for `s0_axi_bresp` for the write responses.

The following waveform represents several read transactions. The rising edges of the clock where the peripheral notices a read request are indicated by a blue vertical line. The rising edges of the clock where the processor acknowledges a read response are indicated by a red vertical line. The highest possible throughput (two clock cycles per read operation) corresponds to the two last transactions. Write transactions are similar (remember that the peripheral groups write address and write data requests).

![`des_cracker` waveform](figures/waveforms.png)

## Validation

Design simulation environment(s) to validate your design(s) (e.g. with Modelsim). Document them in your report. Explain what they simulate and what results you obtained.

## Synthesis and test

Starting from the synthesis script that we used for the [AXI4 lite wrapper for the DHT11 controller](../lab06/dht11_ctrl_axi_wrapper.md) design a synthesis script for your DES cracker. Explain the various results you obtained in your report. Remember that your goal is to optimally use the FPGA resources of the Zynq core of the Zybo to crack DES as fast as possible. Test your cracking machine on the Zybo board. Use carefully crafted plaintext, ciphertext and starting key to observe the discovery of the secret key in a reasonable amount of time.

## Linux software driver

Starting from the [lab on a Linux software driver for the DHT11 controller](../lab07/dht11_driver.md), design a Linux software driver for your cracking machine. Clearly specify it in your report. Test it on the Zybo.

<!-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0: -->
