/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/14 上午9:46:28
madified:
***********************************************/
`timescale 1ns/1ps
module wr_status_ctrl #(
    parameter CSIZE = 4,
    parameter   MODULE_ID = 0
)(
    input                   clock,
    input                   rst_n,
    input                   exec_wr,
    input [23:0]            exec_wr_len,
    output logic            exec_wr_finish,
    //-->> tras 4 tap
    output logic            tras_cmd_vld,
    output logic[CSIZE-1:0] tras_cmd,
    input                   tras_cmd_ready,
    output logic[3:0]       tras_cmd_mid,
    output logic[1:0]       tras_cmd_proc_id,
    input  [3:0]            curr_mid,
    input  [1:0]            curr_proc_id,
    //--->> write fifo
    output logic            wpipe_ready,
    // input                   wfifo_empty,
    input                   wpipe_vld,
    input                   wpipe_data,
    //-->>
    output logic             timeout_cnt_req,
    input                    timeout,
    input                    slaver_ack_ok
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
//----->> EXEC WRITE <<-----------------------------
typedef enum {WIDLE,WSET_START,WGET_DATA,WSET_VALID,WSET_ACK_SCL,WBURST_FSH,WFSH,WWAIT_ACK} WSTATUS ;
WSTATUS     wcstate,wnstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  wcstate <= WIDLE;
    else if(exec_wr)
                wcstate <= wnstate;
    else        wcstate <= WIDLE;

logic data_enough;
logic burst_cnt_fsh;

always@(*)
    case(wcstate)
    WIDLE:
        if(exec_wr)
                // wnstate     = WSET_START;
                wnstate     = WGET_DATA;
        else    wnstate     = WIDLE;
    WSET_START:
        if(tras_cmd_vld && tras_cmd_ready)
                wnstate     = WGET_DATA;
        else    wnstate     = WSET_START;
    WGET_DATA:
        // if(!wfifo_empty)
        if(wpipe_vld && wpipe_ready)
                wnstate     = WSET_VALID;
        else    wnstate     = WGET_DATA;
    WSET_VALID:
        if(tras_cmd_vld && tras_cmd_ready)begin
            if(data_enough)
                    wnstate     = WSET_ACK_SCL;
            else    wnstate     = WGET_DATA;
        end else    wnstate     = WSET_VALID;
    WSET_ACK_SCL:
        if(tras_cmd_vld && tras_cmd_ready)
                wnstate = WWAIT_ACK;
        else    wnstate = WSET_ACK_SCL;
    WWAIT_ACK:
        if(timeout || slaver_ack_ok)
               wnstate      = WBURST_FSH;
        else   wnstate      = WWAIT_ACK;
    WBURST_FSH:
        if(burst_cnt_fsh)
               wnstate      = WFSH;
        else   wnstate      = WGET_DATA;
    WFSH:      wnstate      = WIDLE;
    default:   wnstate      = WIDLE;
    endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  timeout_cnt_req <= 1'b0;
    else
        case(wnstate)
        WWAIT_ACK:
                timeout_cnt_req <= 1'b1;
        default:timeout_cnt_req <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  exec_wr_finish  <= 1'b0;
    else
        case(wnstate)
        WFSH:   exec_wr_finish  <= 1'b1;
        default:exec_wr_finish  <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd_vld    <= 1'b0;
    else
        case(wnstate)
        WSET_START,
        WSET_VALID:begin
            if(wpipe_vld && wpipe_ready)
                tras_cmd_vld    <= 1'b1;
            else if(tras_cmd_ready)
                tras_cmd_vld    <= 1'b0;
            else
                tras_cmd_vld    <= tras_cmd_vld;
        end
        WSET_ACK_SCL:
                tras_cmd_vld    <= 1'b1;
        default:tras_cmd_vld    <= 1'b0;
        endcase

logic   data;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  data    <= 1'b0;
    else begin
        if(wpipe_vld && wpipe_ready)
                data    <= wpipe_data;
        else    data    <= data;
    end

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd    <= CMD_IDLE;
    else
        case(wnstate)
        WSET_START: tras_cmd    <= CMD_START;
        WSET_VALID:begin
            if(wpipe_vld && wpipe_ready)begin
                if(!data_enough)
                        tras_cmd    <= wpipe_data? CMD_1 : CMD_0;
                else    tras_cmd    <= wpipe_data? CMD_L1 : CMD_L0;
            end else    tras_cmd    <= tras_cmd;
        end
        // WSET_STOP:  tras_cmd    <= CMD_STOP;
        WSET_ACK_SCL:  tras_cmd     <= CMD_ACK;
        default:       tras_cmd     <= CMD_IDLE;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  wpipe_ready <= 1'b0;
    else
        case(wnstate)
        WGET_DATA:
                wpipe_ready <= 1'b1;
        default:wpipe_ready <= 1'b0;
        endcase

logic [3:0]     cnt;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cnt     <= 4'd0;
    else begin
        // if(exec_wr)begin
        //     if(tras_cmd_vld && tras_cmd_ready)
        //         cnt     <= cnt + 1'b1;
        //     else
        //         cnt     <= cnt;
        // end else
        //     cnt     <= 4'd0;
        case(wnstate)
        WIDLE,WSET_ACK_SCL,WWAIT_ACK:
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
    else        data_enough <= cnt==7 || (cnt==6 && tras_cmd_vld && tras_cmd_ready);

//-----<< EXEC WRITE >>-----------------------------
//--->> BURST COUNTER <<-----------
logic [23:0]    bcnt;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  bcnt    <= 24'd0;
    else
        case(wnstate)
        WIDLE,WFSH: bcnt    <= 24'd0;
        WBURST_FSH: bcnt    <= bcnt + 1'b1;
        default:    bcnt    <= bcnt;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  burst_cnt_fsh   <= 1'b0;
    else        burst_cnt_fsh   <= bcnt == (exec_wr_len-1);

//
//--->> MODULE PROCESS ID <<---------------------
assign tras_cmd_mid     = MODULE_ID;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd_proc_id <= 2'd0;
    else
        case(wnstate)
        WFSH:   tras_cmd_proc_id <= tras_cmd_proc_id + 1'b1;
        default:tras_cmd_proc_id <= tras_cmd_proc_id;
        endcase
//---<< MODULE PROCESS ID >>---------------------
endmodule
