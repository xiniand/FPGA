module led (
    ////当没有明确信号的类型时，系统自动默认为wire类型
    input   wire    key ,
    output  wire    led

);
assign led = key ? 1:0;
    
endmodule