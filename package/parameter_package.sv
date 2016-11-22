/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/17 上午9:58:10
madified:
***********************************************/
package parameter_package;
localparam  [4-1:0]         CMD_IDLE    = 4'd0,
                            CMD_START   = 4'd1,
                            CMD_1       = 4'd2,
                            CMD_0       = 4'd3,
                            CMD_STOP    = 4'd4,
                            CMD_ACK     = 4'd5,
                            CMD_WR      = 4'd6,
                            CMD_RD      = 4'd7,
                            CMD_L0      = 4'd8,        //last 0
                            CMD_L1      = 4'd9,
                            CMD_OSCL    = 4'd10,      //only scl
                            CMD_MACK    = 4'd11;

localparam  [2:0]   RECV_CMD_START   = 3'd1,
                    RECV_CMD_1       = 3'd2,
                    RECV_CMD_0       = 3'd3,
                    RECV_CMD_STOP    = 3'd4;

endpackage
