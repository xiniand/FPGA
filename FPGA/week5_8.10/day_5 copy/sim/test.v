//UART接收testbench：例化brg产生tick + 例化rx，连续发送两帧验证
`timescale 1ns/1ns
module test;
    reg         clk     ;
    reg         rst_n   ;
    reg         rx      ;
    wire        tick    ;
    wire        rx_done ;
    wire [7:0]  data    ;

    //50MHz时钟
    always #10 clk = ~clk;

    //波特率发生器：使能常开，产生9600bps的tick
    brg brg_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .brg_en(1'b1  ),
        .tick  (tick  )
    );

    //接收器
    rx rx_u(
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .rx     (rx     ),
        .tick   (tick   ),
        .rx_done(rx_done),
        .data   (data   )
    );

    integer fd;                            //结果文件句柄

    //发送一帧：起始位0 + 8位数据(LSB先) + 停止位1，每bit约1/9600s
    task send_byte;
        input [7:0] d;
        integer i;
        begin
            rx = 1'b1;
            #104167 rx = 1'b0;              //起始位
            for(i = 0; i < 8; i = i + 1) begin
                #104167 rx = d[i];          //数据位LSB先
            end
            #104167 rx = 1'b1;              //停止位
        end
    endtask

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        rx    = 1'b1;
        fd = $fopen("result.txt");
        $fdisplay(fd, "--- testbench started ---");
        #100 rst_n = 1'b1;
        #500;

        //第一帧：0x55
        send_byte(8'h55);
        @(posedge rx_done);
        #100;
        if(data == 8'h55)
            $fdisplay(fd, "TEST PASS(1): data = %h", data);
        else
            $fdisplay(fd, "TEST FAIL(1): data=%h", data);

        #100000;                            //帧间隔

        //第二帧：0xA5
        send_byte(8'hA5);
        @(posedge rx_done);
        #100;
        if(data == 8'hA5)
            $fdisplay(fd, "TEST PASS(2): data = %h", data);
        else
            $fdisplay(fd, "TEST FAIL(2): data=%h", data);

        $fclose(fd);
        #1000 $finish;
    end
endmodule
