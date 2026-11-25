`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2026 03:46:07 PM
// Design Name: 
// Module Name: Axi4Lite_spi_controller
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


module Axi4Lite_spi_controller#(
    parameter C_S_AXI_ADDR_WIDTH = 6,
    parameter C_S_AXI_DATA_WIDTH = 32
)(
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
    input logic S_AXI_BREADY,
    
    // SPI bus
    input logic SDO,
    output logic SCK,
    output logic CONV,
    output logic SDI
    );
    
    // Simple Bus Signals
    logic [C_S_AXI_ADDR_WIDTH-1:0] wrAddr, rdAddr;
    logic [C_S_AXI_DATA_WIDTH-1:0] wrData, rdData;
    logic wr, rd;
    
    Axi4LiteSupporter #(.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) Axi4LiteSupporter1 (
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
    ) ;
    
    spi_controller spi_controller_1(
        .clk(S_AXI_ACLK),
        .wr(wr),
        .rd(rd),
        .wrAddr(wrAddr),
        .rdAddr(rdAddr),
        .wrData(wrData),
        .rdData(rdData),
        .SDO(SDO),
        .SCK(SCK),
        .CONV(CONV),
        .SDI(SDI)
    );
endmodule
