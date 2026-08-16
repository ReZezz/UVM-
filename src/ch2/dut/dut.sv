module dut (
    clk,
    rst_n,
    rxd,
    rxd_dv,
    txd,
    txd_en
);

input clk;
input rst_n;
input [7:0] rxd;
input rxd_dv;
output [7:0] txd;
output txd_en;

reg [7:0] txd;
reg txd_en;

always @(posedge clk) begin
    if (!rst_n) begin
        txd <= 8'b0;
        txd_en <= 1'b0;
    end
    else begin
        txd <= rxd;
        txd_en <= rxd_dv;
    end   
end

endmodule