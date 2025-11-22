`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2025 09:03:32 PM
// Design Name: 
// Module Name: Debounce
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


module Debounce#(
    parameter COUNTER_SIZE = 2000000 // 20ms @ 100MHz
)(
    input wire clk,
    input wire reset,
    input wire button_in,
    output reg button_out
    );
    
    reg ff1 = 0;
    reg ff2 = 0;
    reg ff3 = 0;
    reg ff4 = 0;
    
    reg [31:0] count = 0;
    wire count_start;
    
    always @(posedge clk) begin
        if (reset) begin
            ff1 <= 0;
            ff2 <= 0;
        end else begin
            ff1 <= button_in;
            ff2 <= ff1;
        end
    end

    assign count_start = (ff1 ^ ff2);
    
    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            ff3 <= 0;
        end else begin
            if (count_start) begin
                count <= 0;
            end else if (count < COUNTER_SIZE) begin
                count <= count + 1;
            end else begin
                ff3 <= ff2;
            end
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            ff4 <= 0;
            button_out <= 0;
        end else begin
            ff4 <= ff3;
            if (ff3 == 1 && ff4 == 0) 
                button_out <= 1;
            else 
                button_out <= 0;
        end
    end
endmodule
