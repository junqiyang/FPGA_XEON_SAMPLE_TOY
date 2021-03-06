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

   reg addr_cnt_inc;
   reg addr_cnt_clr;

   // --- This afu_user don't use mdata, just set to 0
   assign rd_req_mdata = 0;            
   assign wr_req_mdata = 0;            
 
   // --- Address counter 
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
   assign wr_req_addr = addr_cnt;           

   // --- Num cache lines to copy (from AFU context)
   wire [31:0] num_clines;
   assign num_clines = 32'd1;
   
   wire [511:0] w_cacheline_cells;
   reg [511:0] out_result;
   wire w_done;
   reg 	t_start;

   genvar i;
   generate
        begin: extract_from_cacheline
 	   assign w_cacheline_cells = rd_rsp_data; 
	end
   endgenerate

   // --- Wr Data
   //assign wr_req_data = w_cacheline_cells;
   assign wr_req_data= w_cacheline_cells/w_cacheline_cells;


   // --- FSM
   localparam [2:0]
     FSM_IDLE   = 3'd0,
     FSM_RD_REQ = 3'd1,
     FSM_RD_RSP = 3'd2,
     FSM_WR_REQ = 3'd3,
     FSM_WR_RSP = 3'd4,
     FSM_DONE   = 3'd5;
 
   reg [2:0] fsm_cs, fsm_ns; 
   reg [31:0] r_cnt,n_cnt;
   always @ (posedge clk) begin
      if(!reset_n) fsm_cs <= FSM_IDLE;
      else         fsm_cs <= fsm_ns; 
   end
   always@(posedge clk)
     r_cnt <= (!reset_n) ? 'd0 : n_cnt;

   always @ * begin
      fsm_ns = fsm_cs;
      addr_cnt_inc = 1'b0;
      addr_cnt_clr = 1'b0;
      rd_req_en = 1'b0;             
      wr_req_en = 1'b0;             
      done = 1'b0;          
      t_start = 1'b0;
      n_cnt = r_cnt;
      case(fsm_cs)
         FSM_IDLE: begin
            if(start) begin
               fsm_ns = FSM_RD_REQ;
            end
         end
         FSM_RD_REQ: begin
            // If there's no more data to copy
            if(addr_cnt >= num_clines) 
	      begin
		 fsm_ns = FSM_WR_REQ;
                 addr_cnt_clr = 1'b1;
              end 
            // There's more data to copy
            else begin
               // Issue rd_req
               if(!rd_req_almostfull) begin           
                  rd_req_en = 1'b1;             
                  fsm_ns = FSM_RD_RSP;
               end
            end
         end
         FSM_RD_RSP: 
	   begin
              // Receive rd_rsp, put read data into data_buf 
              if(rd_rsp_valid) 
		begin
		    // $display("addr_cnt = %d", addr_cnt);		   
		     addr_cnt_inc = 1'b1;
		     fsm_ns = FSM_RD_REQ;
		  end
	   end

        FSM_WR_REQ: 
	  begin
	     if(addr_cnt >= num_clines)
	       begin
		  fsm_ns = FSM_DONE;                  
	       end
             else if(!wr_req_almostfull) 
	      begin
                 wr_req_en = 1'b1;    // issue wr_req 
		 fsm_ns = FSM_WR_RSP; 
              end
          end
	FSM_WR_RSP:
	  begin
	     if(wr_rsp0_valid | wr_rsp1_valid)
	       begin
		  fsm_ns = FSM_WR_REQ;                  
		  addr_cnt_inc = 1'b1; // address counter ++
	       end
	  end
        FSM_DONE: 
	  begin
             done   = 1'b1;     // assert done signal 
             fsm_ns = FSM_DONE; // stay in this state
          end
      endcase
   end

endmodule

