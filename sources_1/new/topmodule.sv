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
    input   [1:0]SW,
    output  UART_RXD_OUT,
    output  LED16_B,
    output  LED17_B,
    output  [15:0] LED,
    output  [7:0] AN,
    output  CA, CB, CC, CD, CE, CF, CG,
    output  JA1, JA2
    );
    
    localparam NBytes = 1024;
    
//    logic clock, clk2, reset;
//    always #5 clock = ~clock;
//    always #100 clk2 = ~clk2;
//    initial begin
//        clock = 1'b1;
//        clk2 = 1'b0;
//        reset = 1'b0;
//        #9;
//        reset = 1'b1;
//        #100;
//        reset = 1'b0;
//    end

    /*/// INPUT SERIAL INTERFACE //////////////*/
    
    logic serCLK;
    logic [7:0] rx_byte, bram_byte;
    logic [9:0] bram_write_addr;
    logic bramA_en, bramB_en;
    logic done;
    logic [3:0] result;
    logic [1:0] led;
    logic [2:0] state;
    
    assign serCLK = CLK100MHZ;
    assign JA1 = UART_TXD_IN;
    assign {LED17_B, LED16_B} = led [1:0];   // vetors A & B ready leds
    assign LED[15:0] = {bram_write_addr, 3'd0, state};
    
    input_interface #(.NBytes (NBytes)) rx_interface (
        .clk(serCLK),             // 1 bit Input : clock signal
        .reset(~CPU_RESETN),           // 1 bit Input : cpu reset
        .uart_rx(UART_TXD_IN),         // 1 bit Input : serial receive
        .done(done),            // 1 bit Input : trasnmission
        .bramA_en(bramA_en),        // 1 bit Output : enable BRAM_A write
        .bramB_en(bramB_en),        // 1 bit Output : enable BRAM_B write
        .bram_byte(bram_byte),       // 8 bits Output : BRAM byte of data to write
        .bram_addr(bram_write_addr),       // 10 bits Output : BRAM writing address
        .result(result),           // 2 bits Output : trasnsmit result instruction
        .ready_leds(led[1:0]),
        .s(state)
    );         

    //// MEMORY//////////////////
 
    logic proCLK;
    logic [9:0] bram_read_addr;
    logic [7:0] bramA_read_byte, bramB_read_byte;
       
    blk_mem_gen_0 bram_vectorA (
        .clka(serCLK),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(bramA_en),      // input wire [0 : 0] wea
        .addra(bram_write_addr),  // input wire [9 : 0] addra
        .dina(bram_byte),    // input wire [7 : 0] dina
        .clkb(proCLK),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(bram_read_addr),  // input wire [9 : 0] addrb
        .doutb(bramA_read_byte)  // output wire [7 : 0] doutb
    );
    
    blk_mem_gen_0 bram_vectorB (
        .clka(serCLK),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(bramB_en),      // input wire [0 : 0] wea
        .addra(bram_write_addr),  // input wire [9 : 0] addra
        .dina(bram_byte),    // input wire [7 : 0] dina
        .clkb(proCLK),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(bram_read_addr),  // input wire [9 : 0] addrb
        .doutb(bramB_read_byte)  // output wire [7 : 0] doutb
    );
           
    //// PROCESSING //////////////
    
    logic tx_flag;
    logic [7:0] tx_output;
    logic send;
    
    assign proCLK = CLK100MHZ; 
    
    vector_processing #(.NBytes (NBytes)) processing_unit(
        .clk(proCLK),                    // 1 bit Input : clock signal
        .reset(~CPU_RESETN),                  // 1 bit Input : cpu reset signal
        .tx_flag(tx_flag),         // 1 bit Input : transmission finished flag
        .result(result[3:0]),    // 4 bits Input : operation result selection
        .bramA_byte(bramA_read_byte),       // 8 bits Input : BRAM_A read byte of 
        .bramB_byte(bramB_read_byte),       // 8 bits Input : BRAM_B read byte of data
        .bram_addr(bram_read_addr),      // 10 bits Output : BRAM reading address
        .tx_output(tx_output),       // 8 bits Output : byte to send on uart
        .send(send),             // 1 bit Output : send byte on uart signal
        .done(done)
    );
              
    //// OUTPUT INTERFACE ///////
    
    assign JA2 = UART_RXD_OUT;

    output_interface instance_name (
        .clk(serCLK),             // 1 bit Input :
        .reset(~CPU_RESETN),           // 1 bit Input :
        .send(send),    // 1 bit Input : 
        .result(result[3:2]),            // 2 bits Input :
        .tx_output(tx_output),   // 8 bits Input :   
        .uart_tx(UART_RXD_OUT),        // 1 bit Output :
        .done(tx_flag)            // 1 bit Output :
    );
    
    //// DISPLAY /////////////////
    
    logic dispCLK;
    logic [3:0] bcd;
    logic [7:0] anodes, next_anodes;
    logic [7:0][3:0] displayed_bcd;
    logic [6:0] cathodes;
    assign AN[7:0] = anodes;
    assign {CA, CB, CC, CD, CE, CF, CG} = cathodes;
    
    always_ff @ (posedge dispCLK) begin
        if (~CPU_RESETN == 1'b1) begin
            anodes <= 8'b11111110;
        end
        else begin
            anodes <= next_anodes[7:0];
        end    
    end
    
    always_comb begin
        next_anodes = {anodes[6:0], anodes[7]};
        displayed_bcd = {29'd0, state};
        case (anodes)
            8'b11111110:
                bcd = displayed_bcd[0];
            8'b11111101:
                bcd = displayed_bcd[1];
            8'b11111011:
                bcd = displayed_bcd[2];
            8'b11110111:
                bcd = displayed_bcd[3];
            8'b11101111:
                bcd = displayed_bcd[4];
            8'b11011111:
                bcd = displayed_bcd[5];
            8'b10111111:
                bcd = displayed_bcd[6];
            8'b01111111:
                bcd = displayed_bcd[7];
            default:
                bcd = 4'd10;
        endcase
    end
    
    clock_divider #(.d (50000)) seg7_clk(
        .clk_in(CLK100MHZ),
        .reset(~CPU_RESETN),
        .clk_out(dispCLK)
    );
    
    segment7 seg7(
        .bcd(bcd),
        .seg(cathodes)
    );    
      
endmodule
