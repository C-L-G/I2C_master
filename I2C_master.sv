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
    parameter   PERSCALER = 100
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

assign  cinf.rd_last    = 1'b0;

logic            exec_addr;
logic[0:9]       address_curr;
logic[23:0]      exec_wr_len;
logic            exec_addr_finish;
logic            exec_wr;
logic            exec_wr_finish;
logic            exec_rd;
logic            exec_rd_finish;

logic           wfifo_rst    ;
logic           wfifo_empty  ;
logic           rfifo_rst    ;
logic           rfifo_empty  ;

data_inf #(.DSIZE(3)) main_tras_inf;

main_status_ctrl #(
    .ALEN       (ALEN   )
)main_status_ctrl_inst(
/*    input               */    .clock          (cinf.clock      ),
/*    input               */    .rst_n          (cinf.rst_n      ),
    //---> ctrl
/*    input [3:0]         */    .cmd            (cinf.cmd            ),     //write read
/*    input               */    .cmd_vld        (cinf.cmd_vld        ),
/*    output logic        */    .cmd_ready      (cinf.cmd_ready      ),
/*    output logic        */    .cmd_finish     (cinf.cmd_finish     ),
/*    input [15:0]        */    .addr           (cinf.addr           ),
/*    input [23:0]        */    .burst_len      (cinf.burst_len      ),
/*    output logic [4:0]  */    .curr_status    (cinf.curr_status    ),

/*    output logic        */    .exec_addr         (exec_addr           ),
/*    output logic[0:9]   */    .address_curr      (address_curr        ),
/*    output logic[23:0]  */    .exec_wr_len       (exec_wr_len         ),
/*    input               */    .exec_addr_finish  (exec_addr_finish    ),
/*    output logic        */    .exec_wr           (exec_wr             ),
/*    input               */    .exec_wr_finish    (exec_wr_finish      ),
/*    output logic        */    .exec_rd           (exec_rd             ),
/*    input               */    .exec_rd_finish    (exec_rd_finish      ),
// /*    output logic        */    exist_stop,
/*    //-->> tras 4 tap
/*    output logic        */     .tras_cmd_vld      (main_tras_inf.valid    ),
/*    output logic[2:0]   */     .tras_cmd          (main_tras_inf.data     ),
/*    input               */     .tras_cmd_ready    (main_tras_inf.ready    ),
    //--->> fifo ctrl
/*    output logic        */     .wfifo_rst         (wfifo_rst          ),
/*    input               */     .wfifo_empty       (wfifo_empty        ),
/*    output logic        */     .rfifo_rst         (rfifo_rst          ),
/*    input               */     .rfifo_empty       (rfifo_empty        )
);

logic       addr_timeout_cnt_req;
logic       timeout;
logic       slaver_answer_ok;

data_inf #(.DSIZE(3)) addr_tras_inf;

addr_status_ctrl #(
    .ALEN       (ALEN   )
)addr_status_ctrl_inst(
/*    input               */    .clock                  (cinf.clock              ),
/*    input               */    .rst_n                  (cinf.rst_n              ),
/*    input               */    .exec_addr              (exec_addr          ),
/*    input [0:ALEN-1]    */    .addr                   (address_curr       ),
/*    output logic        */    .exec_addr_finish       (exec_addr_finish   ),
    //-->> tras 4 tap
/*    output logic        */    .tras_cmd_vld           (addr_tras_inf.valid),
/*    output logic[2:0]   */    .tras_cmd               (addr_tras_inf.data ),
/*    input               */    .tras_cmd_ready         (addr_tras_inf.ready),
    //-->>
/*    output logic         */   .timeout_cnt_req        (addr_timeout_cnt_req),
/*    input                */    timeout                (timeout            ),
/*    input                */    slaver_answer_ok       (slaver_answer_ok   )
);
//--->> WR <<-------------------------------------------
logic           wfifo_rd_en ;
logic           wfifo_vld   ;
logic[7:0]      wfifo_data  ;
logic           wr_timeout_cnt_req;

data_inf #(.DSIZE(3)) wr_tras_inf;

wr_status_ctrl wr_status_ctrl_inst(
/*    input              */ .clock                      (cinf.clock              ),
/*    input              */ .rst_n                      (cinf.rst_n              ),
/*    input              */ .exec_wr                    (exec_wr            ),
/*    input [23:0]       */ .exec_wr_len                (exec_wr_len        ),
/*    output logic       */ .exec_wr_finish             (exec_wr_finish     ),
    //-->> tras 4 tap
/*    output logic       */  .tras_cmd_vld              (wr_tras_inf.valid  ),
/*    output logic[2:0]  */  .tras_cmd                  (wr_tras_inf.data   ),
/*    input              */  .tras_cmd_ready            (wr_tras_inf.ready  ),
    //--->> write fifo
/*   output logic        */  .wfifo_rd_en               (wfifo_rd_en        ),
/*   input               */  .wfifo_vld                 (wfifo_vld          ),
/*   input               */  .wfifo_data                (wfifo_data         ),
    //-->>
/*    output logic       */  .timeout_cnt_req           (wr_timeout_cnt_req ),
/*    input              */  .timeout                   (timeout            ),
/*    input              */  .slaver_answer_ok          (slaver_answer_ok   )
);

logic   wfifo_full;
assign cinf.wr_ready    = !wfifo_full;

fifo_nto1 #(
	.DSIZE		(1   		),
	.NSIZE		(8   		),
	.DEPTH		(4      ),
	.ALMOST		(1      ),
	.DEF_VALUE	(0      )
)wfifo_nto1_inst(
	//--->> WRITE PORT <<-----
/*	input				    */	.wr_clk			(cinf.clock		),
/*	input				    */	.wr_rst_n       (cinf.rst_n && !wfifo_rst   ),
/*	input				    */	.wr_en          (cinf.wr_vld     ),
/*	input [NSIZE*DSIZE-1:0]	*/	.wr_data        (cinf.wr_data    ),
/*	output[4:0]			    */	.wr_count       (                ),
/*	output				    */	.wr_full        (wfifo_full      ),
/*  output                  */  .wr_last        (    ),
/*	output				    */	.wr_almost_full (           ),
	//--->> READ PORT <<------
/*	input				    */	.rd_clk			(cinf.clock		    ),
/*	input				    */	.rd_rst_n       (cinf.rst_n         ),
/*	input				    */	.rd_en          (wfifo_rd_en    ),
/*	output[DSIZE-1:0]	    */	.rd_data        (wfifo_data     ),
/*  output                  */  .rd_last        (/*rd_last*/        ),
/*	output[4:0]			    */	.rd_count       (               ),
/*	output				    */	.rd_empty       (wfifo_empty    ),
/*	output				    */	.rd_almost_empty(               ),
/*	output				    */	.rd_vld			(wfifo_vld   	)
);
//---<< WR >>-------------------------------------------
//--->>  RECV <<--------------------------
logic               recv_data;
logic [2:0]         recv_valid;
rev_tap rev_tap_inst(
/*    input      */         .clock         (cinf.clock      ),
/*    input      */         .rst_n         (cinf.rst_n      ),
/*    input      */         .scl_i         (scl_i      ),
/*    input      */         .sda_i         (sda_i      ),
/*    output logic[2:0]  */ .data          (recv_data  ),
/*    output logic       */ .valid         (recv_valid )
);

data_inf #(.DSIZE(3)) rd_tras_inf;

recv_status_ctrl recv_status_ctrl_inst(
/*    input                 */  .clock            (cinf.clock            ),
/*    input                 */  .rst_n            (cinf.rst_n            ),
/*    input                 */  .exec_rd          (exec_rd          ),
/*    output logic          */  .exec_rd_finish   (exec_rd_finish   ),
/*    input  [2:0]          */  .recv_data        (recv_data        ),
/*    input                 */  .recv_valid       (recv_valid       ),
    //-->> read fifo
/*    output logic          */  .rfifo_vld        (rfifo_vld        ),
/*    output logic [7:0]    */  .rfifo_data       (rfifo_data       ),
    //-->> tras 4 tap
/*    output logic          */  .tras_cmd_vld     (rd_tras_inf.valid  ),
/*    output logic[2:0]     */  .tras_cmd         (rd_tras_inf.data   ),
/*    input                 */  .tras_cmd_ready   (rd_tras_inf.ready  ),
/*    output logic          */  .slaver_answer_ok (slaver_answer_ok   )
);

fifo_nto1 #(
	.DSIZE		(8   		),
	.NSIZE		(8   		),
	.DEPTH		(4      ),
	.ALMOST		(1      ),
	.DEF_VALUE	(0      )
)wfifo_nto1_inst(
	//--->> WRITE PORT <<-----
/*	input				    */	.wr_clk			(cinf.clock		      ),
/*	input				    */	.wr_rst_n       (cinf.rst_n && !rfifo_rst   ),
/*	input				    */	.wr_en          (rfifo_vld        ),
/*	input [NSIZE*DSIZE-1:0]	*/	.wr_data        (rfifo_data       ),
/*	output[4:0]			    */	.wr_count       (                 ),
/*	output				    */	.wr_full        (    ),
/*  output                  */  .wr_last        (    ),
/*	output				    */	.wr_almost_full (           ),
	//--->> READ PORT <<------
/*	input				    */	.rd_clk			(cinf.clock		),
/*	input				    */	.rd_rst_n       (cinf.rst_n      ),
/*	input				    */	.rd_en          (cinf.rd_ready        ),
/*	output[DSIZE-1:0]	    */	.rd_data        (cinf.rd_data         ),
/*  output                  */  .rd_last        (),
/*	output[4:0]			    */	.rd_count       (               ),
/*	output				    */	.rd_empty       (rfifo_empty    ),
/*	output				    */	.rd_almost_empty(               ),
/*	output				    */	.rd_vld			(cinf.rd_vld      	)
);
//---<<  RECV >>--------------------------
//--->> INTERCONNECT <<------------------
data_inf #(.DSIZE(3)) tmp_tras_inf0;
data_inf #(.DSIZE(3)) tmp_tras_inf1;
data_inf #(.DSIZE(3)) tmp_tras_inf2;
data_inf #(.DSIZE(3)) tmp_tras_inf3;
data_inf #(.DSIZE(3)) m00_tras_inf;

assign  tmp_tras_inf0.valid     = 0;
assign  tmp_tras_inf0.data      = 3'd0;

assign  tmp_tras_inf1.valid     = 0;
assign  tmp_tras_inf1.data      = 3'd0;

assign  tmp_tras_inf2.valid     = 0;
assign  tmp_tras_inf2.data      = 3'd0;

assign  tmp_tras_inf3.valid     = 0;
assign  tmp_tras_inf3.data      = 3'd0;

data_pipe_interconnect #(
    .DSIZE      (8)
)data_pipe_interconnect_inst(
/*    input             */  .clock         (cinf.clock       ),
/*    input             */  .rst_n         (cinf.rst_n       ),
/*    input             */  .clk_en        (1'b1        ),
/*    input [2:0]       */  .sw            ({exec_addr,exec_wr,exec_rd} ),
/*    output logic[2:0] */  .curr_path     (            ),

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
    .PERSCALER          (PERSCALER      )   // 1/3 SCL
)tras_4_tap_inst(
/*    input             */  .clock          (cinf.clock                 ),
/*    input             */  .rst_n          (cinf.rst_n                 ),
/*    input             */  .cmd_vld        (m00_tras_inf.valid    ),
/*    input [2:0]       */  .cmd            (m00_tras_inf.data     ),
/*    output logic      */  .cmd_ready      (m00_tras_inf.ready    ),

/*    output logic      */  .scl_o          (scl_o            ),
/*    output logic      */  .scl_t          (scl_t            ),
/*    output logic      */  .sda_o          (sda_o            ),
/*    output logic      */  .sda_t          (sda_t            ),
);
//---<< INTERCONNECT >>------------------

endmodule
