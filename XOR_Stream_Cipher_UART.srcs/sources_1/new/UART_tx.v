`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2025 07:56:57 PM
// Design Name: 
// Module Name: UART_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module UART_tx#(
    parameter BAUD_CLK_TICKS = 868
)(
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] tx_data_in,
    output reg tx_data_out,
    output reg tx_active
);
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [13:0] baud_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] data_temp = 0;
    
    always @(posedge clk) begin
        if(reset) begin
            state <= IDLE;
            tx_data_out <= 1;
            baud_count <= 0;
            bit_index <= 0;
            tx_active <= 0;
        end else begin
            case(state)
                IDLE: begin
                    tx_data_out <= 1;
                    baud_count <= 0;
                    bit_index <= 0;
                    
                    if(tx_start) begin
                        data_temp <= tx_data_in;
                        state <= START;
                        tx_active <= 1;
                        tx_data_out <= 0;
                    end else begin
                        tx_active<=0;
                    end
                end
                
                START: begin
                    if (baud_count < BAUD_CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        state <= DATA;
                        
                        tx_data_out <= data_temp[0]; 
                    end
                end
                
                DATA: begin
                    if (baud_count < BAUD_CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        baud_count <= 0;
                        if (bit_index == 7) begin
                            state <= STOP;
                            tx_data_out <= 1;
                        end else begin
                            bit_index <= bit_index + 1;
                            tx_data_out <= data_temp[bit_index + 1]; // Shift ºÔµ¶Ñ´ä»
                        end
                    end
                end
                
                STOP: begin
                    if (baud_count < BAUD_CLK_TICKS - 1) begin
                        baud_count <= baud_count + 1;
                    end else begin
                        state <= IDLE;
                        tx_active <= 0;
                    end
                end
                
           endcase
        end
    end
endmodule
