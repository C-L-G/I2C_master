/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/17 下午2:24:27
madified:
***********************************************/
`timescale 1ns/1ps
module I2C_master_mult_port_tb;

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

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_1(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_2(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_3(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_4(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_5(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_6(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_7(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

common_interface #(
    .CSIZE      (4),
    .LSIZE      (24),
    .DSIZE      (8),
    .ASIZE      (7)
)common_interface_m0(
/*    input */      .clock      (clock      ),
/*    input */      .rst_n      (rst_n      ),
/*    input */      .clk_en     (1'b1          )
);

logic   enable_wr,enable_wr_byte,enable_rd;
logic   enable_rd_byte = 0;
logic   enable_free_bus = 0;
logic   wr_byte_finish;

simple_wr simple_wr_inst(
/*    input                    */     .enable       (enable_wr     ),
/*    common_interface.master  */     .cinf         (common_interface_0)
);

iic_eeprom_wr_byte simple_wr_byte_inst(
/*    input                    */     .enable       (enable_wr_byte     ),
/*    output                   */     .finish       (wr_byte_finish     ),
/*    common_interface.master  */     .cinf         (common_interface_1)
);

simple_rd simple_rd_inst(
/*    input                    */     .enable       (enable_rd     ),
/*    common_interface.master  */     .cinf         (common_interface_2)
);

iic_eeprom_rd_byte iic_eeprom_rd_byte(
/*    input                    */     .enable       (enable_rd_byte     ),
/*    common_interface.master  */     .cinf         (common_interface_3)
);

free_bus free_bus_inst(
/*    input                    */     .enable       (enable_free_bus     ),
/*    common_interface.master  */     .cinf         (common_interface_4 )
);

common_interface_interconnect #(
    .DSIZE          (8      ),
    .COMPACT        ("OFF"  )
)common_interface_interconnect_inst(
/*    common_interface.slaver */ .s0        (common_interface_0 ),
/*    common_interface.slaver */ .s1        (common_interface_1 ),
/*    common_interface.slaver */ .s2        (common_interface_2 ),
/*    common_interface.slaver */ .s3        (common_interface_3 ),
/*    common_interface.slaver */ .s4        (common_interface_4 ),
/*    common_interface.slaver */ .s5        (common_interface_5 ),
/*    common_interface.slaver */ .s6        (common_interface_6 ),
/*    common_interface.slaver */ .s7        (common_interface_7 ),
/*    common_interface.master */ .m0        (common_interface_m0)
);

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
/*    common_interface.slaver */  .cinf     (common_interface_m0 ),
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
assign  sda_i = !sda_t? SDA : sda_o;

M24AA01 M24AA01_inst(
/*  input       */         .A0      (1'b0  ),                             // unconnected pin
/*  input       */         .A1      (1'b0  ),                             // unconnected pin
/*  input       */         .A2      (1'b0  ),                             // unconnected pin
/*  input       */         .WP      (1'b0  ),                             // write protect pin
/*  inout       */         .SDA     (SDA),                            // serial data I/O
/*  input       */         .SCL     (SCL),                            // serial data clock
/*  input       */         .RESET   (!rst_n  )                          // system reset
 );



event   wr_byte_fsh_event;
event   rd_byte_fsh_event;

initial begin
    wait(rd_byte_fsh_event.triggered());
    enable_wr       = 0;
    wait(rst_n);
    repeat(10) @(posedge clock);
    enable_wr       = 1;
    repeat(1) @(posedge clock);
    enable_wr       = 0;
end

initial begin
    enable_rd       = 0;
    wait(rst_n);
    repeat(20) @(posedge clock);
    enable_rd       = 0;
    repeat(1) @(posedge clock);
    enable_rd       = 0;
end

initial begin
    enable_wr_byte  = 0;
    wait(rst_n);
    repeat(10) @(posedge clock);
    enable_wr_byte  = 1;
    repeat(1) @(posedge clock);
    enable_wr_byte  = 0;
    wait(wr_byte_finish);
    repeat(600000) @(posedge clock);
    -> wr_byte_fsh_event;
end

initial begin
    wait(wr_byte_fsh_event.triggered());
    enable_rd_byte  = 0;
    wait(rst_n);
    repeat(100) @(posedge clock);
    enable_rd_byte  = 1;
    repeat(1) @(posedge clock);
    enable_rd_byte  = 0;
    -> rd_byte_fsh_event;
    free_bus_task;
end

task free_bus_task;
    enable_free_bus <= 0;
    repeat(1) @(posedge clock);
    enable_free_bus  = 1;
    repeat(1) @(posedge clock);
    enable_free_bus  = 0;
endtask:free_bus_task

endmodule
