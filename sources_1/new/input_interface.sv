`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2020 15:33:15
// Design Name: 
// Module Name: input_interface
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

    input_interface #(.NBytes (1024)) instance_name (
        .clk(),         // 1 bit Input : clock signal
        .reset(),       // 1 bit Input : cpu reset
        .uart_rx(),     // 1 bit Input : serial receive
        .done(),        // 1 bit Input : trasnmission
        .bramA_en(),    // 1 bit Output : enable BRAM_A write
        .bramB_en(),    // 1 bit Output : enable BRAM_B write
        .bram_byte(),   // 8 bits Output : BRAM byte of data to write
        .bram_addr(),   // 10 bits Output : BRAM writing address
        .result()       // 4 bits Output : trasnsmit result instruction
    );
    
*/ ////////////////////////////////////////////////////////

module input_interface #(parameter NBytes = 1024)(
    input   clk,
    input   reset,
    input   uart_rx,
    input   done,
    output  bramA_en,
    output  bramB_en,
    output [7:0] bram_byte,
    output [9:0] bram_addr,
    output [3:0] result,
    output [1:0] ready_leds,
    output [2:0] s
    );
        
    
    localparam INST =   3'b001; // Waiting for instruction
    localparam ENA =    3'b010; // Enable BRAM_A writing
    localparam SETA =   3'b011; // Sotore VectorA
    localparam ENB =    3'b100; // Enable BRAM_B writing
    localparam SETB =   3'b101; // Store VectorB
    localparam COMM =   3'b111; // Result transmission
    
    logic [2:0] state, next_state;
    logic [7:0] rx_raw_byte, rx_byte;
    logic rx_flag;
    logic [9:0] write_addr, next_w_addr;
    logic wenA, next_wenA, wenB, next_wenB;
    logic [3:0] command, next_command;
    logic [1:0] led, next_led;
    
    assign bramA_en = wenA;
    assign bramB_en = wenB;
    assign bram_byte = rx_byte;
    assign bram_addr = write_addr;
    assign result = command;
    assign ready_leds = led; 
    assign s = state;
     
    always_ff @ (posedge clk) begin
        if (reset == 1'b1) begin
            state <= INST;
            write_addr <= 10'b0;
            wenA <= 1'b0;
            wenB <= 1'b0;
            led <= 2'b0;
            command <= 4'd0;
        end
        else begin
            state <= next_state[2:0];
            write_addr <= next_w_addr;
            wenA <= next_wenA;
            wenB <= next_wenB;
            led <= next_led[1:0];
            command <= next_command[3:0];
        end
    end
    
    always_comb begin       // state combo logic
        next_state = state[2:0];    // same state by default
        case (state)
            INST: begin
                if (rx_flag == 1'b1) begin
                    case (rx_byte)
                        8'd0: next_state = ENA;
                        8'd1: next_state = ENB;
                        default: next_state = COMM;
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
                if (done == 1'b1)
                    next_state = INST;
            end
        endcase
    end
    
    always_comb begin       // store vectors into BRAM and commands combo logic
        next_w_addr = write_addr[9:0];
        next_wenA = wenA;
        next_wenB = wenB;
        next_led = led[1:0];
        next_command = 4'd0;;
        if (rx_flag)
            rx_byte = rx_raw_byte;
        else
            rx_byte = 8'd0;
        case (state)
            INST: begin 
                next_w_addr = 10'd0;      
                if (rx_flag == 1'b1)
                    next_command = rx_byte[3:0];
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
    
    uart_rx #(.CLKS_PER_BIT(100)) serial_rx(
        .Clock(clk),
        .reset(reset),
        .Rx_Serial(uart_rx),
        .Rx_DV(rx_flag),
        .Rx_Byte(rx_raw_byte)
    );
    
endmodule
