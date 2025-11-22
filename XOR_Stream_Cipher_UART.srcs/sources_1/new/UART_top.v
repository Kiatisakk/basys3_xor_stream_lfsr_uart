`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2025 09:08:00 PM
// Design Name: 
// Module Name: UART_top
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


module Top_System(
    input wire clk,         
    input wire reset,
    input wire btn_load_seed, //btnL
    input wire btn_process_all,
    input wire [15:0] sw,
    
    input wire RsRx,
    output wire RsTx,
    
    output wire [15:0] led
);
    
    wire rx_done_tick;
    wire [7:0] rx_data_fifo_in;
    wire [7:0] fifo_data_out;
    wire fifo_empty;
    wire fifo_full;
    reg fifo_rd_en;   
    
    wire btn_process_pulse;
    
    reg lfsr_start;
    wire lfsr_done;
    wire [7:0] key_byte;
    wire [7:0] cipher_byte;
    reg tx_start;
    wire tx_active;
    reg [7:0] tx_data_in;  
    
    reg lfsr_auto_reset;
    Debounce #(.COUNTER_SIZE(2000000)) db_unit (
        .clk(clk), .reset(reset), 
        .button_in(btn_process_all), 
        .button_out(btn_process_pulse) 
    );
    
    keybuilder key_gen_inst (
        .clk(clk), .reset(reset),
        .load_seed(btn_load_seed),
        .auto_reset(lfsr_auto_reset), 
        .seed_sw(sw),
        .start_gen(lfsr_start),
        .done_tick(lfsr_done),
        .key_byte(key_byte),
        .debug_seed_out(led)
    );
    
    assign cipher_byte = fifo_data_out ^ key_byte;
    
    UART_rx #(.BAUD_X16_TICKS(54)) rx (
        .clk(clk), .reset(reset), .rx_data_in(RsRx), 
        .rx_data_out(rx_data_fifo_in), .rx_done_tick(rx_done_tick)
    );

    fifo_generator_0 fifo (
        .clk(clk), .srst(reset), .din(rx_data_fifo_in), .wr_en(rx_done_tick),
        .rd_en(fifo_rd_en), .dout(fifo_data_out), 
        .empty(fifo_empty), .full(fifo_full)
    );
    
    UART_tx #(.BAUD_CLK_TICKS(868)) tx (
        .clk(clk), .reset(reset), .tx_start(tx_start), 
        .tx_data_in(tx_data_in), .tx_data_out(RsTx), .tx_active(tx_active)
    );
    
    localparam S_IDLE       = 0;
    localparam S_READ_FIFO  = 1;
    localparam S_WAIT_DATA  = 2;
    localparam S_GEN_KEY    = 3;
    localparam S_WAIT_KEY   = 4;
    localparam S_SEND_TX    = 5;
    localparam S_CHECK_NEXT = 6;
    
    reg [2:0] state = S_IDLE;
    
    reg [16:0] timeout_count = 0;
    
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            fifo_rd_en <= 0;
            lfsr_start <= 0;
            tx_start <= 0;
            lfsr_auto_reset <= 0;
        end else begin
            fifo_rd_en <= 0;
            lfsr_start <= 0;
            tx_start <= 0;
            lfsr_auto_reset <= 0;

            case (state)
                S_IDLE: begin
                    if (btn_process_pulse && !fifo_empty) begin
                        state <= S_READ_FIFO;
                    end
                end
                
                S_READ_FIFO: begin
                    fifo_rd_en <= 1; 
                    state <= S_WAIT_DATA;
                end
                
                S_WAIT_DATA: begin
                    state <= S_GEN_KEY;
                end
                
                S_GEN_KEY: begin
                    lfsr_start <= 1; 
                    state <= S_WAIT_KEY;
                end
                
                S_WAIT_KEY: begin
                    if (lfsr_done) begin
                        state <= S_SEND_TX;
                    end
                end
                
                S_SEND_TX: begin
                    if (!tx_active) begin
                        tx_data_in <= cipher_byte;
                        tx_start <= 1;
                        state <= S_CHECK_NEXT;
                    end
                end  
                
                S_CHECK_NEXT: begin
                    if (!fifo_empty) begin
                        timeout_count <= 0;
                        state <= S_READ_FIFO; 
                    end else begin
                        if (timeout_count < 100000) begin
                            timeout_count <= timeout_count + 1;
                        end else begin
                            lfsr_auto_reset <= 1; 
                            state <= S_IDLE;      
                        end
                    end
                end
            endcase
        end
    end
endmodule
