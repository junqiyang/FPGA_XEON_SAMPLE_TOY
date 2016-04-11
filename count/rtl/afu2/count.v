module count(
    //outputs
    done, result,
    //inputs
    clk, rst, start, data_set, object
);

    input clk;
    input rst;
    input start;
    input [511:0] data_set;
    input [31:0] object;
    
    output reg done;
    output reg[31:0] result;

    reg [31:0] cp1 = 9;
    reg [31:0] cp2 = 9;
    reg [31:0] cp3 = 9;
    reg [31:0] cp4 = 9;
    reg [31:0] cp5 = 9;
    reg [31:0] cp6 = 9;
    reg [31:0] cp7 = 9;
    reg [31:0] cp8 = 9;
    reg [31:0] cp9 = 9;
    reg [31:0] cp10 = 9;
    reg [31:0] cp11 = 9;
    reg [31:0] cp12 = 9;
    reg [31:0] cp13 = 9;
    reg [31:0] cp14 = 9;
    reg [31:0] cp15 = 9;
    reg [31:0] cp16 = 9;
    localparam [2:0]
     FSM_IDLE = 3'd0,
     FSM_COM = 3'd1,
     FSM_SUM = 3'd2,
     FSM_SUM2 = 3'd3,
     FSM_SUM3 = 3'd4,
     FSM_SUM4 = 3'd5,
     FSM_DONE = 3'd6;
    
    reg [2:0] fsm_cs,fsm_ns;

    always @ (posedge clk) begin
      if(rst) fsm_cs <= FSM_IDLE;
      else     fsm_cs <= fsm_ns; 
    end

    always @ (posedge clk) begin
        fsm_ns = fsm_cs;
        done = 1'b0;

        case(fsm_cs)
           FSM_IDLE: begin
               if(start) begin
               result = 32'd0;
               cp1 <= 32'd9;
               cp2 <= 32'd9;
               cp3 <= 32'd9;
               cp4 <= 32'd9;
               cp5 <= 32'd9;
               cp6 <= 32'd9;
               cp7 <= 32'd9;
               cp8 <= 32'd9;
               cp9 <= 32'd9;
               cp10 <= 32'd9;
               cp11 <= 32'd9;
               cp12 <= 32'd9;
               cp13 <= 32'd9;
               cp14 <= 32'd9;
               cp15 <= 32'd9;
               cp16 <= 32'd9;
               fsm_ns = FSM_COM;                  
               end
           end

           FSM_COM: begin
               cp1 <= (object == data_set[31:0]);
               cp2 <= (object == data_set[63:32]);
               cp3 <= (object == data_set[95:64]);
               cp4 <= (object == data_set[127:96]);
               cp5 <= (object == data_set[159:128]);
               cp6 <= (object == data_set[191:160]);
               cp7 <= (object == data_set[223:192]);
               cp8 <= (object == data_set[255:224]);
               cp9 <= (object == data_set[287:256]);
               cp10 <= (object == data_set[319:288]);
               cp11 <= (object == data_set[351:320]);
               cp12 <= (object == data_set[383:352]);
               cp13 <= (object == data_set[415:384]);
               cp14 <= (object == data_set[447:416]);
               cp15 <= (object == data_set[479:448]);
               cp16 <= (object == data_set[511:480]);
               fsm_ns = FSM_SUM;    
           end
           
           FSM_SUM: begin
               result <= cp1 + cp2 + cp3 + cp4 + cp5 + cp6 + cp7 + cp8 + cp9 + cp10 + cp11 + cp12 + cp13 + cp14 + cp15 + cp16;
               fsm_ns = FSM_DONE;
           end
           
           FSM_DONE: begin
               done = 1'b1;
               fsm_ns = FSM_IDLE;
            end            
        endcase
    end

endmodule


        
       
