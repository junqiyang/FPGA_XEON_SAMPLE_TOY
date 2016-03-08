module matrix_io (
    input clk,
    input reset,
   //output
    output reg[511:0] out_matrix,
    output reg done,
    //input
    input start,
    input[1023:0] in_matrix
);




reg t_start;
reg[511:0] matrixA;
reg[511:0] matrixB;
wire[511:0] result;


always @ (*) begin
    matrixA[511:0] <= in_matrix[511:0];
    matrixB[31:0] = in_matrix[543:512];
    matrixB[63:32] = in_matrix[671:640];
    matrixB[95:64] = in_matrix[799:768];
    matrixB[127:96] = in_matrix[927:896];
    matrixB[159:128] = in_matrix[575:544];
    matrixB[191:160] = in_matrix[703:672];
    matrixB[223:192] = in_matrix[831:800];
    matrixB[255:224] = in_matrix[959:928];
    matrixB[287:256] = in_matrix[607:576];
    matrixB[319:288] = in_matrix[735:704];
    matrixB[351:320] = in_matrix[863:832];
    matrixB[383:352] = in_matrix[991:960];
    matrixB[415:384] = in_matrix[639:608];
    matrixB[447:416] = in_matrix[767:736];
    matrixB[479:448] = in_matrix[895:864];
    matrixB[511:480] = in_matrix[1023:992];
end

always @ (*) begin
   out_matrix <= result;
end


localparam[2:0]
    FSM_PRE = 2'd0,
    FSM_CAL = 2'd1,
    FSM_WAIT = 2'd2,
    FSM_DONE = 2'd3;

reg [2:0] fsm_cs, fsm_ns; 
wire t_done[0:24];


multiply i_multiply_0(.reset(reset), .start(t_start), .in_set_one(matrixA[127:0]), .in_set_two(matrixB[127:0]), .result(result[31:0]), .done(t_done[0]));
multiply i_multiply_1(.reset(reset), .start(t_start), .in_set_one(matrixA[127:0]), .in_set_two(matrixB[255:128]), .result(result[63:32]), .done(t_done[1]));
multiply i_multiply_2(.reset(reset), .start(t_start), .in_set_one(matrixA[127:0]), .in_set_two(matrixB[383:256]), .result(result[95:64]), .done(t_done[2]));
multiply i_multiply_3(.reset(reset), .start(t_start), .in_set_one(matrixA[127:0]), .in_set_two(matrixB[511:384]), .result(result[127:96]), .done(t_done[3]));
multiply i_multiply_4(.reset(reset), .start(t_start), .in_set_one(matrixA[255:128]), .in_set_two(matrixB[127:0]), .result(result[159:128]), .done(t_done[4]));
multiply i_multiply_5(.reset(reset), .start(t_start), .in_set_one(matrixA[255:128]), .in_set_two(matrixB[255:128]), .result(result[191:160]), .done(t_done[5]));
multiply i_multiply_6(.reset(reset), .start(t_start), .in_set_one(matrixA[255:128]), .in_set_two(matrixB[383:256]), .result(result[223:192]), .done(t_done[6]));
multiply i_multiply_7(.reset(reset), .start(t_start), .in_set_one(matrixA[255:128]), .in_set_two(matrixB[511:384]), .result(result[255:224]), .done(t_done[7]));
multiply i_multiply_8(.reset(reset), .start(t_start), .in_set_one(matrixA[383:256]), .in_set_two(matrixB[127:0]), .result(result[287:256]), .done(t_done[8]));
multiply i_multiply_9(.reset(reset), .start(t_start), .in_set_one(matrixA[383:256]), .in_set_two(matrixB[255:128]), .result(result[319:288]), .done(t_done[9]));
multiply i_multiply_10(.reset(reset), .start(t_start), .in_set_one(matrixA[383:256]), .in_set_two(matrixB[383:256]), .result(result[351:320]), .done(t_done[10]));
multiply i_multiply_11(.reset(reset), .start(t_start), .in_set_one(matrixA[383:256]), .in_set_two(matrixB[511:384]), .result(result[383:352]), .done(t_done[11]));
multiply i_multiply_12(.reset(reset), .start(t_start), .in_set_one(matrixA[511:384]), .in_set_two(matrixB[127:0]), .result(result[415:384]), .done(t_done[12]));
multiply i_multiply_13(.reset(reset), .start(t_start), .in_set_one(matrixA[511:384]), .in_set_two(matrixB[255:128]), .result(result[447:416]), .done(t_done[13]));
multiply i_multiply_14(.reset(reset), .start(t_start), .in_set_one(matrixA[511:384]), .in_set_two(matrixB[383:256]), .result(result[479:448]), .done(t_done[14]));
multiply i_multiply_15(.reset(reset), .start(t_start), .in_set_one(matrixA[511:384]), .in_set_two(matrixB[511:384]), .result(result[511:480]), .done(t_done[15]));


//reset
always @ (posedge clk) begin
      if(!reset) fsm_cs <= FSM_PRE;
      else         fsm_cs <= fsm_ns; 
   end

always @ (*) begin
      fsm_ns = fsm_cs;
      done = 1'b0;          
      t_start = 1'b0;

      case(fsm_cs)
         FSM_PRE:begin
            if(start) begin
               fsm_ns = FSM_CAL;
               $display("start");
            end
         end
         
         FSM_CAL:begin
            t_start = 1'b1;
            fsm_ns = FSM_WAIT;
            $display("wait");
	 end         

         FSM_WAIT:begin
	     if(t_done[0]) begin
                fsm_ns = FSM_DONE;
		$display("done");
	     end
         end

         FSM_DONE:begin                
		done = 1'd1;
                fsm_ns = FSM_DONE;         
         end         
   endcase
end


     
endmodule   
