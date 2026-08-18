module top (
    input   clk,
    input   rst_n
);
//fifo：大小8深度256;
//：写写使能打开，同时写入数据
reg	            wrreq           ;//写使能
reg	    [7:0]   data            ;//写入数据
//读：1.打开读使能后，下一个clk读出数据2.先把数据准备好（写入数据后两个时钟周期）打开读使能，读出数据
reg	            rdreq           ;//读使能
wire	[15:0]  q               ;//读数据
//握手信号
/* wire            empty           ;//数据量=0,并且内部指针同一圈重合
wire            full            ; *///数据量到深度-1且内部指针不在同一圈重合时拉高
/* wire	        almost_empty    ;//10 小于10的时候拉高大于等于10为低：空信号
wire	        almost_full     ;//100大于等于100的时候拉高         ：满信号 */
wire	        rdempty         ;//数据量=0,并且内部指针同一圈重合
wire	        rdfull          ;//数据量到深度-1且内部指针不在同一圈重合时拉高
wire	        wrempty         ;//数据量=0,并且内部指针同一圈重合
wire	        wrfull          ;//数据量到深度-1且内部指针不在同一圈重合时拉高
/* wire    [7:0]   wrusedw         ; */
wire	[7:0]   wrusedw         ;//写入时数据量 满的时候0当作256
wire	[6:0]   rdusedw         ;//读出时数据量 满的时候0当作128

//输出时钟
wire            c0_25       ,//pll输出25mhz时钟
                c1_50       ,//pll输出50mhz时钟
                c2_100      ,//pll输出100mhz时钟
                c3_150      ,//pll输出150mhz时钟
                c4_200      ;//pll输出200mhz时钟



reg     [9:0]   cnt;
//0--1023的循环计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 0;
    else
        cnt <= cnt + 1;
end
//模拟fifo写入的过程
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        wrreq   <= 0;
        data    <= 0;
    end
    else if(cnt <= 500)begin
        wrreq   <= 1;
        data    <= data + 1;
    end
    else begin
        wrreq   <=  0;
        data    <=  0;
    end
end
//模拟fifo读数据的过程
always @(posedge c0_25 or negedge rst_n) begin
    if(!rst_n)
        rdreq   <= 0;
    else if(cnt>500 )
        rdreq   <= 1;
    else
        rdreq   <= 0;
end

clock	clock_inst (
	.areset         ( ~rst_n        ),
	.inclk0         ( clk           ),
	.c0             ( c0_25         ),
	.c1             ( c1_50         ),
	.c2             ( c2_100        ),
	.c3             ( c3_150        ),
	.c4             ( c4_200        )
);
fifo_data	fifo_data_inst (        
    .aclr           ( ~rst_n        ),//异步复位
	.data           ( data          ),//写入的数据
	.rdclk          ( c0_25         ),//读时钟
	.rdreq          ( rdreq         ),//读使能
	.wrclk          ( clk           ),//写时钟
	.wrreq          ( wrreq         ),//写使能
	.q              ( q             ),//读出的数据
	.rdempty        ( rdempty       ),//读时钟控制的空信号
	.rdfull         ( rdfull        ),//读时钟控制的满信号
	.rdusedw        ( rdusedw       ),//读时钟控制的数据量
	.wrempty        ( wrempty       ),//写时钟控制的空信号
	.wrfull         ( wrfull        ),//写时钟控制的满信号
	.wrusedw        ( wrusedw       ) //写时钟控制的数据量
);


//同步时钟
/* fifo_data_t	fifo_data_t_inst (
	.clock          ( clk           ),
	.data           ( data          ),
	.rdreq          ( rdreq         ),
	.aclr           ( ~rst_n        ),//aclr异步复位scrl同步复位
	.wrreq          ( wrreq         ),
	.almost_empty   ( almost_empty  ),
	.almost_full    ( almost_full   ),
	.empty          ( empty         ),
	.full           ( full          ),
	.q              ( q             ),
	.usedw          ( usedw         )
); */




endmodule