/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/11/15 上午9:27:42
madified:
***********************************************/
interface common_interface #(
    parameter   CSIZE = 4,
    parameter   LSIZE = 24,
    parameter   DSIZE = 32,
    parameter   ASIZE = 10
)(
    input       clock,
    input       rst_n,
    input       clk_en
);

logic               cmd_vld;
logic[ASIZE-1:0]    addr;
logic[LSIZE-1:0]    burst_len;
logic               cmd_ready;
logic               finish;
logic[CSIZE-1:0]    cmd;
logic[4:0]          status;

//-->>wr port
logic                  wr_vld     ;
logic[DSIZE-1:0]       wr_data    ;
logic                  wr_ready   ;
logic                  wr_last    ;
//-->> rd port
logic                  rd_ready  ;
logic                  rd_vld    ;
logic[DSIZE-1:0]       rd_data   ;
logic                  rd_last   ;

modport master (
    input       clock,
    input       rst_n,
    input       clk_en,
    output      cmd_vld,
    output      addr,
    output      burst_len,
    input       cmd_ready,
    input       finish,
    output      cmd,
    input       status,
    output      wr_vld  ,
    output      wr_data ,
    input       wr_ready,
    output      wr_last ,
    output      rd_ready,
    input       rd_vld  ,
    input       rd_data ,
    input       rd_last
);

modport slaver (
    input       clock,
    input       rst_n,
    input       clk_en,
    input       cmd_vld,
    input       addr,
    input       burst_len,
    input       cmd_ready,
    input       finish,
    input       cmd,
    output      status,
    input       wr_vld  ,
    input       wr_data ,
    output      wr_ready,
    input       wr_last ,
    input       rd_ready,
    output      rd_vld  ,
    output      rd_data ,
    output      rd_last
);

endinterface
