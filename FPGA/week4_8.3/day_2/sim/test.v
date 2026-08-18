`timescale 1ns/1ns
    module test ();
    reg     clk;
    reg     rst;
    wire    buzzer;

    initial begin
        clk <= 0;
        rst <= 0;
        #40
        rst <= 1;
        #20000
        $stop;
    end

    always  #10 clk = clk;
    
    buzzer #(
        .D1 (190)
    )buzzer_u(
        .clk    (clk),
        .rst    (rst),
        .buzzer (buzzer)
    );



    endmodule