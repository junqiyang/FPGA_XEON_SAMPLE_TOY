module multiply (
    //input
    input reset,
    input start,
    input wire[127:0]  in_set_one,
    input wire[127:0]  in_set_two,
    //output
    output reg[31:0] result,
    output reg done
);

localparam[3:0]
    FSM_PRE = 3'd0,
    FSM_MUL = 3'd1,
    FSM_ADDR_1 = 3'd2,
    FSM_ADDR_2 = 3'd3,
    FSM_ADDR_3 = 3'd4,
    FSM_DONE = 3'd5;

reg [2:0] fsm_cs, fsm_ns; 
reg [31:0] res_mul[0:4];

integer j;

always @ (*) begin
      if(!reset) fsm_cs <= FSM_PRE;
      else         fsm_cs <= fsm_ns; 
   end

always @ (*) begin
      fsm_ns = fsm_cs;
      done = 1'b0;          
      
      case(fsm_cs)
         FSM_PRE:begin
            if(start) begin
               fsm_ns = FSM_MUL;
               result = 32'b0;    
            end
         end
         
         FSM_MUL:begin
               res_mul[0] = in_set_one[31:0] * in_set_two[31:0];
               res_mul[1] = in_set_one[63:32] * in_set_two[63:32];
               res_mul[2] = in_set_one[95:64] * in_set_two[95:64];
               res_mul[3] = in_set_one[127:96] * in_set_two[127:96];
               fsm_ns = FSM_ADDR_1;
	 end
         
         FSM_ADDR_1:begin
               res_mul[0] = res_mul[0]+ res_mul[1];
               res_mul[2] = res_mul[2]+ res_mul[3];
               fsm_ns = FSM_ADDR_2;
         end

         FSM_ADDR_2:begin
               result = res_mul[0]+ res_mul[2];
               fsm_ns = FSM_DONE;
         end

         FSM_DONE:begin		
		done = 1'd1;
                fsm_ns = FSM_DONE;         
         end         
   endcase
end
endmodule


