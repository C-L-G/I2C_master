/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/14 下午3:47:37
madified:
***********************************************/
`timescale 1ns/1ps
module I2C_master#(
    parameter   ALEN    = 7,
    parameter   PERSCALER = 100     //      1/Clock_Freq * 1000 * 2.5 = SCL Freq
)(
    // input                   clock,
    // input                   clk_en,     //unused
    // input                   rst_n,
    //---> ctrl
//    input [3:0]             cmd,     //write read
//    input                   cmd_vld,
//    output logic            cmd_ready,
//    output logic            cmd_finish
//    input [15:0]            addr,
//    input [23:0]            burst_len,
//    output logic [4:0]      curr_status,
    common_interface.slaver   cinf,
    //-->>wr port
    // input                   wr_vld          ,
    // input [7:0]             wr_data         ,
    // output                  wr_ready        ,
    // input                   wr_last         ,   //unused
    // //-->> rd port
    // input                   rd_ready        ,
    // output                  rd_vld          ,
    // output  [7:0]           rd_data         ,
    // output                  rd_last         ,    //unused
    //-->> iic
    input                   scl_i,
    input                   sda_i,
    output logic            scl_o,
    output logic            scl_t,
    output logic            sda_o,
    output logic            sda_t
);

localparam  CSIZE = 4;

// assign  cinf.rd_last    = 1'b0;

logic            exec_addr;
logic[0:9]       address_curr;
logic[23:0]      exec_len;
logic            exec_addr_finish;
logic            exec_wr;
logic            exec_wr_finish;
logic            exec_rd;
logic            exec_rd_finish;

logic           wfifo_rst    ;
logic           wfifo_empty  ;
logic           rfifo_rst    ;
logic           rfifo_empty  ;

logic           curr_wr_or_rd;
logic           slaver_ack_ok;
logic           last_9_bit;

logic[3:0]             cmd_mid;
logic[1:0]             cmd_proc_id;
logic[3:0]             curr_mid;
logic[1:0]             curr_proc_id;

logic[3:0]             main_cmd_mid;
logic[1:0]             main_cmd_proc_id;

logic[3:0]             addr_cmd_mid;
logic[1:0]             addr_cmd_proc_id;

logic[3:0]             wr_cmd_mid;
logic[1:0]             wr_cmd_proc_id;

logic[3:0]             rd_cmd_mid;
logic[1:0]             rd_cmd_proc_id;

data_inf #(.DSIZE(CSIZE+4+2)) main_tras_inf();

main_status_ctrl #(
    .ALEN       (ALEN   ),
    .CSIZE      (CSIZE  ),
    .MODULE_ID  (0      )
)main_status_ctrl_inst(
/*    input               */    .clock          (cinf.clock      ),
/*    input               */    .rst_n          (cinf.rst_n      ),
    //---> ctrl
/*    input [3:0]         */    .cmd            (cinf.cmd            ),     //write read
/*    input               */    .cmd_vld        (cinf.cmd_vld        ),
/*    output logic        */    .cmd_ready      (cinf.cmd_ready      ),
/*    output logic        */    .cmd_finish     (cinf.finish         ),
/*    input [15:0]        */    .addr           (cinf.addr           ),
/*    input [23:0]        */    .burst_len      (cinf.burst_len      ),
/*    output logic [4:0]  */    .curr_status    (cinf.status         ),

/*    output logic        */    .exec_addr         (exec_addr           ),
/*    output logic[0:9]   */    .address_curr      (address_curr[0:ALEN-1] ),
/*    output logic[23:0]  */    .exec_len          (exec_len            ),
/*    input               */    .exec_addr_finish  (exec_addr_finish    ),
/*    output logic        */    .exec_wr           (exec_wr             ),
/*    input               */    .exec_wr_finish    (exec_wr_finish      ),
/*    output logic        */    .exec_rd           (exec_rd             ),
/*    input               */    .exec_rd_finish    (exec_rd_finish      ),
/*    output logic        */    .curr_wr_or_rd     (curr_wr_or_rd       ),
// /*    output logic        */    exist_stop,
/*    //-->> tras 4 tap
/*    output logic        */     .tras_cmd_vld      (main_tras_inf.valid    ),
/*    output logic[2:0]   */     .tras_cmd          (main_tras_inf.data[CSIZE-1:0]     ),
/*    input               */     .tras_cmd_ready    (main_tras_inf.ready    ),
/*    output logic[3:0]   */     .tras_cmd_mid      (main_cmd_mid           ),
/*    output logic[1:0]   */     .tras_cmd_proc_id  (main_cmd_proc_id       ),
/*    input  [3:0]        */     .curr_mid          (curr_mid               ),
/*    input  [1:0]        */     .curr_proc_id      (curr_proc_id           ),
    //--->> fifo ctrl
/*    output logic        */     .wfifo_rst         (wfifo_rst          ),
/*    input               */     .wfifo_empty       (wfifo_empty        ),
/*    output logic        */     .rfifo_rst         (rfifo_rst          ),
/*    input               */     .rfifo_empty       (rfifo_empty        ),
/*    input                */    .slaver_ack_ok     (slaver_ack_ok      ),
/*    input                */    .last_9_bit        (last_9_bit         )
);

assign main_tras_inf.data[CSIZE+:6] = {main_cmd_mid,main_cmd_proc_id};

logic       addr_timeout_cnt_req;
logic       timeout;

data_inf #(.DSIZE(CSIZE+4+2)) addr_tras_inf();

addr_status_ctrl #(
    .ALEN       (ALEN   ),
    .CSIZE      (CSIZE  ),
    .MODULE_ID  (1      )
)addr_status_ctrl_inst(
/*    input               */    .clock                  (cinf.clock              ),
/*    input               */    .rst_n                  (cinf.rst_n              ),
/*    input               */    .exec_addr              (exec_addr          ),
/*    input               */    .wr_or_rd               (curr_wr_or_rd      ),
/*    input [0:ALEN-1]    */    .addr                   (address_curr       ),
/*    output logic        */    .exec_addr_finish       (exec_addr_finish   ),
    //-->> tras 4 tap
/*    output logic        */    .tras_cmd_vld           (addr_tras_inf.valid),
/*    output logic[2:0]   */    .tras_cmd               (addr_tras_inf.data[CSIZE-1:0] ),
/*    input               */    .tras_cmd_ready         (addr_tras_inf.ready),
/*    output logic[3:0]   */    .tras_cmd_mid           (addr_cmd_mid       ),
/*    output logic[1:0]   */    .tras_cmd_proc_id       (addr_cmd_proc_id   ),
/*    input  [3:0]        */    .curr_mid               (curr_mid           ),
/*    input  [1:0]        */    .curr_proc_id           (curr_proc_id       ),
    //-->>
/*    output logic         */   .timeout_cnt_req        (addr_timeout_cnt_req),
/*    input                */   .timeout                (timeout            ),
/*    input                */   .slaver_ack_ok       (/*slaver_ack_ok*/1'b1   )
);
assign addr_tras_inf.data[CSIZE+:6] = {addr_cmd_mid,addr_cmd_proc_id};
//--->> WR <<-------------------------------------------
logic           wpipe_ready ;
logic           wpipe_vld   ;
logic           wpipe_data  ;
// logic           wfifo_empty ;
logic           wr_timeout_cnt_req;

data_inf #(.DSIZE(CSIZE+4+2)) wr_tras_inf();

wr_status_ctrl #(
    .CSIZE      (CSIZE  ),
    .MODULE_ID  (2      )
)wr_status_ctrl_inst(
/*    input              */ .clock                      (cinf.clock              ),
/*    input              */ .rst_n                      (cinf.rst_n              ),
/*    input              */ .exec_wr                    (exec_wr            ),
/*    input [23:0]       */ .exec_wr_len                (exec_len           ),
/*    output logic       */ .exec_wr_finish             (exec_wr_finish     ),
    //-->> tras 4 tap
/*    output logic       */  .tras_cmd_vld              (wr_tras_inf.valid  ),
/*    output logic[2:0]  */  .tras_cmd                  (wr_tras_inf.data[CSIZE-1:0]   ),
/*    input              */  .tras_cmd_ready            (wr_tras_inf.ready  ),
/*    output logic[3:0]   */ .tras_cmd_mid              (wr_cmd_mid         ),
/*    output logic[1:0]   */ .tras_cmd_proc_id          (wr_cmd_proc_id     ),
/*    input  [3:0]        */ .curr_mid                  (curr_mid           ),
/*    input  [1:0]        */ .curr_proc_id              (curr_proc_id       ),
    //--->> write fifo
/*   output logic        */  .wpipe_ready               (wpipe_ready        ),
/*   input               */  .wpipe_vld                 (wpipe_vld          ),
/*   input               */  .wpipe_data                (wpipe_data         ),
// /*   input               */  .wfifo_empty               (wfifo_empty        ),
    //-->>
/*    output logic       */  .timeout_cnt_req           (wr_timeout_cnt_req ),
/*    input              */  .timeout                   (timeout            ),
/*    input              */  .slaver_ack_ok          (/*slaver_ack_ok*/1'b1   )
);

assign wr_tras_inf.data[CSIZE+:6] = {wr_cmd_mid,wr_cmd_proc_id};


width_convert #(
    .ISIZE   (8      ),
    .OSIZE   (1      )
)tras_width_convert_inst(
/*    input                         */  .clock           (cinf.clock       ),
/*    input                         */  .rst_n           (cinf.rst_n && !rfifo_rst        ),
/*    input [DSIZE-1:0]             */  .wr_data         (cinf.wr_data       ),
/*    input                         */  .wr_vld          (cinf.wr_vld        ),
/*    output logic                  */  .wr_ready        (cinf.wr_ready      ),
/*    input                         */  .wr_last         (cinf.wr_last       ),
/*    input                         */  .wr_align_last   (1'b0             ),
/*    output logic[DSIZE*NSIZE-1:0] */  .rd_data         (wpipe_data       ),
/*    output logic                  */  .rd_vld          (wpipe_vld        ),
/*    input                         */  .rd_ready        (wpipe_ready      ),
/*    output                        */  .rd_last         (                 )
);
//---<< WR >>-------------------------------------------
//--->>  RECV <<--------------------------
logic [2:0]    recv_data;
logic          recv_valid;
logic          ack_en;

rev_tap rev_tap_inst(
/*    input      */         .clock         (cinf.clock      ),
/*    input      */         .rst_n         (cinf.rst_n      ),
/*    input      */         .enable        (!sda_t          ),
/*    input      */         .ack_en        (ack_en          ),
/*    input      */         .scl_i         (scl_i      ),
/*    input      */         .sda_i         (sda_i      ),
/*    output logic[2:0]  */ .data          (recv_data  ),
/*    output logic       */ .valid         (recv_valid ),
/*    output logic       */ .slaver_ack_ok (slaver_ack_ok   ),
/*    output      */        .last_9_bit    (last_9_bit )
);

logic       rpipe_vld;
logic       rpipe_data;
logic       rpipe_ready;

data_inf #(.DSIZE(CSIZE+4+2)) rd_tras_inf();


logic   rd_timeout_cnt_req;

rd_status_ctrl_A1 #(
    .CSIZE      (CSIZE  ),
    .MODULE_ID  (3      )
)rd_status_ctrl_A1_inst(
/*    input                */   .clock            (cinf.clock            ),
/*    input                */   .rst_n            (cinf.rst_n            ),
/*    input                */   .exec_rd          (exec_rd               ),
/*    input [23:0]         */   .exec_rd_len      (exec_len              ),
/*    output logic         */   .exec_rd_finish   (exec_rd_finish   ),
/*    input  [2:0]         */   .recv_data        (recv_data        ),
/*    input                */   .recv_valid       (recv_valid       ),
    //-->> tras 4 tap
/*    output logic          */  .tras_cmd_vld     (rd_tras_inf.valid  ),
/*    output logic[2:0]     */  .tras_cmd         (rd_tras_inf.data[CSIZE-1:0]   ),
/*    input                 */  .tras_cmd_ready   (rd_tras_inf.ready  ),
/*    output logic[3:0]   */    .tras_cmd_mid     (rd_cmd_mid         ),
/*    output logic[1:0]   */    .tras_cmd_proc_id (rd_cmd_proc_id     ),
/*    input  [3:0]        */    .curr_mid         (curr_mid           ),
/*    input  [1:0]        */    .curr_proc_id     (curr_proc_id       ),
    //--->> write fifo
    // input                   wfifo_rd_en,
    // output logic            wfifo_empty,
/*    output logic       */     .rpipe_vld        (rpipe_vld           ),
/*    input              */     .rpipe_ready      (rpipe_ready         ),
/*    output logic       */     .rpipe_data       (rpipe_data          ),
    //-->>
/*    output logic       */     .timeout_cnt_req           (rd_timeout_cnt_req ),
/*    input              */     .timeout                   (timeout            ),
/*    input              */     .slaver_ack_ok          (/*slaver_ack_ok*/1'b1   )
);

assign rd_tras_inf.data[CSIZE+:6] = {rd_cmd_mid,rd_cmd_proc_id};

width_convert #(
    .ISIZE   (1      ),
    .OSIZE   (8      )
)recv_width_convert_inst(
/*    input                         */  .clock           (cinf.clock       ),
/*    input                         */  .rst_n           (cinf.rst_n && !rfifo_rst        ),
/*    input [DSIZE-1:0]             */  .wr_data         (rpipe_data       ),
/*    input                         */  .wr_vld          (rpipe_vld        ),
/*    output logic                  */  .wr_ready        (rpipe_ready      ),
/*    input                         */  .wr_last         (1'b0             ),
/*    input                         */  .wr_align_last   (1'b0             ),
/*    output logic[DSIZE*NSIZE-1:0] */  .rd_data         (cinf.rd_data     ),
/*    output logic                  */  .rd_vld          (cinf.rd_vld      ),
/*    input                         */  .rd_ready        (cinf.rd_ready    ),
/*    output                        */  .rd_last         (cinf.rd_last     )
);
//---<<  RECV >>--------------------------
//--->> INTERCONNECT <<------------------
data_inf #(.DSIZE(CSIZE+4+2)) tmp_tras_inf0();
data_inf #(.DSIZE(CSIZE+4+2)) tmp_tras_inf1();
data_inf #(.DSIZE(CSIZE+4+2)) tmp_tras_inf2();
data_inf #(.DSIZE(CSIZE+4+2)) tmp_tras_inf3();
data_inf #(.DSIZE(CSIZE+4+2)) m00_tras_inf();

assign  tmp_tras_inf0.valid     = 1'b0;
assign  tmp_tras_inf0.data      = {(CSIZE+6){1'b0}};

assign  tmp_tras_inf1.valid     = 1'b0;
assign  tmp_tras_inf1.data      = {(CSIZE+6){1'b0}};

assign  tmp_tras_inf2.valid     = 1'b0;
assign  tmp_tras_inf2.data      = {(CSIZE+6){1'b0}};

assign  tmp_tras_inf3.valid     = 1'b0;
assign  tmp_tras_inf3.data      = {(CSIZE+6){1'b0}};

data_pipe_interconnect #(
    .DSIZE      (CSIZE+4+2)
)data_pipe_interconnect_inst(
/*    input             */  .clock         (cinf.clock      ),
/*    input             */  .rst_n         (cinf.rst_n      ),
/*    input             */  .clk_en        (1'b1            ),
/*    input [2:0]       */  .sw            ({exec_addr,exec_wr,exec_rd} ),
/*    input             */  .vld_sw        (1'b1            ),
/*    output logic[2:0] */  .curr_path     (                ),

/*    data_inf.slaver   */  .s00           (main_tras_inf   ),
/*    data_inf.slaver   */  .s01           (rd_tras_inf     ),
/*    data_inf.slaver   */  .s02           (wr_tras_inf     ),

/*    data_inf.slaver   */  .s03           (tmp_tras_inf0   ),
/*    data_inf.slaver   */  .s04           (addr_tras_inf   ),
/*    data_inf.slaver   */  .s05           (tmp_tras_inf1   ),
/*    data_inf.slaver   */  .s06           (tmp_tras_inf2   ),
/*    data_inf.slaver   */  .s07           (tmp_tras_inf3   ),

/*    data_inf.master   */  .m00           (m00_tras_inf    )
);

tras_4_tap #(
    .PERSCALER          (PERSCALER      ),   // 1/3 SCL
    .CSIZE              (CSIZE  )
)tras_4_tap_inst(
/*    input             */  .clock          (cinf.clock                 ),
/*    input             */  .rst_n          (cinf.rst_n                 ),
/*    input             */  .cmd_vld        (m00_tras_inf.valid    ),
/*    input [2:0]       */  .cmd            (m00_tras_inf.data[CSIZE-1:0]     ),
/*    output logic      */  .cmd_ready      (m00_tras_inf.ready    ),
/*    input [3:0]       */  .cmd_mid        (cmd_mid               ),
/*    input [1:0]       */  .cmd_proc_id    (cmd_proc_id           ),
/*    output logic[3:0] */  .curr_mid       (curr_mid              ),
/*    output logic[1:0] */  .curr_proc_id   (curr_proc_id          ),

/*    output logic      */  .scl_o          (scl_o            ),
/*    output logic      */  .scl_t          (scl_t            ),
/*    output logic      */  .sda_o          (sda_o            ),
/*    output logic      */  .sda_t          (sda_t            ),
/*    output logic      */  .ack_en         (ack_en           )
);

assign      {cmd_mid,cmd_proc_id}    = m00_tras_inf.data[CSIZE+:6];

//---<< INTERCONNECT >>------------------

endmodule
