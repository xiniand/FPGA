`timescale 1ns/1ns

module test ();
reg               clk         ;
reg               rst_n       ;
reg               iic_start   ;//开始通信信号    
reg       [7:0]   data_i_iic  ;//要发送的信号
wire      [7:0]   data_out    ;//接收到的信号
wire              iic_done_r  ;//读完
wire              iic_done_w  ;//写完
wire              iic_done    ;//写完
tri0              sda         ;//数据线总线
tri0              scl         ;//时钟线 

initial begin
    clk =0;
    rst_n=0;
    iic_start =0;
    #100
    rst_n = 1;
    #100
    iic_start = 1;
    #100
    iic_start = 0;
end

always #10 clk = ~clk;   //时钟翻转 50MHz

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        data_i_iic<=8'h11;
    else if(iic_done_w)
        data_i_iic<=8'h11 +data_i_iic;






iic_0_1 iic_0_1_u(
    .clk         (clk       ),
    .rst_n       (rst_n     ),
    .iic_start   (iic_start ),//开始通信信号
    .rw_ctrl     (1'b0      ),//读写控制0写1读
    .data_i_iic  (data_i_iic),//要发送的信号
    .sendnum     (8'd3      ),
    .recvnum     (8'd0      ),
    .sda         (sda       ),//数据线总线
    .scl         (scl       ),//时钟线
    .data_out    (data_out  ),//接收到的信号
    .iic_done_r  (iic_done_r),//读完
    .iic_done_w  (iic_done_w),//写完
    .iic_done    (iic_done  )//写完
);

endmodule