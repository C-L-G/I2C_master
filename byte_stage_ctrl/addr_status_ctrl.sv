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
    parameter   ALEN = 7
)(
    input                   clock,
    input                   rst_n,
    input                   exec_addr,
    input [0:ALEN-1]        addr,
    output logic            exec_addr_finish,
    //-->> tras 4 tap
    output logic             tras_cmd_vld,
    output logic[2:0]        tras_cmd,
    input                    tras_cmd_ready,
    //-->>
    output logic             timeout_cnt_req,
    input                    timeout,
    input                    slaver_answer_ok
);

//----->> EXEC ADDRESS <<---------------------------
localparam  [2:0]   TRAS_CMD_IDLE    = 3'd0,
                    TRAS_CMD_START   = 3'd1,
                    TRAS_CMD_1       = 3'd2,
                    TRAS_CMD_0       = 3'd3,
                    TRAS_CMD_STOP    = 3'd4;

typedef enum {AIDLE,ASET_START,ASET_VALID,AWAIT_ANSWER,ASET_STOP,AFSH} ASTATUS ;
ASTATUS acstate,anstate;

always@(posedge clock,negedge rst_n)
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
        if(addr_cnt_fsh && tras_cmd_vld && tras_cmd_ready)
                anstate     = AWAIT_ANSWER;
        else    anstate     = ASET_VALID;
    AWAIT_ANSWER:
        if(slaver_answer_ok || timeout)
                anstate     = AFSH;
        else    anstate     = AWAIT_ANSWER;
    ASET_CMD_STOP:
        if(tras_cmd_ready && tras_cmd_vld)
                anstate     = AFSH;
        else    anstate     = ASET_STOP;
    AFSH:       anstate     = AIDLE;
    default:    anstate     = AIDLE;
    endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  tras_cmd_vld     <= 1'b0;
    else
        case(anstate)
        ASET_START: tras_cmd_vld <= 1'b1;
        ASET_VALID: tras_cmd_vld <= 1'b1;
        ASET_STOP:  tras_cmd_vld <= 1'b1;
        default:        tras_cmd_vld <= 1'b0;
        endcase

logic       addr_trigger_timeout_cnt;
always@(posedge clock,negedge rst_n)
    if(~rst_n)  addr_trigger_timeout_cnt <= 1'b0;
    else
        case(anstate)
        AWAIT_ANSWER:   addr_trigger_timeout_cnt <= 1'b1;
        default:        addr_trigger_timeout_cnt <= 1'b0;
        endcase

assign  timeout_cnt_req = addr_trigger_timeout_cnt;

logic[3:0] addr_cnt;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  addr_cnt    <= 4'd0;
    else
        if(exec_addr)begin
            if(tras_cmd_ready && tras_cmd_vld)
                    addr_cnt    <= addr_cnt + 1'b1;
            else    addr_cnt    <= addr_cnt;
        end else    addr_cnt    <= 4'd0;


always@(posedge clock,negedge rst_n)
    if(~rst_n)  addr_cnt_fsh    <= 1'b0;
    else begin
                addr_cnt_fsh    <= addr_cnt == (ALEN-1);  //start and wr/rd
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  tras_cmd    <= TRAS_CMD_IDLE;
    else
        case(anstate)
        ASET_START: tras_cmd    <= TRAS_CMD_START;
        ASET_VALID: tras_cmd    <= address_curr[addr_cnt]? CMD_1 : CMD_0;
        ASET_STOP:  tras_cmd    <= TRAS_CMD_STOP;
        default:    tras_cmd    <= TRAS_CMD_IDLE;
        endcase


always@(posedge clock,negedge rst_n)
    if(~rst_n)  exec_addr_finish    <= 1'b0;
    else
        case(anstate)
        AFSh:   exec_addr_finish   <= 1'b1;
        default:exec_addr_finish   <= 1'b0;
        endcase
//-----<< EXEC ADDRESS >>---------------------------
endmodule
