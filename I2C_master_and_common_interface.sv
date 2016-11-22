/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/22 上午10:35:20
madified:
***********************************************/
`timescale 1ns/1ps
module I2C_master_and_common_interface (
    input                   clock,
    input                   rst_n,
    input                   enable_wr,
    input                   enable_wr_byte,
    input                   enable_rd,
    input                   enable_rd_byte,
    input                   enable_free_bus,
    //-->> iic
    input                   scl_i,
    input                   sda_i,
    output logic            scl_o,
    output logic            scl_t,
    output logic            sda_o,
    output logic            sda_t
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

// logic   enable_wr,enable_wr_byte,enable_rd;
// logic   enable_rd_byte = 0;
// logic   enable_free_bus = 0;
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


I2C_master#(
    .ALEN           (7      ),
    .PERSCALER      (1000*3   )       //    1/Clock_Freq * 1000 * 2.5 = SCL Freq
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

endmodule
