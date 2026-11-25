`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2026 01:36:23 PM
// Design Name: 
// Module Name: spi_controller
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


module spi_controller(
    // Simple bus signals
    input logic clk, wr, rd,
    input logic [5:0] wrAddr, rdAddr,
    input logic [31:0] wrData,
    output logic [31:0] rdData,
    // SPI bus signals
    input logic SDO,
    output logic SCK, CONV, SDI
    );
    
    // Address map
    localparam ENABLE_ADDR = 6'h04;
    localparam DATA_WIDTH_CONFIG_ADDR = 6'h08;
    localparam CLOCK_PER_SAMPLE_CONFIG_ADDR = 6'h0C;
    localparam READ_WRITE_ADDR = 6'h10;
    
    // Signal to MicroBlaze that a response isn't ready yet
    localparam NOT_DONE_SIGNAL = 32'h00010000;
    
    // Constant counter durations
    localparam INIT_CYCLES = 4;
    localparam SCK_CYCLES = 2;
    localparam S1_CYCLES = 3;
    localparam S2_CYCLES = 5;
    
    // Buffers for inputs and outputs
    localparam ADC_BITS_MAX = 16;
    localparam DAC_BITS_MAX = 24;
    logic SDO_BUFFER [ADC_BITS_MAX];
    logic SDI_BUFFER [DAC_BITS_MAX];
    logic IN_EN, OUT_EN;
    
    // Count signals
    logic [1:0] SCK_COUNT;
    logic [2:0] INIT_COUNT, S1_COUNT, S2_COUNT;
    logic [4:0] SAMPLED_BITS_D, SAMPLED_BITS_Q;
    logic [14:0] CONV_COUNT;
    
    // Enable signals for counters
    logic EN_D, EN_Q, SCK_COUNT_EN, INIT_COUNT_EN, S1_COUNT_EN, S2_COUNT_EN;
    
    // FSM states
    typedef enum logic [3:0] {IDLE, INIT, S1, S2, FINAL_CYCLE} Statetype;
    Statetype state, nextState;
    
    // Configuration variables
    logic [14:0] CONV_CYCLES_D, CONV_CYCLES_Q;
    logic [4:0] DATA_SIZE_D, DATA_SIZE_Q;
    
    // Counter instantiations
    counter #(.WIDTH(3)) init_counter(
        .clk(clk), .en(INIT_COUNT_EN), .MAX_COUNT(INIT_CYCLES), .count(INIT_COUNT)
    );
    
    counter #(.WIDTH(2)) sck_counter(
        .clk(clk), .en(SCK_COUNT_EN), .MAX_COUNT(SCK_CYCLES), .count(SCK_COUNT)
    );
    
    counter #(.WIDTH(3)) s1_counter(
        .clk(clk), .en(S1_COUNT_EN), .MAX_COUNT(S1_CYCLES), .count(S1_COUNT)
    );
    
    counter #(.WIDTH(3)) s2_counter (
        .clk(clk), .en(S2_COUNT_EN), .MAX_COUNT(S2_CYCLES), .count(S2_COUNT)
    );
    
    counter #(.WIDTH(15)) conv_counter(
        .clk(clk), .en(EN_Q), .MAX_COUNT(CONV_CYCLES_Q), .count(CONV_COUNT)
    );
    
        
    always_ff @(posedge clk) begin
        // Write to configurable variables with MicroBlaze
        if(wr && wrAddr == READ_WRITE_ADDR && state == IDLE) begin
           for(integer i = DAC_BITS_MAX-1; i >= 0; i--) begin
              SDI_BUFFER[DAC_BITS_MAX-1-i] <= wrData[i];
           end
        end
        
        // flip flops 
        state <= nextState;
        DATA_SIZE_Q <= DATA_SIZE_D;
        SAMPLED_BITS_Q <= SAMPLED_BITS_D;
        CONV_CYCLES_Q <= CONV_CYCLES_D;
        EN_Q <= EN_D;
        
        // writing to sdi with shift register
        if(OUT_EN) begin
            SDI <= SDI_BUFFER[0];
            for(integer i = 0; i < DAC_BITS_MAX-1; i++) begin
                SDI_BUFFER[i] <= SDI_BUFFER[i+1];
            end
        end
        
        // getting input from sdo with shift register
        if(IN_EN) begin
            for(integer i = 0; i < ADC_BITS_MAX-1; i++) begin
                SDO_BUFFER[i+1] <= SDO_BUFFER[i];
            end
            SDO_BUFFER[0] <= SDO;
        end
        
        // change sck every 3 clock cycles
        if(state != IDLE) begin
            if (SCK_COUNT == SCK_CYCLES-1) begin
                SCK <= ~SCK;
            end
        end else begin
            SCK <= 0; // set sck to 0 in IDLE
        end
        
        
    end
    
    always_comb begin
        // default value
        EN_D = EN_Q;
        INIT_COUNT_EN = 0;
        S1_COUNT_EN = 0;
        S2_COUNT_EN = 0;
        SCK_COUNT_EN = 0;
        IN_EN = 0;
        OUT_EN = 0;
        CONV = 1;
        
        // flops
        nextState = state;
        SAMPLED_BITS_D = SAMPLED_BITS_Q;
        CONV_CYCLES_D = CONV_CYCLES_Q;
        DATA_SIZE_D = DATA_SIZE_Q;
        
        // Manager write signals
        if(wr && wrAddr == DATA_WIDTH_CONFIG_ADDR) begin
            DATA_SIZE_D = wrData[4:0];
        end
        if(wr && wrAddr == CLOCK_PER_SAMPLE_CONFIG_ADDR) begin
            CONV_CYCLES_D = wrData[14:0];
        end
        if(wr && wrAddr == ENABLE_ADDR) begin
            EN_D = wrData[0];
        end
        
        // FSM
        case(state)
            IDLE: begin
                if(CONV_COUNT == CONV_CYCLES_Q) begin
                    CONV = 0;
                    nextState = INIT;
                    OUT_EN = 1; // write C3 in the next clock cycle
                    SAMPLED_BITS_D = 0;
                end
            end
            
            INIT: begin
                CONV = 0;
                INIT_COUNT_EN = 1;
                SCK_COUNT_EN = 1;
                if(INIT_COUNT == INIT_CYCLES-1) begin
                    IN_EN = 1; // Sample B15 in the next clock cycle
                end
                if(INIT_COUNT == INIT_CYCLES) begin
                    nextState = S1;
                    SAMPLED_BITS_D = SAMPLED_BITS_D + 1;
                    OUT_EN = 1; // Write C2 in the next clock cycle
                end
            end
            
            S1: begin
                CONV = 0;
                SCK_COUNT_EN = 1;
                S1_COUNT_EN = 1;
                
                if(S1_COUNT == S1_CYCLES - 1) begin
                    IN_EN = 1; // Sample B14 in the next clock cycle
                end
                
                if(S1_COUNT == S1_CYCLES) begin
                    nextState = S2;
                    SAMPLED_BITS_D = SAMPLED_BITS_D + 1;
                end
            end
            
            S2: begin
                CONV = 0;
                SCK_COUNT_EN = 1;
                S2_COUNT_EN = 1;
                
                if (S2_COUNT == S2_CYCLES - 4) begin // S2_COUNT == 1
                    OUT_EN = 1; // Write next bit to SDI after appropriate delay
                end
                
                if (S2_COUNT == S2_CYCLES-1) begin // S2_COUNT == 4
                    IN_EN = 1; // sample next bit from SDO in next clock cycle
                end
                
                if (S2_COUNT == S2_CYCLES) begin 
                    SAMPLED_BITS_D = SAMPLED_BITS_D + 1; // incrememnt sampled bits every 6 clock cycles (1 cycle of sck)
                    
                    if (SAMPLED_BITS_D >= DATA_SIZE_Q) begin // go to idle once we sample enough bits
                        nextState = FINAL_CYCLE;
                    end
                end
            end
            
            FINAL_CYCLE: begin
                CONV = 0;
                SCK_COUNT_EN = 1;
                if(SCK_COUNT == SCK_CYCLES - 2) begin
                    nextState = IDLE;
                end
            end
           
            default: begin // runs at start of program 
                nextState = IDLE;
                CONV_CYCLES_D = 30030; // maximum possible value of CONV_CYCLES as default
                EN_D = 0;
                SCK_COUNT_EN = 0;
                S1_COUNT_EN = 0;
                S2_COUNT_EN = 0;
                INIT_COUNT_EN = 0;
            end
        endcase
        
        // Writeback logic
        if(rd) begin
            if(SAMPLED_BITS_Q == DATA_SIZE_Q) begin
                // Write the valid data over the simple bus
                for(integer i = 0; i < 32; i++) begin
                    if(i < DATA_SIZE_Q) begin
                        rdData[i] = SDO_BUFFER[i];
                        if (i == DATA_SIZE_Q-1) begin // flip highest bit
                            rdData[i] = rdData[i] ^ 1'b1;
                        end
                    end
                    else begin
                        rdData[i] = 0;
                    end
                end
            end
            else rdData = NOT_DONE_SIGNAL;
        end
        else rdData = NOT_DONE_SIGNAL;
    end
endmodule
