/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/13 上午9:53:45
madified:
***********************************************/
`timescale 1ns/1ps
module tras_4_tap #(
    parameter PERSCALER = 100,   // 1/4 SCL
    parameter CSIZE     = 4
)(
    input                   clock,
    input                   rst_n,
    input                   cmd_vld,
    input [CSIZE-1:0]       cmd,
    output logic            cmd_ready,
    input [3:0]             cmd_mid,
    input [1:0]             cmd_proc_id,
    output logic[3:0]       curr_mid,
    output logic[1:0]       curr_proc_id,

    output logic            scl_o,
    output logic            scl_t,
    output logic            sda_o,
    output logic            sda_t,
    output logic            ack_en
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

typedef enum {IDLE,GET_CMD,EXEC,TAP0,TAP1,TAP2,TAP3,TAP4,TAP5,FSH}    STATUS;

STATUS cstate,nstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;

logic   tap_finish;
logic   tap_finish_half;

always@(*)
    case(cstate)
    IDLE:
        if(cmd_vld)
                nstate  = GET_CMD;
        else    nstate  = IDLE;
    GET_CMD:    nstate  = EXEC;
    EXEC:       nstate  = TAP0;
    TAP0:
        if(tap_finish_half)
                nstate  = TAP1;
        else    nstate  = TAP0;
    TAP1:
        if(tap_finish_half)
                nstate  = TAP2;
        else    nstate  = TAP1;
    TAP2:
        if(tap_finish)
                nstate  = TAP3;
        else    nstate  = TAP2;
    TAP3:
        if(tap_finish_half)
                nstate  = TAP4;
        else    nstate  = TAP3;
    TAP4:
        if(tap_finish_half)
                nstate  = TAP5;
        else    nstate  = TAP4;
    TAP5:
        if(tap_finish_half)
                nstate  = FSH;
        else    nstate  = TAP5;
    FSH:        nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

logic [23:0]    tap_cnt;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tap_cnt <= 24'd0;
    else
        case(nstate)
        TAP0,TAP1,TAP3,TAP4,TAP5:begin
            if(tap_cnt  < PERSCALER/2)
                    tap_cnt <= tap_cnt + 1'b1;
            else    tap_cnt <= 24'd0;
        end
        TAP2:begin
            if(tap_cnt  < PERSCALER)
                    tap_cnt <= tap_cnt + 1'b1;
            else    tap_cnt <= 24'd0;
        end
        default:
            tap_cnt <= 24'd0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tap_finish <= 1'b0;
    else        tap_finish <= tap_cnt == PERSCALER;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  tap_finish_half <= 1'b0;
    else        tap_finish_half <= tap_cnt == PERSCALER/2;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cmd_ready   <= 1'b0;
    else
        case(nstate)
        IDLE:   cmd_ready   <= 1'b1;
        default:cmd_ready   <= 1'b0;
        endcase

logic[CSIZE-1:0]      curr_cmd;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  curr_cmd    <= CMD_IDLE;
    else
        case(nstate)
        GET_CMD:curr_cmd    <= cmd;
        default:curr_cmd    <= curr_cmd;
        endcase


/*
          _________
_____zzzz/         \zzzz___________
            _____
_____zzzz__/  |  \__zzzz___________
                    |  |<-TAP5
                 | |<-TAP4
             |  |<---- TAP3
           | |<---------- TAP2
        | |<------------- TAP1
    |   |<--------------- TAP0
   |<-------------------- EXEC

zzzz.zzz.__________________.zzzzzzz
        |__________________|
zzzzz         ________
    \___.___/         \____.______

zzzz.zzzz_____         zzzzzz.zzzzzz
              \______./
zzzz____._____.______.______.
                            \.zzzzzz
zzzz.zzzzzz.____.
                \____.zzzzz
      .____.____.____.____.zzzzz
zzzz./
*/

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  scl_o   <= 1'b1;
    else
        case(nstate)
        TAP0:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0,CMD_WR,CMD_L0:      scl_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      scl_o   <= 1'b0;
            CMD_STOP:   scl_o   <= 1'b0;
            CMD_ACK:    scl_o   <= 1'b0;
            CMD_OSCL:   scl_o   <= 1'b0;
            CMD_MACK:   scl_o   <= 1'b0;
            default:    scl_o   <= 1'b1;
            endcase
        end
        TAP1:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0,CMD_WR,CMD_L0:      scl_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      scl_o   <= 1'b0;
            CMD_STOP:   scl_o   <= 1'b0;
            CMD_ACK:    scl_o   <= 1'b0;
            CMD_OSCL:   scl_o   <= 1'b0;
            CMD_MACK:   scl_o   <= 1'b0;
            default:    scl_o   <= 1'b1;
            endcase
        end
        TAP2:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0,CMD_WR,CMD_L0:      scl_o   <= 1'b1;
            CMD_1,CMD_RD,CMD_L1:      scl_o   <= 1'b1;
            CMD_STOP:   scl_o   <= 1'b1;
            CMD_ACK:    scl_o   <= 1'b1;
            CMD_OSCL:   scl_o   <= 1'b1;
            CMD_MACK:   scl_o   <= 1'b1;
            default:    scl_o   <= 1'b1;
            endcase
        end
        TAP3:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0,CMD_WR,CMD_L0:      scl_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      scl_o   <= 1'b0;
            CMD_STOP:   scl_o   <= 1'b1;
            CMD_ACK:    scl_o   <= 1'b0;
            CMD_OSCL:   scl_o   <= 1'b0;
            CMD_MACK:   scl_o   <= 1'b0;
            default:    scl_o   <= 1'b1;
            endcase
        end
        TAP4:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0,CMD_WR,CMD_L0:      scl_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      scl_o   <= 1'b0;
            CMD_STOP:   scl_o   <= 1'b1;
            CMD_ACK:    scl_o   <= 1'b0;
            CMD_OSCL:   scl_o   <= 1'b0;
            CMD_MACK:   scl_o   <= 1'b0;
            default:    scl_o   <= 1'b1;
            endcase
        end
        default:scl_o   <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  sda_o   <= 1'b1;
    else
        case(nstate)
        TAP0:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b0;
            CMD_0,CMD_WR,CMD_L0:      sda_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      sda_o   <= 1'b0;
            CMD_STOP:   sda_o   <= 1'b0;
            CMD_ACK:    sda_o   <= 1'b0;
            CMD_OSCL:   sda_o   <= 1'b0;
            CMD_MACK:   sda_o   <= 1'b0;
            default:    sda_o   <= 1'b1;
            endcase
        end
        TAP1:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b1;
            CMD_0,CMD_WR,CMD_L0:      sda_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      sda_o   <= 1'b1;
            CMD_STOP:   sda_o   <= 1'b0;
            CMD_ACK:    sda_o   <= 1'b0;
            CMD_OSCL:   sda_o   <= 1'b0;
            CMD_MACK:   sda_o   <= 1'b0;
            default:    sda_o   <= 1'b1;
            endcase
        end
        TAP2:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b0;
            CMD_0,CMD_WR,CMD_L0:      sda_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      sda_o   <= 1'b1;
            CMD_ACK:    sda_o   <= 1'b0;
            CMD_STOP:   sda_o   <= 1'b0;
            CMD_OSCL:   sda_o   <= 1'b0;
            CMD_MACK:   sda_o   <= 1'b0;
            default:    sda_o   <= 1'b1;
            endcase
        end
        TAP3:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b0;
            CMD_0,CMD_WR,CMD_L0:      sda_o   <= 1'b0;
            CMD_1,CMD_RD,CMD_L1:      sda_o   <= 1'b1;
            CMD_ACK:    sda_o   <= 1'b0;
            CMD_STOP:   sda_o   <= 1'b1;
            CMD_OSCL:   sda_o   <= 1'b0;
            CMD_MACK:   sda_o   <= 1'b0;
            default:    sda_o   <= 1'b1;
            endcase
        end
        TAP4:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b0;
            CMD_0,CMD_WR,CMD_L0:      sda_o   <= 1'b0;
            CMD_1,CMD_ACK,CMD_RD,CMD_L1:      sda_o   <= 1'b0;
            CMD_STOP:   sda_o   <= 1'b1;
            CMD_ACK:    sda_o   <= 1'b0;
            CMD_OSCL:   sda_o   <= 1'b0;
            CMD_MACK:   sda_o   <= 1'b0;
            default:    sda_o   <= 1'b1;
            endcase
        end
        default:sda_o   <= 1'b0;
        endcase

logic   scl_rel_en;
logic   sda_rel_en;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  scl_rel_en    <= 1'b0;
    else        scl_rel_en    <= curr_cmd==CMD_STOP;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  sda_rel_en    <= 1'b0;
    else begin
        case(curr_cmd)
        CMD_ACK,CMD_STOP,CMD_WR,CMD_RD,CMD_L1,CMD_L0:
            sda_rel_en  <= 1'b1;
        default:
            sda_rel_en  <= 1'b0;
        endcase
        // sda_rel_en    <= curr_cmd==CMD_ACK || curr_cmd==CMD_STOP || curr_cmd==CMD_WR || curr_cmd==CMD_RD;
    end

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  scl_t   <= 1'b0;
    else
        case(nstate)
        TAP0,TAP1,TAP2,TAP3,TAP4:
                scl_t   <= 1'b1;
        TAP5:   scl_t   <= scl_rel_en? 1'b0 : scl_t;
        default:scl_t   <= scl_t;
        endcase

// logic   per_relax;
//
// always@(posedge clock/*,negedge rst_n*/)
//     if(~rst_n)  per_relax   <= 1'b0;
//     else
//         case(curr_cmd)
//         CMD_RD,CMD_WR,CMD_L0,CMD_L1:    //because next is ack
//                 per_relax   <= 1'b1;
//         default:per_relax   <= 1'b0;
//         endcase
//
// always@(posedge clock/*,negedge rst_n*/)
//     if(~rst_n)  sda_t   <= 1'b0;
//     else
//         case(nstate)
//         TAP1,TAP2,TAP3:
//                 sda_t   <= curr_cmd != CMD_ACK;     //when slaver ack ,dont driver sda
//         TAP4:begin
//                 // sda_t   <= (curr_cmd==CMD_WR || curr_cmd==CMD_RD)? 1'b0 : 1'b1;     //WR /TD pre relax
//                 sda_t   <= per_relax? 1'b0 : 1'b1;     //pre relax
//         end
//         TAP0,TAP5:
//                 sda_t   <= sda_rel_en? 1'b0 : 1'b1;
//         default:sda_t   <= sda_t;
//         endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  sda_t   <= 1'b0;
    else
        case(nstate)
        TAP1:begin
            case(curr_cmd)
            CMD_ACK:    sda_t   <= 1'b0;
            CMD_OSCL:   sda_t   <= 1'b0;
            CMD_MACK:   sda_t   <= 1'b1;
            default:    sda_t   <= 1'b1;
            endcase
        end
        TAP2:
            case(curr_cmd)
            CMD_ACK:    sda_t   <= 1'b0;
            CMD_OSCL:   sda_t   <= 1'b0;
            default:    sda_t   <= sda_t;
            endcase
        TAP3:
            case(curr_cmd)
            CMD_OSCL,CMD_ACK,CMD_L0,CMD_L1,CMD_WR,CMD_RD:
                        sda_t   <= 1'b0;
            default:    sda_t   <= sda_t;
            endcase
        TAP4:begin
            case(curr_cmd)
            CMD_L0,CMD_L1,CMD_WR,CMD_RD,CMD_MACK:
                        sda_t   <= 1'b0;
            default:    sda_t   <= sda_t;
            endcase
        end
        TAP5:begin
            case(curr_cmd)
            CMD_L0,CMD_L1,CMD_WR,CMD_RD:
                        sda_t   <= 1'b0;
            CMD_STOP:   sda_t   <= 1'b0;
            default:    sda_t   <= sda_t;
            endcase
        end
        default:sda_t   <= sda_t;
        endcase

// always@(posedge clock/*,negedge rst_n*/)
//     if(~rst_n)  scl_t   <= 1'b0;
//     else
//         case(nstate)
//         IDLE,GET_CMD:
//                 scl_t   <= 1'b0;
//         default:scl_t   <= 1'b1;
//         endcase
//
// always@(posedge clock/*,negedge rst_n*/)
//     if(~rst_n)  sda_t   <= 1'b0;
//     else
//         case(nstate)
//         IDLE,GET_CMD:
//                 sda_t   <= 1'b0;
//         default:sda_t   <= 1'b1;
//         endcase
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  ack_en  <= 1'b0;
    else if(curr_cmd == CMD_ACK)
            ack_en  <= 1'b1;
    else    ack_en  <= 1'b0;

//---->> MODULE PROCESS ID <<---------------
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  curr_mid   <= 4'b0;
    else
        case(nstate)
        GET_CMD:curr_mid   <= cmd_mid;
        default:curr_mid   <= curr_mid;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  curr_proc_id   <= 2'b0;
    else
        case(nstate)
        GET_CMD:curr_proc_id   <= cmd_proc_id;
        default:curr_proc_id   <= curr_proc_id;
        endcase
//----<< MODULE PROCESS ID >>---------------

endmodule
