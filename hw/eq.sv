`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2026 03:10:49 PM
// Design Name: 
// Module Name: eq
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


module eq #(parameter C_S_AXI_ADDR_WIDTH = 6, C_S_AXI_DATA_WIDTH = 32, RAM_ADDR_WIDTH = 6, RAM_WIDTH = 16, FILTER_TAPS = 279)(
        // Axi4Lite Bus
        input logic S_AXI_ACLK,
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
        input  logic  S_AXI_BREADY,
        // SPI bus for ADC
        input logic SDO_ADC,
        output logic SCK_ADC,
        output logic CONV_ADC,
        output logic SDI_ADC,
        // SPI bus for DAC
        input logic SDO_DAC,
        output logic SCK_DAC,
        output logic CONV_DAC,
        output logic SDI_DAC
    );
    
    // Main Bus Signals
    logic wrMain, rdMain;
    logic [C_S_AXI_ADDR_WIDTH-1:0] wrAddrMain, rdAddrMain;
    logic [C_S_AXI_DATA_WIDTH-1:0] wrDataMain, rdDataMain;
    
    // Main supporter for interfacing with MicroBlaze
    Axi4LiteSupporter #(.C_S_AXI_ADDR_WIDTH(C_S_AXI_DATA_WIDTH), .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) MainSupporter(
    // Simple Bus
    .wrAddr(wrAddrMain),
    .wrData(wrDataMain),
    .wr(wrMain),
    .rdAddr(rdAddrMain),
    .rdData(rdDataMain),
    .rd(rdMain),
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
    
    // ADC Bus Signals
    logic wrADC, rdADC;
    logic [C_S_AXI_ADDR_WIDTH-1:0] wrAddrADC, rdAddrADC;
    logic [C_S_AXI_DATA_WIDTH-1:0] wrDataADC, rdDataADC;
    
    // ADC Axi4Lite Bus
    logic AXI_AWVALID_ADC, AXI_AWREADY_ADC, AXI_WVALID_ADC, AXI_WREADY_ADC, AXI_ARVALID_ADC, AXI_ARREADY_ADC, AXI_RVALID_ADC, AXI_RREADY_ADC, AXI_BVALID_ADC, AXI_BREADY_ADC;
    logic [1:0] AXI_RRESP_ADC, AXI_BRESP_ADC;
    logic [3:0] AXI_WSTRB_ADC;
    logic [C_S_AXI_ADDR_WIDTH-1:0] AXI_AWADDR_ADC, AXI_ARADDR_ADC;
    logic [C_S_AXI_DATA_WIDTH-1:0] AXI_WDATA_ADC, AXI_RDATA_ADC;
    
    // Manager for interfacing with ADC
    Axi4LiteManager #(.C_M_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH), .C_M_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) ADCManager (
    // Simple Bus
    .wrAddr(wrAddrADC),
    .wrData(wrDataADC),
    .wr(wrADC),
    .rdAddr(rdAddrADC),
    .rdData(rdDataADC),
    .rd(rdADC),
    // Axi4Lite Bus
    .M_AXI_ACLK(S_AXI_ACLK),
    .M_AXI_ARESETN(S_AXI_ARESETN),
    .M_AXI_AWADDR(AXI_AWADDR_ADC),
    .M_AXI_AWVALID(AXI_AWVALID_ADC),
    .M_AXI_AWREADY(AXI_AWREADY_ADC),
    .M_AXI_WDATA(AXI_WDATA_ADC),
    .M_AXI_WSTRB(AXI_WSTRB_ADC),
    .M_AXI_WVALID(AXI_WVALID_ADC),
    .M_AXI_WREADY(AXI_WREADY_ADC),
    .M_AXI_ARADDR(AXI_ARADDR_ADC),
    .M_AXI_ARVALID(AXI_ARVALID_ADC),
    .M_AXI_ARREADY(AXI_ARREADY_ADC),
    .M_AXI_RDATA(AXI_RDATA_ADC),
    .M_AXI_RRESP(AXI_RRESP_ADC),
    .M_AXI_RVALID(AXI_RVALID_ADC),
    .M_AXI_RREADY(AXI_RREADY_ADC),
    .M_AXI_BRESP(AXI_BRESP_ADC),
    .M_AXI_BVALID(AXI_BVALID_ADC),
    .M_AXI_BREADY(AXI_BREADY_ADC)
    );
    
    // SPI controller for ADC
    Axi4Lite_spi_controller #(.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH), .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) ADCController(
    // Axi4Lite Bus
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),
    .S_AXI_AWADDR(AXI_AWADDR_ADC),
    .S_AXI_AWVALID(AXI_AWVALID_ADC),
    .S_AXI_AWREADY(AXI_AWREADY_ADC),
    .S_AXI_WDATA(AXI_WDATA_ADC),
    .S_AXI_WSTRB(AXI_WSTRB_ADC),
    .S_AXI_WVALID(AXI_WVALID_ADC),
    .S_AXI_WREADY(AXI_WREADY_ADC),
    .S_AXI_ARADDR(AXI_ARADDR_ADC),
    .S_AXI_ARVALID(AXI_ARVALID_ADC),
    .S_AXI_ARREADY(AXI_ARREADY_ADC),
    .S_AXI_RDATA(AXI_RDATA_ADC),
    .S_AXI_RRESP(AXI_RRESP_ADC),
    .S_AXI_RVALID(AXI_RVALID_ADC),
    .S_AXI_RREADY(AXI_RREADY_ADC),
    .S_AXI_BRESP(AXI_BRESP_ADC),
    .S_AXI_BVALID(AXI_BVALID_ADC),
    .S_AXI_BREADY(AXI_BREADY_ADC),
    // SPI Bus
    .SDO(SDO_ADC),
    .SCK(SCK_ADC),
    .CONV(CONV_ADC),
    .SDI(SDI_ADC)
    );
    
    // DAC Bus Signals
    logic wrDAC, rdDAC;
    logic [C_S_AXI_ADDR_WIDTH-1:0] wrAddrDAC, rdAddrDAC;
    logic [C_S_AXI_DATA_WIDTH-1:0] wrDataDAC, rdDataDAC;
    
    // DAC Axi4Lite Bus
    logic AXI_AWVALID_DAC, AXI_AWREADY_DAC, AXI_WVALID_DAC, AXI_WREADY_DAC, AXI_ARVALID_DAC, AXI_ARREADY_DAC, AXI_RVALID_DAC, AXI_RREADY_DAC, AXI_BVALID_DAC, AXI_BREADY_DAC;
    logic [1:0] AXI_RRESP_DAC, AXI_BRESP_DAC;
    logic [3:0] AXI_WSTRB_DAC;
    logic [C_S_AXI_ADDR_WIDTH-1:0] AXI_AWADDR_DAC, AXI_ARADDR_DAC;
    logic [C_S_AXI_DATA_WIDTH-1:0] AXI_WDATA_DAC, AXI_RDATA_DAC;
    
    // Manager for interfacing with DAC
    Axi4LiteManager #(.C_M_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH), .C_M_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) DACManager (
    // Simple Bus
    .wrAddr(wrAddrDAC),
    .wrData(wrDataDAC),
    .wr(wrDAC),
    .rdAddr(rdAddrDAC),
    .rdData(rdDataDAC),
    .rd(rdDAC),
    // Axi4Lite Bus
    .M_AXI_ACLK(S_AXI_ACLK),
    .M_AXI_ARESETN(S_AXI_ARESETN),
    .M_AXI_AWADDR(AXI_AWADDR_DAC),
    .M_AXI_AWVALID(AXI_AWVALID_DAC),
    .M_AXI_AWREADY(AXI_AWREADY_DAC),
    .M_AXI_WDATA(AXI_WDATA_DAC),
    .M_AXI_WSTRB(AXI_WSTRB_DAC),
    .M_AXI_WVALID(AXI_WVALID_DAC),
    .M_AXI_WREADY(AXI_WREADY_DAC),
    .M_AXI_ARADDR(AXI_ARADDR_DAC),
    .M_AXI_ARVALID(AXI_ARVALID_DAC),
    .M_AXI_ARREADY(AXI_ARREADY_DAC),
    .M_AXI_RDATA(AXI_RDATA_DAC),
    .M_AXI_RRESP(AXI_RRESP_DAC),
    .M_AXI_RVALID(AXI_RVALID_DAC),
    .M_AXI_RREADY(AXI_RREADY_DAC),
    .M_AXI_BRESP(AXI_BRESP_DAC),
    .M_AXI_BVALID(AXI_BVALID_DAC),
    .M_AXI_BREADY(AXI_BREADY_DAC)
    );
    
    // SPI controller for DAC
    Axi4Lite_spi_controller #(.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH), .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) DACController(
    // Axi4Lite Bus
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),
    .S_AXI_AWADDR(AXI_AWADDR_DAC),
    .S_AXI_AWVALID(AXI_AWVALID_DAC),
    .S_AXI_AWREADY(AXI_AWREADY_DAC),
    .S_AXI_WDATA(AXI_WDATA_DAC),
    .S_AXI_WSTRB(AXI_WSTRB_DAC),
    .S_AXI_WVALID(AXI_WVALID_DAC),
    .S_AXI_WREADY(AXI_WREADY_DAC),
    .S_AXI_ARADDR(AXI_ARADDR_DAC),
    .S_AXI_ARVALID(AXI_ARVALID_DAC),
    .S_AXI_ARREADY(AXI_ARREADY_DAC),
    .S_AXI_RDATA(AXI_RDATA_DAC),
    .S_AXI_RRESP(AXI_RRESP_DAC),
    .S_AXI_RVALID(AXI_RVALID_DAC),
    .S_AXI_RREADY(AXI_RREADY_DAC),
    .S_AXI_BRESP(AXI_BRESP_DAC),
    .S_AXI_BVALID(AXI_BVALID_DAC),
    .S_AXI_BREADY(AXI_BREADY_DAC),
    // SPI Bus
    .SDO(SDO_DAC),
    .SCK(SCK_DAC),
    .CONV(CONV_DAC),
    .SDI(SDI_DAC)
    );

    // DSP Bus Signals
    logic wrDSP, rdDSP;
    logic [C_S_AXI_ADDR_WIDTH-1:0] wrAddrDSP, rdAddrDSP;
    logic [C_S_AXI_DATA_WIDTH-1:0] wrDataDSP, rdDataDSP;

    // DSP Axi4Lite Bus Signals
    logic AXI_AWVALID_DSP, AXI_AWREADY_DSP, AXI_WVALID_DSP, AXI_WREADY_DSP, AXI_ARVALID_DSP, AXI_ARREADY_DSP, AXI_RVALID_DSP, AXI_RREADY_DSP, AXI_BVALID_DSP, AXI_BREADY_DSP;
    logic [1:0] AXI_RRESP_DSP, AXI_BRESP_DSP;
    logic [3:0] AXI_WSTRB_DSP;
    logic [C_S_AXI_ADDR_WIDTH-1:0] AXI_AWADDR_DSP, AXI_ARADDR_DSP;
    logic [C_S_AXI_DATA_WIDTH-1:0] AXI_WDATA_DSP, AXI_RDATA_DSP;
    
    // Manager for interfacing with DSP datapath
    Axi4LiteManager #(.C_M_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH), .C_M_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)) DSPManager (
    // Simple Bus
    .wrAddr(wrAddrDSP),
    .wrData(wrDataDSP),
    .wr(wrDSP),
    .rdAddr(rdAddrDSP),
    .rdData(rdDataDSP),
    .rd(rdDSP),
    // Axi4Lite Bus
    .M_AXI_ACLK(S_AXI_ACLK),
    .M_AXI_ARESETN(S_AXI_ARESETN),
    .M_AXI_AWADDR(AXI_AWADDR_DSP),
    .M_AXI_AWVALID(AXI_AWVALID_DSP),
    .M_AXI_AWREADY(AXI_AWREADY_DSP),
    .M_AXI_WDATA(AXI_WDATA_DSP),
    .M_AXI_WSTRB(AXI_WSTRB_DSP),
    .M_AXI_WVALID(AXI_WVALID_DSP),
    .M_AXI_WREADY(AXI_WREADY_DSP),
    .M_AXI_ARADDR(AXI_ARADDR_DSP),
    .M_AXI_ARVALID(AXI_ARVALID_DSP),
    .M_AXI_ARREADY(AXI_ARREADY_DSP),
    .M_AXI_RDATA(AXI_RDATA_DSP),
    .M_AXI_RRESP(AXI_RRESP_DSP),
    .M_AXI_RVALID(AXI_RVALID_DSP),
    .M_AXI_RREADY(AXI_RREADY_DSP),
    .M_AXI_BRESP(AXI_BRESP_DSP),
    .M_AXI_BVALID(AXI_BVALID_DSP),
    .M_AXI_BREADY(AXI_BREADY_DSP)
    );

    // DSP Datapath
    
endmodule
