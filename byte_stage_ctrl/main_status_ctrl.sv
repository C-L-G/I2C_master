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
module main_status_ctrl #(
    parameter ALEN = 7
)(
    input                   clock,
    input                   rst_n,
    //---> ctrl
    input [3:0]             cmd,     //write read
    input                   cmd_vld,
    output logic            cmd_ready,
    output logic            cmd_finish
    input [15:0]            addr,
    input [23:0]            burst_len,
    output logic [4:0]      curr_status,

    output logic            exec_addr,
    output logic[0:9]       address_curr,
    output logic[23:0]      exec_wr_len,
    input                   exec_addr_finish,
    output logic            exec_wr,
    input                   exec_wr_finish,
    output logic            exec_rd,
    input                   exec_rd_finish,
    // output logic            exist_stop,
    //-->> tras 4 tap
    output logic             tras_cmd_vld,
    output logic[2:0]        tras_cmd,
    input                    tras_cmd_ready,
    //--->> fifo ctrl
    output logic             wfifo_rst,
    input                    wfifo_empty,
    output logic             rfifo_rst,
    input                    rfifo_empty
);
localparam  [2:0]   CMD_IDLE    = 3'd0;
                    CMD_START   = 3'd1,
                    CMD_1       = 3'd2,
                    CMD_0       = 3'd3,
                    CMD_STOP    = 3'd4;

//----->> MAIN -CONTRL <<-------------------
localparam      MAIN_CMD_IDLE = 4'd0;
                COMPLETE_WR = 4'd1,
                WR_WNO_STOP = 4'd2, //write without stop
                COMPLETE_RD = 4'd3,
                RD_WNO_STOP = 4'd4; //read without stop
                SET_IDLE    = 4'd5

typedef enum {MIDLE,GET_CMD,EXEC_ADDR,EXEC_WR,EXEC_RD,SET_STOP,MFSH,RESET_FIFO} MSTATUS;

MSTATUS mcstate,mnstate;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  mcstate = MIDLE;
    else        mcstate = mnstate;

logic           curr_wr_or_rd;
logic           exist_stop;
logic [3:0]     curr_cmd;

always@(*)
    case(mcstate)
    MIDLE:
        if(cmd_vld)
                mnstate = GET_CMD;
        else    mnstate = MIDLE;
    GET_CMD:
        if(curr_cmd != SET_IDLE)
                mnstate = EXEC;
        else    mnstate = RESET_FIFO;
    EXEC_ADDR:
        if(exec_addr_finish)begin
            if(curr_wr_or_rd)
                mnstate = EXEC_WR;
            else
                mnstate = EXEC_RD;
        end else
                mnstate = EXEC_ADDR;
    EXEC_WR:
        if(exec_wr_finish)
                mnstate = SET_STOP;
        else    mnstate = EXEC_WR;
    EXEC_RD:
        if(exec_rd_finish)
                mnstate = MFSH;
        else    mnstate = EXEC_RD;
    SET_STOP:
        if(tras_cmd_vld && tras_cmd_ready)
                mnstate = MFSH;
        else    mnstate = SET_STOP;
    MFSH:       mnstate = MIDLE;
    // RESET_FIFO:
    //     if(wfifo_empty && rfifo_empty)
    //             mnstate = MIDLE;
    //     else    mnstate = RESET_FIFO;
    RESET_FIFO: mnstate = MIDLE;
    default:    mnstate = MIDLE;
    endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cmd_ready   <= 1'b0;
    else
        case(mnstate)
        MIDLE:  cmd_ready   <= 1'b1;
        default:cmd_ready   <= 1'b0;
        endcase
//
always@(posedge clock,negedge rst_n)
    if(~rst_n)  cmd_finish   <= 1'b0;
    else
        case(mnstate)
        MFSH:   cmd_finish   <= 1'b1;
        default:cmd_finish   <= 1'b0;
        endcase

logic   exec_wr_req;
logic   exec_addr_req;
logic   exec_rd_req;


always@(posedge clock,negedge rst_n)begin
    if(~rst_n)begin
        exec_wr_req     <= 1'b0;
        exec_addr_req   <= 1'b0;
        exec_rd_req     <= 1'b0;
    end else begin
        exec_wr_req     <= 1'b0;
        exec_addr_req   <= 1'b0;
        exec_rd_req     <= 1'b0;
        case(mnstate)
        EXEC_ADDR:  exec_addr_req   <= 1'b1;
        EXEC_WR:    exec_wr_req     <= 1'b1;
        EXEC_RD:    exec_rd_req     <= 1'b1;
        default:begin
            exec_wr_req     <= 1'b0;
            exec_addr_req   <= 1'b0;
            exec_rd_req     <= 1'b0;
        end
        endcase
end end


assign exec_wr     = exec_wr_req     ;
assign exec_addr   = exec_addr_req   ;
assign exec_rd     = exec_rd_req     ;


always@(posedge clock,negedge rst_n)
    if(~rst_n)  address_curr[0:ALEN-1]    <= {ALEN{1'd0}};
    else
        case(mnstate)
        GET_CMD:address_curr[0:ALEN-1]    <= addr[ALEN-1:0];
        default:address_curr[0:ALEN-1]    <= address_curr[0:ALEN-1];
        endcase

// logic [3:0]   curr_cmd;
always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_cmd    <= MAIN_CMD_IDLE;
    else
        case(mnstate)
        GET_CMD:curr_cmd    <= cmd;
        default:curr_cmd    <= curr_cmd;
        endcase

logic       exist_stop;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  exist_stop  < =1'b0;
    else begin
        exist_stop  <= curr_cmd==COMPLETE_WR || curr_cmd==COMPLETE_RD;
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_wr_or_rd  < =1'b0;
    else begin
        curr_wr_or_rd  <= curr_cmd==COMPLETE_WR || curr_cmd==WR_WNO_STOP;
    end
//-----<< MAIN -CONTRL >>-------------------
always@(posedge clock,negedge rst_n)
    if(~rst_n)  exec_wr_len    <= 24'd0;
    else
        case(mnstate)
        GET_CMD:exec_wr_len    <= burst_len;
        default:exec_wr_len    <= exec_wr_len;
        endcase

always@(posedge clock,negedge   rst_n)
    if(~rst_n)  tras_cmd_vld    <= 1'b0;
    else
        case(mnstate)
        SET_STOP:
                tras_cmd_vld    <= 1'b1;
        default:tras_cmd_vld    <= 1'b0;
        endcase

assign  tras_cmd    = CMD_STOP;
// --->> reset fifo <<-------------
logic   fifo_rst;
always@(posedge clock,negedge   rst_n)
    if(~rst_n)  fifo_rst    <= 1'b0;
    else
        case(mnstate)
        RESET_FIFO:
                fifo_rst    <= 1'b1;
        default:fifo_rst    <= 1'b0;
        endcase
assign  wfifo_rst   = fifo_rst;
assign  rfifo_rst   = fifo_rst;
// ---<< reset fifo >>-------------

endmodule
