# UART Receiver and Transmitter in SystemVerilog HDL

## Overview

This project is an implementation of a UART (Universal Asynchronous Receiver/Transmitter) system using Verilog/SystemVerilog HDL in Xilinx Vivado.

The main purpose of this project is to understand how serial communication works at the hardware level and to design both sides of a UART communication system:

* UART Transmitter (TX)
* UART Receiver (RX)
* Combined UART Top Module
* Testbenches for verification

The transmitter converts 8-bit parallel data into a serial UART signal, while the receiver takes the serial signal and converts it back into 8-bit parallel data.

The project was designed and simulated in Vivado before moving towards hardware implementation.

---

## Project Objectives

The main objectives of this project are:

1. To understand the basic working of UART communication.
2. To design a UART transmitter in Verilog/SystemVerilog.
3. To design a UART receiver in Verilog/SystemVerilog.
4. To understand and implement a Finite State Machine (FSM).
5. To generate the correct baud timing from a 100 MHz clock.
6. To transmit and receive 8-bit data using UART.
7. To verify the transmitter and receiver using simulation.
8. To combine both modules into one complete UART system.
9. To perform loopback testing by connecting the transmitter output to the receiver input.

---

## What is UART?

UART stands for **Universal Asynchronous Receiver/Transmitter**.

It is a communication method used to transfer data serially between two devices.

Unlike some other communication protocols, UART does not use a separate clock line between the two devices. Both devices agree beforehand on the communication speed, known as the **baud rate**.

For this project, the UART is configured as:

| Parameter       | Value     |
| --------------- | --------- |
| Baud Rate       | 9600      |
| Data Bits       | 8         |
| Start Bits      | 1         |
| Stop Bits       | 1         |
| Parity          | None      |
| Data Order      | LSB First |
| Clock Frequency | 100 MHz   |

This configuration is commonly written as **9600, 8-N-1**.

---

## UART Frame Format

Every byte transmitted by the UART follows this structure:

```text
Idle   Start      Data Bits                         Stop
 1       0       D0 D1 D2 D3 D4 D5 D6 D7             1
```

The line normally stays at logic `1` when nothing is being transmitted.

When transmission starts:

1. The line goes to `0` for the start bit.
2. Eight data bits are transmitted.
3. The least significant bit is transmitted first.
4. The line returns to `1` for the stop bit.

For example, if the data is:

```text
10101010
```

UART transmits it starting from the least significant bit:

```text
0 → 1 → 0 → 1 → 0 → 1 → 0 → 1
```

---

# Project Structure

```text
UART-Receiver-Transmitter-Verilog/
│
├── README.md
│
├── src/
│   ├── uart_tx.sv
│   ├── uart_rx.sv
│   └── uart_top.sv
│
├── testbench/
│   ├── uart_tx_tb.sv
│   ├── uart_rx_tb.sv
│   └── uart_top_tb.sv
│
└── docs/
    └── UART_Specification.pdf
```

---

# UART Transmitter

The transmitter converts an 8-bit parallel input into a serial UART signal.

### Transmitter Inputs

| Signal     |  Width | Description             |
| ---------- | -----: | ----------------------- |
| `clk`      |  1 bit | 100 MHz system clock    |
| `reset`    |  1 bit | Resets the transmitter  |
| `tx_data`  | 8 bits | Data to be transmitted  |
| `tx_start` |  1 bit | Starts the transmission |

### Transmitter Outputs

| Signal    | Width | Description                                |
| --------- | ----: | ------------------------------------------ |
| `tx`      | 1 bit | Serial UART output                         |
| `tx_busy` | 1 bit | Indicates that transmission is in progress |

## Transmitter FSM

The transmitter uses four states:

```text
IDLE → START → DATA → STOP → IDLE
```

### IDLE

The transmitter waits for `tx_start`.

The serial output is:

```text
tx = 1
```

When `tx_start` becomes `1`, the transmitter moves to the START state.

### START

The transmitter sends:

```text
tx = 0
```

This represents the UART start bit.

After one complete bit period, the transmitter moves to the DATA state.

### DATA

The eight bits of `tx_data` are transmitted one at a time.

The data is transmitted **LSB first**.

For example:

```text
tx_data = 8'b10101010
```

The order on the serial line is:

```text
0 → 1 → 0 → 1 → 0 → 1 → 0 → 1
```

### STOP

After all eight data bits have been transmitted, the transmitter sends:

```text
tx = 1
```

After one stop-bit period, the transmitter returns to IDLE.

---

# UART Receiver

The receiver performs the opposite operation.

It takes the serial UART signal and reconstructs the original 8-bit data.

### Receiver Inputs

| Signal  | Width | Description          |
| ------- | ----: | -------------------- |
| `clk`   | 1 bit | 100 MHz system clock |
| `reset` | 1 bit | Resets the receiver  |
| `rx`    | 1 bit | Serial UART input    |

### Receiver Outputs

| Signal    |  Width | Description                                      |
| --------- | -----: | ------------------------------------------------ |
| `rx_data` | 8 bits | Received byte                                    |
| `rx_done` |  1 bit | Indicates that a complete byte has been received |

## Receiver FSM

The receiver uses four main states:

```text
IDLE → START → DATA → STOP → IDLE
```

### IDLE

The receiver waits for the serial line to go from:

```text
1 → 0
```

This indicates a possible start bit.

### START

The receiver waits for approximately half of a bit period.

This allows it to check the start bit near its center.

If the signal is still `0`, the receiver confirms that the start bit is valid.

If the signal has returned to `1`, the receiver assumes it was not a valid start bit and returns to IDLE.

### DATA

The receiver samples the eight data bits.

The bits are stored in:

```text
rx_data[0]
rx_data[1]
...
rx_data[7]
```

Since UART sends the least significant bit first, the first received bit is stored in `rx_data[0]`.

### STOP

After receiving all eight data bits, the receiver checks the stop bit.

The stop bit should be:

```text
1
```

If the stop bit is correct, `rx_done` is asserted to indicate that a complete byte has been received.

---

# Baud Rate and Timing

The FPGA system clock used in this project is:

```text
100 MHz
```

The UART baud rate is:

```text
9600 baud
```

The number of clock cycles required for approximately one UART bit is calculated using:

```text
CLK_PER_BIT = CLK_FREQ / BAUD_RATE
```

Therefore:

```text
CLK_PER_BIT = 100,000,000 / 9600
            ≈ 10416
```

The design uses a baud counter to keep track of these clock cycles.

The counter counts the system clock cycles until one UART bit period is completed.

A `baud_tick` is generated when the required number of clock cycles has passed.

This allows the FSM to move from one UART bit to the next at the correct time.

---

# Start Bit Detection in Receiver

The receiver uses half-bit timing when it detects a possible start bit.

The reason is to sample the start bit closer to its center instead of immediately at the transition.

The half-bit value is calculated as:

```text
HALF_BIT = CLK_PER_BIT / 2
```

For this project:

```text
HALF_BIT ≈ 5208 clock cycles
```

The receiver first detects:

```text
rx = 0
```

It then waits approximately half a bit period and checks the signal again.

If it is still `0`, the receiver accepts it as a valid start bit and begins receiving data.

---

# Finite State Machine

Both the transmitter and receiver are implemented using FSMs.

The transmitter uses:

```text
IDLE
START
DATA
STOP
```

The receiver uses the same four states:

```text
IDLE
START
DATA
STOP
```

The current state is stored in a state register, while the next-state logic determines which state should come next.

This makes the UART operation easier to organize and understand.

---

# SystemVerilog Features Used

The project uses SystemVerilog features required for the FSM and sequential logic.

## `logic`

Signals are declared using `logic`.

Example:

```systemverilog
logic clk;
logic reset;
logic [7:0] tx_data;
```

## `always_ff`

Sequential logic such as counters, state registers, and data registers is written using:

```systemverilog
always_ff @(posedge clk or posedge reset)
```

## `always_comb`

Combinational logic such as next-state logic and output logic is written using:

```systemverilog
always_comb
```

## `typedef enum`

The UART states are defined using an enumerated type:

```systemverilog
typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
} state_t;
```

This makes the FSM states easier to read.

## Parameters

The clock frequency and baud rate are defined as parameters:

```systemverilog
parameter CLK_FREQ  = 100_000_000;
parameter BAUD_RATE = 9600;
```

This allows the UART design to be reused with different clock frequencies or baud rates.

---

# Combined UART Top Module

The top module connects the transmitter and receiver together.

```text
          UART TOP MODULE

        ┌───────────────┐
        │   UART TX     │
        └───────┬───────┘
                │
                │ Serial Line
                │
        ┌───────▼───────┐
        │   UART RX     │
        └───────────────┘
```

During loopback testing, the transmitter output is connected directly to the receiver input.

This allows a byte to be transmitted and then received by the same system.

---

# Verification

Separate testbenches are used to verify the individual modules.

## UART TX Testbench

The TX testbench checks whether the transmitter produces the correct UART frame.

It checks:

* Start bit
* Eight data bits
* LSB-first order
* Stop bit
* Busy signal
* Correct timing

Example test data includes:

```text
A5
55
3C
```

The results are printed in the simulator console using `$display`.

---

## UART RX Testbench

The RX testbench generates a UART serial signal and provides it to the receiver.

The testbench sends:

```text
Start bit
     ↓
8 data bits
     ↓
Stop bit
```

The receiver reconstructs the byte and the testbench compares the received value with the expected value.

---

## Combined UART Testbench

The combined testbench performs loopback testing.

```text
       TX
        │
        ▼
   Serial Line
        │
        ▼
       RX
```

For example:

```text
TX sends:       A5
                  ↓
              UART line
                  ↓
RX receives:    A5
```

The testbench compares the transmitted byte with the received byte.

If both values are equal, the test passes.

---

# Simulation

The project is developed and simulated using **Xilinx Vivado**.

The testbenches use `$display` statements to show verification results in the simulator console.

A successful test can produce output similar to:

```text
TEST 1 : PASS
Sent     = A5
Received = A5

TEST 2 : PASS
Sent     = 55
Received = 55

TEST 3 : PASS
Sent     = 3C
Received = 3C
```

The waveform can also be used to observe:

```text
clk
reset
tx_start
tx
tx_busy
rx
rx_data
rx_done
```

The waveform helps in checking the actual timing and sequence of the UART frame.

---

# Tools Used

* Xilinx Vivado
* Verilog/SystemVerilog HDL
* Vivado Simulator
* GitHub
* FPGA development environment

---

# Current Features

* 8-bit UART communication
* 9600 baud rate
* 100 MHz clock support
* 1 start bit
* 8 data bits
* 1 stop bit
* No parity
* LSB-first transmission
* FSM-based transmitter
* FSM-based receiver
* Baud-rate timing
* Half-bit start-bit verification
* Separate TX and RX testbenches
* Combined TX/RX loopback testing

---

# Future Improvements

Possible improvements for future versions include:

* Configurable parity
* Different numbers of stop bits
* Support for additional baud rates
* FIFO buffers
* Multiple-byte transmission
* Error detection
* FPGA hardware testing with a real serial interface
* Computer-to-FPGA UART communication

---

# Conclusion

This project focuses on understanding how UART communication can be implemented directly in digital hardware.

The transmitter and receiver were designed as separate FSM-based modules. Timing is generated from the FPGA clock using a baud counter, while the receiver uses half-bit timing to properly identify and sample the start of a UART frame.

Separate testbenches are used to verify the transmitter and receiver, while the combined design can be tested using loopback communication.

The current design provides a basic UART system that can be extended with additional communication features in the future.
