//偶校验testbench：验证rx的偶校验（parity_error）逻辑
//发送帧结构：起始位0 + 8数据位(LSB先) + 偶校验位 + 停止位1
//偶校验：校验位 = ^data（数据位+校验位中1的个数为偶数）
`timescale 1ns/1ns
module parity_test;
    reg         clk     ;
    reg         rst_n   ;
    reg         rx      ;
    wire        rx_done ;
    wire        parity_error;
    wire [7:0]  data    ;

    always #10 clk = ~clk;

    brg brg_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .brg_en(1'b1  ),
        .tick  (tick  )
    );

    rx rx_u(
        .clk         (clk         ),
        .rst_n       (rst_n       ),
        .rx          (rx          ),
        .tick        (tick        ),
        .rx_done     (rx_done     ),
        .parity_error(parity_error),
        .data        (data        )
    );

    //发送一帧：起始位0 + 8数据(LSB先) + 偶校验位 + 停止位1
    //par_correct=1 校验位正确；=0 校验位取反(错误)
    task send_frame;
        input [7:0] d;
        input       par_correct;
        integer i;
        begin
            rx = 1'b1;
            #104167 rx = 1'b0;                        //起始位
            for(i = 0; i < 8; i = i + 1)
                #104167 rx = d[i];                    //数据位LSB先
            #104167 rx = par_correct ? ^d : ~^d;      //偶校验位
            #104167 rx = 1'b1;                        //停止位
            #104167;
        end
    endtask

    reg rx_done_seen;
    always @(posedge rx_done) rx_done_seen = 1'b1;

    integer fd;
    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        rx    = 1'b1;
        rx_done_seen = 1'b0;
        fd = $fopen("parity_result.txt");
        $fdisplay(fd, "--- uart even-parity test ---");
        #100 rst_n = 1'b1;
        #500;

        //---------- 测试1：校验位正确（0x55，^0x55=0，偶数个1）----------
        rx_done_seen = 1'b0;
        send_frame(8'h55, 1'b1);
        #100;
        if(rx_done_seen && (data == 8'h55) && (parity_error == 1'b0))
            $fdisplay(fd, "PARITY PASS(1): data=%h parity_error=%b", data, parity_error);
        else
            $fdisplay(fd, "PARITY FAIL(1): data=%h parity_error=%b", data, parity_error);

        #100000;

        //---------- 测试2：校验位错误（取反）----------
        rx_done_seen = 1'b0;
        send_frame(8'h55, 1'b0);
        #100;
        if(rx_done_seen && (parity_error == 1'b1))
            $fdisplay(fd, "PARITY PASS(2): wrong-parity detected, parity_error=%b", parity_error);
        else
            $fdisplay(fd, "PARITY FAIL(2): parity_error=%b", parity_error);

        #100000;

        //---------- 测试3：奇数个1的数据（0xA5，^0xA5=1），校验位正确=1 ----------
        rx_done_seen = 1'b0;
        send_frame(8'hA5, 1'b1);
        #100;
        if(rx_done_seen && (data == 8'hA5) && (parity_error == 1'b0))
            $fdisplay(fd, "PARITY PASS(3): data=%h parity_error=%b", data, parity_error);
        else
            $fdisplay(fd, "PARITY FAIL(3): data=%h parity_error=%b", data, parity_error);

        $fclose(fd);
        #1000 $finish;
    end
endmodule
