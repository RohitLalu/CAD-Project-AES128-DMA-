module aes (
    input         clk,
    input         reset_n,
    input         cs,
    input         we,
    input  [7:0]  address,
    input  [31:0] write_data,
    output [31:0] read_data,
    input         VPWR,
    input         VGND
);
endmodule
