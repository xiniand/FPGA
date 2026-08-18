module ztj (
    input   rst ,
    input   clk ,
    input   key ,
    output  led
);
//两段式状态机
always @(posedge clk or negedge rst) begin
    if(!rst)
        c_state <= S0;
    else
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        S0: n_state = (data_in == 1)?S1:S0;
        S1: n_state = (data_in == 0)?S2:S1;
        S2: n_state = (data_in == 1)?S1:S0;
        default: n_state = S0;
    endcase
end
assign  data_out = (data_in == 1) && (c_state == S2);

//三段式状态机
always @(posedge clk or negedge rst) begin
    if(rst)
        c_state <= S0;
    else
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        S0:n_state = (data_in == 1)?S1:S0;
        S1:n_state = (data_in == 0)?S2:S1; 
        S2:n_state = (data_in == 1)?S1:S0; 
        default: n_state = S0;
    endcase
end
always @(posedge clk or negedge rst) begin
    if(!rst)
        data_out <= 0;
    else if((data_in == 1) && (c_state == S2))
        data_out <= 1;
    else
        data_out <= 0;
end

endmodule