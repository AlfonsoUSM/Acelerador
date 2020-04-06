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
        .clk(),             // 1 bit Input :
        .reset(),           // 1 bit Input :
        .send(),            // 1 bit Input : 
        .result(),          // 2 bits Input :
        .vector_output(),   // 1024 Bytes Input :   
        .uart_tx(),         // 1 bit Output :
        .done()             // 1 bit Output :
    );
    
*/ ////////////////////////////////////////////////////////

module output_interface #(parameter NBytes = 1024)(
    input clk,
    input reset,
    input send,
    input [1:0] result,
    input [7:0] tx_output,
    output uart_tx,
    output done
    );
    
    /*
    localparam IDLE =           3'b000;
    localparam SEND_VECTOR =    3'b010;
    localparam VECTOR_WAIT =    3'b011;
    localparam SEND_SCALAR =    3'b100;
    localparam SCALAR_WAIT =    3'b101;
        
    logic [2:0] state, next_state;
    logic [9:0] byte_counter, next_counter;
    logic [7:0] tx_byte;
    //logic send;
    logic tx_flag;
    logic ok, next_ok;
    
    assign done = ok;
    
    always_ff @ (posedge clk) begin
        if (reset == 1'b1) begin
            state <= IDLE;
            byte_counter <= 10'd0;
            ok <= 0;
        end
        else begin
            state <= next_state;
            byte_counter <= next_counter;
            ok <= next_ok;
        end
    end
    
    always_comb begin
        next_state = state; // default
        case (state)
            IDLE: begin
                if (result[1] == 1'b1) begin
                    if (result[0] == 1'b1)
                        next_state = SEND_VECTOR;
                    else
                        next_state = SEND_SCALAR;
                end
            end
            SEND_VECTOR: begin
                next_state = VECTOR_WAIT;
            end
            VECTOR_WAIT: begin
                if (tx_flag == 1'b1) begin 
                    if (byte_counter == (NBytes - 1))
                        next_state = IDLE;
                    else
                        next_state = SEND_VECTOR;
                end
            end
            SEND_SCALAR: begin
                next_state = SCALAR_WAIT;
            end
            SCALAR_WAIT: begin
                next_state = IDLE;
            end
        endcase
    end
 
     always_comb begin
        tx_byte = vector_output[byte_counter];
        next_counter = byte_counter;
        send = 1'b0;
        next_ok = 1'b0;
        case (state)
            IDLE: begin
                next_counter = 10'd0;
            end
            SEND_VECTOR: begin
                send = 1'b1;
            end
            VECTOR_WAIT: begin
                if (tx_flag == 1'b1) begin
                    next_counter = byte_counter + 10'd1;
                    if (byte_counter == (NBytes - 1))
                        next_ok = 1'b1;
                end
            end
            SEND_SCALAR: begin
                send = 1'b1;
            end
            SCALAR_WAIT: begin
                if (tx_flag == 1'b1)
                    next_ok = 1'b1;
            end
        endcase
    end*/
       
    uart_tx #(.CLKS_PER_BIT(100)) instance_name(
        .Clock(clk),
        .reset(reset),
        .Tx_DV(send),
        .Tx_Byte(tx_output), 
        .Tx_Active(),
        .Tx_Serial(uart_tx),
        .Tx_Done(done)
    );
    
endmodule
