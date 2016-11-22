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
module fifo_tb;


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

parameter    WSIZE = 1;
parameter    RSIZE = 8;

logic               wr_ready;
logic               wr_vld = 0;
logic[WSIZE-1:0]    wr_data=0;
logic               fifo_full;

assign wr_ready = !fifo_full;

logic               rd_vld;
logic[RSIZE-1:0]    rd_data;
logic               rd_ready=0;
logic               rd_empty;

assign rd_vld   = !rd_empty;

fifo_1ton #(
	.DSIZE	     (WSIZE),
	.NSIZE	     (RSIZE/WSIZE),   	//1 2 4 8 16
	.DEPTH	     (4),   	//8*n
	.ALMOST      (1),
	.DEF_VALUE   (0)
)fifo_1ton_inst(
/*	input					*/ .wr_clk			(clock		      ),
/*	input					*/ .wr_rst_n        (rst_n            ),
/*	input					*/ .wr_en           (wr_vld           ),
/*	input [DSIZE-1:0]	    */ .wr_data         (wr_data          ),
/*	output					*/ .wr_full         (fifo_full       ),
/*  output                  */ .wr_last         (                 ),
/*	output					*/ .wr_almost_full  (                 ),
/*	output[5*NSIZE-1:0]		*/ .wr_count        (                 ),
/*	input					*/ .rd_clk          (clock		  ),
/*	input					*/ .rd_rst_n		(rst_n       ),
/*	input					*/ .rd_en           (rd_ready        ),
/*	output[DSIZE*NSIZE-1:0]	*/ .rd_data         (rd_data         ),
/*	output					*/ .rd_empty        (rd_empty          ),
/*  output                  */ .rd_last         (),
/*	output					*/ .rd_almost_empty (),
/*	output[4:0]		        */ .rd_count        (),
/*	output					*/ .rd_vld          (      	)
);

int wdata [$];

task automatic random_wr_task(int length =40,int data [$] = {});
int cnt = 0;
int rindex=0;
int cindex=0;
int dlength=0;
    dlength = data.size();
    wr_vld  = 0;
    wr_data = 0;
    @(posedge clock);
    while(cnt < length)begin
        cindex = cnt % RSIZE;
        rindex = cnt / RSIZE;
        if(dlength < rindex)begin
            rindex = rindex % dlength;
        end
        wr_vld  = #1 $urandom_range(10)%3 == 1;
        wr_data = #1 data[rindex][RSIZE-1-cindex];
        @(posedge clock);
        if(wr_vld)  cnt = cnt + 1;
    end
    wr_vld  = 0;
endtask

int     wcnt;
always@(posedge clock)begin
    if(~rst_n)  wcnt    <= 0;
    else begin
        if(wr_vld &&wr_ready)
                wcnt    <= wcnt + 1;
        else    wcnt    <= wcnt;
    end
end

initial begin
    wait(rst_n);
    wdata = {0,1,2,3,4,5,6,7};
    random_wr_task(40,wdata);
end

endmodule
