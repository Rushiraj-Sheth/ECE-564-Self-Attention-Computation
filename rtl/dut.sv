//---------------------------------------------------------------------------
// DUT - 564/464 Project
//---------------------------------------------------------------------------
`include "common.vh"

module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//input SRAM interface
  output wire                           dut__tb__sram_input_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_input_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_input_read_data     ,     

//weight SRAM interface
  output wire                           dut__tb__sram_weight_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_weight_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_weight_read_data     ,     

//result SRAM interface
  output wire                           dut__tb__sram_result_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_result_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_result_read_data     ,         

//scratchpad SRAM interface
  output wire                           dut__tb__sram_scratchpad_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_scratchpad_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_scratchpad_read_data  
);

parameter [5:0] //synopsys enum states
IDLE = 6'd0,
S1 = 6'd1,
S2 = 6'd2,
S3 = 6'd3,
S4 = 6'd4,
S5 = 6'd5,
S6 = 6'd6,
S7 = 6'd7,
S8 = 6'd8,
S9 = 6'd9,
S10 = 6'd10,
S11 = 6'd11,
S12 = 6'd12,
S13 = 6'd13,
S14 = 6'd14,
S15 = 6'd15,
S16 = 6'd16,
S17 = 6'd17,
S18 = 6'd18,
S19 = 6'd19,
S20 = 6'd20,
S21 = 6'd21,
S22 = 6'd22,
S23 = 6'd23,
S24 = 6'd24,
S25 = 6'd25,
S26 = 6'd26,
S27 = 6'd27,
S28 = 6'd28,
S29 = 6'd29,
S30 = 6'd30,
S31 = 6'd31;

reg [5:0] /*synopsys enum states*/ current_state, next_state; 
//synopsys state_vector current_state


reg [1:0] A_sel, acc_sel;// size_sel;
reg [2:0] B_sel;
reg [2:0] k_sel, j_sel, i_sel;
reg [1:0] address_c_sel;

reg [15:0] B_rows, B_cols, A_rows, A_cols;
reg [15:0] count_i,count_j,count_k;

reg [11:0] read_addr_A, read_addr_B, write_addr_C;

reg [31:0] result; 

reg [1:0] A_total_rows_sel, A_total_col_sel, B_total_rows_sel, B_total_col_sel;

reg go;
reg my_dut_ready;

always @(posedge clk or negedge reset_n)
begin
  if(!reset_n)
  current_state <= IDLE;
  //else if(( (dut_valid == 1'd0) | (dut_valid == 1'hx) ) & (dut_ready == 1'd1) & (go == 1'd0))current_state <= IDLE;
  else
  begin
  current_state <= next_state;
  end
end

always @(posedge clk)
begin
  if(k_sel == 3'd0)count_k <= 16'd0;
  else if(k_sel == 3'd1)count_k <= (count_k - 16'd1);
  else if(k_sel == 3'd3) count_k <= B_rows;
  else if(k_sel == 3'd2) count_k <= count_k;
  else if(k_sel == 3'd4)count_k <= B_cols;
  else if(k_sel == 3'd5)count_k <= A_rows;

  if(j_sel == 3'd0)count_j <= 16'd0;
  else if(j_sel == 3'd1)count_j <= (count_j - 16'd1);
  else if(j_sel == 3'd2)count_j <= count_j;
  else if(j_sel == 3'd3) count_j <= B_cols;
  else if(j_sel == 3'd4)count_j <= A_rows;
  else if(j_sel == 3'd5)count_j <= B_cols;

  if(i_sel == 3'd0)count_i <= 16'd0;
  else if(i_sel == 3'd1)count_i <= (count_i - 16'd1);
  else if(i_sel == 3'd2)count_i <= count_i;
  else if(i_sel == 3'd3) count_i <= A_rows;
  else if(i_sel == 3'd4)count_i <= A_rows;
  else if(i_sel == 3'd5)count_i <= A_rows;
  else if(i_sel == 3'd6)count_i <= (A_rows*B_cols);
end

always @(posedge clk)
begin
  if(A_sel == 2'd0)read_addr_A <= 12'd0;
  else if(A_sel == 2'd1)read_addr_A <=  read_addr_A + 12'd1;
  else if(A_sel == 2'd2)read_addr_A <= read_addr_A;
  else if(A_sel == 2'd3)read_addr_A <= (A_rows - count_i)*A_cols + 12'd1;
end

assign dut__tb__sram_input_read_address = read_addr_A;

always @(posedge clk)
begin
  if(B_sel == 3'd0)read_addr_B <= 12'd0;
  else if(B_sel == 3'd1)read_addr_B <=  read_addr_B + 12'd1;
  else if(B_sel == 3'd2)read_addr_B <= read_addr_B;
  else if(B_sel == 3'd3)read_addr_B <= 12'd1;
  else if(B_sel == 3'd4)read_addr_B <= ( (B_rows * B_cols) + 12'd1 );
  else if(B_sel == 3'd5)read_addr_B <= ( (B_rows * B_cols * 12'd2) + 12'd1 );
end

assign dut__tb__sram_weight_read_address = read_addr_B;

always @(posedge clk)
begin

  if(address_c_sel == 2'd0)write_addr_C <= 12'd0;
  else if(address_c_sel == 2'd1)write_addr_C <= write_addr_C + 12'd1;
  else if(address_c_sel == 2'd2)write_addr_C <= write_addr_C; 
end

assign dut__tb__sram_result_write_address = write_addr_C; 

always @(posedge clk)
begin
  if(acc_sel == 2'd0)result <= 32'd0;
  else if(acc_sel == 2'd1)result <= ( (tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data) + result );
  else if(acc_sel == 2'd2)result <= result;
end

//assign dut__tb__sram_result_write_data = result;

always @(posedge clk)
begin
  if(A_total_rows_sel == 2'd1)A_rows <= tb__dut__sram_input_read_data[31:16];
  else if(A_total_rows_sel == 2'd0)A_rows <= A_rows;

  if(A_total_col_sel == 2'd1)A_cols <= tb__dut__sram_input_read_data[15:0];
  else if(A_total_col_sel == 2'd0)A_cols <= A_cols ;

  if(B_total_col_sel == 2'd0)B_cols <= B_cols;
  else if(B_total_col_sel == 2'd1) B_cols <= tb__dut__sram_weight_read_data[15:0];

  if(B_total_rows_sel == 2'd0)B_rows <= B_rows;
  else if(B_total_rows_sel == 2'd1)B_rows <= tb__dut__sram_weight_read_data[31:16];
end

reg sram_write_enable;
reg A_sram_write_enable;
reg B_sram_write_enable;

/* new registers from here */


// counter C for traking convolution of three weight matrices Wq, Wk, Wv
reg [1:0] count_c;
reg [1:0] c_sel;

always @(posedge clk)
begin 
  if(c_sel == 2'd0)count_c <= 2'd0;
  else if(c_sel == 2'd1)count_c <= (count_c - 2'd1);
  else if(c_sel == 2'd2)count_c <= count_c;
  else if(c_sel == 2'd3)count_c <= 2'd3;
end


//declaring result mux connecting accumulator "result" and "result_s_z" to write port of RESULT SRAM
//reg result_mux; // result_mux is actually a mux select line, OFC ! * ;) *

/*reg [31:0] result_data;

always @(*)
begin
if(result_mux == 1'd0) result_data = result; 
if(result_mux == 1'd1)result_data = result_s_z;
end

assign dut__tb__sram_result_write_data = result_data;
*/
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TRANSPOSE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
//declaring hardware for transpose of matrix K
// will copy matrix K in scratch SRAM, with each Ki is K's element in transpose order

//generating address to get Ki from sram result
reg [11:0] read_addr_Key;
reg [1:0] key_addr_sel;

always @(posedge clk)
begin
  if(key_addr_sel == 2'd0)read_addr_Key <= 12'd0;
  else if(key_addr_sel == 2'd3)read_addr_Key <= (A_rows * B_cols);
  else if(key_addr_sel == 2'd1)read_addr_Key <= (read_addr_Key + 12'd1);
  else if(key_addr_sel == 2'd2)read_addr_Key <= read_addr_Key;
end


//storing the read_output_data of result sram. It will be written in scratch sram
reg [31:0] write_val_of_scratch_sram;
always @(posedge clk)
begin
  write_val_of_scratch_sram <= tb__dut__sram_result_read_data;
end

assign dut__tb__sram_scratchpad_write_data = write_val_of_scratch_sram;

//generating write data address for scratch sram
reg [11:0] write_addr_scratch;
reg [1:0] scratch_addr_sel;

always @(posedge clk)
begin
  if(scratch_addr_sel == 2'd0)write_addr_scratch <= 12'd0;
  else if(scratch_addr_sel == 2'd1) write_addr_scratch <= (write_addr_scratch + 12'd1);
  else if(scratch_addr_sel == 2'd2) write_addr_scratch <= write_addr_scratch;
end

assign dut__tb__sram_scratchpad_write_address = write_addr_scratch;

reg scratch_sram_write_enable;

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ TRANSPOSE - END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

// S=Q*K(t)
// generating addr for reading elements of matrix Q
reg [11:0] read_addr_Q;
reg [1:0] Q_sel;

always @(posedge clk)
begin
  if(Q_sel == 2'd0)read_addr_Q <= 12'd0;
  else if(Q_sel == 2'd1)read_addr_Q <= (read_addr_Q + 12'd1);
  else if(Q_sel == 2'd2)read_addr_Q <= read_addr_Q;
  else if(Q_sel == 2'd3)read_addr_Q <= ( ( (A_rows - count_i)*(B_cols) ) );
end

/*always @(*)
begin 
  if(result_input_sel == 3'd2)result_sram_read_addr = read_addr_Q;
end */

//read address for scratch sram. This addr is of K(t) matrix elements
reg [11:0] read_addr_scratch_sram;
reg [1:0] scratch_read_addr_sel;

always @(posedge clk)
begin
  if(scratch_read_addr_sel == 2'd0)read_addr_scratch_sram <= 12'd0;
  else if(scratch_read_addr_sel == 2'd1)read_addr_scratch_sram <= (read_addr_scratch_sram + 12'd1);
  else if(scratch_read_addr_sel == 2'd2)read_addr_scratch_sram <= read_addr_scratch_sram;
end

assign dut__tb__sram_scratchpad_read_address = read_addr_scratch_sram;

// computing/convolution for matrix S
reg [31:0] result_s_z;
reg [1:0] result_s_z_sel;

always @(posedge clk ) begin
  if(result_s_z_sel == 2'd0)result_s_z <= 32'd0;
  else if(result_s_z_sel == 2'd1)result_s_z <= ( (tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data) + (result_s_z) );
  else if(result_s_z_sel == 2'd2)result_s_z <= result_s_z;
  else if(result_s_z_sel == 2'd3)result_s_z <= (tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data);
end

/*always @(*)
begin
  if(result_mux == 1'd1)result_data = result_s_z;
end
*/

reg [31:0] result_data;
reg result_mux;
always @(*)
begin
  if(result_mux == 1'd0) result_data = result; 
  if(result_mux == 1'd1)result_data = result_s_z;
end

assign dut__tb__sram_result_write_data = result_data;

//copying matrix V to scratch SRAM
reg [11:0] read_addr_V_S;
reg [2:0] v_s_sel;

reg [11:0] v_addr; 
reg v_addr_sel;

always @(posedge clk)
begin
  if(v_addr_sel == 1'd0)v_addr <= v_addr;
  else if(v_addr_sel == 1'd1)v_addr <= read_addr_V_S;
end


always @(posedge clk)begin
  if(v_s_sel == 3'd0)read_addr_V_S <= 12'd0;
  else if(v_s_sel == 3'd1)read_addr_V_S <= (read_addr_V_S + 12'd1);
  else if(v_s_sel == 3'd2)read_addr_V_S <= read_addr_V_S;
  else if(v_s_sel == 3'd3)read_addr_V_S <= ( A_rows * B_cols * 12'd2 ); //address of matrix V
  else if(v_s_sel == 3'd4)read_addr_V_S <= ( A_rows * B_cols * 12'd3 ); //address of matrix S
  else if(v_s_sel == 3'd5)read_addr_V_S <= ( v_addr + 12'd1 );
  else if(v_s_sel == 3'd6)read_addr_V_S <= (read_addr_V_S + B_cols);
  else if(v_s_sel == 3'd7)read_addr_V_S <= ( ( (A_rows - count_i) * A_rows ) + (A_rows * B_cols *12'd3) );
end

reg [2:0] result_input_sel; // mux select line for read addr of result SRAM
reg [11:0] result_sram_read_addr;

always @(*)begin
  if(result_input_sel == 3'd3)result_sram_read_addr = read_addr_V_S;
  else if(result_input_sel == 3'd1)result_sram_read_addr = read_addr_Key;
  else result_sram_read_addr = read_addr_Q;
  //if(result_input_sel == 3'd2)result_sram_read_addr = read_addr_Q;
end
assign dut__tb__sram_result_read_address = result_sram_read_addr;



always @(*)
begin
  go = 1'b0;
  sram_write_enable = 1'b0;
  A_sram_write_enable = 1'b0;
  B_sram_write_enable = 1'b0;
  scratch_sram_write_enable = 1'd0;

  casex(current_state)
    IDLE: begin 
      my_dut_ready = 1'b1;
      A_sel = 2'bxx;
      B_sel = 3'bxxx;
      acc_sel = 2'bxx;
      k_sel = 3'bxxx;
      j_sel = 3'bxxx;
      i_sel = 3'bxxx;
      address_c_sel = 2'bxx;
      A_total_rows_sel = 2'bxx;
      A_total_col_sel = 2'bxx;
      B_total_col_sel = 2'bxx;
      B_total_rows_sel = 2'bxx;


      c_sel = 2'bxx;
      result_mux = 1'dx;
      key_addr_sel = 2'dx;
      v_addr_sel = 1'dx;
      result_input_sel =3'dx;
      scratch_addr_sel = 2'dx;
      Q_sel = 2'dx;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'dx;
      v_s_sel = 3'dx;

      next_state = IDLE;
      if(dut_valid == 1'b1)begin next_state = S1; go=1'b1; end
    end

    S1: begin
      my_dut_ready = 1'b0;
      A_sel = 2'b00;
      B_sel = 3'b000;
      acc_sel = 2'b00;
      k_sel = 3'd0;
      j_sel = 3'b000;
      i_sel = 3'b000;
      address_c_sel = 2'b00;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;

      c_sel = 2'b00;
      result_mux = 1'd0;
      key_addr_sel = 2'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      next_state = S2;
    end

    S2: begin
        my_dut_ready = 1'b0;
        acc_sel = 2'b00;
        i_sel = 3'd0;
        j_sel = 3'd0;
        k_sel = 3'd0;

        c_sel = 2'b00;
        A_sel=2'b00;
        B_sel = 3'b000;
        A_total_rows_sel = 2'b00;
        A_total_col_sel = 2'b00;
        B_total_col_sel = 2'b00;
        B_total_rows_sel = 2'b00;
        address_c_sel = 2'd2;
        result_mux = 1'd0;
        key_addr_sel = 2'd0;
        v_addr_sel = 1'd0;
        result_input_sel = 3'dx;
        scratch_addr_sel = 2'd0;
        Q_sel = 2'd0;
        scratch_read_addr_sel = 2'dx;
        result_s_z_sel = 2'd0;
        v_s_sel = 3'd0;

        next_state = S3;        
    end

    S3: begin
      my_dut_ready = 1'b0;
      acc_sel = 2'b00;
      i_sel = 3'd0;
      j_sel = 3'd0;
      address_c_sel = 2'd2;      
      A_total_col_sel = 2'd1;
      A_total_rows_sel = 2'd1;
      B_total_col_sel = 2'd1;
      B_total_rows_sel = 2'd1;
      result_mux = 1'd0;
      key_addr_sel = 2'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      c_sel = 2'b00;
      A_sel = 2'd1;
      B_sel = 3'd1;
      k_sel = 3'd0;

      next_state = S4;
    end

    S4: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd1;
      B_sel = 2'd1;
      acc_sel = 2'b00;
      address_c_sel = 2'd2;

      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      k_sel = 3'd3;
      j_sel = 3'd3;
      i_sel = 3'd3;
      result_mux = 1'd0;
      c_sel = 2'd3;
      key_addr_sel = 2'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      next_state = S5;
    end

    S5: begin

      my_dut_ready = 1'b0;
      address_c_sel = 2'd2;
      i_sel = 3'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      result_mux = 1'd0;
      key_addr_sel = 2'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      if(count_k > 16'd0)begin
        k_sel = 3'd1;
        j_sel = 3'd2;
        i_sel = 3'd2;
        end
      else begin
          k_sel = 3'd3; i_sel = 3'd2;
          if(count_j > 16'd1)begin
              j_sel = 3'd1;
            end
          else begin
              j_sel = 3'd3;
              if(count_i > 16'd1)i_sel = 3'd1;
              else i_sel = 3'd3;
            end  
        end

      if(count_k > 16'd0)acc_sel = 2'd1;
      else acc_sel = 2'd2;

      if(count_k > 16'd2) begin
        A_sel = 2'd1;
        B_sel = 3'd1;
      end
      else begin
        A_sel = 2'd2;
        B_sel = 3'd2;
      end


      c_sel = 2'd2;
      if( (count_k == 16'd0) & (count_j == 16'd1) & (count_i == 16'd1) )begin
        c_sel = 2'd1;
      end

    next_state = S5;
    if(count_k == 16'd0)next_state = S6;
    //else next_state = S6;

    end

    S6: begin //writing result
      my_dut_ready = 1'b0;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      key_addr_sel = 2'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      A_sel = 2'd3;

      if( (count_k == B_rows) & (count_j == B_cols) )begin 
        B_sel = 3'd3; 
        if( count_c == 2'd2 )B_sel = 3'd4;
        
        if( count_c == 2'd1 )B_sel = 3'd5;
      
      end
      else B_sel = 3'd1;

      acc_sel = 2'd2;
      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd2;
      sram_write_enable = 1'd1;
      address_c_sel = 2'd1;

      c_sel = 2'd2;
      result_mux = 1'd0;

      next_state = S7;  
    end

    S7: begin
      my_dut_ready = 1'b0;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      result_mux = 1'd0;
      key_addr_sel = 2'd0;
      v_addr_sel = 1'd0;
      v_s_sel = 3'd0;
      

      A_sel = 2'd1;
      B_sel = 3'd1;
      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd2;
      acc_sel = 2'd0;
      address_c_sel = 2'd2;
      c_sel = 2'd2;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;


      next_state = S5;
      if( (count_i == A_rows) & (count_j == B_cols) & (count_k == B_rows) & (count_c == 2'd0) )begin 
        A_sel = 2'd2;
        B_sel = 3'd2;
        c_sel = 2'd0;

        //continuing new states for project
        result_input_sel = 3'd1;
        key_addr_sel = 2'd3;
        scratch_addr_sel = 2'd0;
        scratch_sram_write_enable = 1'd0;
        i_sel = 3'd0;

        next_state = S8;
      end
    end

    S8: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2;
      acc_sel = 2'd0;
      k_sel = 3'd2;
      j_sel = 3'd2;   
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;  
      c_sel = 2'd2; 
      result_mux = 1'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd1;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      key_addr_sel      = 2'd1;
      scratch_addr_sel  = 2'd2;
      i_sel             = 3'd6;
      //scratch sram write enable is already 0 or LOW
      next_state = S9;
    end

    S9: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2;
      acc_sel = 2'd0;
      k_sel = 3'd2;
      j_sel = 3'd2;
      address_c_sel = 2'd2;     
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd0;
      i_sel = 3'd1;
      key_addr_sel      = 2'd1;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd1;
      scratch_addr_sel  = 2'd2;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;
      
      next_state = S10;
    end

    S10: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      j_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd0;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd1;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      scratch_sram_write_enable = 1'd1;
      scratch_addr_sel = 2'd1;
      key_addr_sel = 2'd2;
      if(count_i > 16'd2)begin
        key_addr_sel = 2'd1;
      end
      //else key_addr_sel = 2'd2;

      if(count_i == 16'd0)begin 
        i_sel = 3'd6;
        scratch_addr_sel = 2'd2;
      end
      else i_sel = 3'd1;

      next_state = S10;
      if(count_i == 16'd0)next_state = S11;

    end

    S11: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      j_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd0;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd1;
      scratch_addr_sel = 2'd2;
      Q_sel = 2'd0;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;

      scratch_sram_write_enable = 1'd0;
      i_sel = 3'd0;

      next_state = S12;
    end

    S12: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd0;
      address_c_sel = 2'd2;  
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd0;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      scratch_addr_sel = 2'd2;
      v_s_sel = 3'd0;
      //transpose is completed here.

    //initialising select lines for computing Q*K(t)
    result_input_sel = 3'd2;
    Q_sel = 2'd0;
    scratch_read_addr_sel = 2'd0;
    result_s_z_sel = 2'd0;

    next_state = S13;
    end

    S13: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd0;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd2;
      scratch_addr_sel = 2'd2;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd0;
      //input of srams are generated.
      //initializing counter for keeping track of convolution
      k_sel = 3'd4;
      j_sel = 3'd4;
      i_sel = 3'd4;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;

      next_state = S14;
    end

    S14: begin
      // performing convolution
      // Qi and K(t)i are available and counters are initialised with req. values of rows and cols. they 
      // will count down i.e. count down counters are used as in mini project
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      address_c_sel = 2'd2;
      i_sel = 3'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd0;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd2;
      scratch_addr_sel = 2'd2;
      scratch_read_addr_sel = 2'd1;
      v_s_sel = 3'd0;



      if(count_k > 16'd0)begin
        k_sel = 3'd1;
        j_sel = 3'd2;
        i_sel = 3'd2;
      end  
      else begin
        k_sel = 3'd4;
        if(count_j > 16'd1)j_sel = 3'd1;
        else begin 
          j_sel =  3'd4;
          if(count_i > 16'd1)i_sel = 3'd1;
          else i_sel = 3'd4;
        end
      end

      if(count_k > 16'd2)begin
        Q_sel = 2'd1;
        scratch_read_addr_sel = 2'd1;
      end
      else begin
        Q_sel = 2'd2;
        scratch_read_addr_sel = 2'd2;
      end

      if(count_k > 16'd0)result_s_z_sel = 2'd1;
      else result_s_z_sel = 2'd2;

      next_state = S14;
      if(count_k == 16'd0)next_state = S15;
      //else next_state = S15;
    end

    S15: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd2;
      scratch_addr_sel = 2'd2;
      v_s_sel = 3'd0;

      Q_sel = 2'd3;
      if( (count_k == B_cols) & (count_j == A_rows) )scratch_read_addr_sel = 2'd0;
      else scratch_read_addr_sel = 2'd1;

      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd2;

      result_s_z_sel = 2'd2;
      result_mux = 1'd1;
      sram_write_enable = 1'd1;
      address_c_sel = 2'd1;

      next_state = S16;
    end

    S16: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      scratch_addr_sel = 2'd2;
      v_s_sel = 3'd0;


      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd2;
      result_s_z_sel = 2'd0;
      sram_write_enable = 1'd0;
      address_c_sel = 2'd2;
      result_input_sel = 3'd2;


      next_state = S14;
      if( (count_i == A_rows) & (count_j == A_rows) & (count_k == B_cols) )begin
        result_input_sel = 3'd3;
        next_state = S17;
      end

    end

    S17: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      result_input_sel = 3'd3;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;

      v_s_sel = 3'd3;
      v_addr_sel = 1'd0;
      scratch_sram_write_enable = 1'd0;
      scratch_addr_sel = 2'd0;
      result_s_z_sel = 2'd0;

      next_state = S18;
    end

    S18: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd0;
      //v_s_sel = 3'd6;

      scratch_addr_sel = 2'd2;
      i_sel = 3'd3;
      j_sel = 3'd3;

      if( A_rows > 16'd1 )begin
       v_s_sel = 3'd6;
       v_addr_sel = 1'd1;      
      end
      else v_s_sel = 3'd1;
     

      next_state = S19;
    end

    S19: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd2;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd0;
      

      if( A_rows > 16'd1 )begin
        v_addr_sel = 1'd0;
        i_sel = 3'd1;
        j_sel = 3'd2;
        v_s_sel = 3'd6;

        if( (count_i == 16'd2) & (count_j > 16'd1) )v_s_sel = 3'd5;
      end
      else begin 
        j_sel = 3'd1; 
        i_sel = 3'd2; 
        v_s_sel = 3'd1; 
      end

      next_state = S20;
    end

    S20: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      //i_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd0;


      if( A_rows > 16'd1 )begin
      scratch_sram_write_enable = 1'd1;
      scratch_addr_sel = 2'd1;
      result_input_sel = 3'd3;
      v_s_sel = 3'd6;
      v_addr_sel = 1'd0;
      i_sel = 3'd1;
      j_sel = 3'd2;

      if( (count_i == 16'd2) & (count_j > 16'd1) )v_s_sel = 3'd5;

      if( (count_i == 16'd1) & (count_j > 16'd1) )begin
        v_addr_sel = 1'd1;
        v_s_sel = 3'd6;
        i_sel = 3'd3;
        j_sel = 3'd1;
      end

      if( (count_i == 16'd2) & (count_j == 16'd1))begin
        v_s_sel = 3'd2;
        v_addr_sel = 1'd0;
      end

      if( (count_i == 16'd1) & (count_j == 16'd1) )begin
        i_sel = 3'd3;
        j_sel = 3'd3;
        v_s_sel = 3'd2;
      end

      next_state = S20;
      if( (count_i == 16'd1) & (count_j == 16'd1) )next_state = S21;
      
      end
      else begin
        scratch_sram_write_enable = 1'd1;
        scratch_addr_sel = 2'd1;
        j_sel = 3'd1;
        v_s_sel = 3'd1;
        v_addr_sel = 1'd0;
        result_input_sel = 3'd3;
        i_sel = 3'd2;

        if(count_j == 16'd1)begin 
          j_sel = 3'd3;
          v_s_sel = 3'd2;
        end

        
        next_state = S20;
        if(count_j == 16'd1)begin
          next_state = S21;
        end
        

      end 

    end

    S21: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd0;


      v_s_sel = 3'd2;
      i_sel = 3'd2;
      j_sel = 3'd2;
      scratch_addr_sel = 2'd2;
      scratch_sram_write_enable = 1'd1;

      next_state = S22;
    end

    S22: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      k_sel = 3'd2;
      i_sel = 3'd2;
      j_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd0;
      v_s_sel = 3'd2;

      scratch_sram_write_enable = 1'd0;
      scratch_addr_sel = 2'd0;
      

      next_state = S23;
    end

    S23: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2;
      acc_sel = 2'd0;
      k_sel = 3'd2;
      i_sel = 3'd2;
      j_sel = 3'd2;
      address_c_sel = 2'd2; 
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;



      result_input_sel = 3'd3;
      v_s_sel = 3'd4;
      scratch_read_addr_sel = 2'd0;
      result_s_z_sel = 2'd0;

      next_state = S24;
      if(A_rows == 16'd1)next_state = S28;
    end

    S24:begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;
      result_s_z_sel = 2'd0;


      k_sel = 3'd5;
      j_sel = 3'd5;
      i_sel = 3'd5;
      v_s_sel = 3'd1;
      scratch_read_addr_sel = 2'd1;

      next_state = S25;
    end

    S25: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;
      i_sel = 3'd2;
      



      if(count_k > 16'd0)begin
        k_sel = 3'd1;
        j_sel = 3'd2;
        i_sel = 3'd2;
      end
      else begin
        k_sel = 3'd5;
        if(count_j > 16'd1)j_sel = 3'd1;
        else begin
          j_sel = 3'd5;
          if(count_i > 16'd1)i_sel = 3'd1;
          else i_sel = 3'd5;
        end
      end

      if(count_k > 16'd2)begin
        v_s_sel = 3'd1;
        scratch_read_addr_sel = 2'd1;
      end
      else begin
        v_s_sel = 3'd2;
        scratch_read_addr_sel = 2'd2;
      end

      if(count_k > 16'd0)begin
        result_s_z_sel = 2'd1;
      end
      else begin result_s_z_sel = 2'd2; end

      next_state  = S25;
      if(count_k == 16'd0)next_state  = S26;
      //else next_state = S26;
    end

    S26: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;



      v_s_sel = 3'd7;
      if( (count_k == A_rows) & (count_j == B_cols))scratch_read_addr_sel = 2'd0;
      else scratch_read_addr_sel = 2'd1;

      k_sel = 3'd2;
      j_sel = 3'd2;
      i_sel = 3'd2;

      result_s_z_sel = 2'd2;
      result_mux = 1'd1;
      sram_write_enable = 1'd1;
      address_c_sel = 2'd1;

      next_state = S27;
    end

    S27: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;



      v_s_sel = 3'd1;
      scratch_read_addr_sel = 2'd1;
      i_sel = 3'd2;
      j_sel = 3'd2;
      k_sel = 3'd2;
      result_s_z_sel = 2'd0;
      sram_write_enable = 1'd0;
      address_c_sel = 2'd2;

      next_state = S25;
      if( (count_k == A_rows) & (count_j == B_cols) & (count_i == A_rows) )next_state = IDLE;
      //else next_state = S25;

    end


    S28: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      i_sel = 3'd2;
      k_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;

      v_s_sel = 3'd4;
      scratch_read_addr_sel = 2'd0;
      result_s_z_sel = 2'd0;
      j_sel = 3'd5;

      next_state = S29;
    end

    S29: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      i_sel = 3'd2;
      k_sel = 3'd2;
      address_c_sel = 2'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;


      v_s_sel = 3'd2;
      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd0;
      j_sel = 3'd2;

      next_state = S30;
    end

    S30: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      i_sel = 3'd2;
      k_sel = 3'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;
      result_mux = 1'd1;
      key_addr_sel = 2'd2;
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;
      v_s_sel = 3'd2;


      scratch_read_addr_sel = 2'd1;
      result_s_z_sel = 2'd3;
      j_sel = 3'd1;
      address_c_sel = 2'd2;

      next_state = S31;
    end

    S31: begin
      my_dut_ready = 1'b0;
      A_sel = 2'd2;
      B_sel = 3'd2; 
      acc_sel = 2'd0;
      i_sel = 3'd2;
      k_sel = 3'd2;
      A_total_rows_sel = 2'b00;
      A_total_col_sel = 2'b00;
      B_total_col_sel = 2'b00;
      B_total_rows_sel = 2'b00;
      c_sel = 2'd2;     
      key_addr_sel = 2'd2; 
      v_addr_sel = 1'd0;
      result_input_sel = 3'd3;
      scratch_addr_sel = 2'd0;
      Q_sel = 2'd1;
      scratch_read_addr_sel = 2'd1;
      v_s_sel = 3'd2;



      result_s_z_sel = 2'd3;
      sram_write_enable = 1'd1;
      address_c_sel = 2'd1;
      result_mux  = 1'd1;
      j_sel = 3'd1;

      next_state = S31;
      if(count_j == 16'd0)begin
        j_sel = 3'd2;
        result_s_z_sel = 2'd2;
        i_sel = 3'd2;

        next_state = IDLE;
      end
    end


  default: begin 
      my_dut_ready = 1'b1;
      A_sel = 2'dx;
      B_sel = 3'dx;
      acc_sel = 2'dx;
      //size_sel = 2'bxx;
      k_sel = 3'dx;
      j_sel = 3'dx;
      i_sel = 3'dx;
      address_c_sel = 2'dx;
      A_total_rows_sel = 2'dx;
      A_total_col_sel = 2'dx;
      B_total_col_sel = 2'dx;
      B_total_rows_sel = 2'dx;
      sram_write_enable = 1'b0;

      

      c_sel = 2'dx;
      result_mux = 1'dx;
      key_addr_sel = 2'dx;
      v_addr_sel = 1'dx;
      result_input_sel = 3'dx;
      scratch_addr_sel = 2'dx;
      Q_sel = 2'dx;
      scratch_read_addr_sel = 2'dx;
      result_s_z_sel = 2'dx;
      v_s_sel = 3'dx;
      
      next_state = S1;
      //if(dut_valid == 1'b1)begin next_state = S1; go=1'b1; end
    end
  endcase
end

//result sram write enable
assign dut__tb__sram_result_write_enable = sram_write_enable;
assign dut_ready = my_dut_ready;

assign dut__tb__sram_input_write_enable=A_sram_write_enable;
assign dut__tb__sram_weight_write_enable=B_sram_write_enable;
//scratch sram
assign dut__tb__sram_scratchpad_write_enable = scratch_sram_write_enable;



endmodule