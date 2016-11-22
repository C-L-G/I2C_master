/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/14 上午9:19:37
madified:
***********************************************/
`timescale 1ns/1ps
module addr_status_ctrl #(
    parameter   ALEN    = 7,
    parameter   CSIZE   = 4,
    parameter   MODULE_ID = 0
)(
    input                   clock,
    input                   rst_n,
    input                   exec_addr,
    input                   wr_or_rd,       //WR:1 RD:0
    input [0:9]             addr,
    output logic            exec_addr_finish,
    //-->> tras 4 tap
    output logic             tras_cmd_vld,
    output logic[CSIZE-1:0]  tras_cmd,
    input                    tras_cmd_ready,
    output logic[3:0]        tras_cmd_mid,
    output logic[1:0]        tras_cmd_proc_id,
    input  [3:0]             curr_mid,
    input  [1:0]             curr_proc_id,
    //-->>
    output logic             timeout_cnt_req,
    input                    timeout,
    input                    slaver_ack_ok
);

//----->> EXEC ADDRESS <<---------------------------
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


typedef enum {AIDLE,ASET_START,ASET_VALID,ASET_WR_RD,ASET_ACK_SCL,ASET_STOP,AFSH,AWAIT_ACK} ASTATUS ;
ASTATUS acstate,anstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  acstate <= AIDLE;
    else if(exec_addr)
                acstate <= anstate;
    else        acstate <= AIDLE;

logic addr_cnt_fsh;

always@(*)
    case(acstate)
    AIDLE:
        if(exec_addr)
                anstate     = ASET_START;
        else    anstate     = AIDLE;
    ASET_START:
        if(tras_cmd_vld && tras_cmd_ready)
                anstate     = ASET_VALID;
        else    anstate     = ASET_START;
    ASET_VALID:
        if(addr_cnt_fsh)
                anstate     = ASET_WR_RD;
        else    anstate     = ASET_VALID;
    ASET_WR_RD:
        if(tras_cmd_vld && tras_cmd_ready)
                anstate     = ASET_ACK_SCL;
        else    anstate     = ASET_WR_RD;
    ASET_ACK_SCL:
        if(tras_cmd_vld && tras_cmd_ready)
                anstate     = AWAIT_ACK;
        else    anstate     = ASET_ACK_SCL;
    ASET_STOP:
        if(tras_cmd_ready && tras_cmd_vld)
                anstate     = AFSH;
        else    anstate     = ASET_STOP;
    AWAIT_ACK:
        if(timeout || slaver_ack_ok)
                anstate     = AFSH;
        else    anstate     = AWAIT_ACK;
    AFSH:       anstate     = AIDLE;
    default:    anstate     = AIDLE;
    endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd_vld     <= 1'b0;
    else
        case(anstate)
        ASET_START: tras_cmd_vld <= 1'b1;
        ASET_VALID: tras_cmd_vld <= 1'b1;
        ASET_WR_RD: tras_cmd_vld <= 1'b1;
        ASET_ACK_SCL:
                    tras_cmd_vld <= 1'b1;
        ASET_STOP:  tras_cmd_vld <= 1'b1;
        default:    tras_cmd_vld <= 1'b0;
        endcase

logic       addr_trigger_timeout_cnt;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  addr_trigger_timeout_cnt <= 1'b0;
    else
        case(anstate)
        AWAIT_ACK:   addr_trigger_timeout_cnt <= 1'b1;
        default:     addr_trigger_timeout_cnt <= 1'b0;
        endcase

assign  timeout_cnt_req = addr_trigger_timeout_cnt;

logic       data_cnt_en;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  data_cnt_en <= 1'b0;
    else
        case(anstate)
        ASET_VALID:     data_cnt_en <= 1'b1;
        default:        data_cnt_en <= 1'b0;
        endcase

logic[3:0] data_cnt;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  data_cnt    <= 4'd0;
    else
        case(anstate)
        ASET_VALID:begin
            if(tras_cmd_ready && tras_cmd_vld)
                    data_cnt    <= data_cnt + 1'b1;
            else    data_cnt    <= data_cnt;
        end
        default:    data_cnt    <= 4'd0;
        endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  addr_cnt_fsh    <= 1'b0;
    else begin
                addr_cnt_fsh    <= data_cnt == (ALEN-0) && tras_cmd_vld && tras_cmd_ready;  //start wr/rd
    end

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd    <= CMD_IDLE;
    else
        case(anstate)
        ASET_START: tras_cmd    <= CMD_START;
        ASET_VALID:begin
            if(tras_cmd_ready && tras_cmd_vld)
                    tras_cmd    <= addr[data_cnt]? CMD_1 : CMD_0;
            else    tras_cmd    <= tras_cmd;
        end
        ASET_WR_RD: tras_cmd    <= wr_or_rd? CMD_WR : CMD_RD;
        ASET_ACK_SCL:
                    tras_cmd    <= CMD_ACK;
        ASET_STOP:  tras_cmd    <= CMD_STOP;
        default:    tras_cmd    <= CMD_IDLE;
        endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  exec_addr_finish    <= 1'b0;
    else
        case(anstate)
        AFSH:   exec_addr_finish   <= 1'b1;
        default:exec_addr_finish   <= 1'b0;
        endcase
//-----<< EXEC ADDRESS >>---------------------------
//--->> MODULE PROCESS ID <<---------------------
assign tras_cmd_mid     = MODULE_ID;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tras_cmd_proc_id <= 2'd0;
    else
        case(anstate)
        AFSH:   tras_cmd_proc_id <= tras_cmd_proc_id + 1'b1;
        default:tras_cmd_proc_id <= tras_cmd_proc_id;
        endcase
//---<< MODULE PROCESS ID >>---------------------
endmodule
