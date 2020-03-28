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
    input   SW0,
    output  LED[1:0],
    output  [7:0] AN,
    output  CA, CB, CC, CD, CE, CF, CG,
    output  JA1, JA2
    );
    
    localparam NBytes = 5;
    localparam IDLE =       1'b0;
    localparam RECEIVED =   1'b1;
    
    logic [1:0] state, next_state;
    logic [2:0] byte_count, next_count;
    logic [9:0] write_addr, next_w_addr;
    logic [7:0] rx_byte;
    logic rx_flag;
    logic led;
    
    assign JA1 = UART_TXD_IN;
    assign JA2 = rx_flag;
    assign LED0 = led;
    
    logic [7:0] anodes, next_anodes;
    logic clock, clk2, reset;
    always #5 clock = ~clock;
    always #100 clk2 = ~clk2;
    initial begin
        clock = 1'b1;
        clk2 = 1'b0;
        reset = 1'b0;
        #9;
        reset = 1'b1;
        #100;
        reset = 1'b0;
    end
    
    always_ff @ (posedge CLK100MHZ) begin
        if (~CPU_RESETN == 1'b1) begin
            byte_count <= 3'b0;
            state <= IDLE;
            write_addr <= 10'b0;
        end
        else begin
            byte_count <= next_count;
            state <= next_state;
            write_addr <= next_w_addr;
        end
    end
    
    always_comb begin
        next_state = state;
        next_count = byte_count;
        next_w_addr = write_addr;
        if (state == IDLE) begin
            led = 1'b0;
            if (rx_flag == 1'b1) begin
                next_count = byte_count + 3'b1;
                next_w_addr = write_addr + 10'b1;
                if (byte_count == (NBytes - 1))
                    next_state = RECEIVED;
            end
        end
        else
            led = 1'b1;
    end
    
    uart_rx #(.CLKS_PER_BIT(100)) uart_rx(
        .Clock(CLK100MHZ),
        .reset(~CPU_RESETN),
        .Rx_Serial(UART_TXD_IN),
        .Rx_DV(rx_flag),
        .Rx_Byte(rx_byte)
    );
    
    logic [3:0] bcd, next_bcd;
    logic seg7_clock;
    logic [7:0] read_byte;
    logic [9:0] read_addr, next_r_addr;
    logic [7:0][3:0] displayed_bcd, next_disp_bcd;
    logic [6:0] cathodes;
    assign AN[7:0] = anodes;
    assign {CA, CB, CC, CD, CE, CF, CG} = cathodes;
//    assign displayed_bcd[0] = 4'd1;
//    assign displayed_bcd[1] = 4'd0;
//    assign displayed_bcd[2] = 4'd1;
//    assign displayed_bcd[3] = 4'd0;
//    assign displayed_bcd[4] = 4'd1;
//    assign displayed_bcd[5] = 4'd5;
//    assign displayed_bcd[6] = 4'd6;
//    assign displayed_bcd[7] = 4'd9;
    logic FF1, FF2;
    
    always_ff @ (posedge CLK100MHZ) begin
        if (~CPU_RESETN == 1'b1) begin
            FF1 <= 1'b1;
            FF2 <= 1'b1;
        end
        else begin
            FF1 <= seg7_clock;
            FF2 <= FF1;
        end
    end
    
    always_ff @ (posedge CLK100MHZ) begin
        if (~CPU_RESETN == 1'b1) begin
            anodes <= 8'b11111110;
            bcd <= 4'b0;
            read_addr <= 10'd1;
            displayed_bcd <= 32'b0;
        end
        else begin
            anodes <= next_anodes[7:0];
            bcd <= next_bcd;
            read_addr <= next_r_addr;
            displayed_bcd <= next_disp_bcd;
        end    
    end
    
    always_comb begin
        next_anodes = anodes;
        next_disp_bcd = displayed_bcd;
        next_bcd = bcd;
        next_r_addr = read_addr;
        if (FF1 == 1'b1 && FF2 == 1'b0) begin
            next_anodes = {anodes[6:0], anodes[7]};
            if (read_addr == 10'd7)
                next_r_addr = 10'd0;
            else
                next_r_addr = read_addr + 10'd1;
            case (next_anodes)
                8'b11111110: begin
                    next_disp_bcd[1] = read_byte[3:0];
                    next_bcd = displayed_bcd[0];
                    end
                8'b11111101: begin
                    next_disp_bcd[2] = read_byte[3:0];
                    next_bcd = displayed_bcd[1];
                    end
                8'b11111011: begin
                    next_disp_bcd[3] = read_byte[3:0];
                    next_bcd = displayed_bcd[2];
                    end
                8'b11110111: begin
                    next_disp_bcd[4] = read_byte[3:0];
                    next_bcd = displayed_bcd[3];
                    end
                8'b11101111: begin
                    next_disp_bcd[5] = read_byte[3:0];
                    next_bcd = displayed_bcd[4];
                    end
                8'b11011111: begin
                    next_disp_bcd[6] = read_byte[3:0];
                    next_bcd = displayed_bcd[5];
                    end
                8'b10111111: begin
                    next_disp_bcd[7] = read_byte[3:0];
                    next_bcd = displayed_bcd[6];
                    end
                8'b01111111: begin
                    next_disp_bcd[0] = read_byte[3:0];
                    next_bcd = displayed_bcd[7];
                    end
                default:
                    next_bcd = 4'd10;
            endcase
        end
    end
    
    blk_mem_gen_0 bram_vectorA (
        .clka(CLK100MHZ),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(1'b1),      // input wire [0 : 0] wea
        .addra(write_addr),  // input wire [9 : 0] addra
        .dina(rx_byte),    // input wire [7 : 0] dina
        .clkb(CLK100MHZ),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(read_addr),  // input wire [9 : 0] addrb
        .doutb(read_byte)  // output wire [7 : 0] doutb
    );
    
    blk_mem_gen_0 bram_vectorB (
        .clka(CLK100MHZ),    // input wire clka
        .ena(),      // input wire ena
        .wea(),      // input wire [0 : 0] wea
        .addra(),  // input wire [9 : 0] addra
        .dina(),    // input wire [7 : 0] dina
        .clkb(),    // input wire clkb
        .enb(),      // input wire enb
        .addrb(),  // input wire [9 : 0] addrb
        .doutb()  // output wire [7 : 0] doutb
    );
        
    clock_divider #(.d (50000)) seg7_clk(
        .clk_in(CLK100MHZ),
        .reset(~CPU_RESETN),
        .clk_out(seg7_clock)
    );
    
    segment7 seg7(
        .bcd(bcd),
        .seg(cathodes)
    );    
    
endmodule
