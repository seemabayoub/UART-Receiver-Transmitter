`timescale 1ns / 1ps

module uart_tx_tb;

    //==========================================================
    // Signals
    //==========================================================

    logic clk;
    logic reset;

    logic [7:0] tx_data;
    logic tx_start;

    logic tx;
    logic tx_busy;


    //==========================================================
    // UART TX Parameters
    //==========================================================

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_RATE = 9600;

    localparam CLK_PER_BIT = CLK_FREQ / BAUD_RATE;

    // One UART bit = approximately 104160 ns
    localparam BIT_TIME = 104160;


    //==========================================================
    // DUT
    //==========================================================

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );


    //==========================================================
    // 100 MHz Clock
    //==========================================================

    always #5 clk = ~clk;


    //==========================================================
    // Task: Send Byte
    //==========================================================

    task send_byte(input logic [7:0] data);

        begin

            tx_data = data;

            // Start transmission
            @(posedge clk);
            tx_start = 1'b1;

            @(posedge clk);
            tx_start = 1'b0;

            // Wait for transmitter to become busy
            wait(tx_busy == 1'b1);

            $display("");
            $display("--------------------------------------------------");
            $display("TX TEST");
            $display("Data Sent = %h", data);
            $display("--------------------------------------------------");

            // Wait until transmission finishes
            wait(tx_busy == 1'b0);

        end

    endtask


    //==========================================================
    // Check UART Frame
    //==========================================================

    task check_frame(input logic [7:0] expected_data);

        integer i;

        begin

            // Wait approximately until START bit begins
            wait(tx_busy == 1'b1);

            #(BIT_TIME / 2);

            // Check START bit
            if (tx == 1'b0)
                $display("START BIT : PASS");
            else
                $display("START BIT : FAIL");


            // Move to middle of first DATA bit
            #(BIT_TIME);

            // Check 8 data bits
            for (i = 0; i < 8; i = i + 1) begin

                if (tx == expected_data[i])
                    $display("DATA BIT %0d : PASS", i);
                else
                    $display(
                        "DATA BIT %0d : FAIL | Expected=%b Received=%b",
                        i,
                        expected_data[i],
                        tx
                    );

                #(BIT_TIME);

            end


            // Check STOP bit
            if (tx == 1'b1)
                $display("STOP BIT : PASS");
            else
                $display("STOP BIT : FAIL");

        end

    endtask


    //==========================================================
    // Main Test
    //==========================================================

    initial begin

        // Initial values
        clk = 1'b0;
        reset = 1'b1;

        tx_data = 8'b0;
        tx_start = 1'b0;


        $display("");
        $display("==================================================");
        $display("           UART TRANSMITTER TEST");
        $display("==================================================");


        // Reset
        #100;
        reset = 1'b0;

        #100;


        //======================================================
        // TEST 1
        //======================================================

        fork
            send_byte(8'hA5);
            check_frame(8'hA5);
        join


        #2000;


        //======================================================
        // TEST 2
        //======================================================

        fork
            send_byte(8'h55);
            check_frame(8'h55);
        join


        #2000;


        //======================================================
        // TEST 3
        //======================================================

        fork
            send_byte(8'h3C);
            check_frame(8'h3C);
        join


        #2000;


        $display("");
        $display("==================================================");
        $display("           UART TX TEST FINISHED");
        $display("==================================================");
        $display("");

        $finish;

    end

endmodule
