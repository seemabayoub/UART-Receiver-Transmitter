`timescale 1ns / 1ps

module uart_rx_tb;

    logic clk;
    logic reset;
    logic rx;

    logic [7:0] rx_data;
    logic rx_done;
    localparam BIT_TIME = 104160;
    task send_byte(input logic [7:0] data);
    integer i;
begin
rx = 1'b0; //in receiver before sending byte startbit=0
    #(BIT_TIME); //wait till one comp. bit time rx=0 rakhega aik bit_time k liye
for (i = 0; i < 8; i = i + 1) begin //8 times chale ga
            rx = data[i]; // i=0 data[0] , i=1 data[1] 
            #(BIT_TIME); //hr bit ko 1 bit_time k liye RX pr hold krega
        end
        rx = 1'b1; //after 8 bits stop_bit=0
        #(BIT_TIME);
end
endtask

initial begin
    #200;
    send_byte(8'b10101010);
    #200;
$finish;
end
always @(posedge rx_done) begin

    if (rx_data == 8'b10101010)
        $display("RX DATA RECEIVED!");
    else
        $display("RX DATA NOT RECEIVED!");

end

    uart_rx uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
always #5 clk = ~clk;
initial begin
    clk = 0;
     reset = 1;
    rx = 1;
    #100;
    reset = 0;
end
endmodule

