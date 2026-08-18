module mux2_1 (
    input   S   ,//S有效就把A的值给led，无效就把B的值给led,SW4
    input   A   ,//SW2
    input   B   ,//SW3
    output  reg led  //LED3
);
//写法一:条件运算符
//assign led = S ? A : B;

//写法二:if else
//always@(*)  //'*'指的是通配符，意思是任意信号有效就执行always模块
//    if(S==1)
//        led = A;
//    else
//        led = B;

//写法三:case语句
always @(*) 
//谁在发生变化就case谁
    case (S)
        0:led = B;
        1:led = A;
        //当被case的对象的所有结果描述完，则写‘;’否则必须给一个赋值 
        default: ;
    endcase
    

endmodule