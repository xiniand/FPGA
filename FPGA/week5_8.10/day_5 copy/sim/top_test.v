//top testbench：验证两条链路（PC串口助手调试模式）
//1) 发送：拨码tx_data + tx_star触发，FPGA经tx发出，PC端(rx)应收到相同字节
//2) 接收：PC端发送字节给FPGA的rx，FPGA应正确接收（rx_done + 内部data）
`timescale 1ns/1ns
module top_test;
    reg         clk     ;
    reg         rst_n   ;
    reg         rx      ;//模拟PC发送 -> top.rx
    reg         tx_star ;
    reg  [7:0]  tx_data ;
    wire        tx      ;//top.tx -> PC
    wire        tx_done ;
    wire        rx_done ;
    wire        tick    ;
    //PC接收端：用rx接收top.tx发出的数据
    wire        pc_rx_done;
    wire [7:0]  pc_data   ;

    always #10 clk = ~clk;

    //波特率发生器（供PC端rx使用）
    brg brg_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .brg_en(1'b1  ),
        .tick  (tick  )
    );

    //被测顶层
    top top_u(
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .rx     (rx     ),
        .tx_star(tx_star),
        .tx_data(tx_data),
        .tx     (tx     ),
        .tx_done(tx_done),
        .rx_done(rx_done)
    );

    //PC接收端
    rx pc_rx(
        .clk    (clk     ),
        .rst_n  (rst_n   ),
        .rx     (tx      ),
        .tick   (tick    ),
        .rx_done(pc_rx_done),
        .data   (pc_data )
    );

    //模拟PC串口发送一帧：起始位0 + 8数据(LSB先) + 停止位1
    task pc_send;
        input [7:0] d;
        integer i;
        begin
            rx = 1'b1;
            #104167 rx = 1'b0;
            for(i = 0; i < 8; i = i + 1) begin
                #104167 rx = d[i];
            end
            #104167 rx = 1'b1;
            #104167;
        end
    endtask

    integer fd;
    reg         rx_done_seen;//捕获rx_done上升沿（脉冲太短，用标志监测）

    //监测rx_done上升沿
    always @(posedge rx_done) rx_done_seen = 1'b1;

    initial begin
        clk     = 1'b0;
        rst_n   = 1'b0;
        rx      = 1'b1;
        tx_star = 1'b0;
        tx_data = 8'h00;
        rx_done_seen = 1'b0;
        fd = $fopen("top_result.txt");
        $fdisplay(fd, "--- uart tx/rx test (serial tool mode) ---");
        #100 rst_n = 1'b1;
        #500;

        //---------- 测试1：发送（拨码0x5A -> 触发 -> PC端收到0x5A）----------
        tx_data = 8'h5A;
        tx_star = 1'b1;
        #200000;                        //保持tx_star超过一个bit周期
        tx_star = 1'b0;

        @(posedge pc_rx_done);
        #100;
        if(pc_data == 8'h5A)
            $fdisplay(fd, "TX PASS: fpga send %h, pc recv %h", 8'h5A, pc_data);
        else
            $fdisplay(fd, "TX FAIL: fpga send %h, pc recv %h", 8'h5A, pc_data);

        #100000;

        //---------- 测试2：接收（PC发0xC3 -> FPGA的rx接收）----------
        rx_done_seen = 1'b0;
        pc_send(8'hC3);
        #100;
        if(rx_done_seen && (top_u.rx_u.data == 8'hC3))
            $fdisplay(fd, "RX PASS: pc send %h, fpga recv %h", 8'hC3, top_u.rx_u.data);
        else
            $fdisplay(fd, "RX FAIL: pc send %h, fpga recv %h", 8'hC3, top_u.rx_u.data);

        $fclose(fd);
        #1000 $finish;
    end
endmodule
