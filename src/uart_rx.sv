module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  logic clk,
    input  logic reset,
    input  logic rx,
    output logic [7:0] rx_data,
    output logic rx_done
);
localparam CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam HALF_BIT = CLK_PER_BIT / 2;
    logic [13:0] baud_counter;
    logic [2:0] bit_count;
    logic baud_tick;
    assign baud_tick = (baud_counter == CLK_PER_BIT - 1);
        typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state, next_state;
       always_ff @(posedge clk or posedge reset) begin
    if (reset)
        baud_counter <= 0;
    else if (state == IDLE)
        baud_counter <= 0;
    else if (state == START && baud_counter == HALF_BIT - 1)
        baud_counter <= 0;
    else if (baud_tick)
        baud_counter <= 0;
    else
        baud_counter <= baud_counter + 1;
end
        always_comb begin
        case (state)

            IDLE: begin
                if (rx == 0)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            START: begin
    if (baud_counter == HALF_BIT - 1) begin
        if (rx == 1'b0)
            next_state = DATA;
        else
            next_state = IDLE;
    end
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
    always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_data <= 8'b0;
    end
    else if (state == DATA && baud_tick) begin
        rx_data[bit_count] <= rx;
    end
end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_done <= 0;
        end
        else begin
            rx_done <= 0;

            if (state == STOP && baud_tick && rx == 1'b1) begin
                rx_done <= 1;
            end
        end
    end
    
endmodule
