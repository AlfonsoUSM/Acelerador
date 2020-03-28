`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// downloaded from www.nandland.com
// 
// Create Date: 25.02.2020 13:32:20
// Design Name: 
// Module Name: uart_rx
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

    uart_rx #(.CLKS_PER_BIT(100)) instance_name(
        .Clock(),
        .reset(),
        .Rx_Serial(),
        .Rx_DV(),
        .Rx_Byte()
    );
    
*/ ////////////////////////////////////////////////////////

// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
  
module uart_rx   #(parameter CLKS_PER_BIT = 100)(
    input           Clock,
    input           reset,
    input           Rx_Serial,
    output          Rx_DV,
    output [7:0]    Rx_Byte
    );
    
    localparam s_IDLE         = 3'b000;
    localparam s_RX_START_BIT = 3'b001;
    localparam s_RX_DATA_BITS = 3'b010;
    localparam s_RX_STOP_BIT  = 3'b011;
    localparam s_CLEANUP      = 3'b100;
     
    logic  r_Rx_Data_R = 1'b1;
    logic  r_Rx_Data   = 1'b1;
     
    logic [7:0]     r_Clock_Count;
    logic [2:0]     r_Bit_Index; //8 bits total
    logic [7:0]     r_Rx_Byte;
    logic           r_Rx_DV;
    logic [2:0]     r_SM_Main;
    
    assign Rx_DV   = r_Rx_DV;
    assign Rx_Byte = r_Rx_Byte;
    
    // Purpose: Double-register the incoming data.
    // This allows it to be used in the UART RX Clock Domain.
    // (It removes problems caused by metastability)
    always @(posedge Clock)
        begin
          r_Rx_Data_R <= Rx_Serial;
          r_Rx_Data   <= r_Rx_Data_R;
        end
     
    // Purpose: Control RX state machine
    always @(posedge Clock)  begin
        if (reset == 1'b1) begin
           r_SM_Main <= s_IDLE;
           r_Clock_Count <= 8'b0;
           r_Bit_Index <= 3'b0;
           r_Rx_Byte <= 8'b0;
           r_Rx_DV <= 1'b0;
        end
        else begin
            case (r_SM_Main) 
                s_IDLE : begin
                  r_Rx_DV       <= 1'b0;
                  r_Clock_Count <= 8'b0;
                  r_Bit_Index   <= 3'b0;
                  if (r_Rx_Data == 1'b0)          // Start bit detected
                    r_SM_Main <= s_RX_START_BIT;
                  else
                    r_SM_Main <= s_IDLE;
                end
              s_RX_START_BIT : begin // Check middle of start bit to make sure it's still low
                  if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
                      if (r_Rx_Data == 1'b0) begin
                          r_Clock_Count <= 0;  // reset counter, found the middle
                          r_SM_Main     <= s_RX_DATA_BITS;
                      end
                      else
                          r_SM_Main <= s_IDLE;
                  end
                  else begin
                      r_Clock_Count <= r_Clock_Count + 1;
                      r_SM_Main     <= s_RX_START_BIT;
                    end
                end // case: s_RX_START_BIT
              s_RX_DATA_BITS : begin  // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
                  if (r_Clock_Count < CLKS_PER_BIT-1) begin
                      r_Clock_Count <= r_Clock_Count + 1;
                      r_SM_Main     <= s_RX_DATA_BITS;
                    end
                  else begin
                      r_Clock_Count          <= 0;
                      r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
                      if (r_Bit_Index < 7) begin // Check if we have received all bits
                          r_Bit_Index <= r_Bit_Index + 1;
                          r_SM_Main   <= s_RX_DATA_BITS;
                        end
                      else begin
                          r_Bit_Index <= 0;
                          r_SM_Main   <= s_RX_STOP_BIT;
                        end
                    end
                end // case: s_RX_DATA_BITS
              s_RX_STOP_BIT: begin // Receive Stop bit.  Stop bit = 1
                  // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                  if (r_Clock_Count < CLKS_PER_BIT-1) begin
                      r_Clock_Count <= r_Clock_Count + 1;
                      r_SM_Main     <= s_RX_STOP_BIT;
                    end
                  else begin
                      r_Rx_DV       <= 1'b1;
                      r_Clock_Count <= 0;
                      r_SM_Main     <= s_CLEANUP;
                    end
                end // case: s_RX_STOP_BIT  
              s_CLEANUP: begin // Stay here 1 clock
                  r_SM_Main <= s_IDLE;
                  r_Rx_DV   <= 1'b0;
                end
              default:
                r_SM_Main <= s_IDLE;
            endcase
        end
    end   
        
endmodule // uart_rx