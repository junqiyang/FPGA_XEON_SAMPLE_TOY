module afu_user #(ADDR_LMT = 20, MDATA = 14, CACHE_WIDTH = 512) 
(
   input                   clk,                
   input                   reset_n,                  
   
   // Read Request
   output [ADDR_LMT-1:0]   rd_req_addr,           
   output [MDATA-1:0] 	   rd_req_mdata,            
   output reg              rd_req_en,             
   input                   rd_req_almostfull,           
   
   // Read Response
   input                   rd_rsp_valid,       
   input [MDATA-1:0] 	   rd_rsp_mdata,            
   input [CACHE_WIDTH-1:0] rd_rsp_data,           

   // Write Request 
   output [ADDR_LMT-1:0]    wr_req_addr,           
   output [MDATA-1:0] 	    wr_req_mdata,            
   output [CACHE_WIDTH-1:0] wr_req_data,    
   output reg               wr_req_en,             
   input                    wr_req_almostfull,           
   
   // Write Response 
   input                    wr_rsp0_valid,       
   input [MDATA-1:0] 	    wr_rsp0_mdata,            
   input                    wr_rsp1_valid,       
   input [MDATA-1:0] 	    wr_rsp1_mdata,            
   
   // Start input signal
   input                    start,                

   // Done output signal 
   output reg               done,          

   // Control info from software
   input [511:0] 	    afu_context
);
   assign rd_req_mdata = 0;            
   assign wr_req_mdata = 0;   




   // --- Address counter 
   reg addr_cnt_inc;
   reg addr_cnt_clr;
   reg [31:0] addr_cnt;
   always @ (posedge clk) begin
      if(!reset_n) 
	addr_cnt <= 0;
      else 
        if(addr_cnt_inc) 
          addr_cnt <= addr_cnt + 1;
	else if(addr_cnt_clr)
	  addr_cnt <= 'd0;
   end   

   // --- Rd and Wr Addr
   assign rd_req_addr = addr_cnt;           
   assign wr_req_addr = 0;           

   // --- Num cache lines to copy (from AFU context)
   reg [31:0] num_clines;

   // --- put current data into a buffer
   reg [511:0] data_buffer;
   reg [31:0] object;
   always @ (*) begin
       if(rd_rsp_valid) begin
	       data_buffer <= rd_rsp_data;
       end
   end

   // --- result
   reg [31:0] final_result;
   reg [31:0] previous_result;
   reg [31:0] counter;
   wire [31:0] w_result;

  assign wr_req_data[31:0] = previous_result;  
  //assign wr_req_data[63:32] = final_result;
 // assign wr_req_data[31:0] = counter;
   //module count
   wire w_done;
   reg t_start;
   count test0  
   (  
      .done		(w_done),
      .result           (w_result),
	
      .clk		(clk),
      .rst		(!reset_n),
      .start		(t_start),
      .data_set		(data_buffer),
      .object           (object)
   );

   // --- FSM
   localparam [3:0]
     FSM_IDLE   = 4'd0,
     FSM_RD_REQ = 4'd1,
     FSM_RD_RSP = 4'd2,
     FSM_READ   = 4'd3,
     FSM_COUNT  = 4'd4,
     FSM_WAIT   = 4'd5,
     FSM_WR_REQ = 4'd6,
     FSM_WR_RSP = 4'd7,
     FSM_DONE   = 4'd8;
 
   reg [3:0] fsm_cs, fsm_ns; 

   always @ (*) begin
      if(!reset_n) fsm_cs <= FSM_IDLE;
      else         fsm_cs <= fsm_ns; 
   end

    
   always @ (posedge clk) begin
      fsm_ns = fsm_cs;
      addr_cnt_inc = 1'b0;
      addr_cnt_clr = 1'b0;
      rd_req_en    = 1'b0;             
      wr_req_en    = 1'b0;
      t_start      = 1'b0;            
      done         = 1'b0;          

      case(fsm_cs)
         FSM_IDLE: begin
            if(start) begin
               fsm_ns = FSM_RD_REQ;
            end
         end

         FSM_RD_REQ: begin
            if(!rd_req_almostfull) begin           
                rd_req_en = 1'b1;             
                fsm_ns = FSM_RD_RSP;
            end
         end

         FSM_RD_RSP: begin
            // Receive rd_rsp, put read data into data_buf 
            if(rd_rsp_valid) begin
                object <= data_buffer[31:0]; 
                num_clines <= data_buffer[63:32];
		final_result <= 32'd0; 
                fsm_ns = FSM_READ;  
                addr_cnt_inc = 1'b1;
             
            end
	 end
         
         FSM_READ: begin
            if(addr_cnt >= num_clines) begin
                fsm_ns = FSM_WR_REQ;                  
            end
            else begin
               if(!rd_req_almostfull) begin  		
                  rd_req_en = 1'b1;   
                  previous_result <= final_result;          
                  fsm_ns = FSM_COUNT;
               end
            end
         end
         
         FSM_COUNT: begin
             if(rd_rsp_valid) begin
                t_start = 1'b1;                     
                fsm_ns = FSM_WAIT;
	     end
          end
  
         FSM_WAIT: begin
             if(w_done) begin
                counter <= w_result;
                final_result <= w_result + previous_result;
                fsm_ns = FSM_READ;
                addr_cnt_inc = 1'b1;	
             end
         end
         
         FSM_WR_REQ: begin
             wr_req_en = 1'b1;    // issue wr_req 
             fsm_ns = FSM_WR_RSP; 
          end

	     FSM_WR_RSP: begin
	     if(wr_rsp0_valid | wr_rsp1_valid) begin                   
	        fsm_ns = FSM_DONE; 	        
	     end
	end

        FSM_DONE:begin
             done   = 1'b1;     // assert done signal 
             fsm_ns = FSM_DONE; // stay in this state

          end
      endcase
   end

endmodule

