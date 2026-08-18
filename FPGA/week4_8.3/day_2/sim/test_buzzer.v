`timescale 1ns/1ns
module test_buzzer;
reg             clk   ;
reg             rst   ;
wire            buzzer;


always #10 clk = ~clk;

initial begin
    clk <= 0;
    rst <= 0;
    #20
    rst <= 1;
    #1000000
    $stop;
end

buzzer_yin #(
    .D1      (190   ),
    .D2      (170   ),
    .D3      (151   ),
    .D4      (142   ),
    .D5      (127   ),
    .D6      (113   ),
    .D7      (100   ),
    .Z1      (95    ),
    .Z2      (85    ),
    .Z3      (75    ),
    .Z4      (71    ),
    .Z5      (63    ),
    .Z6      (56    ),
    .Z7      (50    ),
    .G1      (47    ),
    .G2      (42    ),
    .G3      (37    ),
    .G4      (35    ),
    .G5      (31    ),
    .G6      (28    ),
    .G7      (25    ),
    .TIME_PAI(200   )
) buzzer_yin_u(
    .clk                 (clk   ),
    .rst                 (rst   ),
    .buzzer              (buzzer)
);
endmodule