`timescale 1ns/1ps

module duolu_test ();

reg     in_a;
reg     in_b;
reg     sel;
wire    out;

initial begin
    in_a    =0;  
    in_b    =0;  
    sel     =0;  
    #20 //20ns
    repeat(10)begin
        sel =  {$random};
        in_a = {$random};
        in_b = {$random};
        #40 ;//40ns
    end
    $stop;
end

duolu duolu_u(
.in_a    (in_a),
.in_b    (in_b),
.sel     (sel ),
.out     (out )
);


endmodule