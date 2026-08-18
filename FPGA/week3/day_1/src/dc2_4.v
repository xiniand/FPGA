module dc2_4 (
    input           [1:0]   sw      ,   //sw[0],sw[1]
    output      reg [3:0]   led         //led[0],led[1],led[2],led[3]
);
//第一种
//always @(*)
//    if(sw == 2'b00)
//        led = 4'b0001;
//    else if(sw == 2'b01)
//        led = 4'b0010;
//    else if(sw == 2'b10)
//        led = 4'b0100;
//    else if(sw == 2'b11)
//        led = 4'b1000;
//第二种
always @(*)
    case (sw)
        2'b00:led = 4'b0001;
        2'b01:led = 4'b0010;
        2'b10:led = 4'b0100;
        2'b11:led = 4'b1000; 
        default:;
    endcase
endmodule