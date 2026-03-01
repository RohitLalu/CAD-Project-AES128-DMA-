//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sun Jan 18 17:40:25 2026
//Host        : DD running 64-bit major release  (build 9200)
//Command     : generate_target picosoc_aes128_wrapper.bd
//Design      : picosoc_aes128_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module picosoc_aes128_wrapper
   (clk_100MHz,
    reset_rtl_0);
  input clk_100MHz;
  input reset_rtl_0;

  wire clk_100MHz;
  wire reset_rtl_0;

  picosoc_aes128 picosoc_aes128_i
       (.clk_100MHz(clk_100MHz),
        .reset_rtl_0(reset_rtl_0));
endmodule
