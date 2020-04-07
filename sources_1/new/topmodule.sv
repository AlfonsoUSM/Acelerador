`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.03.2020 11:11:24
// Design Name: 
// Module Name: topmodule
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


module topmodule(
    input   CLK100MHZ,
    input   CPU_RESETN,
    input   UART_TXD_IN,
    output  UART_RXD_OUT,
    output  [7:0] AN,
    output  CA, CB, CC, CD, CE, CF, CG,
    output  JA1, JA2
    );
    
    localparam NBytes = 1024;
    
    //// INPUT SERIAL INTERFACE //////////////
    
    logic in_interface_CLK;
    logic [7:0] rx_byte, bram_byte;
    logic [9:0] bram_write_addr;
    logic bramA_en, bramB_en;
    logic done;
    logic [3:0] result;
    logic [1:0] led;
    logic [2:0] state;
    logic [1:0] vectors_ready;
    
    assign in_interface_CLK = CLK100MHZ;
    assign JA1 = UART_TXD_IN;
    
    input_interface #(.NBytes (NBytes)) rx_interface (
        .clk(in_interface_CLK),             // 1 bit Input : clock signal
        .reset(~CPU_RESETN),           // 1 bit Input : cpu reset
        .uart_rx(UART_TXD_IN),         // 1 bit Input : serial receive
        .done(done),            // 1 bit Input : trasnmission
        .bramA_en(bramA_en),        // 1 bit Output : enable BRAM_A write
        .bramB_en(bramB_en),        // 1 bit Output : enable BRAM_B write
        .bram_byte(bram_byte),       // 8 bits Output : BRAM byte of data to write
        .bram_addr(bram_write_addr),       // 10 bits Output : BRAM writing address
        .result(result),         // 4 bits Output : trasnsmit result instruction
        .vec_ready(vectors_ready)    // 2 bits Output : vectors A and B loaded flags
    );         

    //// MEMORY//////////////////
 
    logic processor_CLK;
    logic [9:0] bram_read_addr;
    logic [7:0] bramA_read_byte, bramB_read_byte;
       
    blk_mem_gen_0 bram_vectorA (
        .clka(in_interface_CLK),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(bramA_en),      // input wire [0 : 0] wea
        .addra(bram_write_addr),  // input wire [9 : 0] addra
        .dina(bram_byte),    // input wire [7 : 0] dina
        .clkb(processor_CLK),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(bram_read_addr),  // input wire [9 : 0] addrb
        .doutb(bramA_read_byte)  // output wire [7 : 0] doutb
    );
    
    blk_mem_gen_0 bram_vectorB (
        .clka(in_interface_CLK),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(bramB_en),      // input wire [0 : 0] wea
        .addra(bram_write_addr),  // input wire [9 : 0] addra
        .dina(bram_byte),    // input wire [7 : 0] dina
        .clkb(processor_CLK),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(bram_read_addr),  // input wire [9 : 0] addrb
        .doutb(bramB_read_byte)  // output wire [7 : 0] doutb
    );
           
    //// PROCESSING //////////////
    
    logic tx_flag;
    logic [7:0] tx_output;
    logic [15:0] scalar_result;
    logic send;
    
    assign processor_CLK = CLK100MHZ; 
    
    vector_processing #(.NBytes (NBytes)) processing_unit(
        .clk(processor_CLK),                    // 1 bit Input : clock signal
        .reset(~CPU_RESETN),                  // 1 bit Input : cpu reset signal
        .tx_flag(tx_flag),         // 1 bit Input : transmission finished flag
        .result(result[3:0]),    // 4 bits Input : operation result selection
        .bramA_byte(bramA_read_byte),       // 8 bits Input : BRAM_A read byte of 
        .bramB_byte(bramB_read_byte),       // 8 bits Input : BRAM_B read byte of data
        .bram_addr(bram_read_addr),      // 10 bits Output : BRAM reading address
        .tx_output(tx_output),       // 8 bits Output : byte to send on uart
        .scalar_output(scalar_result),   // 16 bits Output : result to display 
        .send(send),             // 1 bit Output : send byte on uart signal
        .done(done)
    );
              
    //// OUTPUT INTERFACE ///////
    
    logic out_interface_CLK;
    
    assign JA2 = UART_RXD_OUT;
    assign out_interface_CLK = CLK100MHZ;

    output_interface tx_interface (
        .clk(out_interface_CLK),             // 1 bit Input : input clock
        .reset(~CPU_RESETN),           // 1 bit Input : CPU reset
        .send(send),    // 1 bit Input : start uart transmission signal
        .done(done),            // 1 bit Input : pocessing and transmission finished
        .vectors_ready(vectors_ready),   // 2 bits Input : vectors A and B loaded flags
        .result(result),            // 4 bits Input : user command
        .scalar_result(scalar_result),   // 16 bits Input : result to display 
        .tx_output(tx_output),   // 8 bits Input : serial byte to transmit
        .uart_tx(UART_RXD_OUT),        // 1 bit Output : serial tx signal
        .tx_flag(tx_flag),            // 1 bit Output : serial transmission finished flag  
        .anodes(AN[7:0]),          // 8 bits Output : 7segments anodes control bus
        .cathodes({CA, CB, CC, CD, CE, CF, CG})        // 7 bits Output : 7segments cathodes control bus
    );
       
      
endmodule
