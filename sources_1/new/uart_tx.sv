`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// downloaded from www.nandland.com
//
// Create Date: 25.02.2020 13:32:20
// Design Name: 
// Module Name: uart_tx
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

    uart_tx #(.CLKS_PER_BIT(100)) instance_name(
        .Clock(),
        .reset(),
        .Tx_DV(),
        .Tx_Byte(), 
        .Tx_Active(),
        .Tx_Serial(),
        .Tx_Done()
    );
    
*/ ////////////////////////////////////////////////////////

// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
  
module uart_tx  #(parameter CLKS_PER_BIT = 100) (
    input           Clock,
    input           reset,
    input           Tx_DV,
    input [7:0]     Tx_Byte, 
    output          Tx_Active,
    output logic    Tx_Serial,
    output          Tx_Done
    );
  
    localparam s_IDLE         = 3'b000;
    localparam s_TX_START_BIT = 3'b001;
    localparam s_TX_DATA_BITS = 3'b010;
    localparam s_TX_STOP_BIT  = 3'b011;
    localparam s_CLEANUP      = 3'b100;
     
    logic [2:0]    r_SM_Main;
    logic [7:0]    r_Clock_Count;
    logic [2:0]    r_Bit_Index;
    logic [7:0]    r_Tx_Data;
    logic          r_Tx_Done;
    logic          r_Tx_Active;
       
    assign Tx_Active = r_Tx_Active;
    assign Tx_Done   = r_Tx_Done;
    
    always @(posedge Clock) begin
        if (reset == 1'b1) begin
            r_SM_Main <= s_IDLE;
            r_Clock_Count <= 8'b0;
            r_Bit_Index <= 3'b0;
            r_Tx_Data <= 8'b0;
            r_Tx_Done <= 1'b0;
            r_Tx_Active <= 1'b0;
        end
        else begin
            case (r_SM_Main)
              s_IDLE :  begin
                  Tx_Serial   <= 1'b1;         // Drive Line High for Idle
                  r_Tx_Done     <= 1'b0;
                  r_Clock_Count <= 0;
                  r_Bit_Index   <= 0;
                  if (Tx_DV == 1'b1) begin
                      r_Tx_Active <= 1'b1;
                      r_Tx_Data   <= Tx_Byte;
                      r_SM_Main   <= s_TX_START_BIT;
                    end
                  else
                    r_SM_Main <= s_IDLE;
                end // case: s_IDLE
              s_TX_START_BIT : // Send out Start Bit. Start bit = 0
                begin
                  Tx_Serial <= 1'b0;
                  // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
                  if (r_Clock_Count < CLKS_PER_BIT-1) begin
                      r_Clock_Count <= r_Clock_Count + 1;
                      r_SM_Main     <= s_TX_START_BIT;
                    end
                  else  begin
                      r_Clock_Count <= 0;
                      r_SM_Main     <= s_TX_DATA_BITS;
                    end
                end // case: s_TX_START_BIT
              s_TX_DATA_BITS:  begin // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish   
                  Tx_Serial <= r_Tx_Data[r_Bit_Index];
                  if (r_Clock_Count < CLKS_PER_BIT-1) begin
                      r_Clock_Count <= r_Clock_Count + 1;
                      r_SM_Main     <= s_TX_DATA_BITS;
                    end
                  else begin
                      r_Clock_Count <= 0;
                      // Check if we have sent out all bits
                      if (r_Bit_Index < 7) begin
                          r_Bit_Index <= r_Bit_Index + 1;
                          r_SM_Main   <= s_TX_DATA_BITS;
                        end
                      else begin
                          r_Bit_Index <= 0;
                          r_SM_Main   <= s_TX_STOP_BIT;
                        end
                    end
                end // case: s_TX_DATA_BITS
              s_TX_STOP_BIT : begin // Send out Stop bit.  Stop bit = 1
                  Tx_Serial <= 1'b1;
                  // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                  if (r_Clock_Count < CLKS_PER_BIT-1) begin
                      r_Clock_Count <= r_Clock_Count + 1;
                      r_SM_Main     <= s_TX_STOP_BIT;
                    end
                  else begin
                      r_Tx_Done     <= 1'b1;
                      r_Clock_Count <= 0;
                      r_SM_Main     <= s_CLEANUP;
                      r_Tx_Active   <= 1'b0;
                    end
                end // case: s_Tx_STOP_BIT
              s_CLEANUP : begin // Stay here 1 clock
                  r_Tx_Done <= 1'b1;
                  r_SM_Main <= s_IDLE;
                end
              default :
                r_SM_Main <= s_IDLE;
            endcase
        end
    end
    
endmodule