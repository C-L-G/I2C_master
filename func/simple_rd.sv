/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/17 上午11:34:38
madified:
***********************************************/
`timescale 1ns/1ps
module simple_rd(
    input       enable,
    common_interface.master cinf
);

logic   clock,rst_n;
assign  clock   = cinf.clock;
assign  rst_n   = cinf.rst_n;


localparam      MAIN_CMD_IDLE = 4'd0,
                COMPLETE_WR = 4'd1,
                WR_WNO_STOP = 4'd2, //write without stop
                COMPLETE_RD = 4'd3,
                RD_WNO_STOP = 4'd4, //read without stop
                SET_IDLE    = 4'd5;

assign cinf.cmd         = COMPLETE_RD;
assign cinf.addr        = 7'b1010_000;
assign cinf.burst_len   = 1;

assign cinf.wr_data     = 8'b1000_0001;
assign cinf.wr_last     = 0;

assign cinf.rd_ready    = 1;

typedef enum {IDLE,SET_CMD,SET_DATA,FSH} STATUS;
STATUS cstate,nstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cstate  = IDLE;
    else        cstate  = nstate;

always@(*)
    case(cstate)
    IDLE:
        if(enable)
                nstate  = SET_CMD;
        else    nstate  = IDLE;
    SET_CMD:
        if(cinf.cmd_ready)
                nstate  = SET_DATA;
        else    nstate  = SET_CMD;
    SET_DATA:
        if(cinf.wr_ready)
                nstate  = FSH;
        else    nstate  = SET_DATA;
    FSH:        nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.cmd_vld    <= 1'b0;
    else
        case(nstate)
        SET_CMD:cinf.cmd_vld    <= 1'b1;
        default:cinf.cmd_vld    <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.wr_vld    <= 1'b0;
    else
        case(nstate)
        SET_DATA:
                cinf.wr_vld    <= 1'b1;
        default:cinf.wr_vld    <= 1'b0;
        endcase

endmodule
