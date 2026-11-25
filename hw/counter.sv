`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 01:53:21 PM
// Design Name: 
// Module Name: counter
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


module counter #(parameter WIDTH = 2)(
    input logic clk, en,
    input logic [WIDTH-1:0] MAX_COUNT,
    output logic [WIDTH-1:0] count
    );
    always_ff @(posedge clk) begin
        if (!en) count <= 0;
        else count <= (count < MAX_COUNT) ? count + 1 : 0;
    end
endmodule
