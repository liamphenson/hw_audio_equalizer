`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2026 02:24:59 PM
// Design Name: 
// Module Name: Axi4LiteRegs
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


////////////////////////////////////////////////////////////////
// Axi4Lite Supporter module declaration
////////////////////////////////////////////////////////////////
module Axi4LiteSupporter # 
    (parameter C_S_AXI_ADDR_WIDTH = 6, C_S_AXI_DATA_WIDTH = 32)
    (
        // Simple Bus
        output logic  [C_S_AXI_ADDR_WIDTH-1:0] wrAddr,
        output logic  [C_S_AXI_DATA_WIDTH-1:0] wrData,
        output logic  wr,
        output logic  [C_S_AXI_ADDR_WIDTH-1:0] rdAddr,
        input  logic  [C_S_AXI_DATA_WIDTH-1:0] rdData,
        output logic  rd,
        // Axi4Lite Bus
        input  logic  S_AXI_ACLK,
        input  logic  S_AXI_ARESETN,
        input  logic  [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
        input  logic  S_AXI_AWVALID,
        output logic  S_AXI_AWREADY,
        input  logic  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
        input  logic  [3:0] S_AXI_WSTRB,
        input  logic  S_AXI_WVALID,
        output logic  S_AXI_WREADY,
        input  logic  [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
        input  logic  S_AXI_ARVALID,
        output logic  S_AXI_ARREADY,
        output logic  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
        output logic  [1:0] S_AXI_RRESP,
        output logic  S_AXI_RVALID,
        input  logic  S_AXI_RREADY,
        output logic  [1:0] S_AXI_BRESP,
        output logic  S_AXI_BVALID,
        input  logic  S_AXI_BREADY
    );
    // TODO: Implement supporter
    
    // FSM states
    typedef enum logic [3:0] {IDLE, WR1, WR2, RD} statetype;
    statetype nextState, currState;
    
    // Write Flops
    logic [C_S_AXI_ADDR_WIDTH-1:0] wrAddrD, wrAddrQ;
    logic [C_S_AXI_DATA_WIDTH-1:0] wrDataD, wrDataQ;
    
    // Read Flop
    logic [C_S_AXI_DATA_WIDTH-1:0] rdDataD, rdDataQ;
    
    // Sequential Logic
    always_ff @ (posedge S_AXI_ACLK) begin
        if(!S_AXI_ARESETN) begin
            currState <= IDLE;
            wrAddrQ <= 0;
            wrDataQ <= 0;
            rdDataQ <= 0;
        end else begin
            currState <= nextState;
            wrAddrQ <= wrAddrD;
            wrDataQ <= wrDataD;
            rdDataQ <= rdDataD;
        end
    end
    
    always_comb begin
        nextState = currState;
        S_AXI_AWREADY = 0;
        S_AXI_WREADY = 0;
        S_AXI_BVALID = 0;
        S_AXI_ARREADY = 0;
        S_AXI_RVALID = 0;
        S_AXI_RDATA = 0;
        S_AXI_BRESP = 2'b00;
        S_AXI_RRESP = 2'b00;
        wrDataD = wrDataQ;
        wrAddrD = wrAddrQ;
        rdDataD = rdDataQ;
        wr = 0;
        wrAddr = 0;
        wrData = 0;
        rdAddr = 0;
        rd = 0;
        case(currState)
            IDLE: begin
                if(S_AXI_AWVALID & S_AXI_WVALID) begin
                    S_AXI_AWREADY = 1;
                    S_AXI_WREADY = 1;
                    wrDataD = S_AXI_WDATA;
                    wrAddrD = S_AXI_AWADDR;
                    nextState = WR1;
                end
                else if(S_AXI_ARVALID) begin
                    rdAddr = S_AXI_ARADDR;
                    rdDataD = rdData;
                    S_AXI_ARREADY = 1;
                    rd = 1;
                    nextState = RD;
                end
            end
            WR1: begin
                wrAddr = wrAddrQ;
                wrData = wrDataQ;
                wr = 1;
                nextState = WR2;
            end
            WR2: begin
                S_AXI_BRESP = 2'b00;
                S_AXI_BVALID = 1;
                if(S_AXI_BREADY) begin
                    nextState = IDLE;
                end
            end
            RD: begin
                S_AXI_RVALID = 1;
                if(S_AXI_RREADY) begin
                    S_AXI_RDATA = rdDataQ;
                    S_AXI_RRESP = 2'b00;
                    nextState = IDLE;
                end
            end
            default: begin
                nextState = IDLE;
            end
        endcase
    end
endmodule