`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2020 15:33:15
// Design Name: 
// Module Name: output_interface
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


/* /////////////// Instance Template ////////////////////

    output_interface  #(.NBytes (1024)) instance_name (
        .clk(),             // 1 bit Input : input clock
        .reset(),           // 1 bit Input : CPU reset
        .send(),            // 1 bit Input : start uart transmission signal
        .done(),            // 1 bit Input : pocessing and transmission finished
        .vectors_ready(),   // 2 bits Input : vectors A and B loaded flags
        .result(),          // 4 bits Input : user command
        .tx_output(),       // 8 bits Input : serial byte to transmit
        .scalar_result(),   // 16 bits Input : result to display 
        .uart_tx(),         // 1 bit Output : serial tx signal
        .tx_flag(),         // 1 bit Output : serial transmission finished flag 
        .anodes(),          // 8 bits Output : 7segments anodes control bus
        .cathodes()         // 7 bits Output : 7segments cathodes control bus
    );
    
*/ ////////////////////////////////////////////////////////

module output_interface #(parameter NBytes = 1024)(
    input clk,
    input reset,
    input send,
    input done,
    input [1:0] vectors_ready,
    input [3:0] result,
    input [7:0] tx_output,
    input [15:0] scalar_result,
    output uart_tx,
    output tx_flag,
    output [7:0] anodes,
    output [6:0] cathodes
    );
    
    //// UART TX /////////////
       
    uart_tx #(.CLKS_PER_BIT(100)) instance_name(
        .Clock(clk),
        .reset(reset),
        .Tx_DV(send),
        .Tx_Byte(tx_output), 
        .Tx_Active(),
        .Tx_Serial(uart_tx),
        .Tx_Done(tx_flag)
    );
    
    //// DISPLAY /////////////////
    
    localparam IDLE =   2'b00;
    localparam READY =  2'b01;
    localparam RESULT = 2'b10;
    
    logic dispCLK;
    logic [1:0] state, next_state;
    logic [3:0] bcd;
    logic [7:0] anode_mask;
    logic [7:0] an7seg, next_an7seg;
    logic [7:0][3:0] display, next_display;
    
    assign anodes = an7seg[7:0] | anode_mask[7:0] ;
    
    always_ff @ (posedge clk) begin
        if (reset == 1'b1) begin
            state <= IDLE;
            display <= 32'd0;
        end
        else begin
            state <= next_state;
            display <= next_display;
        end
    end
    
    always_comb begin
        next_state = state;
        next_display = display;
        anode_mask = 8'b11111111;
        case (state)
            IDLE: begin
                if (vectors_ready == 2'b11) begin
                    next_state = READY;
                    next_display = 32'd0;
                end
            end
            READY: begin
                anode_mask = 8'b00000000;
                if (vectors_ready != 2'b11) begin
                    next_state = IDLE;
                end
                if (result[3:2] == 2'b10) begin
                    next_state = RESULT;
                end
            end
            RESULT: begin
                anode_mask = 8'b11100000;
                if (done)
                    next_display = {16'd0, scalar_result};
                if (vectors_ready != 2'b11)
                    next_state = IDLE;
            end
        endcase
    end
    
    always_ff @ (posedge dispCLK) begin
        if (reset == 1'b1) begin
            an7seg <= 8'b11111110;
        end
        else begin
            an7seg <= next_an7seg[7:0];
        end    
    end
    
    always_comb begin
        next_an7seg = {an7seg[6:0], an7seg[7]};
        case (an7seg)
            8'b11111110:
                bcd = display[0];
            8'b11111101:
                bcd = display[1];
            8'b11111011:
                bcd = display[2];
            8'b11110111:
                bcd = display[3];
            8'b11101111:
                bcd = display[4];
            8'b11011111:
                bcd = display[5];
            8'b10111111:
                bcd = display[6];
            8'b01111111:
                bcd = display[7];
            default:
                bcd = 4'd10;
        endcase
    end
    
    clock_divider #(.d (50000)) seg7_clk(
        .clk_in(clk),
        .reset(reset),
        .clk_out(dispCLK)
    );
    
    segment7 seg7(
        .bcd(bcd),
        .seg(cathodes)
    ); 
    
endmodule
