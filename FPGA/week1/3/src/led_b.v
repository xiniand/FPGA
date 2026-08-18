module led_b (
    input               clk     ,
    input               rst     ,
    input               sw      ,
    output   reg        [3:0]   led     
);
   /*  localparam  TIME=24_999_999 ; */
  /*   reg     [24:0]      cnt     ; */
    wire                sw_negedge;
    reg      [1:0]       sw_in;   

//时间计数
/* always@(posedge clk)
    if(!rst == 0)
        cnt <= 0;
    else if(cnt == TIME)
        cnt <= 0;
    else
        cnt <= cnt+1; */
//开关计数
always@(posedge clk)
    if(rst == 0)
        sw_in <= 0;
    else    
        sw_in <= {sw_in[0],sw};
assign sw_negedge = sw_in[1] & ~sw_in[0];

always@(posedge clk)
    if(rst == 0)
        led <= 0;
    else if(sw_negedge)
        led <= led + 1;
endmodule