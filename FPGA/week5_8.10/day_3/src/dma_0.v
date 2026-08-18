module dma_0 (
    input                   clk     ,
    input                   clk_rg  ,
    input                   rst     ,
    input           [2:0]   key     ,
    output          [3:0]   data_out
);
//1.写状态2.改状态3.读状态
parameter   TIME    = 24_999_999    ,
            WR_S    = 2'b00         ,
            GAI_S   = 2'b01         ,
            RE_S    = 2'b10         ,
            GAI_IDLE= 3'b000        ,
            GAI_RD  = 3'b001        ,
            GAI_WAIT= 3'b010        ,
            GAI_SAVE= 3'b011        ,
            GAI_WR  = 3'b100        ;
reg     [3:0]       data        ;//写状态写入数据
reg     [3:0]       data_num_0  ;//写地址
reg     [3:0]       rd_scan     ;//读扫描地址
reg     [3:0]       gai_cnt     ;//改状态遍历地址
reg     [3:0]       gai_tmp     ;//改状态寄存数据
reg     [24:0]      cnt_time    ;
reg     [1:0]       c_state     ,//主状态
                    n_state     ;
reg     [2:0]       gai_c_state ,//改状态子状态
                    gai_n_state ;
wire    [3:0]       wraddr      ;//写地址
wire    [3:0]       wrdata      ;//写数据
wire                wren        ;//写使能
wire    [3:0]       rdaddr      ;//读地址
wire                rden        ;//读使能
wire    [3:0]       ram_q       ;//输出数据
wire                enter_gai   ;//写回改
wire                clk_rg_out  ;
//主状态切换
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= WR_S;
    else
        c_state  <= n_state;
end
//主状态转移
always @(*) begin
    case (c_state)
        WR_S    :begin
                    if(key[0])
                        n_state = GAI_S;
                    else if(key[1] && data_num_0 == 9)
                        n_state = RE_S;
                    else
                        n_state = WR_S;
                 end
        GAI_S   :n_state = key[1] ? RE_S : GAI_S;
        RE_S    :begin
                    if(key[0])
                        n_state = GAI_S;
                    else if(key[2])
                        n_state = WR_S;
                    else
                        n_state = RE_S;
                 end
        default: n_state = WR_S;
    endcase
end
//改状态子状态：1.读状态2.等待读数据3.保存读数据4.改写状态
assign  enter_gai = (n_state == GAI_S) && (c_state != GAI_S);
always @(posedge clk or negedge rst) begin
    if(!rst)
        gai_c_state <= GAI_IDLE;
    else
        gai_c_state  <= gai_n_state;
end
always @(*) begin
    case (gai_c_state)
        GAI_IDLE:gai_n_state = ((c_state == GAI_S && key[0]) || enter_gai) ? GAI_RD : GAI_IDLE;
        GAI_RD  :gai_n_state = GAI_WAIT;
        GAI_WAIT:gai_n_state = GAI_SAVE;
        GAI_SAVE:gai_n_state = GAI_WR;
        GAI_WR  :gai_n_state = (gai_cnt == 9) ? GAI_IDLE : GAI_RD;
        default :gai_n_state = GAI_IDLE;
    endcase
end
//写地址
always @(posedge clk or negedge rst) begin
    if(!rst)
        data_num_0 <= 0;
    else if(c_state == WR_S) begin
        if(data_num_0 == 9)
            data_num_0 <= data_num_0;
        else
            data_num_0 <= data_num_0 + 1;
    end
    //清零地址
    else if((c_state != WR_S) && (n_state == WR_S))
        data_num_0 <= 0;
end
//改状态遍历地址
always @(posedge clk or negedge rst) begin
    if(!rst)
        gai_cnt <= 0;
    else if(gai_c_state == GAI_IDLE)//空闲态时清零
        gai_cnt <= 0;
    else if(gai_c_state == GAI_WR) begin
        if(gai_cnt == 9)
            gai_cnt <= gai_cnt;
        else
            gai_cnt <= gai_cnt + 1;
    end
end
//改状态保存当前地址旧值
always @(posedge clk or negedge rst) begin
    if(!rst)
        gai_tmp <= 0;
    else if(gai_c_state == GAI_SAVE)
        gai_tmp <= ram_q;
end
//读地址
always @(posedge clk_rg or negedge rst) begin
    if(!rst)
        cnt_time <= 0;
    else if(c_state != RE_S)
        cnt_time <= 0;
    else if(cnt_time == TIME)
        cnt_time <= 0;
    else
        cnt_time <= cnt_time + 1;
end

always @(posedge clk_rg or negedge rst) begin
    if(!rst)
        rd_scan <= 0;
    else if(c_state != RE_S)
        rd_scan <= 0;
    else if(cnt_time == TIME)
        if(rd_scan == 9)
            rd_scan <= 0;
        else
            rd_scan <= rd_scan + 1;
end
//写状态初始数据
always @(*) begin
    if(c_state == WR_S)begin
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
    else
        data = 0;
end
assign  wraddr      = (c_state == WR_S)       ? data_num_0 :
                      (gai_c_state == GAI_WR) ? gai_cnt   : 4'd0;
assign  wrdata      = (gai_c_state == GAI_WR) ? gai_tmp + 1 : data;
assign  wren        = (c_state == WR_S) || (gai_c_state == GAI_WR);
assign  rdaddr      = (c_state == GAI_S) ? gai_cnt   :
                      (c_state == RE_S) ? rd_scan   : 4'd0;
assign  rden        = (c_state == GAI_S) || (c_state == RE_S);
assign  data_out    = ram_q;
assign  clk_rg_out  = (c_state == RE_S)?clk_rg:clk;

ram_data_2 ram_data_2_inst (
    .data      ( wrdata     ),
    .inclock   ( clk        ),
    .outclock  ( clk_rg_out ),
    .rdaddress ( rdaddr     ),
    .rden      ( rden       ),
    .wraddress ( wraddr     ),
    .wren      ( wren       ),
    .q         ( ram_q      )
);

endmodule
