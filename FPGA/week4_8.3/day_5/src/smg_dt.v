module smg_dt(
    input  wire       clk     ,
    input  wire       rst_n   ,
    output reg  [5:0] sel     ,   //位选
    output reg  [6:0] seg        //段选
);

//时间模块
parameter TIME = 2499; //5uS
reg [23:0] cnt;
parameter CLOCK = 999999;
reg [23:0] cnt_clock;   //十进制转二进制的位数
reg [47:0] cnt_save ;   //二进制移位寄存器
wire [23:0] cnt_out    ;   //输出的十进制BCD码
wire [4:0 ] save_out_1 ,   //寄存输出BCD码的每一位
            save_out_2 ,
            save_out_3 ,
            save_out_4 ,
            save_out_5 ,
            save_out_6 ;
reg  [4:0 ] save_out   ;

 always @(posedge clk or negedge rst_n)  
    if(rst_n == 0)
        cnt <= 0;
    else 
        cnt <= (cnt >= TIME)? 0 : cnt+1;

//计数模块
always @(posedge clk or negedge rst_n)  
    if(rst_n == 0)
        cnt_clock <= 0;
    else if(cnt == TIME)
        cnt_clock <= (cnt_clock < 999_999)? cnt_clock + 1 : 0;

//二进制转BCD码，把计数模块的十进制看成二进制来移位
always @(posedge clk or negedge rst_n)  
    if(rst_n == 0)
        cnt_save = 0;
    else begin
        cnt_save = {24'b0,cnt_clock};       //24'b0,24'b0
        repeat (20)begin
            /* cnt_save = (cnt_save[23:20] >= 5)? cnt_save + 3 : cnt_save;
            cnt_save = (cnt_save[27:24] >= 5)? cnt_save + 3 : cnt_save;
            cnt_save = (cnt_save[31:28] >= 5)? cnt_save + 3 : cnt_save;
            cnt_save = (cnt_save[35:32] >= 5)? cnt_save + 3 : cnt_save;
            cnt_save = (cnt_save[39:36] >= 5)? cnt_save + 3 : cnt_save;
            cnt_save = (cnt_save[43:40] >= 5)? cnt_save + 3 : cnt_save; */
            if(cnt_save[27:24] >= 5) 
                cnt_save = cnt_save + 3;
            if(cnt_save[31:28] >= 5) 
                cnt_save = cnt_save + 3;
            if(cnt_save[35:32] >= 5) 
                cnt_save = cnt_save + 3;
            if(cnt_save[39:36] >= 5)
                cnt_save = cnt_save + 3;
            if(cnt_save[43:40] >= 5)
                cnt_save = cnt_save + 3;
            if(cnt_save[47:44] >= 5) 
                cnt_save = cnt_save + 3;
            cnt_save = cnt_save << 1;
        end
    end
//输出的BCD码
assign cnt_out = cnt_save[47:24];
//寄存输出BCD码的每一位
assign save_out_1 = cnt_out[3:0  ];
assign save_out_2 = cnt_out[7:4  ];
assign save_out_3 = cnt_out[11:8 ];
assign save_out_4 = cnt_out[15:12];
assign save_out_5 = cnt_out[19:16];
assign save_out_6 = cnt_out[23:20];

//位选计数器
parameter TIME_sel = 49999;
reg [15:0] cnt_sel;
always @(posedge clk or negedge rst_n)  
    if(rst_n == 0)
        cnt_sel <= 0;
    else 
        cnt_sel <= (cnt_sel < TIME_sel)? cnt_sel + 1 : 0;

//数码管动态显示
always @(posedge clk or negedge rst_n)  
    if(rst_n == 0)
        sel <= 6'b111_110;
    else
        sel <= (cnt_sel < TIME_sel)? sel : {sel[4:0],sel[5]};   


always @(posedge clk or negedge rst_n)  
    case (sel)
       6'b111_110 : save_out <= save_out_1;
       6'b111_101 : save_out <= save_out_2;
       6'b111_011 : save_out <= save_out_3;
       6'b110_111 : save_out <= save_out_4;
       6'b101_111 : save_out <= save_out_5;
       6'b011_111 : save_out <= save_out_6;
          default : save_out <= save_out_1;
    endcase

always @(posedge clk or negedge rst_n)
    if(rst_n == 0)
        seg <= 7'b100_0000;
    else
        case (save_out)
            4'b0000:seg <= 7'b100_0000;   //0
            4'b0001:seg <= 7'b111_1001;   //1
            4'b0010:seg <= 7'b010_0100;   //2
            4'b0011:seg <= 7'b011_0000;   //3
            4'b0100:seg <= 7'b001_1001;   //4
            4'b0101:seg <= 7'b001_0010;   //5
            4'b0110:seg <= 7'b000_0010;   //6
            4'b0111:seg <= 7'b111_1000;   //7
            4'b1000:seg <= 7'b000_0000;   //8
            4'b1001:seg <= 7'b001_0000;   //9 
            default:seg <= 7'b100_0000;  
        endcase

endmodule



