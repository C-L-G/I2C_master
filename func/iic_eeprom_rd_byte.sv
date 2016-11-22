/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/17 下午4:52:46
madified:
***********************************************/
`timescale 1ns/1ps
module iic_eeprom_rd_byte(
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

logic[23:0]         length = 8;
// assign cinf.cmd         = COMPLETE_WR;
assign cinf.addr        = 7'b1010_000;
// assign cinf.burst_len   = 2;

assign cinf.wr_last     = 0;

// assign cinf.rd_ready    = 1;

typedef enum {IDLE,SET_CMD0,SET_EEPROM_ADDR0,SET_CMD1,SET_EEPROM_ADDR1,GET_DATA,FSH} STATUS;
STATUS cstate,nstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cstate  = IDLE;
    else        cstate  = nstate;

logic rd_data_last;

always@(*)
    case(cstate)
    IDLE:
        if(enable)
                nstate  = SET_CMD0;
        else    nstate  = IDLE;
    SET_CMD0:
        if(cinf.cmd_ready)
                nstate  = SET_EEPROM_ADDR0;
        else    nstate  = SET_CMD0;
    SET_EEPROM_ADDR0:
        if(cinf.wr_ready)
                nstate  = SET_CMD1;
        else    nstate  = SET_EEPROM_ADDR0;
    SET_CMD1:
        if(cinf.cmd_ready)
                nstate  = SET_EEPROM_ADDR1;
        else    nstate  = SET_CMD1;
    SET_EEPROM_ADDR1:
        if(cinf.wr_ready)
                nstate  = GET_DATA;
        else    nstate  = SET_EEPROM_ADDR1;
    GET_DATA:
        if(rd_data_last && cinf.rd_vld && cinf.rd_ready)
                nstate  = FSH;
        else    nstate  = GET_DATA;
    FSH:        nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.cmd_vld    <= 1'b0;
    else
        case(nstate)
        SET_CMD0,SET_CMD1:
                cinf.cmd_vld    <= 1'b1;
        default:cinf.cmd_vld    <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)      cinf.cmd    <= MAIN_CMD_IDLE;
    else
        case(nstate)
        SET_CMD0:   cinf.cmd    <= WR_WNO_STOP;
        SET_CMD1:   cinf.cmd    <= COMPLETE_RD;
        default:    cinf.cmd    <= MAIN_CMD_IDLE;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)      cinf.burst_len    <= 0;
    else
        case(nstate)
        SET_CMD0:   cinf.burst_len    <= 1;
        SET_CMD1:   cinf.burst_len    <= length;
        default:    cinf.burst_len    <= 0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.wr_vld    <= 1'b0;
    else
        case(nstate)
        SET_EEPROM_ADDR0,SET_EEPROM_ADDR1:
                cinf.wr_vld    <= 1'b1;
        default:cinf.wr_vld    <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.wr_data    <= 8'd0;
    else
        case(nstate)
        SET_EEPROM_ADDR0:
                cinf.wr_data    <= 8'd0;
        SET_EEPROM_ADDR1:
                cinf.wr_data    <= 8'd0;
        default:cinf.wr_data    <= 8'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.rd_ready    <= 1'd0;
    else
        case(nstate)
        GET_DATA:
                cinf.rd_ready    <= 1'd1;
        default:cinf.rd_ready    <= 1'b0;
        endcase

logic[23:0]     cnt;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cnt     <= 24'd0;
    else
        case(nstate)
        IDLE:   cnt     <= 24'd0;
        default:begin
            if(cinf.rd_vld && cinf.rd_ready)
                    cnt     <= cnt + 1'b1;
            else    cnt     <= cnt;
        end
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  rd_data_last   <= 1'b0;
    else begin
        if(cinf.rd_vld && cinf.rd_ready && (cnt == (length-2)))
                rd_data_last   <= 1'b1;
        else if(cnt == (length-1))
                rd_data_last   <= 1'b1;
        else    rd_data_last   <= 1'b0;
    end

endmodule
