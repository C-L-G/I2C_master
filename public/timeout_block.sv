/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/14 下午12:57:32
madified:
***********************************************/
`timescale 1ns/1ps
module timeout_block #(
    parameter   LEN  = 32'hFFFF_0000,
    parameter   MODE = "HOLD"   //HOLD EDGE
)(
    input           clock,
    input           rst_n,
    input           enable,
    input           start,        //catch posedge only
    output logic    timeout,
    output logic    timeout_pulse
);


logic en;

always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  en  <= 1'b0;
    else        en  <= enable;

wire start_raising;
wire start_falling;
edge_generator #(
	.MODE      ("NORMAL")   // FAST NORMAL BEST
)edge_generator_inst(
/*	input		*/   .clk     (clock  ),
/*	input		*/   .rst_n   (rst_n  ),
/*	input		*/   .in      (start  ),
/*	output		*/   .raising    (start_raising),
/*	output		*/   .falling    (start_falling)
);

integer    cnt;
always@(posedge clock/*,negedge rst_n*/)
    if(~rst_n)  cnt     <= 32'd0;
    else begin
        if(MODE=="NOLD")begin
            if(en)begin
                if(cnt < LEN)
                        cnt     <= cnt + 1'b1;
                else    cnt     <= cnt;
            end else    cnt     <= 32'd0;
        end else if(MODE=="EDGE")begin
            if(start_raising)
                    cnt     <= 32'd1;
            else if(cnt > 0)
                    cnt     <= cnt + 1;
            else    cnt     <= 32'd0;
        end
    end

always@(posedge clock/*,negedge rst_n*/)begin
    if(~rst_n)begin
        timeout_pulse   <= 1'b0;
        timeout         <= 1'b0;
    end else begin
        if(MODE=="HOLD")
            timeout     <= cnt == LEN;
        else
            timeout     <= 1'b0;

        if(MODE=="EDGE")
            timeout_pulse  <= cnt == LEN;
        else
            timeout_pulse   <= 1'b0;
end end

endmodule
