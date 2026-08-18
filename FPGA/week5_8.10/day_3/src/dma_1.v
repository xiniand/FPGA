module dma_1 (
    input                   clk     ,
    input                   clk_rg  ,
    input                   rst     ,
    input                   key     ,
    output          [3:0]   data_out
);
//1.写状态2.改状态3.读状态
parameter   TIME    = 24_999_999    ,
            WR_S    = 2'b00         ,
            RE_S    = 2'b10         ;
reg     [3:0]       data        ;//写入的数据
reg     [3:0]       data_num    ;
reg		[3:0]       data_num_0  ;//写地址and改地址
reg     [3:0]       rd_addr     ;//读地址
wire                re_en       ;
wire                wr_en       ;
reg     [24:0]      cnt_time    ; 
reg     [1:0]       c_state     ,//现态
                    n_state     ;//次态
//状态切换
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= WR_S;
    else
        c_state  <= n_state;
end
//状态转移
always @(*) begin
    case (c_state)
        WR_S    :n_state = key?RE_S:WR_S;
        RE_S    :n_state = key?WR_S:RE_S;
        default: n_state = WR_S;
    endcase
end
//输出
//写和改地址
always @(posedge clk or negedge rst) begin
    if(!rst) 
        data_num_0 <= 0;
    else begin
        if(c_state == WR_S) begin
            if(data_num_0==9)
                data_num_0 <= data_num_0;
            else
                data_num_0 <= data_num_0 + 1;
        end
        else if((c_state != WR_S) && (n_state == WR_S))
            data_num_0 <= 0;
    end
end
//读地址
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_time <= 0;
    else if(!re_en)
        cnt_time <= 0;
    else if(cnt_time == TIME )
        cnt_time <= 0;
    else
        cnt_time <= cnt_time + 1;
end

always @(posedge clk or negedge rst) begin
    if(!rst)
        rd_addr <= 0;
    else if(!re_en)
        rd_addr <= 0;
    else if(cnt_time == TIME )
        if(rd_addr == 9)
            rd_addr <= 0;
        else
            rd_addr <= rd_addr + 1;
end

always @(*) begin
    case (data_num_0)
        0:data = 2  ;
        1:data = 4  ;
        2:data = 6  ;
        3:data = 8  ;
        4:data = 10 ;
        5:data = 12 ;
        6:data = 14 ;
        7:data = 7  ; 
        8:data = 9  ;
        9:data = 5  ;
        default: data = 5;
    endcase
end

always @(*) begin
    if(!rst)
        data_num = 0;
    else if(c_state == WR_S)
        data_num = data_num_0;
    else if(c_state == RE_S)
        data_num = rd_addr;
    else
        data_num = data_num_0;
end

assign  re_en = (c_state == RE_S)?1:0;
assign  wr_en = (c_state == WR_S)?1:0;

ram_data_1	ram_data_1_inst (
	.address    ( data_num  ),
	.data       ( data      ),
	.inclock    ( clk       ),
	.rden       ( re_en     ),
	.wren       ( wr_en     ),
	.q          ( data_out  )
);

endmodule