`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2026 02:34:24 PM
// Design Name: 
// Module Name: ram
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


module ram #(parameter RAM_WIDTH = 32, parameter RAM_ADDR_BITS = 32, parameter MEM_SIZE = 1024)(
    input logic CLK,
    input logic WE,
    input logic [RAM_ADDR_BITS-1:0] ADDR,
    input logic signed [RAM_WIDTH-1:0] WR_DATA,
    output logic signed [RAM_WIDTH-1:0] RD_DATA
    );
    
    (* ram_style = "distributed" *)
    
    logic [RAM_WIDTH-1:0] mem [0:MEM_SIZE-1];
    
    always_ff @ (posedge CLK) begin
        if (WE) begin
            mem[ADDR] <= WR_DATA;
        end
    
    end
    
    assign RD_DATA = mem[ADDR];
endmodule