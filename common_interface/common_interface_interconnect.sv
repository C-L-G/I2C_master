/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/11/15 上午9:48:28
madified:
***********************************************/
`timescale 1ns/1ps
module common_interface_interconnect #(
    parameter DSIZE = 8,
    parameter COMPACT = "OFF"
)(
    common_interface.slaver  s0,
    common_interface.slaver  s1,
    common_interface.slaver  s2,
    common_interface.slaver  s3,
    common_interface.slaver  s4,
    common_interface.slaver  s5,
    common_interface.slaver  s6,
    common_interface.slaver  s7,
    common_interface.master  m0
);

assign  s0.status  = m0.status;
assign  s1.status  = m0.status;
assign  s2.status  = m0.status;
assign  s3.status  = m0.status;
assign  s4.status  = m0.status;
assign  s5.status  = m0.status;
assign  s6.status  = m0.status;
assign  s7.status  = m0.status;

typedef enum {IDLE,SL0,SL1,SL2,SL3,SL4,SL5,SL6,SL7,EX_REQ,REQ_EXEC,REQ_FSH} ROLL_ARBIT;

ROLL_ARBIT rnstate,rcstate;

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   rcstate <= IDLE;
    else            rcstate <= rnstate;

logic[2:0]      curr_port;

always@(*)
    case(rcstate)
    IDLE:   rnstate = SL0;
    SL0:if(s0.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL1;
    SL1:if(s1.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL2;
    SL2:if(s2.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL3;
    SL3:if(s3.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL4;
    SL4:if(s4.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL5;
    SL5:if(s5.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL6;
    SL6:if(s6.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL7;
    SL7:if(s7.cmd_vld)
                rnstate = EX_REQ;
        else    rnstate = SL0;
    EX_REQ:
        if(m0.cmd_ready && m0.cmd_vld)
                rnstate = REQ_EXEC;
        else    rnstate = EX_REQ;
    REQ_EXEC:
        // if(m0.cmd_ready)
        if(m0.finish)
                rnstate = REQ_FSH;
        else    rnstate = REQ_EXEC;
    REQ_FSH:
        case(curr_port)
        // 0:  rnstate = SL1;
        // 1:  rnstate = SL2;
        // 2:  rnstate = SL3;
        // 3:  rnstate = SL4;
        // 4:  rnstate = SL5;
        // 5:  rnstate = SL6;
        // 6:  rnstate = SL7;
        // 7:  rnstate = SL0;
        0:  rnstate = SL0;
        1:  rnstate = SL1;
        2:  rnstate = SL2;
        3:  rnstate = SL3;
        4:  rnstate = SL4;
        5:  rnstate = SL5;
        6:  rnstate = SL6;
        7:  rnstate = SL7;
        default:
            rnstate = IDLE;
        endcase
    default:rnstate = IDLE;
    endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   curr_port   <= 3'd0;
    else
        case(rnstate)
        SL0:    curr_port   <= 3'd0;
        SL1:    curr_port   <= 3'd1;
        SL2:    curr_port   <= 3'd2;
        SL3:    curr_port   <= 3'd3;
        SL4:    curr_port   <= 3'd4;
        SL5:    curr_port   <= 3'd5;
        SL6:    curr_port   <= 3'd6;
        SL7:    curr_port   <= 3'd7;
        default:curr_port   <= curr_port;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.cmd_vld  <= 1'b0;
    else
        case(rnstate)
        EX_REQ:     m0.cmd_vld  <= 1'b1;
        default:    m0.cmd_vld  <= 1'b0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.burst_len  <= 24'd0;
    else
        case(rnstate)
        EX_REQ:begin
            case(curr_port)
            0:  m0.burst_len  <= s0.burst_len;
            1:  m0.burst_len  <= s1.burst_len;
            2:  m0.burst_len  <= s2.burst_len;
            3:  m0.burst_len  <= s3.burst_len;
            4:  m0.burst_len  <= s4.burst_len;
            5:  m0.burst_len  <= s5.burst_len;
            6:  m0.burst_len  <= s6.burst_len;
            7:  m0.burst_len  <= s7.burst_len;
            default:;
            endcase
        end
        default:m0.burst_len  <= 24'd0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.addr  <= 0;
    else
        case(rnstate)
        EX_REQ:begin
            case(curr_port)
            0:  m0.addr  <= s0.addr;
            1:  m0.addr  <= s1.addr;
            2:  m0.addr  <= s2.addr;
            3:  m0.addr  <= s3.addr;
            4:  m0.addr  <= s4.addr;
            5:  m0.addr  <= s5.addr;
            6:  m0.addr  <= s6.addr;
            7:  m0.addr  <= s7.addr;
            default:;
            endcase
        end
        default:m0.addr  <= m0.addr;
        endcase


always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.cmd  <= 0;
    else
        case(rnstate)
        EX_REQ:begin
            case(curr_port)
            0:  m0.cmd  <= s0.cmd;
            1:  m0.cmd  <= s1.cmd;
            2:  m0.cmd  <= s2.cmd;
            3:  m0.cmd  <= s3.cmd;
            4:  m0.cmd  <= s4.cmd;
            5:  m0.cmd  <= s5.cmd;
            6:  m0.cmd  <= s6.cmd;
            7:  m0.cmd  <= s7.cmd;
            default:;
            endcase
        end
        default:m0.cmd  <= 24'd0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)begin
        s0.finish  <= 1'b0;
        s1.finish  <= 1'b0;
        s2.finish  <= 1'b0;
        s3.finish  <= 1'b0;
        s4.finish  <= 1'b0;
        s5.finish  <= 1'b0;
        s6.finish  <= 1'b0;
        s7.finish  <= 1'b0;
    end else begin
        s0.finish  <= 1'b0;
        s1.finish  <= 1'b0;
        s2.finish  <= 1'b0;
        s3.finish  <= 1'b0;
        s4.finish  <= 1'b0;
        s5.finish  <= 1'b0;
        s6.finish  <= 1'b0;
        s7.finish  <= 1'b0;
        case(rnstate)
        REQ_FSH:begin
            case(curr_port)
            0:  s0.finish  <= 1'b1;
            1:  s1.finish  <= 1'b1;
            2:  s2.finish  <= 1'b1;
            3:  s3.finish  <= 1'b1;
            4:  s4.finish  <= 1'b1;
            5:  s5.finish  <= 1'b1;
            6:  s6.finish  <= 1'b1;
            7:  s7.finish  <= 1'b1;
            default:;
            endcase
        end
        default:;
        endcase
    end

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)begin
        s0.cmd_ready  <= 1'b0;
        s1.cmd_ready  <= 1'b0;
        s2.cmd_ready  <= 1'b0;
        s3.cmd_ready  <= 1'b0;
        s4.cmd_ready  <= 1'b0;
        s5.cmd_ready  <= 1'b0;
        s6.cmd_ready  <= 1'b0;
        s7.cmd_ready  <= 1'b0;
    end else begin
        s0.cmd_ready  <= 1'b0;
        s1.cmd_ready  <= 1'b0;
        s2.cmd_ready  <= 1'b0;
        s3.cmd_ready  <= 1'b0;
        s4.cmd_ready  <= 1'b0;
        s5.cmd_ready  <= 1'b0;
        s6.cmd_ready  <= 1'b0;
        s7.cmd_ready  <= 1'b0;
        // case(curr_port)
        // 0:  s0.cmd_ready  <= m0.cmd_ready;
        // 1:  s1.cmd_ready  <= m0.cmd_ready;
        // 2:  s2.cmd_ready  <= m0.cmd_ready;
        // 3:  s3.cmd_ready  <= m0.cmd_ready;
        // 4:  s4.cmd_ready  <= m0.cmd_ready;
        // 5:  s5.cmd_ready  <= m0.cmd_ready;
        // 6:  s6.cmd_ready  <= m0.cmd_ready;
        // 7:  s7.cmd_ready  <= m0.cmd_ready;
        // default:;
        // endcase
        case(rnstate)
        SL0:    s0.cmd_ready  <= 1'b1;
        SL1:    s1.cmd_ready  <= 1'b1;
        SL2:    s2.cmd_ready  <= 1'b1;
        SL3:    s3.cmd_ready  <= 1'b1;
        SL4:    s4.cmd_ready  <= 1'b1;
        SL5:    s5.cmd_ready  <= 1'b1;
        SL6:    s6.cmd_ready  <= 1'b1;
        SL7:    s7.cmd_ready  <= 1'b1;
        default:;
        endcase
    end

logic   curr_port_vld;

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   curr_port_vld   <= 1'b0;
    else
        case(rnstate)
        REQ_EXEC:   curr_port_vld   <= 1'b1;
        default:    curr_port_vld   <= 1'b0;
        endcase

//---- about COMPACT ---------
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf0();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf1();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf2();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf3();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf4();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf5();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf6();
data_inf #(.DSIZE(DSIZE+1)) slaver_wr_data_inf7();

data_inf #(.DSIZE(DSIZE+1)) master_wr_data_inf();

assign slaver_wr_data_inf0.valid   = s0.wr_vld;
assign slaver_wr_data_inf1.valid   = s1.wr_vld;
assign slaver_wr_data_inf2.valid   = s2.wr_vld;
assign slaver_wr_data_inf3.valid   = s3.wr_vld;
assign slaver_wr_data_inf4.valid   = s4.wr_vld;
assign slaver_wr_data_inf5.valid   = s5.wr_vld;
assign slaver_wr_data_inf6.valid   = s6.wr_vld;
assign slaver_wr_data_inf7.valid   = s7.wr_vld;

assign slaver_wr_data_inf0.data    = {s0.wr_last,s0.wr_data};
assign slaver_wr_data_inf1.data    = {s1.wr_last,s1.wr_data};
assign slaver_wr_data_inf2.data    = {s2.wr_last,s2.wr_data};
assign slaver_wr_data_inf3.data    = {s3.wr_last,s3.wr_data};
assign slaver_wr_data_inf4.data    = {s4.wr_last,s4.wr_data};
assign slaver_wr_data_inf5.data    = {s5.wr_last,s5.wr_data};
assign slaver_wr_data_inf6.data    = {s6.wr_last,s6.wr_data};
assign slaver_wr_data_inf7.data    = {s7.wr_last,s7.wr_data};

assign s0.wr_ready  = slaver_wr_data_inf0.ready;
assign s1.wr_ready  = slaver_wr_data_inf1.ready;
assign s2.wr_ready  = slaver_wr_data_inf2.ready;
assign s3.wr_ready  = slaver_wr_data_inf3.ready;
assign s4.wr_ready  = slaver_wr_data_inf4.ready;
assign s5.wr_ready  = slaver_wr_data_inf5.ready;
assign s6.wr_ready  = slaver_wr_data_inf6.ready;
assign s7.wr_ready  = slaver_wr_data_inf7.ready;

assign master_wr_data_inf.ready = m0.wr_ready;
assign m0.wr_vld    = master_wr_data_inf.valid;
assign m0.wr_data   = master_wr_data_inf.data[0+:DSIZE];
assign m0.wr_last   = master_wr_data_inf.data[DSIZE];

logic   write_flag;

generate
if(COMPACT == "ON")begin
always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   write_flag  <= 1'b0;
    else
        case(rnstate)
        REQ_EXEC:   write_flag  <= 1'b1;
        default:    write_flag  <= 1'b0;
        endcase

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.wr_data  <= 0;
    else begin
        if(write_flag && m0.clk_en)begin
            case(curr_port)
            0:      m0.wr_data  <= (s0.wr_vld && m0.wr_ready)? s0.wr_data : m0.wr_data;
            1:      m0.wr_data  <= (s1.wr_vld && m0.wr_ready)? s1.wr_data : m0.wr_data;
            2:      m0.wr_data  <= (s2.wr_vld && m0.wr_ready)? s2.wr_data : m0.wr_data;
            3:      m0.wr_data  <= (s3.wr_vld && m0.wr_ready)? s3.wr_data : m0.wr_data;
            4:      m0.wr_data  <= (s4.wr_vld && m0.wr_ready)? s4.wr_data : m0.wr_data;
            5:      m0.wr_data  <= (s5.wr_vld && m0.wr_ready)? s5.wr_data : m0.wr_data;
            6:      m0.wr_data  <= (s6.wr_vld && m0.wr_ready)? s6.wr_data : m0.wr_data;
            7:      m0.wr_data  <= (s7.wr_vld && m0.wr_ready)? s7.wr_data : m0.wr_data;
            default:;
            endcase
        end else    m0.wr_data  <= m0.wr_data;
    end

always@(posedge m0.clock,negedge m0.rst_n)
    if(~m0.rst_n)   m0.wr_vld  <= 1'b0;
    else begin
        if(write_flag)begin
            if(m0.clk_en)begin
                case(curr_port)
                0:      m0.wr_vld  <= (s0.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s0.wr_vld && m0.wr_vld && m0.wr_ready);
                1:      m0.wr_vld  <= (s1.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s1.wr_vld && m0.wr_vld && m0.wr_ready);
                2:      m0.wr_vld  <= (s2.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s2.wr_vld && m0.wr_vld && m0.wr_ready);
                3:      m0.wr_vld  <= (s3.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s3.wr_vld && m0.wr_vld && m0.wr_ready);
                4:      m0.wr_vld  <= (s4.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s4.wr_vld && m0.wr_vld && m0.wr_ready);
                5:      m0.wr_vld  <= (s5.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s5.wr_vld && m0.wr_vld && m0.wr_ready);
                6:      m0.wr_vld  <= (s6.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s6.wr_vld && m0.wr_vld && m0.wr_ready);
                7:      m0.wr_vld  <= (s7.wr_vld && !m0.wr_vld) || (m0.wr_vld && !m0.wr_ready) || (s7.wr_vld && m0.wr_vld && m0.wr_ready);
                default:;
                endcase
            end else begin
                m0.wr_vld   <= m0.wr_vld;
            end
        end else    m0.wr_vld  <= 1'b0;
    end

assign s0.wr_last   = m0.wr_last;
assign s1.wr_last   = m0.wr_last;
assign s2.wr_last   = m0.wr_last;
assign s3.wr_last   = m0.wr_last;
assign s4.wr_last   = m0.wr_last;
assign s5.wr_last   = m0.wr_last;
assign s6.wr_last   = m0.wr_last;
assign s7.wr_last   = m0.wr_last;

assign s0.wr_ready   = m0.wr_ready;
assign s1.wr_ready   = m0.wr_ready;
assign s2.wr_ready   = m0.wr_ready;
assign s3.wr_ready   = m0.wr_ready;
assign s4.wr_ready   = m0.wr_ready;
assign s5.wr_ready   = m0.wr_ready;
assign s6.wr_ready   = m0.wr_ready;
assign s7.wr_ready   = m0.wr_ready;
end else begin
//---------------------------------------------------
data_pipe_interconnect #(
    .DSIZE      (DSIZE +1     )
)data_pipe_interconnect_inst(
/*  input             */  .clock          (m0.clock         ),
/*  input             */  .rst_n          (m0.rst_n         ),
/*  input             */  .clk_en         (m0.clk_en        ),
/*  input             */  .vld_sw         (curr_port_vld    ),
/*  input [2:0]       */  .sw             (curr_port        ),
/*  output logic[2:0] */  .curr_path      (),

/*  data_inf.slaver   */  .s00            (slaver_wr_data_inf0),
/*  data_inf.slaver   */  .s01            (slaver_wr_data_inf1),
/*  data_inf.slaver   */  .s02            (slaver_wr_data_inf2),
/*  data_inf.slaver   */  .s03            (slaver_wr_data_inf3),
/*  data_inf.slaver   */  .s04            (slaver_wr_data_inf4),
/*  data_inf.slaver   */  .s05            (slaver_wr_data_inf5),
/*  data_inf.slaver   */  .s06            (slaver_wr_data_inf6),
/*  data_inf.slaver   */  .s07            (slaver_wr_data_inf7),

/*  data_inf.master   */  .m00            (master_wr_data_inf )
);
//----------------------------------------------------
end
endgenerate

data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf0();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf1();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf2();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf3();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf4();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf5();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf6();
data_inf #(.DSIZE(DSIZE+1)) slaver_rd_data_inf7();

data_inf #(.DSIZE(DSIZE+1)) master_rd_data_inf();

assign s0.rd_vld    = slaver_rd_data_inf0.valid;
assign s1.rd_vld    = slaver_rd_data_inf1.valid;
assign s2.rd_vld    = slaver_rd_data_inf2.valid;
assign s3.rd_vld    = slaver_rd_data_inf3.valid;
assign s4.rd_vld    = slaver_rd_data_inf4.valid;
assign s5.rd_vld    = slaver_rd_data_inf5.valid;
assign s6.rd_vld    = slaver_rd_data_inf6.valid;
assign s7.rd_vld    = slaver_rd_data_inf7.valid;

assign {s0.rd_last,s0.rd_data}  = slaver_rd_data_inf0.data;
assign {s1.rd_last,s1.rd_data}  = slaver_rd_data_inf1.data;
assign {s2.rd_last,s2.rd_data}  = slaver_rd_data_inf2.data;
assign {s3.rd_last,s3.rd_data}  = slaver_rd_data_inf3.data;
assign {s4.rd_last,s4.rd_data}  = slaver_rd_data_inf4.data;
assign {s5.rd_last,s5.rd_data}  = slaver_rd_data_inf5.data;
assign {s6.rd_last,s6.rd_data}  = slaver_rd_data_inf6.data;
assign {s7.rd_last,s7.rd_data}  = slaver_rd_data_inf7.data;

assign slaver_rd_data_inf0.ready    = s0.rd_ready;
assign slaver_rd_data_inf1.ready    = s1.rd_ready;
assign slaver_rd_data_inf2.ready    = s2.rd_ready;
assign slaver_rd_data_inf3.ready    = s3.rd_ready;
assign slaver_rd_data_inf4.ready    = s4.rd_ready;
assign slaver_rd_data_inf5.ready    = s5.rd_ready;
assign slaver_rd_data_inf6.ready    = s6.rd_ready;
assign slaver_rd_data_inf7.ready    = s7.rd_ready;

assign m0.rd_ready =   master_rd_data_inf.ready;
assign master_rd_data_inf.valid            = m0.rd_vld ;
assign master_rd_data_inf.data[0+:DSIZE]   = m0.rd_data;
assign master_rd_data_inf.data[DSIZE]      = m0.rd_last;

data_pipe_interconnect_MM_S0 #(
    .DSIZE      (DSIZE+1)
)data_pipe_interconnect_MM_S0_inst(
/*  input             */  .clock          (m0.clock         ),
/*  input             */  .rst_n          (m0.rst_n         ),
/*  input             */  .clk_en         (m0.clk_en        ),
/*  input             */  .sw_vld         (curr_port_vld    ),
/*  input [2:0]       */  .sw             (curr_port        ),
/*  output logic[2:0] */  .curr_path      (),

/*  data_inf.master   */  .m00            (slaver_rd_data_inf0  ),
/*  data_inf.master   */  .m01            (slaver_rd_data_inf1  ),
/*  data_inf.master   */  .m02            (slaver_rd_data_inf2  ),
/*  data_inf.master   */  .m03            (slaver_rd_data_inf3  ),
/*  data_inf.master   */  .m04            (slaver_rd_data_inf4  ),
/*  data_inf.master   */  .m05            (slaver_rd_data_inf5  ),
/*  data_inf.master   */  .m06            (slaver_rd_data_inf6  ),
/*  data_inf.master   */  .m07            (slaver_rd_data_inf7  ),

/*  data_inf.slaver   */  .s00            (master_rd_data_inf   )
);


endmodule
