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
module wr_status_ctrl (
    input                   clock,
    input                   rst_n,
    input                   exec_wr,
    input [23:0]            exec_wr_len,
    output logic            exec_wr_finish,
    //-->> tras 4 tap
    output logic            tras_cmd_vld,
    output logic[2:0]       tras_cmd,
    input                   tras_cmd_ready,
    //--->> write fifo
    output logic            wfifo_rd_en,
    input                   wfifo_vld,
    input                   wfifo_data,
    //-->>
    output logic             timeout_cnt_req,
    input                    timeout,
    input                    slaver_answer_ok
);

localparam  [2:0]   CMD_IDLE    = 3'd0;
                    CMD_START   = 3'd1,
                    CMD_1       = 3'd2,
                    CMD_0       = 3'd3,
                    CMD_STOP    = 3'd4;

//----->> EXEC WRITE <<-----------------------------
typedef enum {WIDLE,WSET_START,WGET_DATA,WSET_VALID,WWAIT_ANSWER,WBURST_FSH,WFSH} WSTATUS ;
WSTATUS     wcstate,wnstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  wcstate <= WIDLE;
    else if(exec_wr)
                wcstate <= wnstate;
    else        wcstate <= WIDL

logic data_enough;
logic burst_cnt_fsh;

always@(*)
    case(wcstate)
    WIDLE:
        if(exec_wr)
                // wnstate     = WSET_START;
                wnstate     = WGET_DATA
        else    wnstate     = WIDLE;
    WSET_START:
        if(tras_cmd_vld && tras_cmd_ready)
                wnstate     = WGET_DATA;
        else    wnstate     = WSET_START
    WGET_DATA:
        if(wfifo_vld && wfifo_rd_en)
                wnstate     = WSET_VALID;
        else    wnstate     = WGET_DATA;
    WSET_VALID:
        if(data_enough)
                wnstate     = WWAIT_ANSWER;
        else if(tras_cmd_vld && tras_cmd_ready)
                wnstate     = WGET_DATA;
        else    wnstate     = WSET_VALID;
    WWAIT_ANSWER:
        if(timeout || slaver_answer_ok)
            if(exist_stop)
                    // wnstate = WSET_STOP;
                    wnstate = WBURST_FSH;
            else    wnstate = WBURST_FSH;
        else   wnstate      = WWAIT_ANSWER;
    WBURST_FSH:
        if(burst_cnt_fsh)
               wnstate      = WFSH;
        else   wnstate      = WGET_DATA;
    WFSH:      wnstate      = WIDLE;
    default:   wnstate      = WIDLE;
    endcase


always@(posedge clock,negedge rst_n)
    if(~rst_n)  timeout_cnt_req <= 1'b0;
    else
        case(wnstate)
        WWAIT_ANSWER:
                timeout_cnt_req <= 1'b1;
        default:timeout_cnt_req <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  exec_wr_finish  <= 1'b0;
    else
        case(wnstate)
        WFSH:   exec_wr_finish  <= 1'b1;
        default:exec_wr_finish  <= 1'b0;
        endcase

always@(posedge clock,negedge   rst_n)
    if(~rst_n)  tras_cmd_vld    <= 1'b0;
    else
        case(wnstate)
        WSET_START,WSET_VALID,WSET_STOP:
                tras_cmd_vld    <= 1'b1;
        default:tras_cmd_vld    <= 1'b0;
        endcase

logic   data;
always@(posedge clock,negedge   rst_n)
    if(~rst_n)  data    <= 1'b0;
    else begin
        if(wfifo_vld && wfifo_rd_en)
                data    <= wfifo_data;
        else    data    <= data;
    end

always@(posedge clock,negedge   rst_n)
    if(~rst_n)  tras_cmd    <= CMD_IDLE;
    else
        case(wnstate)
        WSET_START: tras_cmd    <= CMD_START;
        WSET_VALID: tras_cmd    <= data? CMD_1 : CMD_0;
        WSET_STOP:  tras_cmd    <= CMD_STOP;
        default:    tras_cmd    <= CMD_IDLE;
        endcase

always@(posedge clock,negedge   rst_n)
    if(~rst_n)  wfifo_rd_en <= 1'b0;
    else
        case(wnstate)
        WGET_DATA:
                wfifo_rd_en <= 1'b1;
        default:wfifo_rd_en <= 1'b0;
        endcase

logic [3:0]     cnt;
always@(posedge clock,negedge rst_n)
    if(~rst_n)  cnt     <= 4'd0;
    else begin
        if(exec_wr)begin
            if(tras_cmd_vld && tras_cmd_ready)
                cnt     <= cnt + 1'b1;
            else
                cnt     <= cnt;
        end else
            cnt     <= 4'd0;
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  data_enough <= 1'b0;
    else        data_enough <= cnt==7;

//-----<< EXEC WRITE >>-----------------------------
//--->> BURST COUNTER <<-----------
logic [23:0]    bcnt;
always@(posedge clock,negedge rst_n)
    if(~rst_n)  bcnt    <= 24'd0;
    else
        case(wnstate)
        WIDLE,WFSH: bcnt    <= 24'd0;
        WBURST_FSH: bcnt    <= bcnt + 1'b1;
        default:    bcnt    <= bcnt;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  burst_cnt_fsh   <= 1'b0;
    else        burst_cnt_fsh   <= bcnt == (exec_wr_len-1);


endmodule
