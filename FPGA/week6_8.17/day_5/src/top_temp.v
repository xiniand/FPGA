module top_temp (
    input           clk     ,
    input           rst_n   ,
    input           key     ,
    inout           dq      ,
    output  [7:0]   dig     ,
    output  [5:0]   sel

);
wire            flag_temp;
wire    [15:0]  temp_shift; 
wire    [7:0]   temp_smg_zs; 
wire    [13:0]  temp_smg_xs;
wire    [11:0]  data_bcd_zs,
				data_bcd_xs;
wire    [23:0]  data        ;
assign  data    = {data_bcd_zs,data_bcd_xs}  ;


key key_u(
    .key            (key        ),
    .clk            (clk        ),
    .rst            (rst_n      ),
    .flag           (flag_temp  )
);

DS18B20_a DS18B20_a_u(
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .key        (flag_temp  ),
    .dq         (dq         ),//dq总线
    .data_T     (data_T     ),
    .data       (temp_shift )
);

dt_smg dt_smg_u(
    .rst            (rst_n      ),
    .clk            (clk        ),
    .data           (data       ),
    .dig            (dig        ),
    .sel            (sel        )
);

temp temp_u(
    .clk            (clk        ),
    .rst_n          (rst_n      ),
    .temp_shift     (temp_shift ),
    .temp_smg_zs    (temp_smg_zs),
    .temp_smg_xs    (temp_smg_xs)
);


bin_to_bcd bin_to_bcd_u(
    .clk            (clk        ),
    .rst_n          (rst_n      ),
    .data_zs_in     (temp_smg_zs),//输入待转换的数据
    .data_xs_in     (temp_smg_xs),//输入待转换的数据
    .data_bcd_zs    (data_bcd_zs),//输出转换后的BCD码数据
    .data_bcd_xs    (data_bcd_xs) //输出转换后的BCD码数据
);

endmodule