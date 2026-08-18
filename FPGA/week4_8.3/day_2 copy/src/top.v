module top(
    input  wire       clk  ,
    input  wire       rst_n,
    output reg [3:0] led 

);

parameter TIME = 24_999_999;
parameter delay = 19_999_999_9;
wire led_s_en;
wire led_l_en;
wire led_m_en;
wire [3:0] led_s;
wire [3:0] led_l;
wire [3:0] led_m;


ztji #(
    .TIME_ztji(delay    )
)ztji_u(
    .clk      (clk      ),
    .rst_n    (rst_n    ),
    .led_s_en    (led_s_en    ),
    .led_l_en    (led_l_en    ),
    .led_m_en    (led_m_en    )
);

led_s #(
    .TIME_s(TIME   )
)led_s_u(
    .clk   (clk    ), 
    .rst_n (rst_n  ),
    .en    (led_s_en  ),
    .led   (led_s   )
);

led_l #(
    .TIME_l(TIME   )
)led_l_u(
    .clk   (clk    ), 
    .rst_n (rst_n  ),
    .en    (led_l_en  ),
    .led   (led_l   )
);

led_m #(
    .TIME_m(TIME   )
)led_m_u(
    .clk   (clk    ), 
    .rst_n (rst_n  ),
    .en    (led_m_en  ),
    .led   (led_m   )
);

always @(*)
    case({led_s_en,led_l_en,led_m_en})
        3'b100 : led = led_s;
        3'b010 : led = led_l;
        3'b001 : led = led_m;
       default : led = 4'b0001;
    endcase


endmodule