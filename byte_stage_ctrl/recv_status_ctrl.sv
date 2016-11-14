/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/14 上午10:55:17
madified:
***********************************************/
`timescale 1ns/1ps
module recv_status_ctrl (
    input                   clock,
    input                   rst_n,
    input                   exec_rd,
    output logic            exec_rd_finish,
    input  [2:0]            recv_data,
    input                   recv_valid,
    //-->> read fifo
    output logic            rfifo_vld,
    output logic [7:0]      rfifo_data,
    //-->> tras 4 tap
    output logic             tras_cmd_vld,
    output logic[2:0]        tras_cmd,
    input                    tras_cmd_ready,
    output logic             slaver_answer_ok
);
localparam  [2:0]   RECV_CMD_START   = 3'd1,
                    RECV_CMD_1       = 3'd2,
                    RECV_CMD_0       = 3'd3,
                    RECV_CMD_STOP    = 3'd4;

//
localparam  [2:0]   TRAS_CMD_IDLE    = 3'd0,
                    TRAS_CMD_START   = 3'd1,
                    TRAS_CMD_1       = 3'd2,
                    TRAS_CMD_0       = 3'd3,
                    TRAS_CMD_STOP    = 3'd4,
                    TRAS_CMD_ANSWER  = 3'd2;

typedef enum {RIDLE,RGET_DATA,WR_FIFO,RSET_ANSWER,RFSH} RSTATUS;
RSTATUS rnstate,rcstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  rcstate <= RIDLE;
    else if(exec_rd)
                rcstate <= rnstate;
    else        rcstate <= RIDLE;

logic   rcnt_fsh;

always@(*)
    case(rcstate)
    RIDLE:
        if(exec_rd)
                rnstate = RGET_DATA;
        else    rnstate = RIDLE;
    RGET_DATA:
        if(recv_data==CMD_STOP && recv_valid)
                rnstate = RFSH;
        else if(rcnt_fsh)
                rnstate = WR_FIFO;
        else    rnstate = RGET_DATA;
    WR_FIFO:    rnstate = RSET_ANSWER;
    RSET_ANSWER:
        if(tras_cmd_vld && tras_cmd_ready)
                rnstate = RGET_DATA;
        else    rnstate = RSET_ANSWER;
    RFSH:       rnstate = RIDLE;
    default:    rnstate = RIDLE;
    endcase

logic           data_bit;

assign data_bit = (recv_data==RECV_CMD_1)? 1'b1 : 1'b0;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  rfifo_data    <= 8'b0000_0000;
    else begin
        case(rnstate)
        RGET_DATA:begin
            if(recv_valid)
                    rfifo_data <= {rfifo_data[6:0],data_bit};
            else    rfifo_data <= rfifo_data;
        end
        default:    rfifo_data <= rfifo_data;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  rfifo_vld   <= 1'b0;
    else
        case(rnstate)
        WR_FIFO:    rfifo_vld   <= 1'b1;
        default:    rfifo_vld   <= 1'b0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  slaver_answer_ok    <= 1'b0;
    else begin
        if(~exec_rd)
                slaver_answer_ok    <= recv_data==RECV_CMD_1 && recv_valid;
        else    slaver_answer_ok    <= 1'b0;
    end

     
endmodule
