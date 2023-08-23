`timescale 1ns/1ps
///Introduction: This is a graduation project about cache
///Engineer: Feng PeiLei// // Create Date: 2023/3/29 14:58       

import axi_pkg::*;
import cache_pkg::*;
module cache_control(
    input  logic          clk,
    input  logic          rst_n,
    //CPU  -> cache
    input  logic          cpu_req_valid_i,
    output logic          cpu_req_ready_o,
    input  cpu_req_t      cpu_req_i,
    output logic          dcache_resp_valid_o,
    output dcache_resp_t  dcache_resp_o,
    output dcache_ctrl_t  dcache_ctrl_o,

    //cache -> LSU
    //axi_ar
    output logic          axi_ar_valid_o,
    output axi_ar_t       axi_ar_o,
    input  logic          axi_ar_ready_i,
    //axi_r
    input  logic          axi_r_valid_i,
    input  axi_r_t        axi_r_i,
    output logic          axi_r_ready_o,
    //axi_aw  
    output logic          axi_aw_valid_o,
    output axi_aw_t       axi_aw_o,
    input  logic          axi_aw_ready_i,
    //axi_w
    output logic          axi_w_valid_o,
    output axi_w_t        axi_w_o,
    input  logic          axi_w_ready_i,
    //axi_b
    input  logic          axi_b_valid_i,
    input  axi_b_t        axi_b_i,
    output logic          axi_b_ready_o
);

  typedef enum logic [2:0] {
    IDLE        = 3'b000,
    ECC_CHECK   = 3'b001,
    COMPARE     = 3'b011,
    REQ_AR      = 3'b010,
    WAIT_RESP   = 3'b110,
    RECV_DATA   = 3'b111,
    STORE_MERGE = 3'b101,
    REFILL      = 3'b100
  } state_t;

  state_t   state;
  state_t   next_state;

  cpu_req_t                cpu_req;           //寄存一下

  logic                    tag_rd_req_valid;
  logic [CACHE_IDX_W-1:0]  tag_rd_req_idx;
  logic [CACHE_WAY_N-1:0]  tag_rd_req_way_en;

  logic                    wb_tag_rd_req_valid;
  logic [CACHE_IDX_W-1:0]  wb_tag_rd_req_idx;
  logic [CACHE_WAY_N-1:0]  wb_tag_rd_req_way_en;

  logic                    lsu_tag_rd_req_valid;
  logic [CACHE_IDX_W-1:0]  lsu_tag_rd_req_idx;
  logic [CACHE_TAG_W-1:0]  lsu_tag_rd_req_way_en;

  logic                    cpu_tag_wr_req_valid;
  logic [CACHE_IDX_W-1:0]  cpu_tag_wr_req_idx;
  logic [CACHE_WAY_N-1:0]  cpu_tag_wr_req_way_en;
  cache_tag_t              cpu_tag_wr_req_tag;

  logic                    tag_wr_req_valid;
  logic [CACHE_IDX_W-1:0]  tag_wr_req_idx;
  logic [CACHE_WAY_N-1:0]  tag_wr_req_way_en;
  cache_tag_t              tag_wr_req_tag; 
  cache_tag_t              tag_rd [CACHE_WAY_N-1:0];
  logic [TAG_ECC_W-1:0]    tag_ecc_rd [CACHE_WAY_N-1:0];

  logic                    refill_tag_wr_req_valid;
  logic [CACHE_IDX_W-1:0]  refill_tag_wr_req_idx;
  logic [CACHE_WAY_N-1:0]  refill_tag_wr_req_way_en;
  cache_tag_t              refill_tag_wr_req_tag; 

  logic                    data_rd_req_valid;
  logic [CACHE_IDX_W-1:0]  data_rd_req_idx;
  logic [CACHE_BANK_N-1:0] data_rd_bank_en;
  logic [CACHE_WAY_N-1:0]  data_rd_req_way_en;

  logic                    wb_data_rd_req_valid;
  logic [CACHE_IDX_W-1:0]  wb_data_rd_req_idx;
  logic [CACHE_BANK_N-1:0] wb_data_rd_req_bank_en;
  logic [CACHE_WAY_N-1:0]  wb_data_rd_req_way_en;

  logic                    lsu_data_rd_req_valid;
  logic [CACHE_IDX_W-1:0]  lsu_data_rd_req_idx;
  logic [CACHE_BANK_N-1:0] lsu_data_rd_bank_en;
  logic [CACHE_WAY_N-1:0]  lsu_data_rd_req_way_en;

  logic                    cpu_data_wr_req_valid;
  logic [CACHE_IDX_W-1:0]  cpu_data_wr_req_idx;
  logic [CACHE_BANK_N-1:0] cpu_data_wr_req_bank_en;
  logic [CACHE_WAY_N-1:0]  cpu_data_wr_req_way_en;
  logic [CACHE_BANK_W-1:0] cpu_data_wr_req_data [CACHE_BANK_N-1:0];

  logic                    data_wr_req_valid;
  logic [CACHE_IDX_W-1:0]  data_wr_req_idx;
  logic [CACHE_BANK_N-1:0] data_wr_req_bank_en;
  logic [CACHE_WAY_N-1:0]  data_wr_req_way_en;
  logic [CACHE_BANK_W-1:0] data_wr_req_data [CACHE_BANK_N-1:0];  
  logic [CACHE_BANK_W-1:0] data_rd [CACHE_WAY_N-1:0];
  logic [BANK_ECC_W-1:0]   data_ecc_rd [CACHE_BANK_N-1:0];

  logic                    refill_data_wr_req_valid;
  logic [CACHE_IDX_W-1:0]  refill_data_wr_req_idx;
  logic [CACHE_BANK_N-1:0] refill_data_wr_req_bank_en;
  logic [CACHE_WAY_N-1:0]  refill_data_wr_req_way_en;
  logic [CACHE_BANK_W-1:0] refill_data_wr_req_data [CACHE_BANK_N-1:0];  
 

  cache_tag_t              corrected_tag [CACHE_WAY_N-1:0];
  logic [CACHE_BANK_W-1:0] corrected_data [CACHE_WAY_N-1:0];
  logic [CACHE_WAY_N-1:0]  tag_single_error;
  logic [CACHE_WAY_N-1:0]  tag_double_error;
  logic [CACHE_WAY_N-1:0]  data_uncorrectable_error;                 
  logic [CACHE_WAY_N-1:0]  tag_match;
  logic [CACHE_WAY_N-1:0]  cache_line_valid;
  logic [CACHE_WAY_N-1:0]  cache_line_valid_r;
  logic [CACHE_WAY_N-1:0]  cache_line_dirty;
  logic [CACHE_WAY_N-1:0]  cache_line_dirty_r;
  logic                    cache_hit_way_dirty;
  logic [CACHE_WAY_N-1:0]  cache_hit_way_tc0;
  logic                    cache_hit_tc0;
  logic [CACHE_WAY_N-1:0]  cache_hit_way_r;
  logic                    cache_hit_r;
  logic [CACHE_BANK_W-1:0] cache_hit_data;
  cache_tag_t              cache_hit_tag_r;
  cache_tag_t              cache_hit_tag;
  logic                    cache_set_has_invaild_way;
  //logic [LFSR_WIDTH-1:0]   lfsr_sel;
  logic [CACHE_WAY_IDX_W+2-1:0]   lfsr_sel;
  logic [LINE_SIZE-1:0]    refill_data;
  logic [LINE_SIZE-1:0]    merge_cacheline;
  logic [LINE_SIZE-1:0]    merge_cacheline_r;
  logic [LINE_SIZE-1:0]    wb_data;
  logic [LINE_SIZE-1:0]    r_data;
  logic [LINE_CNT_W-1:0]   r_data_ptr; //[1:0] 
  logic                    r_last;    
  logic [CACHE_WAY_N-1:0]  refill_way;
  logic                    refill_way_dirty;
  logic [255:0]            wb_data_rd_tc1;  //  cache line (2 cycles)
  logic [255:0]            wb_data_rd_tc2;
  logic                    wb_req_aw;
  logic [CACHE_TAG_W-1:0]  wb_tag;
  logic [CACHE_TAG_W-1:0]  wb_tag_r;
  logic                    axi_ar_fire;
  logic                    axi_ar_fire_tc1;
  logic                    axi_ar_fire_tc2;
  logic                    wb_get_data_tc1;
  logic                    wb_get_data_tc2;
  logic                    wb_req_w;
  logic [LINE_CNT_W-1:0]   wb_cnt;  //[1:0]  
  logic [DATA_WIDTH-1:0]   cpu_w_data;
  logic [$clog2(CACHE_WAY_N)-1:0] lfsr_way_sel;
  logic [CACHE_WAY_N-1:0]  lfsr_way_sel_oh;   
  logic [CACHE_WAY_N-1:0]  invalid_way_arb_req;
  logic [CACHE_WAY_N-1:0]  invalid_way_arb_grant;
  logic                    invalid_way_arb_grant_valid;
  logic                    get_b_resp;
  axi_b_resp_t             b_resp;    
  logic                    need_wait_b;


  //-------------------SRAM BEGIN------------------------------------------------------------------------------
  //----------- Tag SRAM -----------------
    tag_array u_tag_array(.clk(clk),
                              .rd_req_valid_i(tag_rd_req_valid),
                              .rd_req_idx_i(tag_rd_req_idx),
                              .rd_req_way_en_i(tag_rd_req_way_en),
                              .wr_req_valid_i(tag_wr_req_valid),
                              .wr_req_idx_i(tag_wr_req_idx),
                              .wr_req_way_i(tag_wr_req_way_en),
                              .wr_req_tag_i(tag_wr_req_tag),
                              .tag_rd_o(tag_rd),
                              .tag_ecc_rd_o(tag_ecc_rd)
                            );
  //----------- Data SRAM ----------------
    data_array u_data_array(.clk(clk),
                                .rd_req_valid_i(data_rd_req_valid),
                                .rd_req_idx_i(data_rd_req_idx),
                                .rd_req_bank_en_i(data_rd_bank_en),
                                .rd_req_way_i(data_rd_req_way_en),
                                .wr_req_valid_i(data_wr_req_valid),
                                .wr_req_idx_i(data_wr_req_idx),
                                .wr_req_bank_en_i(data_wr_req_bank_en),
                                .wr_req_way_i(data_wr_req_way_en),
                                .wr_req_data_i(data_wr_req_data),
                                .data_rd_o(data_rd),
                                .data_ecc_rd_o(data_ecc_rd)
                                );

  //-------做SRAM的接口仲裁-------
  //cache 要读写tag和读写data   refill：只有写tag和写data   wb：只有读data 
  assign tag_rd_req_valid     = wb_tag_rd_req_valid || lsu_tag_rd_req_valid;  
  assign tag_rd_req_idx       = (wb_tag_rd_req_valid) ? wb_tag_rd_req_idx         : lsu_tag_rd_req_idx; 
  assign tag_rd_req_way_en    = (wb_tag_rd_req_valid) ? wb_tag_rd_req_way_en      : lsu_tag_rd_req_way_en;  
                      
  assign data_rd_req_valid    = wb_data_rd_req_valid  || lsu_data_rd_req_valid;
  assign data_rd_req_idx      = (wb_data_rd_req_valid) ? wb_data_rd_req_idx        : lsu_data_rd_req_idx;
  assign data_rd_bank_en      = (wb_data_rd_req_valid) ? wb_data_rd_req_bank_en    : lsu_data_rd_bank_en;
  assign data_rd_req_way_en   = (wb_data_rd_req_valid) ? wb_data_rd_req_way_en     : lsu_data_rd_req_way_en;

  assign tag_wr_req_valid     = refill_tag_wr_req_valid || cpu_tag_wr_req_valid ;
  assign tag_wr_req_idx       = (state == REFILL)  ? refill_tag_wr_req_idx     : cpu_tag_wr_req_idx   ;
  assign tag_wr_req_way_en    = (state == REFILL)  ? refill_tag_wr_req_way_en  : cpu_tag_wr_req_way_en;
  assign tag_wr_req_tag       = (state == REFILL)  ? refill_tag_wr_req_tag     : cpu_tag_wr_req_tag   ;
 
  assign data_wr_req_valid    = refill_data_wr_req_valid || cpu_data_wr_req_valid  ;
  assign data_wr_req_idx      = (state == REFILL)  ? refill_data_wr_req_idx    : cpu_data_wr_req_idx    ;
  assign data_wr_req_bank_en  = (state == REFILL)  ? refill_data_wr_req_bank_en: cpu_data_wr_req_bank_en;
  assign data_wr_req_way_en   = (state == REFILL)  ? refill_data_wr_req_way_en : cpu_data_wr_req_way_en ;
  assign data_wr_req_data     = (state == REFILL)  ? refill_data_wr_req_data   : cpu_data_wr_req_data   ;

  
  //---------------- SRAM END ---------------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  always_comb begin
    next_state = state;
    unique case(state)
        IDLE: begin
            if(cpu_req_valid_i) 
              next_state = ECC_CHECK;   
        end
        ECC_CHECK:begin
            //这里暂时不知道ecc怎么处理，所以直接跳转到COMPARE状态
            next_state = COMPARE;
        end
        COMPARE:begin
            //这里需要比较是否hit/miss
            //hit的判断，在后面的assign部分判断
            if(cache_hit_r) 
                next_state = IDLE;
            else    
                next_state = REQ_AR;
        end
        REQ_AR:begin
            if(axi_ar_ready_i && axi_ar_valid_o)
                next_state = WAIT_RESP;
        end
        WAIT_RESP:begin
            if(axi_r_ready_o && axi_r_valid_i) 
                next_state = RECV_DATA;
        end
        RECV_DATA:begin
            if(cpu_req.inst_type == LOAD && axi_r_i.last) 
                next_state = REFILL;
            else if(cpu_req.inst_type == STORE && axi_r_i.last) 
                next_state = STORE_MERGE;
        end
        STORE_MERGE:begin
            next_state = REFILL;
        end
        REFILL:begin
          if(need_wait_b ? (get_b_resp || axi_b_valid_i) : 1'b1) //只有写响应(往下面写的时候)的时候，才能跳转到idle
            next_state = IDLE; 
        end
      default: next_state = IDLE;
    endcase
  end

  always_ff@(posedge clk) begin                                       //寄存一下端口请求
    if(cpu_req_valid_i && cpu_req_ready_o)                         
      cpu_req <= cpu_req_i;
  end

  assign cpu_req_ready_o = (state == IDLE);

  //  read tag and data
  assign lsu_tag_rd_req_valid  = cpu_req_valid_i;
  assign lsu_tag_rd_req_idx    = cpu_req.addr[IDX_MSB:IDX_LSB];
  assign lsu_tag_rd_req_way_en = {CACHE_WAY_N{1'b1}};
  assign lsu_data_rd_req_valid = cpu_req_valid_i;
  assign lsu_data_rd_req_idx   = cpu_req.addr[IDX_MSB:IDX_LSB];

  bin2oh  #(CACHE_BANK_N) u_rd_bank_offset(                            //[2:0]的二进制码，转换为[7:0]的格雷码
    .bin_i  (cpu_req.addr[BANK_MSB:BANK_LSB]),
    .oh_o   (lsu_data_rd_bank_en)
  );
  
  assign lsu_data_rd_req_way_en = {CACHE_WAY_N{1'b1}};
  //将其与例化的SRAM接起来
  //这里的东西写在了上面，有个仲裁

  //  Tag ECC decoder
  generate
    for(genvar i=0; i<CACHE_WAY_N; i++) begin: g_tag_ecc_decoder
     sec_ded_decoder_28 u_tag_ecc_decoder(
            .data_i           (tag_rd[i]),
            .ecc_i            (tag_ecc_rd[i]),
            .corrected_data_o (corrected_tag[i]),
            .single_error_o   (tag_single_error[i]),
            .double_error_o   (tag_double_error[i])
     );
    end
  endgenerate

  //  hit or miss
  generate 
      for(genvar i= 0;i<CACHE_WAY_N;i++) begin:g_hit
        assign tag_match[i] = (corrected_tag[i].addr == cpu_req.addr[TAG_MSB:TAG_LSB]);
        assign cache_line_valid[i] = corrected_tag[i].valid;
        assign cache_line_dirty[i] = corrected_tag[i].dirty;
      end
  endgenerate

  assign cache_hit_way_tc0 = tag_match & cache_line_valid; //one hot 4bit  告诉我们哪一路hit
  assign cache_hit_tc0 = |cache_hit_way_tc0;               //告诉我们是否hit

  oh_logic_mux #(                                       //对数据处理
    .NUM(CACHE_WAY_N),
    .WIDTH(CACHE_TAG_W)       
  ) tag_hit_oh_logic_mux(
    .oh_sel_i(cache_hit_way_tc0),
    .data_i(corrected_tag),
    .data_o(cache_hit_tag)
  );

  always_ff@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
          cache_hit_way_r <= '0;
          cache_hit_r <= '0;
          cache_line_valid_r <= '0;
          cache_line_dirty_r <= '0;
          cache_hit_tag_r <= '0; 
      end
      else begin
          cache_hit_way_r <= cache_hit_way_tc0;
          cache_hit_r <= cache_hit_tc0;
          cache_line_dirty_r <= cache_line_dirty;
          cache_hit_tag_r <= cache_hit_tag;
          cache_line_valid_r <= cache_line_valid;
      end
  end

  //  Data ECC Decoder
  generate
    for(genvar i=0; i<CACHE_WAY_N; i++) begin: g_data_ecc_decoder
     sec_ded_daec_decoder_64 u_data_ecc_decoder(
            .clk                   (clk),
            .data_i                (data_rd[i]),
            .ecc_i                 (data_ecc_rd[i]),
            .corrected_data_o      (corrected_data[i]),
            .uncorrectable_error_o (data_uncorrectable_error[i])
     );
    end
  endgenerate

  //  Load hit response
  assign load_hit_resp_valid = cache_hit_r && (cpu_req.inst_type == LOAD);   //读数据
  
  oh_logic_mux #(                                       //对数据处理
    .NUM(CACHE_WAY_N),
    .WIDTH(CACHE_BANK_W)       
  ) data_oh_logic_mux(
    .oh_sel_i(cache_hit_way_r),
    .data_i(corrected_data),
    .data_o(cache_hit_data)
  );
  
  assign load_resp_data_hit = load_data_gen(cpu_req.addr[BYTE_OFFSET-1:0],
                                            cpu_req.inst_signed          ,
                                            cpu_req.inst_size            ,
                                            cache_hit_data               ); //return a 64 bit data


  //  Store hit, write data. Clean -> Dirty
  //clean or dirty
  assign cpu_data_wr_req_valid = cache_hit_r && (cpu_req.inst_type == STORE);
  assign cpu_data_wr_req_idx   = cpu_req.addr[IDX_MSB:IDX_LSB];

  bin2oh  #(CACHE_BANK_N) u_wr_bank_offset(                            //[2:0]的二进制码，转换为[7:0]的独热码
    .bin_i  (cpu_req.addr[BANK_MSB:BANK_LSB]),
    .oh_o   (cpu_data_wr_req_bank_en)
  );

  assign cpu_data_wr_req_way_en = cache_hit_way_r;
  assign cpu_w_data = store_merge_data(cpu_req.addr[BYTE_OFFSET-1:0],cpu_req.inst_size,cpu_req.data,cpu_req.data);  //这里有些疑惑
  generate 
    for(genvar i=0;i<CACHE_BANK_N;i++) begin:g_data
       assign cpu_data_wr_req_data[i] = cpu_w_data;
    end
  endgenerate

  assign cache_hit_way_dirty = |(cache_hit_way_r & cache_line_dirty_r);

  //when clean, should wirte tag,tag.dirty->1 但是仅仅更新tag
  assign cpu_tag_wr_req_valid     = cache_hit_r && (cpu_req.inst_type == STORE) && !cache_hit_way_dirty;  //写tag的vaild应该是跟写data一样
  assign cpu_tag_wr_req_idx       = cpu_req.addr[IDX_MSB:IDX_LSB];
  assign cpu_tag_wr_req_way_en    = cache_hit_way_r;
  assign cpu_tag_wr_req_tag.dirty = 1'b1;
  assign cpu_tag_wr_req_tag.valid = cache_hit_tag_r.valid;
  assign cpu_tag_wr_req_tag.addr  = cache_hit_tag_r.addr;  //等会看看这里，3.31 14:52

  //------------------------------------------------------以上hit就做完了
  //  Cache miss

  //  AR request
  assign axi_ar_valid_o = (state == REQ_AR);
  //  TODO: 
  assign axi_ar_o.id    = {AXI_AWID_WIDTH{1'b0}};
  assign axi_ar_o.addr  = cpu_req.addr;                               //----------这里还有工作没有做
  assign axi_ar_o.len   = {512/DATA_WIDTH} - 1'b1;
  assign axi_ar_o.size  = 3'd4;
  assign axi_ar_o.burst = WRAP;
  assign axi_ar_o.lock  = 1'b0;
  assign axi_ar_o.cache = 4'b1111;
  assign axi_ar_o.prot  = 3'b010;
  //  ...

  //  replacement
  assign cache_set_has_invaild_way = |(~cache_line_valid_r);  //然后根据这个信号来选择使用的是哪一种方式来替换

  //  the set has invalid way
  prior_arb #(CACHE_WAY_N) u_invalid_way_arb(
      .req(invalid_way_arb_req),
      .grant(invalid_way_arb_grant),   //one hot
      .grant_valid(invalid_way_arb_grant_valid)  //1 B
  );

  assign invalid_way_arb_req = ~cache_line_valid_r;

  //  the set dosen't have invalid way
  lfsr #(CACHE_WAY_IDX_W+2) u_lfsr(
      .clk(clk),
      .rst_n(rst_n),
      .lfsr_data(lfsr_sel)
  ); 

  assign lfsr_way_sel = lfsr_sel[2+:CACHE_WAY_IDX_W];

  bin2oh  #(.OH_WIDTH(CACHE_WAY_N)) u_lfsr_way_bin2oh(
    .bin_i  (lfsr_way_sel),
    .oh_o   (lfsr_way_sel_oh)
  );

  assign refill_way = cache_set_has_invaild_way ? invalid_way_arb_grant : lfsr_way_sel_oh;
  assign refill_way_dirty = |(cache_line_dirty_r & refill_way);

  //  Dirty -> Write back
  //  Read data, AW          两拍处理    从SRAM里面读整个cache line（2次），写回（总线）需要4次
  assign axi_ar_fire = axi_ar_valid_o & axi_ar_ready_i;

  //  delay a cycle
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      axi_ar_fire_tc1 <= 1'b0;
      axi_ar_fire_tc2 <= 1'b0;
    end
    else begin
      axi_ar_fire_tc1 <= axi_ar_fire;
      axi_ar_fire_tc2 <= axi_ar_fire_tc1;
    end
  end

  //  read tag as AWADDR
  assign wb_tag_rd_req_valid = refill_way_dirty && axi_ar_fire;
  assign wb_tag_rd_req_idx   = cpu_req.addr[IDX_MSB:IDX_LSB];
  assign wb_tag_rd_req_way_en = refill_way;

  oh_logic_mux #(                                       //这一步就是根据refill_way挑选出需要回写的tag（wb_tag）
    .NUM(CACHE_WAY_N),
    .WIDTH(CACHE_TAG_W)       
  ) wb_tag_oh_logic_mux(
    .oh_sel_i(refill_way),
    .data_i(tag_rd),
    .data_o(wb_tag)
  );

  always_ff@(posedge clk) begin
    if(refill_way_dirty && axi_ar_fire_tc1)
      wb_tag_r <= wb_tag;  //  tag，AWADDR
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      wb_req_aw <= 1'b0;
    else if(refill_way_dirty && axi_ar_fire_tc1)  //  has got tag,这里不太清楚了
      wb_req_aw <= 1'b1;
    else if(axi_aw_valid_o && axi_aw_ready_i)
      wb_req_aw <= 1'b0;
  end

  //  read data which needs be writeback
  assign wb_data_rd_req_valid   = refill_way_dirty && (axi_ar_fire || axi_ar_fire_tc1);
  assign wb_data_rd_req_idx     = cpu_req.addr[IDX_MSB:IDX_LSB];
  assign wb_data_rd_req_bank_en = axi_ar_fire ? 8'b0000_1111 : 8'b1111_0000; //分两次读，先读低4个bank->高4个bank
  assign wb_data_rd_req_way_en  = refill_way;

  always_ff @(posedge clk) begin
    if(wb_get_data_tc1)
      wb_data_rd_tc1 <= {data_rd[3],data_rd[2],data_rd[1],data_rd[0]};  //256 bit数据，需要写回的
  end

  always_ff @(posedge clk) begin
    if(wb_get_data_tc2)
      wb_data_rd_tc2 <= {data_rd[3],data_rd[2],data_rd[1],data_rd[0]};  //256 bit数据，需要写回的
  end

  assign wb_get_data_tc1 = refill_way_dirty && axi_ar_fire_tc1;
  assign wb_get_data_tc2 = refill_way_dirty && axi_ar_fire_tc2;

  //  AW request (write dirty cache line that is replaced) (1 cycle),
  assign axi_aw_valid_o = wb_req_aw;                  //当需要进行写回的时候，访问axi通道进行回写数据,只有1拍
  assign axi_aw_o.id    = {AXI_AWID_WIDTH{1'b0}};
  assign axi_aw_o.addr  = {wb_tag_r, cpu_req.addr[IDX_MSB:IDX_LSB], 6'b0};                                 //往下写的地址应该是什么呢
  assign axi_aw_o.len   = {512/DATA_WIDTH} - 1'b1;    //  4 beats (3+1)
  assign axi_aw_o.size  = 3'd4;                       //  16 Bytes
  assign axi_aw_o.burst = WRAP;                      //  WRAP
  assign axi_aw_o.lock  = 1'b0;
  assign axi_aw_o.cache = 4'b1111;
  assign axi_aw_o.prot  = 3'b010;                     //  non-secure, data, unpriviedge
  //  aw....

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      need_wait_b <= 1'b0;
    else if(cpu_req_valid_i && cpu_req_ready_o)
      need_wait_b <= 1'b0;
    else if(axi_aw_valid_o && axi_aw_ready_i)
      need_wait_b <= 1'b1;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      wb_req_w <= 1'b0;
    else if(refill_way_dirty && axi_ar_fire_tc1)  //  has got data
      wb_req_w <= 1'b1;
    else if(axi_w_valid_o && axi_w_ready_i && axi_w_o.last)
      wb_req_w <= 1'b0;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      wb_cnt <= {LINE_CNT_W{1'b0}};
    else if(axi_w_valid_o && axi_w_ready_i)
      wb_cnt <= wb_cnt + 1'b1;
  end

  assign wb_data = {wb_data_rd_tc2, wb_data_rd_tc1};  //  512 bits

  //  W request (4 cycles)
  assign axi_w_valid_o = wb_req_w;
  assign axi_w_o.data  = wb_data[wb_cnt*DATA_WIDTH+:DATA_WIDTH];
  assign axi_w_o.strb  = {AXI_STRB_WIDTH{1'b1}};
  assign axi_w_o.last  = (wb_cnt == {LINE_CNT_W{1'b1}});

  //  B response
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      get_b_resp <= 1'b0;
    else if(cpu_req_valid_i && cpu_req_ready_o)
      get_b_resp <= 1'b0;
    else if(axi_b_valid_i && axi_b_ready_o)
      get_b_resp <= 1'b1;
  end

  always_ff @(posedge clk) begin   
    if(axi_b_valid_i && axi_b_ready_o)
      b_resp <= axi_b_i.resp;
  end

  assign dcache_ctrl_o.bus_err_valid = axi_b_valid_i && (axi_b_i.resp == SLVERR || axi_b_i.resp == DECERR);
  assign dcache_ctrl_o.bus_err_addr  = cpu_req.addr;
 
  //  R response (get new cache line which will be refilled)
  always_ff @(posedge clk) begin
    if(cpu_req_valid_i && cpu_req_ready_o)
      r_data_ptr <= cpu_req.addr[5:$clog2(DATA_WIDTH/8)]; 
    else if(axi_r_valid_i && axi_r_ready_o) 
      r_data_ptr <= r_data_ptr + 1'b1;
  end

  always_ff@(posedge clk) begin
    if(axi_r_valid_i && axi_r_ready_o)
      r_data[r_data_ptr*DATA_WIDTH+:DATA_WIDTH] <= axi_r_i.data;  
  end

  always_ff @(posedge clk) begin
    if(cpu_req_valid_i && cpu_req_ready_o)
      r_last <= 1'b0;
    else if(axi_r_valid_i && axi_r_ready_o && axi_r_i.last)
      r_last <= 1'b1;
  end

  assign axi_r_ready_o = 1'b1;
  assign axi_b_ready_o = 1'b1;

  //  Store merge
  //  r_data -> refill_data   r_data是一个axi返回的512 bit数据，现在要转换为refill_data数据，然后回填到cache里面
  assign refill_data_sel = line_data_sel(cpu_req.addr[BANK_MSB:BANK_LSB],r_data);  //64 bit，需要回填的数据
  assign merge_data      = store_merge_data(cpu_req.addr[BANK_MSB:BANK_LSB],cpu_req.inst_size,cpu_req.data,refill_data_sel);
  //assign merge_cacheline = r_data                                                      //怎么把这64bit和原来的cacheline拼起来
  always_comb begin
    unique case(cpu_req.addr[5:3])
          3'h0:merge_cacheline = {r_data[511:64], merge_data};
          3'h1:merge_cacheline = {r_data[511:128], merge_data, r_data[63:0]};
          3'h2:merge_cacheline = {r_data[511:192], merge_data, r_data[127:0]};
          3'h3:merge_cacheline = {r_data[511:256], merge_data, r_data[191:0]};
          3'h4:merge_cacheline = {r_data[511:320], merge_data, r_data[255:0]};
          3'h5:merge_cacheline = {r_data[511:384], merge_data, r_data[319:0]};
          3'h6:merge_cacheline = {r_data[511:447], merge_data, r_data[383:0]};
          3'h7:merge_cacheline = {merge_data, r_data[447:0]};
    endcase
  end
  always_ff@(posedge clk) begin
    if(state == STORE_MERGE) 
      merge_cacheline_r <= merge_cacheline;
  end
  //  Refill tag和data都要refill
  //先写refill tag的部分，就是将新的接口和sram接起来，最后在仲裁一下，仲裁的步骤后面再写
  assign refill_tag_wr_req_valid    = (state == REFILL);
  assign refill_tag_wr_req_idx      = cpu_req.addr[IDX_MSB:IDX_LSB];
  assign refill_tag_wr_req_way_en   = refill_way;
  assign refill_tag_wr_req_tag.dirty= (cpu_req.inst_type == STORE) ;
  assign refill_tag_wr_req_tag.valid= 1'b1 ;
  assign refill_tag_wr_req_tag.addr = cpu_req.addr[TAG_MSB:TAG_LSB] ;

  //然后是refill data部分
  assign refill_data_wr_req_valid   = (state == REFILL);
  assign refill_data_wr_req_idx     = cpu_req.addr[IDX_MSB:IDX_LSB];
  assign refill_data_wr_req_bank_en = 8'b1111_1111;                 //应该写整个cache line
  assign refill_data_wr_req_way_en  = refill_way;
  assign refill_data                = (cpu_req.inst_type == STORE) ? merge_cacheline_r : r_data ;   //如果是store就选择merge过的数据，如果是load，就用axi读出来的r_data
  generate 
      for(genvar i=0;i<CACHE_BANK_N;i++) begin:g_refill_data
          assign refill_data_wr_req_data[i] = refill_data[i*CACHE_BANK_W+63:i*CACHE_BANK_W];
      end
  endgenerate
  //处理load response，关于hit部分的数据已经在大约275行左右处理，接下来写miss部分的数据

  assign load_resp_data_miss = load_data_gen(cpu_req.addr[BYTE_OFFSET-1:0],
                                             cpu_req.inst_signed          ,
                                             cpu_req.inst_size            ,
                                             refill_data_sel              );
  //当满足这个条件的时候，正好的r通道接受数据的下一拍
  assign load_miss_resp_valid = (r_data_ptr == cpu_req.addr[5:$clog2(DATA_WIDTH/8)] + 1'b1) ;
  assign dcache_resp_valid_o  = load_hit_resp_valid  | load_miss_resp_valid ;
  assign dcache_resp_o.data   = load_hit_resp_valid ? load_resp_data_hit :load_resp_data_miss ;
  
  //按照时间顺序，对SRAM的接口信号进行仲裁，将这个写到最上面SRAM例化那里


endmodule
