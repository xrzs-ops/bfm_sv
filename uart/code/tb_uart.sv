`timescale 1ns/1ps

module tb_uart();

import BFM_UART::*;

parameter DATA_BITS = 6;

uart inst0_uart(
    .rx (u_if.tx),
    .tx (u_if.rx)
);

uart_gen #(DATA_BITS) gen;
uart_if u_if();

initial begin
    gen = new(u_if,1'b1);
end

initial $wlfdumpvars();

endmodule