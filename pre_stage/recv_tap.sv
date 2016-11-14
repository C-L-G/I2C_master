/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/13 下午12:18:09
madified:
***********************************************/
`timescale 1ns/1ps
module rev_tap (
    input               clock,
    input               rst_n,
    input               scl_i,
    input               sda_i,
    output logic[2:0]   data,
    output logic        valid
);

localparam  [2:0]   CMD_START   = 3'd1,
                    CMD_1       = 3'd2,
                    CMD_0       = 3'd3,
                    CMD_STOP    = 3'd4;

logic       scl,sda;
cross_clk_sync #(
	.LAT	  (2  ),
	.DSIZE	  (1  )
)scl_cross_clk_sync_inst(
/*	input					*/ .clk        (clock  ),
/*	input					*/ .rst_n      (rst_n  ),
/*	input [DSIZE-1:0]		*/ .d          (scl_i  ),
/*	output[DSIZE-1:0]		*/ .q          (scl    )
);


cross_clk_sync #(
	.LAT	  (2  ),
	.DSIZE	  (1  )
)sda_cross_clk_sync_inst(
/*	input					*/ .clk        (clock  ),
/*	input					*/ .rst_n      (rst_n  ),
/*	input [DSIZE-1:0]		*/ .d          (sda_i  ),
/*	output[DSIZE-1:0]		*/ .q          (sda    )
);

logic       scl_raising,scl_falling;
edge_generator #(
	.MODE      ("NORMAL")   // FAST NORMAL BEST
)scl_edge_generator(
/*	input		*/.clk            (clock  ),
/*	input		*/.rst_n          (rst_n  ),
/*	input		*/.in             (scl    ),
/*	output		*/.raising        (scl_raising),
/*	output		*/.falling        (scl_falling)
);


logic       sda_raising,sda_falling;
edge_generator #(
	.MODE      ("NORMAL")   // FAST NORMAL BEST
)sda_edge_generator(
/*	input		*/.clk            (clock  ),
/*	input		*/.rst_n          (rst_n  ),
/*	input		*/.in             (sda    ),
/*	output		*/.raising        (sda_raising),
/*	output		*/.falling        (sda_falling)
);

logic   scl_lat2,sda_lat2;
cross_clk_sync #(
	.LAT	  (2  ),
	.DSIZE	  (2  )
)scl_sda_cross_clk_sync_inst(
/*	input					*/ .clk        (clock  ),
/*	input					*/ .rst_n      (rst_n  ),
/*	input [DSIZE-1:0]		*/ .d          ({scl,sda}  ),
/*	output[DSIZE-1:0]		*/ .q          ({scl_lat2,sda_lat2}    )
);


logic       stop_flag;
logic       start_flag;
logic       high_flag;
logic       low_flag;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  start_flag  <= 1'b0;
    else        start_flag  <= sda_falling && scl_lat2;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  stop_flag  <= 1'b0;
    else        stop_flag  <= sda_raising && scl_lat2;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  high_flag  <= 1'b0;
    else        high_flag  <= scl_raising && sda_lat2;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  low_flag  <= 1'b0;
    else        low_flag  <= scl_raising && !sda_lat2;


always@(posedge clock,negedge rst_n)
    if(~rst_n)  data    <= 3'd0;
    else begin
        if(start_flag)
                data    <= CMD_START;
        else if(stop_flag)
                data    <= CMD_STOP;
        else if(high_flag)
                data    <= CMD_1;
        else if(low_flag)
                data    <= CMD_0;
        else    data    <= 3'd0;
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  valid   <= 1'b0;
    else        valid   <= stop_flag |  start_flag | high_flag | low_flag;

endmodule
