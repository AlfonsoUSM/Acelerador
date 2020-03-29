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
    output  LED16_B,
    output  LED17_B,
    output  [15:0] LED,
    output  [7:0] AN,
    output  CA, CB, CC, CD, CE, CF, CG,
    output  JA1, JA2, JA3, JA4
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

    /*/// UART SERIAL INTERFACE //////////////*/
    
    localparam INST =   3'b000;
    localparam ENA =    3'b010;
    localparam SETA =   3'b011;
    localparam ENB =    3'b100;
    localparam SETB =   3'b101;
    localparam COMM =   3'b111;
    
    logic serCLK;
    logic [2:0] state, next_state;
    logic [7:0] rx_raw_byte, rx_byte;
    logic rx_flag;
    logic [9:0] write_addr, next_w_addr;
    logic wenA, next_wenA, wenB, next_wenB;
    logic [1:0] led, next_led;
    
    assign serCLK = CLK100MHZ;
    assign JA1 = UART_TXD_IN;
    assign JA2 = rx_flag;
    assign {JA3, JA4} = led[1:0];
    assign {LED17_B, LED16_B} = led [1:0];   // vetors A & B ready leds
    assign LED[15:0] = {write_addr, 3'b0, state};
     
    always_ff @ (posedge serCLK) begin
        if (~CPU_RESETN == 1'b1) begin
            write_addr <= 10'b0;
            state <= INST;
            wenA <= 1'b0;
            wenB <= 1'b0;
            led <= 2'b0;
        end
        else begin
            write_addr <= next_w_addr;
            state <= next_state[2:0];
            wenA <= next_wenA;
            wenB <= next_wenB;
            led <= next_led[1:0];
        end
    end
    
    always_comb begin       // state combo logic
        next_state = state[2:0];
        case (state)
            INST: begin
                if (rx_flag == 1'b1) begin
                    case (rx_byte)
                        8'd0: next_state = ENA;
                        8'd1: next_state = ENB;
                        8'd2: next_state = COMM;
                    endcase
                end                
            end
            ENA: next_state = SETA;
            SETA: begin
                if ((rx_flag == 1'b1) && (write_addr == (NBytes - 1)))
                    next_state = INST;
            end
            ENB: next_state = SETB;
            SETB: begin
                if ((rx_flag == 1'b1) && (write_addr == (NBytes - 1)))
                    next_state = INST;
            end
            COMM: begin
            
            end
        endcase
    end
    
    always_comb begin       // store vectors into BRAM and commands combo logic
        next_w_addr = write_addr[9:0];
        next_wenA = wenA;
        next_wenB = wenB;
        next_led = led[1:0];
        if (rx_flag)
            rx_byte = rx_raw_byte;
        else
            rx_byte = 8'd0;
        case (state)
            INST: begin 
                next_w_addr = 10'd0;          
            end
            ENA: begin
                next_wenA = 1'b1;
                next_led[1] = 1'b0;
            end
            SETA: begin
                if (rx_flag) begin
                    if (write_addr == (NBytes - 1)) begin
                        next_wenA = 1'b0;
                        next_led[1] = 1'b1;
                    end
                    else
                        next_w_addr = write_addr + 10'd1;
                end
            end
            ENB: begin
                next_wenB = 1'b1;
                next_led[0] = 1'b0;
            end
            SETB: begin
                if (rx_flag) begin
                    if (write_addr == (NBytes - 1)) begin
                        next_wenB = 1'b0;
                        next_led[0] = 1'b1;
                    end
                    else
                        next_w_addr = write_addr + 10'd1;
                end
            end
            COMM: begin
            end
        endcase
    end
    
    //// PROCESSING //////////////
    
    logic proCLK;
    logic [1023:0][7:0] vectorA, next_vectA, vectorB, next_vectB, sumVector, avgVector;
//    logic [7:0] vectorA [1023:0];
//    logic [7:0] next_vectA [1023:0];
//    logic [7:0] vectorB [1023:0];
//    logic [7:0] next_vectB [1023:0];
//    logic [7:0] sumVector [1023:0];
//    logic [7:0] avgVector [1023:0];
    logic eucDist, manDist;
    
    logic [9:0] read_addr, next_r_addr;
    logic [7:0] read_byteA, read_byteB;
    
    assign proCLK = CLK100MHZ; 
    assign sumVector = vectorA + vectorB;
    assign avgVector[1023:0] = sumVector[1023:0] >> 1;
    
    always_ff @ (posedge proCLK) begin
        if (~CPU_RESETN == 1'b1)begin
            read_addr <= 10'd0;
            vectorA <= '{1024{8'b0}}; //8192'd0;
            vectorB <= '{1024{8'b0}}; //8192'd0;
        end
        else begin
            read_addr <= next_r_addr[9:0];
            vectorA <= next_vectA;
            vectorB <= next_vectB;
        end
    end
    
    always_comb begin
        next_vectA = vectorA;
        next_vectB = vectorB;
        if (read_addr == 0) begin
            next_vectA[NBytes - 2] = read_byteA[7:0];
            next_vectB[NBytes - 2] = read_byteB[7:0];
        end
        else begin
            if (read_addr == 1) begin
                next_vectA[NBytes - 1] = read_byteA[7:0];
                next_vectB[NBytes - 1] = read_byteB[7:0];
            end
            else
                next_vectA[read_addr - 10'd2] = read_byteA[7:0];
                next_vectB[read_addr - 10'd2] = read_byteB[7:0];
        end    
        if (read_addr == (NBytes - 1))
            next_r_addr = 10'd0;
        else
            next_r_addr = read_addr + 10'd1;
    end
    
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
        case(SW[1:0])
            2'b00: begin
                displayed_bcd[0] = vectorA[0][3:0];
                displayed_bcd[1] = vectorA[1][3:0];
                displayed_bcd[2] = vectorA[2][3:0];
                displayed_bcd[3] = vectorA[3][3:0];
                displayed_bcd[4] = vectorA[4][3:0];
                displayed_bcd[5] = vectorA[5][3:0];
                displayed_bcd[6] = vectorA[6][3:0];
                displayed_bcd[7] = vectorA[7][3:0];
            end
            2'b01: begin 
                displayed_bcd[0] = vectorB[0][3:0];
                displayed_bcd[1] = vectorB[1][3:0];
                displayed_bcd[2] = vectorB[2][3:0];
                displayed_bcd[3] = vectorB[3][3:0];
                displayed_bcd[4] = vectorB[4][3:0];
                displayed_bcd[5] = vectorB[5][3:0];
                displayed_bcd[6] = vectorB[6][3:0];
                displayed_bcd[7] = vectorB[7][3:0];
            end
            2'b10: begin
                displayed_bcd[0] = sumVector[0][3:0];
                displayed_bcd[1] = sumVector[1][3:0];
                displayed_bcd[2] = sumVector[2][3:0];
                displayed_bcd[3] = sumVector[3][3:0];
                displayed_bcd[4] = sumVector[4][3:0];
                displayed_bcd[5] = sumVector[5][3:0];
                displayed_bcd[6] = sumVector[6][3:0];
                displayed_bcd[7] = sumVector[7][3:0];
            end
            2'b11: begin
                displayed_bcd[0] = avgVector[0][3:0];
                displayed_bcd[1] = avgVector[1][3:0];
                displayed_bcd[2] = avgVector[2][3:0];
                displayed_bcd[3] = avgVector[3][3:0];
                displayed_bcd[4] = avgVector[4][3:0];
                displayed_bcd[5] = avgVector[5][3:0];
                displayed_bcd[6] = avgVector[6][3:0];
                displayed_bcd[7] = avgVector[7][3:0];
            end
        endcase
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
    
    //// INSTANCES /////////////
        
    uart_rx #(.CLKS_PER_BIT(100)) uart_rx(
        .Clock(CLK100MHZ),
        .reset(~CPU_RESETN),
        .Rx_Serial(UART_TXD_IN),
        .Rx_DV(rx_flag),
        .Rx_Byte(rx_raw_byte)
    );
    
    blk_mem_gen_0 bram_vectorA (
        .clka(serCLK),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(wenA),      // input wire [0 : 0] wea
        .addra(write_addr),  // input wire [9 : 0] addra
        .dina(rx_byte),    // input wire [7 : 0] dina
        .clkb(proCLK),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(read_addr),  // input wire [9 : 0] addrb
        .doutb(read_byteA)  // output wire [7 : 0] doutb
    );
    
    blk_mem_gen_0 bram_vectorB (
        .clka(serCLK),    // input wire clka
        .ena(1'b1),      // input wire ena
        .wea(wenB),      // input wire [0 : 0] wea
        .addra(write_addr),  // input wire [9 : 0] addra
        .dina(rx_byte),    // input wire [7 : 0] dina
        .clkb(proCLK),    // input wire clkb
        .enb(1'b1),      // input wire enb
        .addrb(read_addr),  // input wire [9 : 0] addrb
        .doutb(read_byteB)  // output wire [7 : 0] doutb
    );
        
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
