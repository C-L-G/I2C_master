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
    parameter PERSCALER = 100   // 1/4 SCL
)(
    input                   clock,
    input                   rst_n,
    input                   cmd_vld,
    input [2:0]             cmd,
    output logic            cmd_ready,

    output logic            scl_o,
    output logic            scl_t,
    output logic            sda_o,
    output logic            sda_t
);

localparam  [2:0]   CMD_START   = 3'd1,
                    CMD_1       = 3'd2,
                    CMD_0       = 3'd3,
                    CMD_STOP    = 3'd4;

typedef enum {IDLE,GET_CMD,EXEC,TAP0,TAP1,TAP2,FSH}    STATUS;

STATUS cstate,nstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cstate  <= IDLE;
    else        cstate  <= nstate;

logic   tap_finish;

always@(*)
    case(cstate)
    IDLE:
        if(cmd_vld)
                nstate  = GET_CMD;
        else    nstate  = IDLE;
    GET_CMD:    nstate  = EXEC;
    EXEC:       nstate  = TAP0;
    TAP0:
        if(tap_finish)
                nstate  = TAP1;
        else    nstate  = TAP0;
    TAP1:
        if(tap_finish)
                nstate  = TAP2;
        else    nstate  = TAP1;
    TAP2:
        if(tap_finish)
                nstate  = FSH;
        else    nstate  = TAP2;
    FSH:        nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

logic [23:0]    tap_cnt;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  tap_cnt <= 24'd0;
    else
        case(nstate)
        TAP0,TAP1,TAP2:begin
            if(tap_cnt  < PERSCALER)
                    tap_cnt <= tap_cnt + 1'b1;
            else    tap_cnt <= 24'd0;
        end
        default:
            tap_cnt <= 24'd0;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  tap_finish <= 1'b0;
    else        tap_finish <= tap_cnt == PERSCALER;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  cmd_ready   <= 1'b0;
    else
        case(nstate)
        IDLE:   cmd_ready   <= 1'b1;
        default:cmd_ready   <= 1'b0;
        endcase

logic[2:0]      curr_cmd;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  curr_cmd    <= 3'd0;
    else
        case(nstate)
        GET_CMD:curr_cmd    <= cmd;
        default:curr_cmd    <= curr_cmd;
        endcase


/*
    _________
___/         \___________
      _____
_____/     \_____________
           | |<- TAP2
     |     |<--- TAP1
   | |<-------- TAP0
   |<----------- EXEC
*/

always@(posedge clock,negedge rst_n)
    if(~rst_n)  scl_o   <= 1'b1;
    else
        case(nstate)
        TAP0:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0:      scl_o   <= 1'b0;
            CMD_1:      scl_o   <= 1'b0;
            CMD_STOP:   scl_o   <= 1'b0:
            default:    scl_o   <= 1'b1;
            endcase
        end
        TAP1:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b1;
            CMD_0:      scl_o   <= 1'b1;
            CMD_1:      scl_o   <= 1'b1;
            CMD_STOP:   scl_o   <= 1'b1:
            default:    scl_o   <= 1'b1;
            endcase
        end
        TAP2:begin
            case(curr_cmd)
            CMD_START:  scl_o   <= 1'b0;
            CMD_0:      scl_o   <= 1'b0;
            CMD_1:      scl_o   <= 1'b0;
            CMD_STOP:   scl_o   <= 1'b1:
            default:    scl_o   <= 1'b1;
            endcase
        end
        default:scl_o   <= 1'b1;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  sda_o   <= 1'b1;
    else
        case(nstate)
        TAP0:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b1;
            CMD_0:      sda_o   <= 1'b0;
            CMD_1:      sda_o   <= 1'b1;
            CMD_STOP:   sda_o   <= 1'b0:
            default:    sda_o   <= 1'b1;
            endcase
        end
        TAP1:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b0;
            CMD_0:      sda_o   <= 1'b0;
            CMD_1:      sda_o   <= 1'b1;
            CMD_STOP:   sda_o   <= 1'b0:
            default:    sda_o   <= 1'b1;
            endcase
        end
        TAP2:begin
            case(curr_cmd)
            CMD_START:  sda_o   <= 1'b0;
            CMD_0:      sda_o   <= 1'b0;
            CMD_1:      sda_o   <= 1'b1;
            CMD_STOP:   sda_o   <= 1'b1:
            default:    sda_o   <= 1'b1;
            endcase
        end
        default:sda_o   <= 1'b1;
        endcase

always@(posedge clock,negedge rst_n)
    if(~rst_n)  scl_t   <= 1'b0;
    else
        case(nstate)
        TAP0,TAP1,TAP2:
                scl_t   <= 1'b1;
        default:scl_t   <= 1'b0;
        endcase

assign sda_t    = scl_t;


endmodule
