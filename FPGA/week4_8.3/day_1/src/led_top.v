module led_top (
    input               clk                 ,
    input               rst                 ,
    output    reg[3:0]  led                              
);
wire        state_en_1  ,
            state_en_2  ,
            state_en_3  ;
wire  [3:0] led_1       ,
            led_2       ,
            led_3       ;
state state_inst(
    /* input                */.clk                  (clk         ),
    /* input                */.rst                  (rst         ),
    /* output               */.state_en_1           (state_en_1  ),   //流水灯使能
    /* output               */.state_en_2           (state_en_2  ),   //跑马灯使能
    /* output               */.state_en_3           (state_en_3  )    //闪烁灯使能
);
led_liushui led_liushui_inst(
    /* input                */.clk                  (clk         ),
    /* input                */.rst                  (rst         ),
    /* input                */.state_en             (state_en_1  ),
    /* output  reg [3:0]    */.led                  (led_1       ) 
);
led_paoma led_paoma_inst(
    /* input                */.clk                  (clk         ),
    /* input                */.rst                  (rst         ),
    /* input                */.state_en             (state_en_2  ),
    /* output  reg [3:0]    */.led                  (led_2       ) 
);
led_shanshuo led_shanshuo_inst(
    /* input                */.clk                  (clk         ),
    /* input                */.rst                  (rst         ),
    /* input                */.state_en             (state_en_3  ),
    /* output  reg [3:0]    */.led                  (led_3       ) 
);
always @(*)
    case ({state_en_1,state_en_2,state_en_3})
        3'b100:led = led_1;
        3'b010:led = led_2;
        3'b001:led = led_3; 
        default:led = led_1; 
    endcase
endmodule