module buzzer_xx (
    input   clk,
    input   rst,
    input   en,
    output reg buzzer
);

parameter   D1      = 190839    ,//低音
            D2      = 170068    ,
            D3      = 151515    ,
            D4      = 142857    ,
            D5      = 127226    ,
            D6      = 113378    ,
            D7      = 100000    ,
            Z1      = 95602     ,//中音
            Z2      = 85179     ,
            Z3      = 75873     ,
            Z4      = 71633     ,
            Z5      = 63776     ,
            Z6      = 56818     ,
            Z7      = 50100     ,
            G1      = 47801     ,//高音
            G2      = 42589     ,
            G3      = 37936     ,
            G4      = 35816     ,
            G5      = 31887     ,
            G6      = 28409     ,
            G7      = 25303     ,
            TIME_PAI= 24_999_999,//单个节拍0.5s计数器
            COUNT   = 108       ,//音符的个数
            COUNT_YUE=1;

reg [23:0]  cnt_hz          ;//频率计数器
wire        add_cnt_hz      ,
            end_cnt_hz      ;
wire [23:0]  freq_zkb          ;//占空比
reg [27:0]  cnt_pai          ;//节拍时间计数器
wire        add_cnt_pai      ,
            end_cnt_pai      ;

reg [7:0]   cnt_count       ;//音符个数计数器
reg [23:0]  hz_rg           ;//频率寄存器
reg [1:0]   cnt_yue         ;//音乐寄存器
//0.25s计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_pai <= 0;
    else if(add_cnt_pai)begin
        if(end_cnt_pai)
            cnt_pai <= 0;
        else 
            cnt_pai <= cnt_pai + 1;
    end
end
assign  add_cnt_pai = en;
assign  end_cnt_pai = add_cnt_pai &&(cnt_pai == TIME_PAI);
//音频计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_hz <= 0;
    else if(add_cnt_hz)begin
        if(end_cnt_hz | end_cnt_pai)
            cnt_hz <= 0;
        else 
            cnt_hz <= cnt_hz + 1;
    end
end
assign  add_cnt_hz = en;
assign  end_cnt_hz = add_cnt_hz &(cnt_hz == (hz_rg-1));
//音符计数器
always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_count <= 0;
    else if(en == 0)
        cnt_count <= 0;
    else if(end_cnt_pai)begin
        if(cnt_count == COUNT)
            cnt_count <= 0;
        else 
            cnt_count <= cnt_count + 1;
    end
end
//音乐计数器
/* always @(posedge clk or negedge rst) begin
    if(!rst)
        cnt_yue <= 0;
    else if(key)begin
        if(cnt_yue == COUNT_YUE)
            cnt_yue <= 0;
        else 
            cnt_yue <= cnt_yue + 1;
    end
end
 */
always @(*) begin
    if(en==1)begin
        case (cnt_count)
             0:hz_rg    =    D1;
             1:hz_rg    =    D2;
             2:hz_rg    =    D3;
             3:hz_rg    =    D4;
             4:hz_rg    =    D5;
             5:hz_rg    =    D6;
             6:hz_rg    =    D7;  
             7:hz_rg    =    Z1;
             8:hz_rg    =    Z2;
             9:hz_rg    =    Z3;
            10:hz_rg    =    Z4;
            11:hz_rg    =    Z5;
            12:hz_rg    =    Z6;
            13:hz_rg    =    Z7;   
            14:hz_rg    =    G1;
            15:hz_rg    =    G2;
            16:hz_rg    =    G3;
            17:hz_rg    =    G4;
            18:hz_rg    =    G5;
            19:hz_rg    =    G6;
            20:hz_rg    =    G7;   
            21:hz_rg    =    D1;
            22:hz_rg    =    D2;
            23:hz_rg    =    D3;
            24:hz_rg    =    D4;
            25:hz_rg    =    D5;
            26:hz_rg    =    D6;
            27:hz_rg    =    D7;   
            28:hz_rg    =    Z1;
            29:hz_rg    =    Z2;
            30:hz_rg    =    Z3;
            31:hz_rg    =    Z4;
            default: hz_rg = 0;
        endcase
    end
end 

assign freq_zkb = (hz_rg >> 1);

always @(*) begin
    if(!rst)
        buzzer <= 0;
    else if(cnt_hz == freq_zkb)
        buzzer <= 1;
    else if(end_cnt_hz)
        buzzer <= 0;
end

endmodule
/* always @(*) begin
    case (cnt_count)
        0   : hz_rg = D7        ;
        1   : hz_rg = Z2        ;
        2   : hz_rg = Z6        ;
        3   : hz_rg = D7        ;
        4   : hz_rg = Z2        ;
        5   : hz_rg = Z6        ;
        6   : hz_rg = D7        ;
        7   : hz_rg = Z2        ;
        8   : hz_rg = Z6        ;
        9   : hz_rg = D7        ;
        10  : hz_rg = Z2        ;
        11  : hz_rg = Z6        ;
        12  : hz_rg = D7        ;
        13  : hz_rg = Z2        ;
        14  : hz_rg = Z6        ;
        15  : hz_rg = Z2        ;
        16  : hz_rg = 0         ;
        17  : hz_rg = 0         ;
        18  : hz_rg = D7        ;
        19  : hz_rg = Z2        ;
        20  : hz_rg = Z5        ;
        21  : hz_rg = D7        ;
        22  : hz_rg = Z2        ;
        23  : hz_rg = Z5        ;
        24  : hz_rg = D7        ;
        25  : hz_rg = Z2        ;
        26  : hz_rg = Z5        ;
        27  : hz_rg = D7        ;
        28  : hz_rg = Z2        ;
        29  : hz_rg = Z5        ;
        30  : hz_rg = D7        ;
        31  : hz_rg = Z2        ;
        32  : hz_rg = Z5        ;
        33  : hz_rg = D7        ;
        34  : hz_rg = 0         ;
        35  : hz_rg = 0         ;
        36  : hz_rg = Z1        ;
        37  : hz_rg = Z3        ;
        38  : hz_rg = Z7        ;
        39  : hz_rg = Z1        ;
        40  : hz_rg = Z3        ;
        41  : hz_rg = Z7        ;
        42  : hz_rg = Z1        ;
        43  : hz_rg = Z3        ;
        44  : hz_rg = Z7        ;
        45  : hz_rg = Z1        ;
        46  : hz_rg = Z3        ;
        47  : hz_rg = Z7        ;
        48  : hz_rg = Z1        ;
        49  : hz_rg = Z3        ;
        50  : hz_rg = Z7        ;
        51  : hz_rg = Z1        ;
        52  : hz_rg = 0         ;
        53  : hz_rg = 0         ;
        54  : hz_rg = D7        ;
        55  : hz_rg = Z1        ;
        56  : hz_rg = Z6        ;
        57  : hz_rg = D7        ;
        58  : hz_rg = Z1        ;
        59  : hz_rg = Z6        ;
        60  : hz_rg = D7        ;
        61  : hz_rg = Z1        ;
        62  : hz_rg = Z6        ;
        63  : hz_rg = D7        ;
        64  : hz_rg = Z1        ;
        65  : hz_rg = Z6        ;
        66  : hz_rg = D7        ;
        67  : hz_rg = Z1        ;
        68  : hz_rg = Z6        ;
        69  : hz_rg = D7        ;
        70  : hz_rg = 0         ;
        71  : hz_rg = 0         ;
        72  : hz_rg = D7        ;
        73  : hz_rg = Z2        ;
        74  : hz_rg = Z6        ;
        75  : hz_rg = D7        ;
        76  : hz_rg = Z2        ;
        77  : hz_rg = Z6        ;
        78  : hz_rg = D7        ;
        79  : hz_rg = Z2        ;
        80  : hz_rg = Z6        ;
        81  : hz_rg = D7        ;
        82  : hz_rg = Z2        ;
        83  : hz_rg = Z6        ;
        84  : hz_rg = D7        ;
        85  : hz_rg = Z2        ;
        86  : hz_rg = Z6        ;
        87  : hz_rg = Z2        ;
        88  : hz_rg = 0         ;
        89  : hz_rg = 0         ;
        90  : hz_rg = D7        ;
        91  : hz_rg = Z2        ;
        92  : hz_rg = Z5        ;
        93  : hz_rg = D7        ;
        94  : hz_rg = Z2        ;
        95  : hz_rg = Z5        ;
        96  : hz_rg = D7        ;
        97  : hz_rg = Z2        ;
        98  : hz_rg = Z5        ;
        99  : hz_rg = D7        ;
        100 : hz_rg = Z2        ;
        101 : hz_rg = Z5        ;
        102 : hz_rg = D7        ;
        103 : hz_rg = Z2        ;
        104 : hz_rg = Z5        ;
        105 : hz_rg = D7        ;
        106 : hz_rg = 0         ;
        107 : hz_rg = 0         ;
        108 : hz_rg = 0         ;
        default: hz_rg = 0      ;
    endcase
end */