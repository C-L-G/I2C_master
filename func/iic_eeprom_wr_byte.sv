/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/17 上午11:20:24
madified:
***********************************************/
`timescale 1ns/1ps
module iic_eeprom_wr_byte(
    input       enable,
    output logic finish,
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

logic [23:0]    length = 1+8;       //eeprom_addr + 7xdata

assign cinf.cmd         = COMPLETE_WR;
assign cinf.addr        = 7'b1010_000;
assign cinf.burst_len   = length;

assign cinf.rd_ready    = 1;

typedef enum {IDLE,SET_CMD,SET_EEPROM_ADDR,SET_DATA,FSH} STATUS;
STATUS cstate,nstate;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cstate  = IDLE;
    else        cstate  = nstate;

logic   data_last;
always@(*)
    case(cstate)
    IDLE:
        if(enable)
                nstate  = SET_CMD;
        else    nstate  = IDLE;
    SET_CMD:
        if(cinf.cmd_ready)
                nstate  = SET_EEPROM_ADDR;
        else    nstate  = SET_CMD;
    SET_EEPROM_ADDR:
        if(cinf.wr_ready)
                nstate  = SET_DATA;
        else    nstate  = SET_EEPROM_ADDR;
    SET_DATA:
        if(cinf.wr_ready)
            if(data_last)
                    nstate  = FSH;
            else    nstate  = SET_DATA;
        else    nstate  = SET_DATA;
    FSH:        nstate  = IDLE;
    default:    nstate  = IDLE;
    endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.cmd_vld    <= 1'b0;
    else
        case(nstate)
        SET_CMD:cinf.cmd_vld    <= 1'b1;
        default:cinf.cmd_vld    <= 1'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.wr_vld    <= 1'b0;
    else
        case(nstate)
        SET_DATA,SET_EEPROM_ADDR:
                cinf.wr_vld    <= 1'b1;
        default:cinf.wr_vld    <= 1'b0;
        endcase

logic [23:0]    cnt;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cnt <= 24'd0;
    else
        case(nstate)
        IDLE:   cnt <= 24'd0;
        default:begin
            if(cinf.wr_vld && cinf.wr_ready)
                    cnt     <= cnt + 1'b1;
            else    cnt     <= cnt;
        end
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cinf.wr_data    <= 8'd0;
    else
        case(nstate)
        SET_EEPROM_ADDR:
                cinf.wr_data    <= 8'd0;
        SET_DATA:
            // cinf.wr_data    <= cnt[7:0];
            if(cinf.wr_vld && cinf.wr_ready)
                    cinf.wr_data    <= cinf.wr_data + 1'b1;
            else    cinf.wr_data    <= cinf.wr_data;
        default:cinf.wr_data    <= 8'b0;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  data_last   <= 1'b0;
    else begin
        if(cinf.wr_vld && cinf.wr_ready && (cnt == (length-2)))
                data_last   <= 1'b1;
        else if(cnt == (length-1))
                data_last   <= 1'b1;
        else    data_last   <= 1'b0;
    end

assign cinf.wr_last     = data_last;


assign finish   = cinf.finish;

endmodule
