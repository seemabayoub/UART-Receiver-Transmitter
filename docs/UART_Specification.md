# UART Receiver and Transmitter Specification

## 1. Project Overview

This project implements a UART (Universal Asynchronous Receiver/Transmitter) using SystemVerilog.

The design contains:

* UART Transmitter (TX)
* UART Receiver (RX)
* Combined UART Top Module
* Separate testbenches for verification
* Combined loopback testbench for system-level verification

The design is developed and simulated using Xilinx Vivado.

---

## 2. UART Configuration

| Parameter        | Value     |
| ---------------- | --------- |
| Clock Frequency  | 100 MHz   |
| Baud Rate        | 9600      |
| Data Bits        | 8         |
| Start Bits       | 1         |
| Stop Bits        | 1         |
| Parity           | None      |
| Data Order       | LSB First |
| Logic Idle State | HIGH      |

### Baud Timing

The number of clock cycles per UART bit is:

$$
CLK\_PER\_BIT = \frac{100{,}000{,}000}{9600}
$$

$$
CLK\_PER\_BIT \approx 10416
$$

Therefore, approximately 10416 clock cycles are used for each UART bit.

---

## 3. UART Frame Format

Each transmitted byte follows this format:

```text
Idle     Start       Data Bits              Stop
 1         0       D0 D1 D2 D3 D4 D5 D6 D7   1
 |         |        |                    |   |
 HIGH     LOW     LSB First            MSB  HIGH
```

For example, if the data is:

```text
10101010
```

UART sends it as:

```text
Start → 0
D0    → 0
D1    → 1
D2    → 0
D3    → 1
D4    → 0
D5    → 1
D6    → 0
D7    → 1
Stop  → 1
```

So the data bits are transmitted **LSB first**.

---

## 4. UART Transmitter Specification

The transmitter converts an 8-bit parallel data value into a serial UART signal.

### Inputs

| Signal     | Width  | Description            |
| ---------- | ------ | ---------------------- |
| `clk`      | 1 bit  | 100 MHz system clock   |
| `reset`    | 1 bit  | Resets the transmitter |
| `tx_data`  | 8 bits | Data to be transmitted |
| `tx_start` | 1 bit  | Starts transmission    |

### Outputs

| Signal    | Width | Description                                |
| --------- | ----- | ------------------------------------------ |
| `tx`      | 1 bit | Serial UART output                         |
| `tx_busy` | 1 bit | Indicates that transmission is in progress |

### Transmitter Operation

When `tx_start` becomes HIGH:

1. The transmitter accepts `tx_data`.
2. It sends the start bit (`0`).
3. It sends 8 data bits, LSB first.
4. It sends the stop bit (`1`).
5. It returns to the `IDLE` state.
6. `tx_busy` becomes LOW.

### Transmitter FSM

```text
             tx_start
                |
                v
           +---------+
           |  IDLE   |
           +---------+
                |
                v
           +---------+
           |  START  |
           +---------+
                |
                v
           +---------+
           |  DATA   |
           +---------+
                |
             bit 7?
                |
                v
           +---------+
           |  STOP   |
           +---------+
                |
                v
              IDLE
```

---

## 5. UART Receiver Specification

The receiver converts the incoming serial UART signal back into an 8-bit parallel data value.

### Inputs

| Signal  | Width | Description            |
| ------- | ----- | ---------------------- |
| `clk`   | 1 bit | 100 MHz system clock   |
| `reset` | 1 bit | Resets the receiver    |
| `rx`    | 1 bit | Incoming serial UART signal |

### Outputs

| Signal    | Width  | Description                             |
| --------- | ------ | --------------------------------------- |
| `rx_data` | 8 bits | Received byte                           |
| `rx_done` | 1 bit  | Indicates that a byte has been received |

### Receiver Operation

The receiver:

1. Waits for the UART line to go LOW.
2. Detects the start bit.
3. Waits for half a bit period.
4. Checks the middle of the start bit to confirm it is valid.
5. Samples the 8 data bits.
6. Stores them in `rx_data`.
7. Checks the stop bit.
8. Generates `rx_done = 1`.
9. Returns to `IDLE`.

---

## 6. Receiver Half-Bit Detection

The receiver does not immediately assume that every LOW signal is a valid start bit.

After detecting a LOW signal:

```text
        Start bit
       <---------->
       0          0
       |          |
       ^          ^
     Detect      Sample
       |<-- 1/2 bit -->|
```

It waits for half of the bit period and checks the signal again.

If the signal is still LOW:

```text
Valid start bit
```

The receiver continues to receive data.

If it becomes HIGH:

```text
Invalid start bit
```

The receiver returns to `IDLE`.

This helps the receiver sample the start bit near its center.

---

## 7. Receiver FSM

The receiver uses four main states:

```text
           RX = 0
              |
              v
         +----------+
         |   IDLE   |
         +----------+
              |
              v
         +----------+
         |  START   |
         +----------+
              |
        Valid start
              |
              v
         +----------+
         |   DATA   |
         +----------+
              |
           8 bits
              |
              v
         +----------+
         |   STOP   |
         +----------+
              |
              v
            IDLE
```

---

## 8. Baud Counter

The baud counter controls the timing of UART bits.

For this project:

```text
Clock frequency = 100 MHz
Baud rate       = 9600
```

Approximately:

```text
10416 clock cycles = 1 UART bit
```

The counter counts these clock cycles.

When the required number of cycles is completed:

```text
baud_tick = 1
```

The UART uses this event to move to the next bit.

---

## 9. Top Module

The `uart_top` module combines the transmitter and receiver.

```text
             +----------------------+
             |      UART TOP        |
             |                      |
tx_data ---->|  UART Transmitter    |----> tx
tx_start --->|                      |
             |                      |
rx <---------|  UART Receiver       |
             |                      |----> rx_data
             |                      |----> rx_done
             +----------------------+
```

For loopback testing:

```text
TX --------------------> RX
       UART LINE
```

The transmitted data is directly connected to the receiver input.

This allows the complete UART system to be tested.

---

## 10. Verification

The project contains three levels of verification:

### TX Testbench

Tests only the transmitter:

```text
tx_data → UART TX → tx
```

Checks:

* Start bit
* 8 data bits
* Stop bit
* Correct bit order

### RX Testbench

Tests only the receiver:

```text
Testbench → rx → UART RX → rx_data
```

Checks:

* Start-bit detection
* Data reception
* Stop-bit detection
* `rx_done`

### Top Testbench

Tests the complete system:

```text
       +---------+
       |   TX    |
       +----+----+
            |
         UART LINE
            |
       +----v----+
       |   RX    |
       +---------+
```

The transmitted data should be received correctly.

---

## 11. Expected Result

For a transmitted byte such as:

```text
8'hA5
```

the receiver should produce:

```text
rx_data = 8'hA5
rx_done = 1
```

The simulation testbench checks the received value automatically.

---

## 12. Final Specification Summary

```text
UART Type       : Asynchronous
Clock           : 100 MHz
Baud Rate       : 9600
Data            : 8 bits
Start Bit       : 1
Stop Bit        : 1
Parity          : None
Data Order      : LSB First
TX              : Parallel to Serial
RX              : Serial to Parallel
Verification    : TX TB + RX TB + Loopback TB
Tool            : Xilinx Vivado
Language        : SystemVerilog
```
