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
	  addr_cnt <= 0;
   end   

   // --- Rd and Wr Addr
   assign rd_req_addr = addr_cnt;           
   assign wr_req_addr = addr_cnt;           

   // --- Num cache lines to copy (from AFU context)
   reg [31:0] num_clines;
   //assign num_clines = 32'd10;
   
   wire [511:0] w_cacheline_cells;
   reg [31:0] counter;

   wire w_done;
   reg 	t_start;

   assign wr_req_data= counter;
   // --- FSM
   localparam [5:0]
     FSM_IDLE   = 5'd0,
     FSM_RD_REQ = 5'd1,
     FSM_RD_RSP = 5'd2,
     FSM_RD_R = 5'd3,
     FSM_RD_S = 5'd4,
     FSM_SUM = 5'd5,
     FSM_WR_REQ = 5'd6,
     FSM_WR_RSP = 5'd7,
     FSM_DONE   = 5'd8;
 
   reg [4:0] fsm_cs, fsm_ns; 
   reg [31:0] r_cnt,n_cnt;
   reg [31:0] cp1,cp2,cp3,cp4,cp5,cp6,cp7,cp8,cp9,cp10,cp11,cp12,cp13,cp14,cp15,cp16;


   always @ (posedge clk) begin
      if(!reset_n) fsm_cs <= FSM_IDLE;
      else         fsm_cs <= fsm_ns; 
   end
   always@(posedge clk)
     r_cnt <= (!reset_n) ? 'd0 : n_cnt;



   reg [32:0] object;
   always @ (posedge clk) begin
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
               if(!rd_req_almostfull) begin           
                  rd_req_en = 1'b1;             
                  fsm_ns = FSM_RD_RSP;
               end
         end

         FSM_RD_RSP: 
	   begin
              // Receive rd_rsp, put read data into data_buf 
              if(rd_rsp_valid) 
		begin
                     object = rd_rsp_data[31:0]; 
                     $display("target: %d",object);
                     num_clines = rd_rsp_data[63:32];
                     $display("num of reading: %d",num_clines);
                     fsm_ns = FSM_RD_R;  
                     counter = 0;                
		end
	    end
         
         FSM_RD_R:
          begin
               if(addr_cnt > num_clines) begin
                   addr_cnt_clr = 1'b1;
                   fsm_ns = FSM_WR_REQ;                  
               end
               else begin
                   if(!rd_req_almostfull) begin           
                      rd_req_en = 1'b1;             
                      fsm_ns = FSM_RD_S;
                   end
               end
          end
         
         FSM_RD_S:
          begin
              if(rd_rsp_valid) 
		begin
                     cp1 = object && rd_rsp_data[31:0];
                     cp2 = object && rd_rsp_data[63:32];
                     cp3 = object && rd_rsp_data[95:64];
                     cp4 = object && rd_rsp_data[127:96];
                     cp5 = object && rd_rsp_data[159:128];
                     cp6 = object && rd_rsp_data[191:160];
                     cp7 = object && rd_rsp_data[223:192];
                     cp8 = object && rd_rsp_data[255:224];
                     cp9 = object && rd_rsp_data[287:256];
                     cp10 = object && rd_rsp_data[319:288];
                     cp11 = object && rd_rsp_data[351:320];
                     cp12 = object && rd_rsp_data[383:352];
                     cp13 = object && rd_rsp_data[415:384];
                     cp14 = object && rd_rsp_data[447:416];
                     cp15 = object && rd_rsp_data[479:448];
                     cp16 = object && rd_rsp_data[511:480];
                     fsm_ns = FSM_SUM;
		end
          end

         FSM_SUM:
          begin              
              counter = counter +cp1 +cp2 +cp3 +cp4 +cp5 +cp6 +cp7 +cp8 +cp9 +cp10 +cp11 +cp12 +cp13 +cp14 +cp15 +cp16;
              addr_cnt_inc = 1'b1; // address counter ++              
              fsm_ns = FSM_RD_R; 
          end
         
         FSM_WR_REQ: 
	  begin
              //addr_cnt = 0;
              $display("write data: %b",wr_req_data);
              $display("address: %d",addr_cnt);
              wr_req_en = 1'b1;    // issue wr_req 
              fsm_ns = FSM_WR_RSP; 
          end

	FSM_WR_RSP:
	  begin
	     if(wr_rsp0_valid | wr_rsp1_valid)
	       begin
		  fsm_ns = FSM_DONE; 
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

