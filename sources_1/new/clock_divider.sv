`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.02.2020 17:16:45
// Design Name: 
// Module Name: clock_divider
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

////////    Instance template   /////////////
/* 
    clock_divider #(.d (2)) instance_name(
        .clk_in(),
        .reset(),
        .clk_out()
    );
*/
////////////////////////////////////////////

module clock_divider #(parameter d = 2)(
    input clk_in,
    input reset,
    output clk_out
    );
    
    logic next_clk, clk;
    logic [27:0] next_counter, counter;
    
    assign clk_out = clk;
    
    always_ff @ (posedge clk_in) begin
        if (reset == 1'b1) begin
            clk <= 1'b0;
            counter[27:0] <= 28'b0;
        end
        else begin
            clk <= next_clk;
            counter[27:0] <= next_counter[27:0];
        end
    end
    
    always_comb begin
        if ( counter == (d/2 - 1) ) begin
            next_clk = ~clk;
            next_counter[27:0] = 28'b0; 
        end
        else begin
            next_clk = clk;
            next_counter[27:0] = counter[27:0] + 1;
        end
    end
    
endmodule
