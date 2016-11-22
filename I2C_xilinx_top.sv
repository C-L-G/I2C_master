/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/22 上午10:35:27
madified:
***********************************************/
`timescale 1ns/1ps
module I2C_xilinx_top (
    input               sysclk_p,
    input               sysclk_n,
    input [4:0]         sw,
    inout               SCL,
    inout               SDA
);

wire    clock,rst_n;

system_mmcm system_mmcm_inst
 (
 // Clock in ports
 /* input   */      .clk_in1_p      (sysclk_p       ),
 /* input   */      .clk_in1_n      (sysclk_n       ),
  // Clock out ports
 /* output  */      .clk_out1       (clock          ),
  // Status and control signals
/*  output  */      .locked         (rst_n          )
 );

 logic            scl_i;
 logic            sda_i;
 logic            scl_o;
 logic            scl_t;
 logic            sda_o;
 logic            sda_t;


I2C_master_and_common_interface I2C_master_and_common_interface_inst(
/*    input              */     .clock                 (clock       ),
/*    input              */     .rst_n                 (rst_n       ),
/*    input              */     .enable_wr             (sw[0]       ),
/*    input              */     .enable_wr_byte        (sw[1]       ),
/*    input              */     .enable_rd             (sw[2]       ),
/*    input              */     .enable_rd_byte        (sw[3]       ),
/*    input              */     .enable_free_bus       (sw[4]       ),
    //-->> iic
/*    input              */     .scl_i                 (scl_i       ),
/*    input              */     .sda_i                 (sda_i       ),
/*    output logic       */     .scl_o                 (scl_o       ),
/*    output logic       */     .scl_t                 (scl_t       ),
/*    output logic       */     .sda_o                 (sda_o       ),
/*    output logic       */     .sda_t                 (sda_t       )
);


assign  SCL = scl_t? scl_o : 1'bz;
assign  SDA = sda_t? sda_o : 1'bz;

assign  scl_i = !scl_t? SCL : scl_o;
assign  sda_i = !sda_t? SDA : sda_o;

endmodule
