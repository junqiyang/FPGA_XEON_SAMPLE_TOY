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



   // --- This afu_user don't use mdata, just set to 0
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

   // --- calculation counter 
   reg [31:0] addr_cnt_R;
   reg addr_cnt_inc_R;
   reg addr_cnt_clr_R;
   always @ (posedge clk) begin
      if(!reset_n) 
	addr_cnt_R <= 0;
      else 
        if(addr_cnt_inc_R) 
          addr_cnt_R <= addr_cnt_R + 1;
	else if(addr_cnt_clr_R)
	  addr_cnt_R <= 'd0;
   end   

   // --- Rd and Wr Addr
   assign rd_req_addr = addr_cnt;           
   assign wr_req_addr = addr_cnt;           

   // --- Num cache lines to copy (from AFU context)
   wire [31:0] num_clines;
   assign num_clines = 32'd1000000;
   
   reg [31:0] seed_1, seed_2, seed_3, seed_4, seed_5;
   reg [31:0] range;
   reg [31:0] a_1, a_2, a_3, a_4, a_5;
   reg [31:0] b_1, b_2, b_3, b_4, b_5;

   wire w_done;
   reg 	w_start = 1'b0;
   reg [479:0] out_result;

   reg  control = 1'b0;
   
   assign wr_req_data = out_result;
   
   always @ (posedge clk) begin
            if(control) begin
	     case(addr_cnt_R)
	       'd0:
		 begin
		     out_result[31:0]= seed_1;
   		     out_result[63:32]= seed_2;
   		     out_result[95:64]= seed_3;
   		     out_result[127:96]= seed_4;
   		     out_result[159:128]= seed_5;
                     
		 end
	       'd1:
		 begin
		     out_result[191:160]= seed_1;
   		     out_result[223:192]= seed_2;
   		     out_result[255:224]= seed_3;
   		     out_result[287:256]= seed_4;
   		     out_result[319:288]= seed_5;

		 end
	       'd2:
		 begin
		     out_result[351:320]= seed_1;
                     out_result[383:352]= seed_2;
                     out_result[415:384]= seed_3;
                     out_result[447:416]= seed_4;
                     out_result[479:448]= seed_5;

		 end
      	     endcase // case (addr_cnt)
         end
     end // always@ (posedge clk)



   localparam [2:0]
     FSM_WR_IDLE   = 3'd0,
     FSM_WR_REQ = 3'd1,
     FSM_WR_RSP = 3'd2,
     FSM_WR_DONE = 3'd3;
   
   reg [2:0] fsm_cs_w, fsm_ns_w; 
   always @ (posedge clk) begin
      if(!reset_n) fsm_cs_w <= FSM_WR_IDLE;
      else         fsm_cs_w <= fsm_ns_w; 
   end   

   always @ (posedge clk) begin
        fsm_ns_w = fsm_cs_w;
        addr_cnt_clr = 1'b0;
        addr_cnt_inc = 1'b0;
        wr_req_en = 1'b0; 
        done = 1'b0; 
        case(fsm_cs_w)
          FSM_WR_IDLE: begin
              if (w_start) begin
                 fsm_ns_w = FSM_WR_REQ;
              end
              
              if(addr_cnt >= num_clines) begin
		 fsm_ns_w = FSM_WR_DONE;                  
	      end          
           end

          FSM_WR_REQ:begin	                   
               if(!wr_req_almostfull)begin
                 wr_req_en = 1'b1;    // issue wr_req 
		 fsm_ns_w = FSM_WR_RSP; 
               end
          end

          FSM_WR_RSP:begin
	       if(wr_rsp0_valid | wr_rsp1_valid) begin
		  fsm_ns_w = FSM_WR_IDLE;                  
		  addr_cnt_inc = 1'b1; // address counter ++
	       end
	  end   
      
          FSM_WR_DONE:begin
             done   = 1'b1;     // assert done signal 
             fsm_ns_w = FSM_WR_DONE; // stay in this state
          end 
         
        endcase
    end



   // --- FSM
   localparam [2:0]
     FSM_IDLE   = 3'd0,
     FSM_RD_REQ = 3'd1,
     FSM_RD_RSP = 3'd2,
     FSM_RNG_RUN = 3'd3,
     FSM_RNG_WR = 3'd4,
     FSM_RNG_DONE = 3'd5;

   reg [2:0] fsm_cs, fsm_ns; 
   
   always @ (posedge clk) begin
      if(!reset_n) fsm_cs <= FSM_IDLE;
      else         fsm_cs <= fsm_ns; 
   end   

   always @ (posedge clk) begin
      fsm_ns = fsm_cs;
      rd_req_en = 1'b0; 
      addr_cnt_clr_R = 1'b0;
      addr_cnt_inc_R = 1'b0;
      control = 1'b0;
      w_start = 1'b0;
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
            if(rd_rsp_valid) begin
               range   <= rd_rsp_data[31:0];
               seed_1  <= rd_rsp_data[63:32];
	       a_1 <= rd_rsp_data[95:64];
	       b_1 <= rd_rsp_data[127:96];
	       seed_2 <= rd_rsp_data[159:128];
	       a_2 <= rd_rsp_data[191:160];
	       b_2 <= rd_rsp_data[223:192];
	       seed_3 <= rd_rsp_data[255:224];
	       a_3 <= rd_rsp_data[287:256];
	       b_3 <= rd_rsp_data[319:288];
	       seed_4 <= rd_rsp_data[351:320];
	       a_4 <= rd_rsp_data[383:352];
	       b_4 <= rd_rsp_data[415:384];
	       seed_5 <= rd_rsp_data[447:416];
	       a_5 <= rd_rsp_data[479:448];
               b_5 <= rd_rsp_data[511:480];
	       fsm_ns = FSM_RNG_RUN;
	    end
	 end

         
         FSM_RNG_RUN: begin
            if(addr_cnt >= num_clines) begin
		fsm_ns = FSM_RNG_DONE;                  
	    end

            if(addr_cnt_R >= 3) begin
		fsm_ns = FSM_RNG_WR;                  
	    end            
            else begin
                seed_1 <= (seed_1 * a_1 + b_1) % range;
                seed_2 <= (seed_2 * a_2 + b_2) % range;
                seed_3 <= (seed_3 * a_3 + b_3) % range;
                seed_4 <= (seed_4 * a_4 + b_4) % range;
                seed_5 <= (seed_5 * a_5 + b_5) % range;
                addr_cnt_inc_R = 1'b1;  
                control = 1'b1;       
            end
         end  

         FSM_RNG_WR: begin
            if(!w_start) begin
                 w_start = 1'b1;
                 addr_cnt_clr_R = 1'b1;
                 fsm_ns = FSM_RNG_RUN;                 
            end
         end              
         
         FSM_RNG_DONE: begin
             fsm_ns = FSM_RNG_DONE; // stay in this state
          end
      endcase
   end

endmodule

