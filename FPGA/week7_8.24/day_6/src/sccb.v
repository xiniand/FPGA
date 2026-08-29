module sccb (
    input       clk ,
    input       rst_n,
    input       rw_ctrl,

    inout       c_sda,

    output      c_scl,
    output      data
);
    
reg     c_sda_out;
reg     c_sda_en;
wire    c_sda_in;
assign  c_sda       = c_sda_en?c_sda_out:1'bz;
assign  c_sda_in    = c_sda;

parameter   sys_clk =   50_000_000      ,
            sccb_clk=   400_000         ,
            delay   =   sys_clk/sccb_clk,
            MID     =   delay/2         ,
            Q_MID   =   MID/2           ,
            TQ_MID  =   MID + Q_MID     ;

localparam  IDLE  = 5'b0                ,//空闲总线空闲，SIO_C和SIO_D均为高电平。
            START = 5'b1                ,//起始在SIO_C为高时，将SIO_D拉低，表示传输开始。
            ID    = 5'b10               ,//发送地址依次发送7位设备地址和1位读写位。
            ACK   = 5'b100              ,//应答位
            DATA  = 5'b1000             ,//发送数据发送8位数据（寄存器地址或寄存器值）。
            STOP  = 5'b10000            ;//停止在SIO_C为高时，将SIO_D拉高，表示传输结

reg [7:0]   cnt_time;
reg [4:0]   c_state,n_state;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE;
    else 
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        IDLE :begin//空闲总线空闲，SIO_C和SIO_D均为高电平。

        end
        START:begin//起始在SIO_C为高时，将SIO_D拉低，表示传输开始。

        end
        ID   :begin//发送地址依次发送7位设备地址和1位读写位。

        end
        ACK  :begin//应答位

        end
        DATA :begin//发送数据发送8位数据（寄存器地址或寄存器值）。

        end
        STOP :begin//停止在SIO_C为高时，将SIO_D拉高，表示传输结

        end 
        default: 
    endcase
end

    
endmodule