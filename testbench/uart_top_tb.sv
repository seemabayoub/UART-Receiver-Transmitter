`timescale 1ns / 1ps

module uart_top_tb;
    // Signals

    logic clk;
    logic reset;

    logic [7:0] tx_data;
    logic tx_start;

    logic uart_line;

    logic tx_busy;
    logic [7:0] rx_data;
    logic rx_done;
    // Test counters

    integer test_count;
    integer pass_count;
    integer fail_count;

    // DUT - Device Under Test

    uart_top uut (

        .clk(clk),
        .reset(reset),

        .tx_data(tx_data),
        .tx_start(tx_start),

        .rx(uart_line),

        .tx(uart_line),
        .tx_busy(tx_busy),

        .rx_data(rx_data),
        .rx_done(rx_done)
    );


    always #5 clk = ~clk;

  //send one byte

    task send_byte(input logic [7:0] data);

        begin

            // data to transmitter
            tx_data = data;

            // Start transmission
            @(posedge clk);
            tx_start = 1'b1;

            @(posedge clk);
            tx_start = 1'b0;

            // wait till busy=1
            wait(tx_busy == 1'b1);

            // Wait until transmission is complete
            wait(tx_busy == 1'b0);

        end

    endtask
// check received data

    task check_received(input logic [7:0] expected);

        begin
//data received
            wait(rx_done == 1'b1);

            test_count = test_count + 1;

            if (rx_data == expected) begin

                pass_count = pass_count + 1;

                $display("--------------------------------------------------");
                $display("TEST %0d : PASS", test_count);
                $display("Sent     = %h", expected);
                $display("Received = %h", rx_data);
                $display("--------------------------------------------------");

            end
            else begin

                fail_count = fail_count + 1;

                $display("--------------------------------------------------");
                $display("TEST %0d : FAIL", test_count);
                $display("Sent     = %h", expected);
                $display("Received = %h", rx_data);
                $display("--------------------------------------------------");

            end

        end

    endtask
// main test

    initial begin

        // Initial values
        clk = 1'b0;
        reset = 1'b1;

        tx_data = 8'b0;
        tx_start = 1'b0;

        test_count = 0;
        pass_count = 0;
        fail_count = 0;
// reset

        $display("");
        $display("==================================================");
        $display("       UART LOOPBACK TEST STARTED");
        $display("==================================================");
        $display("");

        #100;

        reset = 1'b0;

        #100;
      
        // TEST 1
      
        $display("Sending Byte 1...");

        fork
            send_byte(8'hA5);
            check_received(8'hA5);
        join


        // Small gap
        #1000;

        // TEST 2

        $display("Sending Byte 2...");

        fork
            send_byte(8'h55);
            check_received(8'h55);
        join


        #1000;
        // TEST 3

        $display("Sending Byte 3...");

        fork
            send_byte(8'hF0);
            check_received(8'hF0);
        join


        #1000;

        // TEST 4

        $display("Sending Byte 4...");

        fork
            send_byte(8'h3C);
            check_received(8'h3C);
        join


        #1000;

        // FINAL RESULT

        $display("");
        $display("==================================================");
        $display("              UART TEST RESULTS");
        $display("==================================================");

        $display("Total Tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("************** ALL TESTS PASSED **************");
            $display("************** UART WORKING! *****************");

        end
        else begin

            $display("");
            $display("************** SOME TESTS FAILED *************");

        end

        $display("==================================================");
        $display("");

        $finish;

    end

endmodule
