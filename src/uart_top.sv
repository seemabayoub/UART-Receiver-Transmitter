`timescale 1ns / 1ps

module uart_top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  logic       clk,
    input  logic       reset,

    // Transmitter inputs
    input  logic [7:0] tx_data,
    input  logic       tx_start,

    // Serial connection
    input  logic       rx,

    // Transmitter outputs
    output logic       tx,
    output logic       tx_busy,

    // Receiver outputs
    output logic [7:0] rx_data,
    output logic       rx_done
);

    // UART Transmitter
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) transmitter (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // UART Receiver
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) receiver (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

endmodule
