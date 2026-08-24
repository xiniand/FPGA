module DS18B20_a (
    input   clk     ,
    input   rst_n   ,
	input	key	  ,
    inout   dq      ,//dq总线
    output  reg     [15:0]  data,
    output  reg data_T  //每完成一次读取输出一次脉冲
);
//三态门
reg       dq_en   ;//时钟总线的开关使能
reg       dq_out  ;
wire      dq_in   ;

assign    dq   = (dq_en)?dq_out:1'bz;
assign    dq_in= dq                 ;

//时间参数
parameter   delay       =   50          ,//1us
            delay_ini   =   960         ,//960us，初始化总时间
            delay_a     =   480         ,//480us，复位脉冲时间
            delay_b     =   30          ,//30us，等待时间
            delay_c     =   70          ,//70us,采样点
            delay_lost  =   64          ,//64us,bit周期时间
            delay_ms    =   750_000     ;//750 000us==750ms
//主状态机
localparam  IDLE        =   8'b0        ,//1.空闲
            START       =   8'b1        ,//2.开始
            INIT        =   8'b10       ,//3:初始化
            SKIP        =   8'b100      ,//4.rom指令cc
            CONV        =   8'b1000     ,//5.功能指令44
            DELAY       =   8'b10000    ,//6.等待延时
            READ        =   8'b100000   ,//7.功能指令be
            DATA        =   8'b1000000  ,//8.获取温度
            STOP        =   8'b10000000 ;//9.结束

//命令  
localparam  SKIP_U        =   8'hCC,//跳过rom
            TEMP_Z      =   8'h44,//温度转化
            REG_RD      =   8'hBE;//寄存器读取

reg     [15:0]  data_reg                    ;
reg     [3:0]   cnt_bit                     ;
reg     [5:0]   cnt_time                    ;
reg     [20:0]  cnt_us                      ;
reg             flag                        ;//跳过ROM命令完成标志完成为0
reg             en                          ; 
reg     [7:0]   c_state , n_state;


//状态切换
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else 
        c_state <= n_state;
end
//状态转移
always @(*) begin
    case (c_state)
        IDLE :begin
            if(key)
                n_state = START;
            else
                n_state = c_state;
        end
        START:begin
            n_state = INIT;
        end
        INIT :begin
            if( cnt_us == delay_ini - 1 &&  en == 1)
                n_state =SKIP;
            else if( cnt_us == delay_ini - 1 && en == 0)
                n_state = IDLE;
            else
                n_state = c_state;
        end
        SKIP :begin//cc
            if(  cnt_bit == 7&& cnt_us == delay_lost - 1&& flag == 0&& cnt_time == delay - 1)
                n_state =CONV;
            else if( cnt_bit==7 && cnt_us == delay_lost - 1&& flag == 1&& cnt_time == delay - 1)
                n_state = READ;
            else
                n_state = c_state;
        end
        CONV :begin//44
            if( cnt_us == delay_lost - 1&& cnt_bit == 7&& cnt_time == delay - 1)
                n_state =DELAY;
            else
                n_state = c_state;
        end
        DELAY:begin
            if( cnt_us == delay_ms - 1)
                n_state = INIT;
            else
                n_state = c_state;
        end
        READ :begin//be
            if( cnt_us == delay_lost - 1&& cnt_bit == 7&& cnt_time == delay - 1)
                n_state =DATA;
            else
                n_state = c_state;
        end
        DATA :begin
            if( cnt_us == delay_lost - 1&& cnt_bit == 15&& cnt_time == delay - 1)
                n_state =STOP;
            else
                n_state = c_state;
        end
        STOP :begin
            n_state = IDLE;
        end 
        default: n_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cnt_bit <=0;
        cnt_time<=0;
        cnt_us  <=0;
        flag    <=0;
        en      <=0;
        data    <=0;
        data_reg<=0;
        dq_en   <=0;
        dq_out  <=1;
        data_T  <=0;
		end
    else
        case (c_state)
            IDLE :begin
                cnt_bit <=0;
                cnt_time<=0;
                cnt_us  <=0;
                flag    <=0;
                en      <=0;
                data_reg <= data_reg;
                data_T  <=0;
                dq_en   <=0;
                dq_out  <=1;
            end
            START:begin
                cnt_bit <=0;
                cnt_time<=0;
                cnt_us  <=0;
                flag    <=0;
                en      <=0;
                data_reg <= data_reg;
                dq_en   <=0;
                dq_out  <=1;
            end
            INIT :begin
                if(cnt_time == delay - 1)
                    cnt_time<=0;
                else
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)begin
                    if(cnt_us == delay_ini-1)
                        cnt_us  <=0;
                    else 
                        cnt_us <= cnt_us + 1;
                end

                if(cnt_us == delay_a + delay_b + delay_c-1)
                    en <= ~dq_in;
                else
                    en <= en;
                data_reg  <= data_reg;
                cnt_bit   <=0 ;
                if(cnt_us < delay_a)begin
                    dq_en   <= 1;
                    dq_out  <=  0;
                end
                else begin
                    dq_en   <= 0;
                    dq_out  <= 1;
                end 
            end
            SKIP :begin//cc
                if(cnt_time == delay - 1)
                    cnt_time<=0;
                else
                    cnt_time <= cnt_time + 1;

                if(cnt_time == delay - 1)begin
                    if(cnt_us == delay_lost-1)
                        cnt_us  <=0;
                    else 
                        cnt_us <= cnt_us + 1;
                end

                
                if( cnt_us == delay_lost - 1 && cnt_time == delay - 1)begin
                    if(cnt_bit == 7)
                        cnt_bit <=0;
                    else
                        cnt_bit   <=cnt_bit+1 ;
                end
                else 
                    cnt_bit     <= cnt_bit;
                en <= 0;
                data_reg  <= data_reg;
                if(SKIP_U[cnt_bit]  == 0)begin
                    if(cnt_us < delay_lost - 2)begin
                        dq_en   <= 1;
                        dq_out  <=  0;
                    end
                    else begin
                        dq_en   <= 0;
                        dq_out  <= 1;
                    end 
                end 
                else begin
                    if(cnt_us <= 2)begin
                        dq_en   <= 1;
                        dq_out  <= 0;
                    end
                    else begin
                        dq_en   <= 0;
                        dq_out  <= 1; 
                    end
                end 

            end
            CONV :begin//44
                if(cnt_time == delay - 1)
                    cnt_time<=0;
                else
                    cnt_time <= cnt_time + 1;

                if(cnt_time == delay - 1)begin
                    if(cnt_us == delay_lost-1)
                        cnt_us  <=0;
                    else 
                        cnt_us <= cnt_us + 1;
                end

                en <= 0;
                data_reg  <= 0;
                if(cnt_us == delay_lost - 1&& cnt_time == delay - 1)begin
                    if(cnt_bit == 7)
                        cnt_bit <=0;
                    else
                        cnt_bit   <=cnt_bit+1 ;
                end
                else 
                    cnt_bit     <= cnt_bit;
                
                if(TEMP_Z[cnt_bit]  == 0)begin
                    if(cnt_us < delay_lost - 2)begin
                        dq_en   <= 1;
                        dq_out  <=  0;
                    end
                    else if(cnt_us == delay_lost - 1)begin
                        dq_en   <= 0;
                        dq_out  <= 1;
                    end
                end
                else if(TEMP_Z[cnt_bit]  == 1)begin
                    if(cnt_us <= 2)begin
                        dq_en   <= 1;
                        dq_out  <= 0;
                    end
                    else begin
                        dq_en   <= 0;
                        dq_out  <= 1; 
                    end
                end
            end
            DELAY:begin
                if(cnt_time == delay - 1)
                    cnt_time<=0;
                else
                    cnt_time <= cnt_time + 1;
                if(cnt_time == delay - 1)begin
                    if(cnt_us == delay_ms-1)
                        cnt_us  <=0;
                    else 
                        cnt_us <= cnt_us + 1;
                end
                en<=0;
                dq_en   <= 0;
                dq_out  <= 1;
                flag    <= 1;
                data_reg<=data_reg;
            end
            READ :begin//be
                if(cnt_time == delay - 1)
                    cnt_time<=0;
                else
                    cnt_time <= cnt_time + 1;

                if(cnt_time == delay - 1)begin
                    if(cnt_us == delay_lost-1)
                        cnt_us  <=0;
                    else 
                        cnt_us <= cnt_us + 1;
                end

                en <= 0;
                data_reg  <= 0;
                if(cnt_us == delay_lost - 1&& cnt_time == delay - 1)begin
                    if(cnt_bit == 7)
                        cnt_bit <=0;
                    else
                        cnt_bit   <=cnt_bit+1 ;
                end
                else 
                    cnt_bit     <= cnt_bit;
                
                if(REG_RD[cnt_bit]  == 0)begin
                    if(cnt_us < delay_lost - 2)begin
                        dq_en   <= 1;
                        dq_out  <=  0;
                    end
                    else if(cnt_us == delay_lost - 1)begin
                        dq_en   <= 0;
                        dq_out  <= 1;
                    end
                end
                else if(REG_RD[cnt_bit]  == 1)begin
                    if(cnt_us <= 2)begin
                        dq_en   <= 1;
                        dq_out  <= 0;
                    end
                    else begin
                        dq_en   <= 0;
                        dq_out  <= 1; 
                    end
                end 
            end
            DATA :begin
                if(cnt_time == delay - 1)
                    cnt_time<=0;
                else
                    cnt_time <= cnt_time + 1;

                if(cnt_time == delay - 1)begin
                    if(cnt_us == delay_lost-1)
                        cnt_us  <=0;
                    else 
                        cnt_us <= cnt_us + 1;
                end

                en <= 0;
                if(cnt_us == delay_lost - 1&& cnt_time == delay - 1)begin
                    if(cnt_bit == 15)
                        cnt_bit <=0;
                    else begin
                        cnt_bit   <=cnt_bit +1 ;
                    end
                end
                else 
                    cnt_bit     <= cnt_bit;
                if(cnt_us == 10)begin
                    data_reg[cnt_bit]<= dq_in;
                end
                if(cnt_us <= 2)begin
                    dq_en<=1;
                    dq_out<=0;
                end 
                else begin
                    dq_en<=0;
                    dq_out<=1;
                end 
            end
            STOP :begin
                cnt_bit <=0;
                cnt_time<=0;
                cnt_us  <=0;
                flag    <=0;
                en      <=0;
                data    <= data_reg;
                data_T  <= 1;
                dq_en   <=0;
                dq_out  <=1;
            end 
            default: begin  
                cnt_bit <=0;
                cnt_time<=0;
                cnt_us  <=0;
                flag    <=0;
                en      <=0;
                data_T  <= 0;
                data_reg <= data_reg;
                dq_en   <=0;
                dq_out  <=1;
            end 
        endcase
end



endmodule