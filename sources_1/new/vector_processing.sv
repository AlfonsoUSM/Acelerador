`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2020 15:33:15
// Design Name: 
// Module Name: vector_processing
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

    vector_processing #(.NBytes (1024)) instance_name(
        .clk(),             // 1 bit Input : clock signal
        .reset(),           // 1 bit Input : cpu reset signal
        .tx_flag(),         // 1 bit Input : transmission finished flag
        .result(),          // 4 bits Input : operation result selection
        .bramA_byte(),      // 8 bits Input : BRAM_A read byte of data
        .bramB_byte(),      // 8 bits Input : BRAM_B read byte of data
        .bram_addr(),       // 10 bits Output : BRAM reading address
        .tx_output(),       // 8 bits Output : byte to send on uart
        .scalar_outputt(),   // 16 bits Output : result to display 
        .send(),            // 1 bit Output : send byte on uart signal
        .done()
    );
    
*/ ////////////////////////////////////////////////////////


module vector_processing #(parameter NBytes = 1024)(
    input   clk,
    input   reset,
    input   tx_flag,
    input [3:0] result,
    input [7:0] bramA_byte,
    input [7:0] bramB_byte,
    output [9:0] bram_addr,
    output [7:0] tx_output,
    output [15:0] scalar_output,
    output send,
    output done
    );
    
    // General processing State
    localparam IDLE =       2'b00;      // waiting for command
    localparam VECTOR =     2'b01;      // vector type result (1024 bytes) 
    localparam SCALAR =     2'b10;      // scalar type resul (2 bytes)
    
    // Internal processing/transmission State
    localparam INIT =       2'b00;      
    localparam BYTE_SEND =  2'b01;      // start byte transmission
    localparam BYTE_WAIT =  2'b10;      // wait for transmission to end / read and process next byte to send
    localparam BYTE_READ =  2'b11;      // read byte and process scalar result
    
    // Commands with vector type result
    localparam READ_A =     2'b00;      // read vector A
    localparam READ_B =     2'b01;      // read vector B
    localparam SUM =        2'b10;      // calculate A + B
    localparam AVG =        2'b11;      // calculate (A + B)/2
    
    // Commands with scalar type result
    localparam EUC_DIST =   1'b0;       // calculate euclidian distance
    localparam MAN_DIST =   1'b1;       // calculate manhattan distance
           
    logic [1:0] state, next_state;      // general state
    logic [1:0] instate, next_instate;  // internal state
    logic [1:0] command, next_command;  // received operation command
    logic [9:0] byte_num, next_num;     // max number for counting
    logic [9:0] read_addr, next_addr;   // bram reading address
    logic [7:0] tx_byte;                // uart byte to transmit
    logic [15:0] euc_distance, scalar_out; 
    //logic [7:0] read_byteA, read_byteB;
    logic send_signal;                  // uart tx send signal
    logic ready, next_ready;            // done processing command signal (pulse)
    
    //assign read_byteA = bramA_byte;
    //assign read_byteB = bramB_byte;
    assign bram_addr = read_addr;
    assign tx_output = tx_byte;
    assign scalar_output = scalar_out;
    assign send = send_signal;
    assign done = ready;
    
    logic [7:0] sum_byte, avg_byte;
    logic [7:0] byte_distance;
    logic [15:0] distance_product;
    logic [25:0] scalar_result, next_scalar;
    logic root_en, root_flag;
    
    assign sum_byte = bramA_byte[7:0] + bramB_byte[7:0];
    assign avg_byte = sum_byte[7:0] >> 1; 
    assign distance_product[15:0] = byte_distance * byte_distance;
        
    always_ff @ (posedge clk) begin
        if (reset == 1'b1) begin
            state <= IDLE;
            instate <= INIT;
            command <= READ_A;
            byte_num <= NBytes - 1;
            read_addr <= 10'd0;
            ready <= 1'b0;
            scalar_result <= 26'b0;
        end
        else begin
            state <= next_state;
            instate <= next_instate;
            command <= next_command;
            byte_num <= next_num;
            read_addr <= next_addr;
            ready <= next_ready;
            scalar_result <= next_scalar;
        end
    end
    
    
    always_comb begin           // processing and transmission logic
    // scalar results processing
        if (bramA_byte >= bramB_byte)
            byte_distance = bramA_byte - bramB_byte;
        else 
            byte_distance = bramB_byte - bramA_byte;
        if (command[0] == 1'b1)
            scalar_out = scalar_result;
        else
            scalar_out = euc_distance;
    // default values
        next_state = state;
        next_instate = instate;
        next_command = command;
        next_num = byte_num;
        next_addr = read_addr;
        next_ready = 1'b0;
        tx_byte = 8'd0;
        send_signal = 1'b0;
        next_scalar = scalar_result;
        root_en = 1'b0;
        
        case (state)
            IDLE: begin
                next_scalar = 26'd0;
                if (result[3] == 1'b1) begin        // command received signal (pulse)
                    next_command = result[1:0];
                    next_num = NBytes - 1;
                    if (result[2] == 1'b1) begin    // command result type (vector or scalar)
                        next_state = VECTOR;
                        next_instate = BYTE_SEND;
                    end
                    else begin
                        next_state = SCALAR;
                        next_instate = INIT;
                        next_addr = read_addr + 10'd1;
                    end
                end 
            end
            VECTOR: begin
                case (command[1:0])
                    READ_A: tx_byte = bramA_byte;
                    READ_B: tx_byte = bramB_byte;
                    SUM: tx_byte = sum_byte;
                    AVG: tx_byte = avg_byte;
                endcase
            end
            SCALAR: begin
                if (command[0] == 1'b0)
                    root_en = 1'b1;
            end            
        endcase
        
        case (instate)
            INIT: begin
                if (state == SCALAR) begin
                    next_instate = BYTE_READ;
                    next_addr = read_addr + 10'd1;
                end
            end
            BYTE_SEND: begin
                next_instate = BYTE_WAIT;
                send_signal = 1'b1;
                if (state == SCALAR) begin
                    if (read_addr[0] == 1'b0)
                        tx_byte = scalar_out[15:8];
                    else
                        tx_byte = scalar_out[7:0];
                end
                if (read_addr == byte_num)
                    next_addr = 10'd0;
                else
                    next_addr = read_addr + 10'd1;
            end
            BYTE_WAIT: begin
                if (tx_flag) begin
                    if (read_addr == 10'd0) begin
                        next_instate = INIT;
                        next_state = IDLE;
                        next_ready = 1'b1;
                        //next_addr = 10'd0;
                    end
                    else 
                        next_instate = BYTE_SEND;
                end
            end
            BYTE_READ: begin
                if (command[0] == 1'b1)
                    next_scalar = scalar_result + {18'd0, byte_distance};
                else
                    next_scalar = scalar_result + {10'd0, distance_product};
                case (read_addr)
                    byte_num: next_addr = 10'd0;
                    10'd1: begin
                        next_instate = BYTE_SEND;
                        next_num  = 10'd1;
                        next_addr = 10'd0;
                    end
                    default: next_addr = read_addr + 10'd1;
                endcase
            end
        endcase
    end
    
    cordic_0 square_root (
        .s_axis_cartesian_tvalid(root_en),  // input wire s_axis_cartesian_tvalid
        .s_axis_cartesian_tdata({6'd0, scalar_result}),    // input wire [31 : 0] s_axis_cartesian_tdata
        .m_axis_dout_tvalid(root_flag),            // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata(euc_distance)              // output wire [15 : 0] m_axis_dout_tdata
    );

endmodule
