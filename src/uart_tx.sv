`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input logic clk,
    input logic reset,
    input logic [7:0] tx_data,
    input logic tx_start,
    output logic tx,
    output logic tx_busy
);

    localparam CLK_PER_BIT = CLK_FREQ / BAUD_RATE;

    logic [13:0] baud_counter;
    logic [2:0] bit_count;
    logic baud_tick;

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state, next_state;

    assign baud_tick = (baud_counter == CLK_PER_BIT - 1);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            baud_counter <= 0;
        end
        else if (state == IDLE) begin
            baud_counter <= 0;
        end
        else if (baud_tick) begin
            baud_counter <= 0;
        end
        else begin
            baud_counter <= baud_counter + 1;
        end
    end
        always_comb begin
        case (state)
            IDLE: begin
                if (tx_start)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            START: begin
                if (baud_tick)
                    next_state = DATA;
                else
                    next_state = START;
            end
            DATA: begin
                if (baud_tick) begin
                    if (bit_count == 3'd7)
                        next_state = STOP;
                    else
                        next_state = DATA;
                end
                else begin
                    next_state = DATA;
                end
            end
                        STOP: begin
                if (baud_tick)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end
                        default: begin
                next_state = IDLE;
            end
        endcase
    end
        always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
        always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_count <= 0;
        end
        else if (state == IDLE) begin
            bit_count <= 0;
        end
        else if (state == DATA && baud_tick) begin
            bit_count <= bit_count + 1;
        end
    end
        always_comb begin
        case (state)

            IDLE: begin
                tx = 1;
            end

            START: begin
                tx = 0;
            end

            DATA: begin
                tx = tx_data[bit_count];
            end

            STOP: begin
                tx = 1;
            end

            default: begin
                tx = 1;
            end

        endcase
    end
        always_comb begin
        if (state == IDLE)
            tx_busy = 0;
        else
            tx_busy = 1;
    end
endmodule
