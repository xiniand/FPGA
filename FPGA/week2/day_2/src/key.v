module key (
    input           key,
    input           clk,
    input           rst,
    output   		flag
);
parameter  delay = 1_000_000;//20ms
reg   [19:0]  cnt;

//计数

always @(posedge clk) begin
    if(!rst)
        cnt <= 0;
    else if(key == 0) begin
        if(cnt == delay-1)
            cnt <= cnt;//保持
        else
            cnt <= cnt+1;//累加
    end
    else
        cnt <= 0;
end

//消抖
assign flag = (cnt == delay -2)? 1 : 0;


endmodule