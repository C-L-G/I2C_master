/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/15 上午11:48:26
madified:
***********************************************/
`timescale 1ns/1ps
module I2C_master_simple_tb;

logic       clock,rst_n;
clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(100  	    )
)clock_rst_inst(
	.clock			(clock	    ),
	.rst_x			(rst_n		)
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_0(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

logic   enable;

simple_rd simple_wr_inst(
/*    input                    */     .enable       (enable     ),
/*    common_interface.master  */     .cinf         (common_interface_0)
);

// iic_eeprom_wr_byte simple_wr_inst(
// /*    input                    */     .enable       (enable     ),
// /*    common_interface.master  */     .cinf         (common_interface_0)
// );

logic            scl_i;
logic            sda_i;
logic            scl_o;
logic            scl_t;
logic            sda_o;
logic            sda_t;

tri1            SCL,SDA;

I2C_master#(
    .ALEN           (7      ),
    .PERSCALER      (1000   )
)I2C_master_inst(
/*    common_interface.slaver */  .cinf     (common_interface_0 ),
    //-->> iic
/*    input               */    .scl_i      (scl_i              ),
/*    input               */    .sda_i      (sda_i              ),
/*    output logic        */    .scl_o      (scl_o              ),
/*    output logic        */    .scl_t      (scl_t              ),
/*    output logic        */    .sda_o      (sda_o              ),
/*    output logic        */    .sda_t      (sda_t              )
);

assign  SCL = scl_t? scl_o : 1'bz;
assign  SDA = sda_t? sda_o : 1'bz;

assign  scl_i = !scl_t? SCL : scl_o;
assign  sda_i = !sda_t? SDA : scl_o;

M24AA01 M24AA01_inst(
/*  input       */         .A0      (1'b0  ),                             // unconnected pin
/*  input       */         .A1      (1'b0  ),                             // unconnected pin
/*  input       */         .A2      (1'b0  ),                             // unconnected pin
/*  input       */         .WP      (1'b0  ),                             // write protect pin
/*  inout       */         .SDA     (SDA),                            // serial data I/O
/*  input       */         .SCL     (SCL),                            // serial data clock
/*  input       */         .RESET   (!rst_n  )                          // system reset
 );

initial begin
    enable  = 0;
    wait(rst_n);
    repeat(10) @(posedge clock);
    enable  = 1;
    repeat(1) @(posedge clock);
    enable  = 0;
end


endmodule
