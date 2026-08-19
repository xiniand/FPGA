module uart_send_ctrl (
    input   wire            clk,
    input   wire            rst_n,
    input   wire [71:0]     rgb_data,
    input   wire            data_vld,       // 数据有效，触发发送 (高电平脉冲)
    
    // UART发送接口
    output  reg             uart_tx_en,
    output  reg [7:0]       uart_tx_data,
    input   wire            uart_tx_done
);

// 参数定义 
localparam  BYTE_NUM = 4'd14;
localparam  FRAME_HEAD1 = 8'hAA;
localparam  FRAME_HEAD2 = 8'h55;
localparam  SENSOR_ID   = 8'h53; // 传感器设备地址作为 ID

localparam  FRAME_TAIL1 = 8'h0D; // \r
localparam  FRAME_TAIL2 = 8'h0A; // \n

// 状态机定义
localparam  S_IDLE      = 2'd0;
localparam  S_SEND      = 2'd1;
localparam  S_WAIT_DONE = 2'd2;

//  内部寄存器定义 
reg [1:0]   curr_state;
reg [3:0]   byte_idx;       
reg [7:0]   send_buf[13:0]; 

//  发送数据缓存及切片 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // 复位清零
        send_buf[0]  <= 8'd0; send_buf[1]  <= 8'd0; send_buf[2]  <= 8'd0;
        send_buf[3]  <= 8'd0; send_buf[4]  <= 8'd0; send_buf[5]  <= 8'd0;
        send_buf[6]  <= 8'd0; send_buf[7]  <= 8'd0; send_buf[8]  <= 8'd0;
        send_buf[9]  <= 8'd0; send_buf[10] <= 8'd0; send_buf[11] <= 8'd0;
        send_buf[12] <= 8'd0; send_buf[13] <= 8'd0;
    end
    else if(data_vld) begin
        send_buf[0]  <= FRAME_HEAD1;
        send_buf[1]  <= FRAME_HEAD2;
        send_buf[2]  <= SENSOR_ID;
        
        // R 通道 (发送顺序: MSB -> 1 -> LSB)
        send_buf[3]  <= rgb_data[31:24]; // R_MSB
        send_buf[4]  <= rgb_data[39:32]; // R_1
        send_buf[5]  <= rgb_data[47:40]; // R_LSB
        
        // G 通道
        send_buf[6]  <= rgb_data[55:48]; // G_MSB
        send_buf[7]  <= rgb_data[63:56]; // G_1
        send_buf[8]  <= rgb_data[71:64]; // G_LSB
        
        // B 通道
        send_buf[9]  <= rgb_data[7:0];   // B_MSB
        send_buf[10] <= rgb_data[15:8];  // B_1
        send_buf[11] <= rgb_data[23:16]; // B_LSB
        
        send_buf[12] <= FRAME_TAIL1;
        send_buf[13] <= FRAME_TAIL2;
    end
end

// 发送状态机 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        curr_state <= S_IDLE;
        byte_idx <= 4'd0;
        uart_tx_en <= 1'b0;
        uart_tx_data <= 8'd0;
    end
    else begin
        case(curr_state)
            S_IDLE: begin
                if(data_vld) begin
                    curr_state <= S_SEND;
                    byte_idx <= 4'd0;
                end
                uart_tx_en <= 1'b0;
            end
            S_SEND: begin
                if(byte_idx < BYTE_NUM) begin
                    uart_tx_en <= 1'b1;
                    uart_tx_data <= send_buf[byte_idx];
                    byte_idx <= byte_idx + 4'd1;
                    curr_state <= S_WAIT_DONE;
                end
                else begin
                    curr_state <= S_IDLE;
                    byte_idx <= 4'd0;
                end
            end
            S_WAIT_DONE: begin
                uart_tx_en <= 1'b0;
                if(uart_tx_done) begin
                    curr_state <= S_SEND;
                end
            end
            default: curr_state <= S_IDLE;
        endcase
    end
end

endmodule