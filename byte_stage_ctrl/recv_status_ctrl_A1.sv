/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/17 上午11:50:17
madified:
***********************************************/
`timescale 1ns/1ps
module rd_status_ctrl_A1 #(
    parameter CSIZE = 4,
    parameter   MODULE_ID = 0
)(
    input                   clock,
    input                   rst_n,
    input                   exec_rd,
    input [23:0]            exec_rd_len,
    output logic            exec_rd_finish,
    input  [2:0]            recv_data,
    input                   recv_valid,
    //-->> tras 4 tap
    output logic            tras_cmd_vld,
    output logic[CSIZE-1:0] tras_cmd,
    input                   tras_cmd_ready,
    output logic[3:0]        tras_cmd_mid,
    output logic[1:0]        tras_cmd_proc_id,
    input  [3:0]             curr_mid,
    input  [1:0]             curr_proc_id,
    //--->> write fifo
    // input                   wfifo_rd_en,
    // output logic            wfifo_empty,
    output logic            rpipe_vld,
    input                   rpipe_ready,
    output logic            rpipe_data,
    //-->>
    output logic            timeout_cnt_req,
    input                   timeout,
    input                   slaver_ack_ok
);

// localparam  [CSIZE-1:0]
//                     CMD_IDLE    = 4'd0,
//                     CMD_START   = 4'd1,
//                     CMD_1       = 4'd2,
//                     CMD_0       = 4'd3,
//                     CMD_STOP    = 4'd4,
//                     CMD_ACK     = 4'd5,
//                     CMD_WR      = 4'd6,
//                     CMD_RD      = 4'd7,
//                     CMD_L0      = 4'd8,        //last 0
//                     CMD_L1      = 4'd9;

import parameter_package::*;

//----->> EXEC READ <<-----------------------------
typedef enum {RIDLE,RSET_SCL,RGET_DATA,R_WR_FIFO,RSET_ACK,RWAIT_ACK,RBURST_FSH,RFSH} RSTATUS ;
RSTATUS     rcstate,rnstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  rcstate <= RIDLE;
    else if(exec_rd)
                rcstate <= rnstate;
    else        rcstate <= RIDLE;

logic data_enough;
logic burst_cnt_fsh;

always@(*)
    case(rcstate)
    RIDLE:
        if(exec_rd)
                // rnstate     = WSET_START;
                rnstate     = RSET_SCL;
        else    rnstate     = RIDLE;
    RSET_SCL:
        if(tras_cmd_vld && tras_cmd_ready)
                rnstate     = RGET_DATA;
        else    rnstate     = RSET_SCL;
    RGET_DATA:
        if(recv_valid)
                rnstate     = R_WR_FIFO;
        else    rnstate     = RGET_DATA;
    R_WR_FIFO:
        if(rpipe_vld)begin
            if(!data_enough)
                    rnstate     = RSET_SCL;
            else    rnstate     = RSET_ACK;
        end else    rnstate     = R_WR_FIFO;
    RSET_ACK:
        if(tras_cmd_vld && tras_cmd_ready)
                rnstate = RWAIT_ACK;
        else    rnstate = RSET_ACK;
    RWAIT_ACK:
        // if(timeout || slaver_ack_ok)
               rnstate      = RBURST_FSH;
        // else   rnstate      = RWAIT_ACK;
    RBURST_FSH:
        if(burst_cnt_fsh)
               rnstate      = RFSH;
        else   rnstate      = RSET_SCL;
    RFSH:      rnstate      = RIDLE;
    default:   rnstate      = RIDLE;
    endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  timeout_cnt_req <= 1'b0;
    else
        case(rnstate)
        RWAIT_ACK:
                timeout_cnt_req <= 1'b1;
        default:timeout_cnt_req <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  exec_rd_finish  <= 1'b0;
    else
        case(rnstate)
        RFSH:   exec_rd_finish  <= 1'b1;
        default:exec_rd_finish  <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd_vld    <= 1'b0;
    else
        case(rnstate)
        RSET_SCL:   tras_cmd_vld    <= 1'b1;
        RSET_ACK:   tras_cmd_vld    <= 1'b1;
        default:    tras_cmd_vld    <= 1'b0;
        endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd    <= CMD_IDLE;
    else
        case(rnstate)
        RSET_SCL:   tras_cmd    <= CMD_OSCL;
        RSET_ACK:   tras_cmd    <= CMD_MACK;
        default:    tras_cmd    <= CMD_IDLE;
        endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  rpipe_vld <= 1'b0;
    else
        case(rnstate)
        R_WR_FIFO:
                // rpipe_vld <= rpipe_ready;
                rpipe_vld <= 1'b1;
        default:rpipe_vld <= 1'b0;
        endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  rpipe_data  <= 1'b0;
    else begin
        if(recv_valid)
                rpipe_data  <= (recv_data==RECV_CMD_1)? 1'b1 : 1'b0;
        else    rpipe_data  <= rpipe_data;
    end

logic [3:0]     cnt;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cnt     <= 4'd0;
    else begin
        // if(exec_rd)begin
        //     if(tras_cmd_vld && tras_cmd_ready)
        //         cnt     <= cnt + 1'b1;
        //     else
        //         cnt     <= cnt;
        // end else
        //     cnt     <= 4'd0;
        case(rnstate)
        RIDLE,RSET_ACK,RWAIT_ACK:
            cnt     <= 4'd0;
        default:begin
            if(tras_cmd_vld && tras_cmd_ready)
                cnt     <= cnt + 1'b1;
            else
                cnt     <= cnt;
        end
        endcase
    end

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  data_enough <= 1'b0;
    else        data_enough <= cnt==8;

//-----<< EXEC WRITE >>-----------------------------
//--->> BURST COUNTER <<-----------
logic [23:0]    bcnt;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  bcnt    <= 24'd0;
    else
        case(rnstate)
        RIDLE,RFSH: bcnt    <= 24'd0;
        RBURST_FSH: bcnt    <= bcnt + 1'b1;
        default:    bcnt    <= bcnt;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  burst_cnt_fsh   <= 1'b0;
    else        burst_cnt_fsh   <= bcnt == (exec_rd_len-1);

//--->> MODULE PROCESS ID <<---------------------
assign tras_cmd_mid     = MODULE_ID;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd_proc_id <= 2'd0;
    else
        case(rnstate)
        RFSH:   tras_cmd_proc_id <= tras_cmd_proc_id + 1'b1;
        default:tras_cmd_proc_id <= tras_cmd_proc_id;
        endcase
//---<< MODULE PROCESS ID >>---------------------
endmodule
