`timescale 1ns/1ps

module Axi4Lite_dsp_datapath #(
    parameter C_S_AXI_ADDR_WIDTH = 9,
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter WORD_SIZE = 16,
    parameter FILTER_SIZE = 279,
) (
    // Axi4Lite Bus
    input logic S_AXI_ACLK,
    input logic S_AXI_ARESETN,
    input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input logic S_AXI_AWVALID,
    output logic S_AXI_AWREADY,
    input logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input logic [3:0] S_AXI_WSTRB,
    input logic S_AXI_WVALID,
    output logic S_AXI_WREADY,
    input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input logic S_AXI_ARVALID,
    output logic S_AXI_ARREADY,
    output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [1:0] S_AXI_RRESP,
    output logic S_AXI_RVALID,
    input logic S_AXI_RREADY,
    output logic [1:0] S_AXI_BRESP,
    output logic S_AXI_BVALID,
    input logic S_AXI_BREADY
);
    // Simple Bus Signals
    logic wr, rd;
    logic signed [C_S_AXI_ADDR_WIDTH-1:0] wrAddr, rdAddr;
    logic signed [C_S_AXI_DATA_WIDTH-1:0] wrData, rdData;

    Axi4LiteSupporter #(
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH), 
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
    ) Axi4LiteSupporter1 (
        // Simple Bus
        .wrAddr(wrAddr),                    // output   [C_S_AXI_ADDR_WIDTH-1:0]
        .wrData(wrData),                    // output   [C_S_AXI_DATA_WIDTH-1:0]
        .wr(wr),                            // output
        .rdAddr(rdAddr),                    // output   [C_S_AXI_ADDR_WIDTH-1:0]
        .rdData(rdData),                    // input    [C_S_AXI_ADDR_WIDTH-1:0]
        .rd(rd),                            // output   
        // Axi4Lite Bus
        .S_AXI_ACLK(S_AXI_ACLK),            // input
        .S_AXI_ARESETN(S_AXI_ARESETN),      // input
        .S_AXI_AWADDR(S_AXI_AWADDR),        // input    [C_S_AXI_ADDR_WIDTH-1:0]
        .S_AXI_AWVALID(S_AXI_AWVALID),      // input
        .S_AXI_AWREADY(S_AXI_AWREADY),      // output
        .S_AXI_WDATA(S_AXI_WDATA),          // input    [C_S_AXI_DATA_WIDTH-1:0]
        .S_AXI_WSTRB(S_AXI_WSTRB),          // input    [3:0]
        .S_AXI_WVALID(S_AXI_WVALID),        // input
        .S_AXI_WREADY(S_AXI_WREADY),        // output        
        .S_AXI_ARADDR(S_AXI_ARADDR),        // input    [C_S_AXI_ADDR_WIDTH-1:0]
        .S_AXI_ARVALID(S_AXI_ARVALID),      // input
        .S_AXI_ARREADY(S_AXI_ARREADY),      // output
        .S_AXI_RDATA(S_AXI_RDATA),          // output   [C_S_AXI_DATA_WIDTH-1:0]
        .S_AXI_RRESP(S_AXI_RRESP),          // output   [1:0]
        .S_AXI_RVALID(S_AXI_RVALID),        // output    
        .S_AXI_RREADY(S_AXI_RREADY),        // input
        .S_AXI_BRESP(S_AXI_BRESP),          // output   [1:0]
        .S_AXI_BVALID(S_AXI_BVALID),        // output
        .S_AXI_BREADY(S_AXI_BREADY)         // input
    );

    dsp_datapath #(
        .WORD_SIZE(WORD_SIZE),
        .FILTER_SIZE(FILTER_SIZE),
        .ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .BUS_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
    ) dsp_datapath1 (
        .CLK(S_AXI_ACLK),
        .WR_ADDR(wrAddr),
        .RD_ADDR(rdAddr),
        .WR_DATA(wrData),
        .RD_DATA(rdData),
        .WR(wr),
        .RD(rd)
    );

endmodule