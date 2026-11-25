`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/27/2026 03:18:32 PM
// Design Name: 
// Module Name: Axi4LiteManager
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
// Axi4Lite Manager module declaration
////////////////////////////////////////////////////////////////
module Axi4LiteManager # 
    (parameter C_M_AXI_ADDR_WIDTH = 8, C_M_AXI_DATA_WIDTH = 32)
    (
        // Simple Bus
        input  logic    [C_M_AXI_ADDR_WIDTH-1:0] wrAddr,
        input  logic    [C_M_AXI_DATA_WIDTH-1:0] wrData,
        input  logic    wr,
        output  logic   wrDone,
        input  logic    [C_M_AXI_ADDR_WIDTH-1:0] rdAddr,
        output logic    [C_M_AXI_DATA_WIDTH-1:0] rdData,
        input  logic    rd,
        output  logic   rdDone,
        // Axi4Lite Bus
        input  logic    M_AXI_ACLK,
        input  logic    M_AXI_ARESETN,
        output logic    [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
        output logic    M_AXI_AWVALID,
        input  logic    M_AXI_AWREADY,
        output logic    [C_M_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
        output logic    [3:0] M_AXI_WSTRB,
        output logic    M_AXI_WVALID,
        input  logic    M_AXI_WREADY,
        output logic    [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
        output logic    M_AXI_ARVALID,
        input  logic    M_AXI_ARREADY,
        input  logic    [C_M_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
        input  logic    [1:0] M_AXI_RRESP,
        input  logic    M_AXI_RVALID,
        output logic    M_AXI_RREADY,
        input  logic    [1:0] M_AXI_BRESP,
        input  logic    M_AXI_BVALID,
        output logic    M_AXI_BREADY
    );
    
    // FSM states
    typedef enum logic [3:0] {IDLE, WR1, WR2, WR3, WR4, RD1, RD2} statetype;
    statetype nextState, currState;
    
    // Write Flops
    logic [C_M_AXI_ADDR_WIDTH-1:0] wrAddrD, wrAddrQ;
    logic [C_M_AXI_DATA_WIDTH-1:0] wrDataD, wrDataQ;
    
    // Read Flop
    logic [C_M_AXI_ADDR_WIDTH-1:0] rdAddrD, rdAddrQ;
    logic [C_M_AXI_DATA_WIDTH-1:0] rdDataD, rdDataQ;
    
    // Sequential Logic
    always_ff @ (posedge M_AXI_ACLK) begin
        if(!M_AXI_ARESETN) begin
            currState <= IDLE;
            wrAddrQ <= 0;
            wrDataQ <= 0;
            rdAddrQ <= 0;
            rdDataQ <= 0;
        end else begin
            currState <= nextState;
            wrAddrQ <= wrAddrD;
            wrDataQ <= wrDataD;
            rdAddrQ <= rdAddrD;
            rdDataQ <= rdDataD;
        end
    end
    
    always_comb begin
        nextState = currState;
        M_AXI_AWADDR = 0;
        M_AXI_AWVALID = 0;
        M_AXI_WDATA = 0;
        M_AXI_WVALID = 0;
        M_AXI_WSTRB = 4'b1111;
        M_AXI_BREADY = 0;
        M_AXI_RREADY = 0;
        M_AXI_ARVALID = 0;
        M_AXI_ARADDR = 0;
        wrDataD = wrDataQ;
        wrAddrD = wrAddrQ;
        wrDone = 0;
        rdAddrD = rdAddrQ;
        rdDataD = rdDataQ;
        rdData = 0;
        rdDone = 0;
        // TODO: Finish read states
        case(currState)
            IDLE: begin
                if (wr ^ rd) begin
                    if (wr) begin
                        wrDataD = wrData;
                        wrAddrD = wrAddr;
                        nextState = WR1;
                    end
                    else if (rd) begin
                        rdAddrD = rdAddr;
                        nextState = RD1;
                    end
                end
            end
            WR1: begin
                M_AXI_AWADDR = wrAddrQ;
                M_AXI_AWVALID = 1;
                M_AXI_WDATA = wrDataQ;
                M_AXI_WVALID = 1;
                if (M_AXI_AWREADY & M_AXI_WREADY) begin
                    nextState = WR2;
                end
            end
            WR2: begin
                nextState = WR3;
            end
            WR3: begin
                nextState = WR4;
            end
            WR4: begin
                M_AXI_BREADY = 1;
                wrDone = 1;
                nextState = IDLE;
            end
            RD1: begin
                M_AXI_ARADDR = rdAddrQ;
                M_AXI_ARVALID = 1;
                if (M_AXI_ARREADY) begin
                    nextState = RD2;
                end
            end
            RD2: begin
                if(M_AXI_RVALID) begin
                    M_AXI_RREADY = 1;
                    rdData = M_AXI_RDATA;
                    rdDone = 1;
                    nextState = IDLE;
                end
            end
            default: begin
                nextState = IDLE;
            end
        endcase
    end
endmodule
