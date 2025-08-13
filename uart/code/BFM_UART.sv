`timescale 1ns/1ps
package BFM_UART;
class uart_cfg;

    real baud_rate = 115200;    //波特率115200
    real stop_bits = 1;         //停止位位数
    real start_bits = 1;        //起始位位数
    real idle_bits = 0;         //空闲位位数
    bit [2:0] check_bit = 0;    //校验位模式 0:无校验 1:奇校验 2:偶校验 3:固定1 4:固定0
    bit start_level = 0;        //起始位电平 0:低电平 1:高电平
    bit stop_level = 1;         //停止位电平 0:低电平 1:高电平
    bit lsb_msb = 1;            //字节顺序  1:先低后高 0:先高后低
    bit polarity = 1;           //信号极性 1:空闲高电平 0:空闲低电平

endclass

class uart_gen #(parameter DATA_BITS = 8); //DATA_BITS:数据位位数

    virtual uart_if vif;

    uart_cfg cfg;

    typedef enum {IDLE, START, DATA, CHECK, STOP} uart_state_e;

    uart_state_e state = IDLE;
    

    function new(input virtual uart_if vif = null ,input bit polarity);
        this.vif = vif;
        cfg = new();
        cfg.polarity = polarity;
        vif.tx = cfg.polarity;
    endfunction

    //UART数据发送
    task tx_data(input [DATA_BITS-1:0] data);
        bit [7:0] i = 0;

        //起始位
        state = START;
        vif.tx = cfg.start_level;
        #(1e9/cfg.baud_rate*cfg.start_bits);
        
        //数据位
        state = DATA;
        repeat(DATA_BITS) begin
            vif.tx = cfg.lsb_msb ? data[i] : data[DATA_BITS-i-1];
            #(1e9/cfg.baud_rate);
            i++;
        end

        //校验位
        state = CHECK;
        case (cfg.check_bit)
            1 : vif.tx = !(^data); //奇校验
            2 : vif.tx = ^data;    //偶校验
            3 : vif.tx = 1;        //固定1
            4 : vif.tx = 0;        //固定0
            default : ;
        endcase
        if(cfg.check_bit)
            #(1e9/cfg.baud_rate);
        
        //停止位
        state = STOP;
        vif.tx = cfg.stop_level;
        #(1e9/cfg.baud_rate*cfg.stop_bits);

        //空闲位
        state = IDLE;
        vif.tx = cfg.polarity;
        if(cfg.idle_bits)
            #(1e9/cfg.baud_rate*cfg.idle_bits);
    endtask

    task rx_data(output [DATA_BITS-1:0] data);

        logic [DATA_BITS-1:0] data_r = 0;
        bit check_r;
        bit [7:0] i = 0;
        bit start_r;
        bit stop_r;

        if(cfg.polarity)
            @(negedge vif.rx);
        else
            @(posedge vif.rx); 

        //起始位
        #(1e9/cfg.baud_rate/2);
        start_r = vif.rx;
        if(start_r == cfg.polarity) begin
            $display("start bit error");
            return;
        end
    
        //数据位
        repeat(DATA_BITS) begin
            #(1e9/cfg.baud_rate);
            if (cfg.lsb_msb)
                data_r[i] = vif.rx;
            else
                data_r[DATA_BITS-i-1] = vif.rx;
            i++;
        end
        
        //校验位
        if (cfg.check_bit) begin
            #(1e9/cfg.baud_rate);
            case (cfg.check_bit)
                1 : check_r = !(^data_r); //奇校验
                2 : check_r = ^data_r;    //偶校验
                3 : check_r = 1;          //固定1
                4 : check_r = 0;          //固定0
                default : ;
            endcase
            if (vif.rx != check_r) begin
                $display("check bit error");
                return;
            end
        end
        

        //停止位
        #(1e9/cfg.baud_rate);
        stop_r = vif.rx;
        if(stop_r != cfg.polarity) begin
            $display("stop bit error");
            return;
        end

        //输出数据
        #(1e9/cfg.baud_rate/2);
        data = data_r;
        //$display("rx_data is %0h",data);

    endtask

endclass
endpackage