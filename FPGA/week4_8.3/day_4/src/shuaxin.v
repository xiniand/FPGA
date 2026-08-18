module shuaxin (
    input           clk,
    input           rst,
    input   [1:0]   key,
    output   reg  [22:0]  shua
);
parameter   COUNT = 20;//可调档数
reg [8:0]   cnt_num;
parameter   shua_0  = 499_999 ,
            shua_1  = 599_999 ,
            shua_2  = 699_999 ,
            shua_3  = 799_999 ,
            shua_4  = 899_999 ,
            shua_5  = 999_999 ,
            shua_6  = 1099_999,
            shua_7  = 1199_999,
            shua_8  = 1299_999,
            shua_9  = 1399_999,
            shua_10 = 1499_999,
            shua_11 = 1599_999,
            shua_12 = 1699_999,
            shua_13 = 1799_999,
            shua_14 = 1899_999,
            shua_15 = 1999_999,
            shua_16 = 2099_999,
            shua_17 = 2199_999,
            shua_18 = 2299_999,
            shua_19 = 2399_999,
            shua_20 = 2499_999; 

always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_num <= 0;
    else if(key[1])
        cnt_num <= ((cnt_num == COUNT)?0:(cnt_num + 1));
    else if(key[0])
        cnt_num <= ((cnt_num == 0)?COUNT:(cnt_num - 1));
end

always @(posedge clk or negedge rst) begin
    if(!rst)
        shua<=shua_0;
    else begin
        case (cnt_num)
             0:shua <= shua_0  ;
             1:shua <= shua_1  ;
             2:shua <= shua_2  ;
             3:shua <= shua_3  ;
             4:shua <= shua_4  ;
             5:shua <= shua_5  ;
             6:shua <= shua_6  ;
             7:shua <= shua_7  ;
             8:shua <= shua_8  ;
             9:shua <= shua_9  ;
            10:shua <= shua_10 ;
            11:shua <= shua_11 ;
            12:shua <= shua_12 ;
            13:shua <= shua_13 ;
            14:shua <= shua_14 ;
            15:shua <= shua_15 ;
            16:shua <= shua_16 ;
            17:shua <= shua_17 ;
            18:shua <= shua_18 ;
            19:shua <= shua_19 ;
            20:shua <= shua_20 ; 
            default: shua <= 499_999;
        endcase
    end
end


endmodule