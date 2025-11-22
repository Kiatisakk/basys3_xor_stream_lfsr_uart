`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 12:58:29 AM
// Design Name: 
// Module Name: keybuilder
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


module keybuilder(
    input wire clk,
    input wire reset,
    
    input wire load_seed,
    input wire auto_reset,
    input wire [15:0] seed_sw,
    input wire start_gen,
    output reg done_tick,
    
    output wire [7:0] key_byte,
    output wire [15:0] debug_seed_out
    );
    
    reg [15:0] r_lfsr = 16'h0001;
    reg [15:0] stored_seed = 16'h0001;
    
    wire feedback;
    reg [3:0] shift_count = 0;
    reg busy = 0;
    
    assign feedback = r_lfsr[15] ^ r_lfsr[14] ^ r_lfsr[12] ^ r_lfsr[3];
	
    always @(posedge clk) begin
        if (reset) begin
            r_lfsr <= 16'h0001;
            stored_seed <= 16'h0001;
            shift_count <= 0;
            busy <= 0;
            done_tick <= 0;
        end else begin
            done_tick <= 0;
            
            if (load_seed) begin
                if (seed_sw == 0) begin
                    r_lfsr <= 16'h0001;
                    stored_seed <= 16'h0001;
                end else begin
                    r_lfsr <= seed_sw;
                    stored_seed <= seed_sw;
                end
                shift_count <= 0;
                busy <= 0;
            end
            else if (auto_reset) begin
                r_lfsr <= stored_seed;
                shift_count <= 0;
                busy <= 0;
            end
            else if (start_gen && !busy) begin
                shift_count <= 4'd8;
                busy <= 1;
            end
            
            else if (shift_count > 0) begin
                r_lfsr <= {r_lfsr[14:0], feedback};
                shift_count <= shift_count - 1;
            end
            
            else if (busy && shift_count == 0) begin
                busy <= 0;
                done_tick <= 1;
            end
        end
    end
    
    assign debug_seed_out = stored_seed;
    assign key_byte = r_lfsr[7:0];
      
endmodule

