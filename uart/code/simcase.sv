`timescale 1ns/1ps

module simcase();

parameter DATA_BITS = 6;
logic [DATA_BITS-1:0] data;

tb_uart tb();

initial begin
    fork
        begin #10ns; tb.gen.tx_data(6'h37); end
        begin tb.gen.rx_data(data); end
    join
end

endmodule