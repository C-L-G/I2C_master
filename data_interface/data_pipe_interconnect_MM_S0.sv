/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version:
creaded: 2016/11/15 上午10:36:10
madified:
***********************************************/
`timescale 1ns/1ps
module data_pipe_interconnect_MM_S0 #(
    parameter   DSIZE = 8
)(
    input               clock,
    input               rst_n,
    input               clk_en,
    input               sw_vld,
    input [2:0]         sw,
    output logic[2:0]   curr_path,

    data_inf.master     m00,
    data_inf.master     m01,
    data_inf.master     m02,
    data_inf.master     m03,
    data_inf.master     m04,
    data_inf.master     m05,
    data_inf.master     m06,
    data_inf.master     m07,

    data_inf.slaver     s00
);

logic              from_up_vld;
logic[DSIZE-1:0]   from_up_data;
logic              to_up_ready;

// logic[7:0]         to_up_ready_array;
logic [7:0]             to_down_vld_array;

logic              from_down_ready;
logic              to_down_vld;
logic[DSIZE-1:0]   to_down_data;


assign  from_up_vld     = s00.valid;
assign  from_up_data    = s00.data;
assign  s00.ready       = to_up_ready;

assign  m00.data        = to_down_data;
assign  m01.data        = to_down_data;
assign  m02.data        = to_down_data;
assign  m03.data        = to_down_data;
assign  m04.data        = to_down_data;
assign  m05.data        = to_down_data;
assign  m06.data        = to_down_data;
assign  m07.data        = to_down_data;

assign  m00.valid       = to_down_vld_array[0];
assign  m01.valid       = to_down_vld_array[1];
assign  m02.valid       = to_down_vld_array[2];
assign  m03.valid       = to_down_vld_array[3];
assign  m04.valid       = to_down_vld_array[4];
assign  m05.valid       = to_down_vld_array[5];
assign  m06.valid       = to_down_vld_array[6];
assign  m07.valid       = to_down_vld_array[7];


always@(*)
    case(curr_path)
    0:  from_down_ready = m00.ready;
    1:  from_down_ready = m01.ready;
    2:  from_down_ready = m02.ready;
    3:  from_down_ready = m03.ready;
    4:  from_down_ready = m04.ready;
    5:  from_down_ready = m05.ready;
    6:  from_down_ready = m06.ready;
    7:  from_down_ready = m07.ready;
    default:
        from_down_ready = m00.ready;
    endcase




reg [3:0]       cstate,nstate;
localparam      IDLE                    = 4'd0,
                EM_CN_EM_BUF            = 4'd1,     //  empty connector,empty buffer
                VD_CN_EM_BUF            = 4'd2,     //  valid connector,empty buffer
                VD_CN_VD_BUF_CLD_OPU    = 4'd3,     //  valid connector,valid buffer,close down stream ,open upstream
                VD_CN_VD_BUF_OPD_CLU    = 4'd4,     //  valid connector,valid buffer,open down stream ,close upstream
                OVER_FLOW               = 4'd5;     //  error

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)   cstate  <= IDLE;
    else         cstate  <= nstate;

reg         over_flow_buffer;
wire        empty_buffer;
wire        full_buffer;
reg         connector_vld;

always@(*)
    case(cstate)
    IDLE:       nstate  = EM_CN_EM_BUF;
    EM_CN_EM_BUF:
        if(from_up_vld && to_up_ready && clk_en)
                nstate  = VD_CN_EM_BUF;
        else    nstate  = EM_CN_EM_BUF;
    VD_CN_EM_BUF:
        if(from_up_vld && to_up_ready && clk_en)begin
            if(from_down_ready)
                    nstate = VD_CN_EM_BUF;
            else    nstate = VD_CN_VD_BUF_CLD_OPU;
        end else begin
            if(!connector_vld)
                    nstate = EM_CN_EM_BUF;
            else    nstate = VD_CN_EM_BUF;
        end
    VD_CN_VD_BUF_CLD_OPU:
        if(over_flow_buffer)
                nstate = OVER_FLOW;
        //else if(from_up_vld && to_up_ready && clk_en)
        else if(full_buffer && clk_en)
                nstate = VD_CN_VD_BUF_OPD_CLU;
        else    nstate = VD_CN_VD_BUF_CLD_OPU;
    VD_CN_VD_BUF_OPD_CLU:
        if(empty_buffer && clk_en)
                nstate = VD_CN_EM_BUF;
        else    nstate = VD_CN_VD_BUF_OPD_CLU;
    OVER_FLOW:  nstate = OVER_FLOW;
    default:    nstate = IDLE;
    endcase
//--->> current path <<---------------------
logic curr_path_vld;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  curr_path   <= 3'd0;
    else
        case(nstate)
        IDLE,EM_CN_EM_BUF:
                curr_path   <= sw;
        default:curr_path   <= curr_path;
        endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  curr_path_vld   <= 1'd0;
    else
        case(nstate)
        IDLE,EM_CN_EM_BUF:
                curr_path_vld   <= sw_vld;
        default:curr_path_vld   <= curr_path_vld;
        endcase
//---<< current path >>---------------------
//--->> to up ready signal <<---------------
reg             to_u_ready_reg;
reg             over_buf_vld;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)   to_up_ready   <= 1'd0;
    else begin
        to_up_ready   <= 8'd0;
        case(nstate)
        EM_CN_EM_BUF,VD_CN_EM_BUF:
            if(clk_en)
                    to_up_ready  <= 1'b1;
            else    to_up_ready  <= to_up_ready;
        VD_CN_VD_BUF_CLD_OPU:begin
            if(clk_en)begin
                if(from_up_vld && to_up_ready)
                        to_up_ready   <= 1'b0;
                else    to_up_ready   <= to_up_ready;
            end else    to_up_ready   <= to_up_ready;
        end
        default:to_up_ready<= 1'b0;
        endcase
    end

// assign to_up_ready  = to_u_ready_reg;
//---<< to up ready signal >>---------------
//--->> CONNECTOR <<------------------
reg [DSIZE-1:0]     connector;
// reg                 connector_vld;
reg [DSIZE-1:0]     over_buf;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)   connector   <= {DSIZE{1'b0}};
    else
        case(nstate)
        VD_CN_EM_BUF:
            if(from_up_vld && to_up_ready && clk_en)
                    connector   <= from_up_data;
            else    connector   <= connector;
        VD_CN_VD_BUF_OPD_CLU:
            if(from_down_ready && to_down_vld && clk_en)
                    connector   <= over_buf;
            else    connector   <= connector;
        default:connector   <= connector;
        endcase


always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)   connector_vld   <= 1'b0;
    else
        case(nstate)
        VD_CN_EM_BUF:
            if(~(from_up_vld & to_up_ready) && from_down_ready && clk_en)
                    connector_vld   <= 1'b0;
            else    connector_vld   <= 1'b1;
        VD_CN_VD_BUF_OPD_CLU:
            if(clk_en)
                    connector_vld   <= 1'b1;
            else    connector_vld   <= connector_vld;
        default:connector_vld   <= 1'b0;
        endcase
//---<< CONNECTOR >>------------------
//----->> BUFFER <<---------------------
always@(posedge clock/*,negedge rst_n*/)begin:BUFFER_BLOCK
    if(~rst_n)begin
        over_buf    <= {DSIZE{1'b0}};
    end else begin
        case(nstate)
        VD_CN_VD_BUF_CLD_OPU:begin
            if(from_up_vld && !over_buf_vld && clk_en)
                    over_buf    <= from_up_data;
            else    over_buf    <= over_buf;
        end
        VD_CN_VD_BUF_OPD_CLU:begin
            if(from_down_ready && to_down_vld && clk_en)begin
                    over_buf    <= {DSIZE{1'b0}};
            end
        end
        default:;
        endcase
end end

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)   over_buf_vld    <= 1'b0;
    else
        case(nstate)
        VD_CN_VD_BUF_CLD_OPU:
            if(clk_en)
                    over_buf_vld <= from_up_vld;
            else    over_buf_vld <= over_buf_vld;
        VD_CN_VD_BUF_OPD_CLU:
            if(from_down_ready && to_down_vld && clk_en)
                    over_buf_vld <= 1'b0;
            else    over_buf_vld <= over_buf_vld;
        default:    over_buf_vld    <= 1'b0;
        endcase

assign empty_buffer = !over_buf_vld;
assign full_buffer  =  over_buf_vld;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)   over_flow_buffer    <= 1'b0;
    else
        case(nstate)
        VD_CN_VD_BUF_CLD_OPU:
            if( over_buf_vld && to_up_ready && from_up_vld && clk_en)
                    over_flow_buffer    <= 1'b1;
            else    over_flow_buffer    <= 1'b0;
        default:    over_flow_buffer    <= 1'b0;
        endcase
//-----<< BUFFER >>---------------------
//----->> to down data <<---------------
reg         to_d_wr_en_reg;

// always@(posedge clock,negedge rst_n)
//     if(~rst_n)  to_d_wr_en_reg  <= 1'b0;
//     else
//         case(nstate)
//         VD_CN_EM_BUF:
//             if(~(from_up_vld & to_up_ready) && from_down_ready && clk_en)
//                     to_d_wr_en_reg  <= 1'b0;
//             else    to_d_wr_en_reg  <= 1'b1;
//         VD_CN_VD_BUF_OPD_CLU:
//             if(clk_en)
//                     to_d_wr_en_reg  <= 1'b1;
//             else    to_d_wr_en_reg  <= to_d_wr_en_reg;
//         default:to_d_wr_en_reg  <= 1'b0;
//         endcase

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  to_down_vld_array  <= 8'b0000_0000;
    else begin
        to_down_vld_array  <= 8'b0000_0000;
        case(nstate)
        VD_CN_EM_BUF:
            if(~(from_up_vld & to_up_ready) && from_down_ready && clk_en)
                    to_down_vld_array[curr_path]  <= 1'b0;
            else    to_down_vld_array[curr_path]  <= curr_path_vld;
        VD_CN_VD_BUF_OPD_CLU:
            if(clk_en)
                    to_down_vld_array[curr_path]  <= curr_path_vld;
            else    to_down_vld_array[curr_path]  <= to_down_vld_array[curr_path];
        default:to_down_vld_array[curr_path]  <= 1'b0;
        endcase
    end
//-----<< to down data >>---------------
assign to_down_data = connector;
// assign to_down_vld  = to_d_wr_en_reg;
assign to_down_vld = to_down_vld_array[curr_path];


endmodule
