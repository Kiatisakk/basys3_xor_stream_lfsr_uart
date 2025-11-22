`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2025 08:37:55 PM
// Design Name: 
// Module Name: UART_rx
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


module UART_rx#(
    parameter BAUD_X16_TICKS = 54
)(
    input wire clk,
    input wire reset,
    input wire rx_data_in,      
    output reg [7:0] rx_data_out,
    output reg rx_done_tick
    );

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [13:0] baud_count = 0;
    reg baud_x16_tick = 0;

    reg [3:0] bit_spacing_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] stored_data = 0;
    
    reg rx_sync_1, rx_sync_2;
    wire rx_bit_val;

    always @(posedge clk) begin
        if (reset) begin
            rx_sync_1 <= 1;
            rx_sync_2 <= 1;
        end else begin
            rx_sync_1 <= rx_data_in;
            rx_sync_2 <= rx_sync_1;
        end
    end
    
    assign rx_bit_val = rx_sync_2;
    
    always @(posedge clk) begin
        if (reset) begin
            baud_count <= 0;
            baud_x16_tick <= 0;
        end else begin
            if (baud_count == BAUD_X16_TICKS - 1) begin
                baud_count <= 0;
                baud_x16_tick <= 1;
            end else begin
                baud_count <= baud_count + 1;
                baud_x16_tick <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            rx_data_out <= 0;
            bit_spacing_count <= 0;
            bit_index <= 0;
            stored_data <= 0;
            rx_done_tick <= 0;
        end else begin
        
            rx_done_tick <= 0; 

            if (baud_x16_tick) begin
                case (state)
                    IDLE: begin
                        bit_spacing_count <= 0;
                        bit_index <= 0;
                        if (rx_bit_val == 0) begin 
                            state <= START;
                        end
                    end

                    START: begin

                        if (bit_spacing_count == 7) begin
                            if (rx_bit_val == 0) begin
                                bit_spacing_count <= 0;
                                state <= DATA;
                            end else begin
                                state <= IDLE; 
                            end
                        end else begin
                            bit_spacing_count <= bit_spacing_count + 1;
                        end
                    end

                    DATA: begin

                        if (bit_spacing_count == 15) begin
                            bit_spacing_count <= 0;
                            stored_data[bit_index] <= rx_bit_val;
                            
                            if (bit_index == 7) begin
                                bit_index <= 0;
                                state <= STOP;
                            end else begin
                                bit_index <= bit_index + 1;
                            end
                        end else begin
                            bit_spacing_count <= bit_spacing_count + 1;
                        end
                    end

                    STOP: begin
                        
                        if (bit_spacing_count == 15) begin
                            state <= IDLE;
                            rx_data_out <= stored_data; 
                            rx_done_tick <= 1;          
                        end else begin
                            bit_spacing_count <= bit_spacing_count + 1;
                        end
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule
