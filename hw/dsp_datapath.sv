`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2026 03:39:13 PM
// Design Name: 
// Module Name: fir_filter
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


module dsp_datapath #(parameter WORD_SIZE = 16, FILTER_SIZE = 279, ADDR_WIDTH = 9, BUS_DATA_WIDTH = 32)(
    input logic CLK, 
    input logic [ADDR_WIDTH-1:0] WR_ADDR, RD_ADDR,
    input logic signed [BUS_DATA_WIDTH-1:0] WR_DATA,
    output logic signed [BUS_DATA_WIDTH-1:0] RD_DATA,
    input logic WR, RD
    );
    localparam int D_WORD_SIZE = WORD_SIZE * 2;
    //filter write addresses + 13 
    localparam [8:0] RESET_ADDR = 9'h000;
    localparam [8:0] CONVOLUTION_ADDR = 9'h001;
    localparam [8:0] CONVOLUTION_ADDR_RIGHT = 9'h002;
    localparam [8:0] CHANNEL_SEL_ADDR = 9'h003;
    localparam [8:0] BUFFER_WRITE_ADDR = 9'h004;
    localparam [8:0] BUFFER_WRITE_ADDR_RIGHT = 9'h005;
    localparam [8:0] FILTER_SEL_ADDR = 9'h006;
    localparam [8:0] FILTER_WRITE_ADDR = 9'h010; // Address for writing to filter 
    localparam [8:0] ATTEN_FACTOR_WRITE_ADDR = 9'h020; // Address for writing attenuation factors
    localparam [31:0] NOT_DONE_SIGNAL = 32'h00010000; // Signal to Microblaze that convolution is not done yet. This value is beyond the dynamic range of a 16-bit number so it's an impossible value for a valid fitler output
    
    logic signed [WORD_SIZE-1:0] FILTER_IN [0:12];
    logic signed [WORD_SIZE-1:0] BUFFER_LEFT, BUFFER_RIGHT, BUFFER_OP;
    logic signed [WORD_SIZE-1:0] DATA_IN, DATA_OUT;
    logic [ADDR_WIDTH-1:0] i, j, i_new, j_new, circ_index, circ_index_new, circ_index_right, circ_index_right_new, ADDR_COMP;
    logic [ADDR_WIDTH-1:0] i_right, i_right_new;
    
    //buffer addresses for each channel 
    logic [ADDR_WIDTH-1:0] BUFFER_ADDR, BUFFER_ADDR1; 
    
    //coeff addresses for the 13 bands 
    logic signed [ADDR_WIDTH-1:0] coeff [0:12];
    logic signed [ADDR_WIDTH-1:0] coeff_new [0:12];
    
    logic signed [WORD_SIZE-1:0] atten_factors[0:12];
    logic signed [WORD_SIZE-1:0] atten_factors_new[0:12];
    
    logic signed [D_WORD_SIZE-1:0] prod [0:12];
    logic signed [D_WORD_SIZE-1:0] sum [0:12];
    logic signed [D_WORD_SIZE-1:0] sum_new [0:12];
    logic signed [D_WORD_SIZE-1:0] sum_next [0:12];
    logic signed [WORD_SIZE-1:0] FILTER_OUT [0:12];
    logic signed [D_WORD_SIZE-1:0] ATTEN_OUT [0:12];
    logic signed [D_WORD_SIZE-1:0] RAW_OUTPUT;
    
    //selecting between the all 13 filters
    logic [3:0] filter_sel, filter_sel_new;
    logic channel_sel, channel_sel_new;
    logic buffer_sel, buffer_sel_new;
    logic RESET;
    
    //WE signals for every coeff ram
    logic WE_FILTER [0:12];
    logic WE_BUFFER, WE_BUFFER1; 
    
    //WR signals for every coeff ram
    logic signed [WORD_SIZE-1:0] WR_FILTER [0:12];
    logic signed [WORD_SIZE-1:0] WR_BUFFER_LEFT, WR_BUFFER_RIGHT; 
   
    //filter is coeff and buffer is samples     
    typedef enum logic[3:0] {IDLE, MAC, WRITE_FILTER, WRITE_BUFFER, WRITEBACK} statetype;
    statetype currState, nextState;
    
    // Assign input and output signals
    assign DATA_IN = WR_DATA[WORD_SIZE-1:0];
    assign RD_DATA = RD ? ((currState != WRITEBACK) ? NOT_DONE_SIGNAL : {{16{DATA_OUT[15]}}, DATA_OUT}) : 0; // Sends NOT_DONE_SIGNAL if Microblaze attempts to read when the filter is not done
    assign RESET = WR && (WR_ADDR == RESET_ADDR) ? 1 : 0; // LSB of WR_ADDR should be set to trigger a reset
    
    // Memories
    genvar g;
    generate
        for(g = 0; g < 13; g++) begin 
            ram #(.RAM_WIDTH(WORD_SIZE), .RAM_ADDR_BITS(ADDR_WIDTH), .MEM_SIZE(FILTER_SIZE)) filter0( //coeff0 
                .CLK(CLK), 
                .WE(WE_FILTER[g]), 
                .ADDR(coeff[g]), //j 
                .WR_DATA(WR_FILTER[g]), 
                .RD_DATA(FILTER_IN[g])
            );
        end 
    endgenerate
    
    
    ram #(.RAM_WIDTH(WORD_SIZE), .RAM_ADDR_BITS(ADDR_WIDTH), .MEM_SIZE(FILTER_SIZE)) buffer1( //channel 1
        .CLK(CLK), 
        .WE(WE_BUFFER), 
        .ADDR(BUFFER_ADDR), 
        .WR_DATA(WR_BUFFER_LEFT), 
        .RD_DATA(BUFFER_LEFT)
    );
    
    ram #(.RAM_WIDTH(WORD_SIZE), .RAM_ADDR_BITS(ADDR_WIDTH), .MEM_SIZE(FILTER_SIZE)) buffer2( //channel 2
        .CLK(CLK), 
        .WE(WE_BUFFER1), 
        .ADDR(BUFFER_ADDR1), 
        .WR_DATA(WR_BUFFER_RIGHT), 
        .RD_DATA(BUFFER_RIGHT)
    );
    
    // Sequential Logic
    always_ff @(posedge CLK) begin
        if(RESET) begin
            i <= 0;
            i_right <= 0;
            j <= 0;
            
            for(int k = 0; k < 13; k++) begin
                coeff[k] <= 0;
            end
            
            for(int i = 0; i < 13; i++) begin
                sum[i] <= 0;
            end
            currState <= IDLE;
            circ_index <= 0;
            circ_index_right <= 0;
            filter_sel <= 0;
            channel_sel <= 0;
            buffer_sel <= 0;
        end
        else begin
            i <= i_new;
            i_right <= i_right_new;
            j <= j_new;
            
            for(int k = 0; k < 13; k++) begin
                coeff[k] <= coeff_new[k];
            end
            
            sum <= sum_new;
            currState <= nextState;
            circ_index <= circ_index_new;
            circ_index_right <= circ_index_right_new;
            filter_sel <= filter_sel_new;
            channel_sel <= channel_sel_new;
            buffer_sel <= buffer_sel_new;
        end
        
        for(int i = 0; i < 13; i++) begin
            atten_factors[i] = atten_factors_new[i];
        end
    end
    
    // Arithmetic Logic
    assign BUFFER_OP = !j ? DATA_IN : (channel_sel ? BUFFER_RIGHT : BUFFER_LEFT);
    assign ADDR_COMP = WR_ADDR[8:0];
    always_comb begin
        RAW_OUTPUT = '0;
        for(int i = 0; i < 13; i++) begin
            prod[i] = FILTER_IN[i] * BUFFER_OP;
            sum_next[i] = prod[i] + sum[i];
            FILTER_OUT[i] = ((sum[i] >> 14) + 1) >> 1;
            ATTEN_OUT[i] = atten_factors[i] * FILTER_OUT[i];
            RAW_OUTPUT = RAW_OUTPUT + ATTEN_OUT[i];
        end
    end
    
    assign DATA_OUT = ((RAW_OUTPUT >> 13) + 1) >> 1;
    
//    assign prod = FILTER_IN[filter_sel] * BUFFER_OP;
//    assign sum_next = prod + sum;
//    assign ADDR_COMP = WR_ADDR[5:0];
//    assign DATA_OUT = ((sum >> 14) + 1) >> 1;
    
    // Next State Logic
    always_comb begin
        i_new = 0;
        i_right_new = 0;
        j_new = 0;
        circ_index_new = circ_index;
        circ_index_right_new = circ_index_right;
        filter_sel_new = filter_sel;
        channel_sel_new = channel_sel;
        buffer_sel_new = buffer_sel;
        nextState = currState;
        
        for(int k = 0; k < 13; k++) begin
            WE_FILTER[k] = 0;
            WR_FILTER[k] = 0;
            coeff_new[k] = coeff[k];
        end
        
        WE_BUFFER = 0;
        WE_BUFFER1 = 0;
        WR_BUFFER_LEFT = 0;
        WR_BUFFER_RIGHT = 0;
        BUFFER_ADDR = i;
        BUFFER_ADDR1 = i_right;
        for(int i = 0; i < 13; i++) begin
            sum_new[i] = 0;
        end
        case(currState)
            IDLE: begin
                if(WR) begin
                    if (ADDR_COMP == FILTER_WRITE_ADDR) begin
                        automatic int bandIndex = filter_sel;
                        WE_FILTER[bandIndex] = 1;
                        WR_FILTER[bandIndex] = DATA_IN;
                        j_new = 1;
                        filter_sel_new = bandIndex;
                        coeff_new[bandIndex] = j_new;
                        nextState = WRITE_FILTER;
                    end
                    else begin
                        case(ADDR_COMP)
                            BUFFER_WRITE_ADDR: begin
                                buffer_sel_new = 1'b0;
                                WE_BUFFER = 1;
                                WR_BUFFER_LEFT = DATA_IN;
                                i_new = 0;
                                nextState = WRITE_BUFFER;
                            end
                            BUFFER_WRITE_ADDR_RIGHT: begin
                                buffer_sel_new = 1'b1;
                                WE_BUFFER1 = 1;
                                WR_BUFFER_RIGHT = DATA_IN;
                                i_right_new = 0;
                                nextState = WRITE_BUFFER;
                            end
                            FILTER_SEL_ADDR: begin
                                filter_sel_new = DATA_IN[3:0];
                            end
                            CONVOLUTION_ADDR: begin
                                channel_sel_new = 1'b0;
                                j_new = 1;
                                i_new = circ_index > 0 ? circ_index - 1 : FILTER_SIZE - 1;
                                BUFFER_ADDR = circ_index;
                                sum_new = sum_next;
                                WE_BUFFER = 1;
                                WR_BUFFER_LEFT = DATA_IN;
                                nextState = MAC;
                                for(int k = 0; k < 13; k++) begin
                                    coeff_new[k] = j_new;
                                end
                            end
                            CONVOLUTION_ADDR_RIGHT: begin
                                channel_sel_new = 1'b1;
                                j_new = 1;
                                i_right_new = circ_index_right > 0 ? circ_index_right - 1 : FILTER_SIZE - 1;
                                BUFFER_ADDR1 = circ_index_right;
                                sum_new = sum_next;
                                WE_BUFFER1 = 1;
                                WR_BUFFER_RIGHT = DATA_IN;
                                nextState = MAC;
                                for(int k = 0; k < 13; k++) begin
                                    coeff_new[k] = j_new;
                                end
                            end
                            default: begin
                                // Do nothing else
                            end
                        endcase
                    end
                end 
            end
            WRITE_FILTER: begin
                if(WR) begin
                    automatic int bandIndex = filter_sel;
                    j_new = j + 1;
                    WE_FILTER[bandIndex] = 1;
                    WR_FILTER[bandIndex] = DATA_IN;
                    coeff_new[bandIndex] = j_new;
                    nextState = j_new < FILTER_SIZE ? WRITE_FILTER : IDLE;
                    if(nextState == IDLE) begin
                        coeff_new[bandIndex] = 0;
                    end
                end
                else begin
                    j_new = j;
                end
            end
            WRITE_BUFFER: begin
                if(WR) begin
                    if(!buffer_sel) begin
                        i_new = i + 1;
                        WE_BUFFER = 1;
                        WR_BUFFER_LEFT = DATA_IN;
                        nextState = i_new < FILTER_SIZE ? WRITE_BUFFER : IDLE;
                    end else begin 
                        i_right_new = i_right + 1;
                        WE_BUFFER1 = 1;
                        WR_BUFFER_RIGHT = DATA_IN;
                        nextState = i_right_new < FILTER_SIZE ? WRITE_BUFFER : IDLE;
                    end
                end
                else begin
                    i_new = i;
                    i_right_new = i_right;
                end
            end
            MAC: begin
                sum_new = sum_next;
                j_new = j + 1;
                if(channel_sel) begin
                    i_right_new = i_right > 0 ? i_right - 1: FILTER_SIZE - 1;
                    i_new = i;
                end else begin
                    i_new = i > 0 ? i - 1: FILTER_SIZE - 1;
                    i_right_new = i_right;
                end
                BUFFER_ADDR = i;
                BUFFER_ADDR1 = i_right;
                
                for(int k = 0; k < 13; k++) begin
                    coeff_new[k] = j_new;
               end
               nextState = j_new < FILTER_SIZE ? MAC : WRITEBACK; 
            end
            WRITEBACK: begin
                if(RD && ((RD_ADDR == CONVOLUTION_ADDR && !channel_sel) || (RD_ADDR == CONVOLUTION_ADDR_RIGHT && channel_sel))) begin
                    if(channel_sel) begin
                        circ_index_right_new = circ_index_right < FILTER_SIZE - 1 ? circ_index_right + 1 : 0;
                    end else begin
                        circ_index_new = circ_index < FILTER_SIZE - 1 ? circ_index + 1 : 0;
                    end
                    for(int k = 0; k < 13; k++) begin
                        coeff_new[k] = '0;
                    end
                    nextState = IDLE;
                    i_new = 0;
                    j_new = 0;
                end
                else begin
                    sum_new = sum;
                end
            end
            default: begin
                nextState = IDLE;
            end
        endcase
        
        if(ADDR_COMP == ATTEN_FACTOR_WRITE_ADDR) begin
            automatic int idx = filter_sel;
            atten_factors_new[idx] = DATA_IN;
        end
    end
    
endmodule
