package cache_pkg;
  import axi_pkg::*;

  //  Physical Address (40-bit):
  //  -------------------------------------------------
  //  |   tag   |  index  | bank offset | byte offset |
  //  | [39:14] |  [13:6] |    [5:3]    |    [2:0]    |
  //  -------------------------------------------------

  //======================================================
  //                    Configuration
  //======================================================

  //  parameter of DCache

  parameter ADDR_WIDTH      = 40; //  CPU address width
  parameter DATA_WIDTH      = 64; //  CPU data width
  parameter CACHE_SIZE      = 64; //  KB
  parameter CACHE_WAY_N     = 4;
  parameter CACHE_WAY_IDX_W = $clog2(CACHE_WAY_N);
  parameter CACHE_BANK_N    = 8;
  parameter LINE_SIZE       = 512;  //  bit
  parameter CACHE_BANK_W    = 64;
  parameter CACHE_SET_N     = CACHE_SIZE*1024/(LINE_SIZE/8)/CACHE_WAY_N;
  parameter LINE_BEATS      = LINE_SIZE/AXI_DATA_WIDTH;  ///???????为什么axi data是128呢，固定的吗
  parameter LINE_CNT_W      = $clog2(LINE_BEATS);

  parameter BYTE_OFFSET     = $clog2(DATA_WIDTH/8);  // 3 bit
  parameter BANK_OFFSET     = $clog2(CACHE_BANK_N);      //3 bit
  parameter LINE_OFFSET     = $clog2(LINE_SIZE/8);  //[5:0]
  parameter LINE_ADDR_WIDTH = ADDR_WIDTH-LINE_OFFSET;   //  [39:6]
  parameter CACHE_IDX_W     = $clog2(CACHE_SET_N);
  parameter CACHE_TAG_PA_W  = ADDR_WIDTH-LINE_OFFSET-CACHE_IDX_W;
  parameter BANK_LSB        = BYTE_OFFSET;
  parameter BANK_MSB        = BYTE_OFFSET+BANK_OFFSET-1;
  parameter IDX_LSB         = LINE_OFFSET;
  parameter IDX_MSB         = IDX_LSB+CACHE_IDX_W-1;
  parameter TAG_LSB         = IDX_MSB+1;
  parameter TAG_MSB         = ADDR_WIDTH-1;

  typedef struct packed {
    logic   dirty;
    logic   valid;
    logic[CACHE_TAG_PA_W-1:0] addr;
  } cache_tag_t;

  parameter CACHE_TAG_W = $bits(cache_tag_t);

  parameter TAG_ECC_W = get_ecc_width(CACHE_TAG_W);    ///////这个不太明白做了什么事情

  //  Bank data
  typedef logic[CACHE_BANK_W-1:0] bank_data_t;
  parameter BANK_ECC_W = get_ecc_width(CACHE_BANK_W);

  //  Cache line address
  typedef logic[LINE_ADDR_WIDTH-1:0] line_addr_t;
  //  Cache line
  typedef logic[LINE_SIZE-1:0] line_data_t;

  //  Instruction type
  typedef enum logic[2:0] {
    LOAD      = 3'b000,
    STORE     = 3'b001,
    FENCE     = 3'b010,
    CBO_CLEAN = 3'b100,
    CBO_FLUSH = 3'b101,
    CBO_INVAL = 3'b110
  } inst_type_t;

  //  instruction size: 0 = byte, 1 = half-word, 2 = word, 3 = double-word
  typedef enum logic[1:0] {BYTE, HALFWORD, WORD, DWORD} inst_size_t;

  //======================================================
  //           Interface between CPU <-> DCache
  //======================================================

  //  CPU Request (CPU -> DCache)
  typedef struct packed {
    logic[ADDR_WIDTH-1:0] addr;         //  request address
    logic[DATA_WIDTH-1:0] data;         //  store data
    inst_type_t           inst_type;    //  instruction type
    inst_size_t           inst_size;    //  instruction size
    logic                 inst_signed;  //  0 = unsigned, 1 = signed
    //logic                 cacheable;    //  request is cacheable
  } cpu_req_t;

  //  DCache Response (DCache -> CPU)
  typedef struct packed {
    logic[DATA_WIDTH-1:0] data;       //  read data
  } dcache_resp_t;

  //  DCache Information (DCache -> CPU)
  typedef struct packed {
    logic                 bus_err_valid;  //  bus error valid
    logic[ADDR_WIDTH-1:0] bus_err_addr;   //  bus error address
  } dcache_ctrl_t;

  //======================================================
  //                   Common Function
  //======================================================

  function automatic logic[63:0] load_data_gen(logic[2:0]  addr_offset,
                                               logic       inst_signed,
                                               inst_size_t inst_size,
                                               logic[63:0] data_in);
    logic[63:0] data_gen;

    unique case(inst_size)
      BYTE: begin
        unique case(addr_offset)
          3'h0: data_gen = {{56{data_in[7]  & inst_signed}}, data_in[7:0]};
          3'h1: data_gen = {{56{data_in[15] & inst_signed}}, data_in[15:8]};
          3'h2: data_gen = {{56{data_in[23] & inst_signed}}, data_in[23:16]};
          3'h3: data_gen = {{56{data_in[31] & inst_signed}}, data_in[31:24]};
          3'h4: data_gen = {{56{data_in[39] & inst_signed}}, data_in[39:32]};
          3'h5: data_gen = {{56{data_in[47] & inst_signed}}, data_in[47:40]};
          3'h6: data_gen = {{56{data_in[55] & inst_signed}}, data_in[55:48]};
          3'h7: data_gen = {{56{data_in[63] & inst_signed}}, data_in[63:56]};
          default: data_gen = 64'bx;
        endcase
      end
      HALFWORD: begin
        unique case(addr_offset[2:1])
          2'h0: data_gen = {{48{data_in[15] & inst_signed}}, data_in[15:0]};
          2'h1: data_gen = {{48{data_in[31] & inst_signed}}, data_in[31:16]};
          2'h2: data_gen = {{48{data_in[47] & inst_signed}}, data_in[47:32]};
          2'h3: data_gen = {{48{data_in[63] & inst_signed}}, data_in[63:48]};
          default: data_gen = 64'bx;
        endcase

        assert(addr_offset[0] == 1'b0)
        else
          $error("Address Misalign! inst_size = %0b, addr_offset = %0b", inst_size, addr_offset);
      end
      WORD: begin
        unique case(addr_offset[2])
          1'b0: data_gen = {{32{data_in[31] & inst_signed}}, data_in[31:0]};
          1'b1: data_gen = {{32{data_in[63] & inst_signed}}, data_in[63:32]};
          default: data_gen = 64'bx;
        endcase

        assert(addr_offset[1:0] == 2'b0)
        else
          $error("Address Misalign! inst_size = %0b, addr_offset = %0b", inst_size, addr_offset);
      end
      DWORD: begin
        data_gen = data_in;

        assert(addr_offset == 3'b0)
        else
          $error("Address Misalign! inst_size = %0b, addr_offset = %0b", inst_size, addr_offset);
      end
      default: data_gen = 64'bx;
    endcase
    
    return data_gen;

  endfunction: load_data_gen

  function automatic logic[63:0] store_merge_data(logic[2:0]  addr_offset,
                                                  inst_size_t inst_size,
                                                  logic[63:0] store_data,
                                                  logic[63:0] data_ori);   //原来的数据

    logic[63:0] merged_data;

    unique case(inst_size)
      BYTE: begin
        unique case(addr_offset[2:0])
          3'h0: merged_data = {data_ori[63:8] , store_data[7:0]                  };
          3'h1: merged_data = {data_ori[63:16], store_data[15:8] , data_ori[7:0] };
          3'h2: merged_data = {data_ori[63:24], store_data[23:16], data_ori[15:0]};
          3'h3: merged_data = {data_ori[63:32], store_data[31:24], data_ori[23:0]};
          3'h4: merged_data = {data_ori[63:40], store_data[39:32], data_ori[31:0]};
          3'h5: merged_data = {data_ori[63:48], store_data[47:40], data_ori[39:0]};
          3'h6: merged_data = {data_ori[63:56], store_data[55:48], data_ori[47:0]};
          3'h7: merged_data = {                 store_data[63:56], data_ori[55:0]};
          default: merged_data = 64'bx;
        endcase
      end
      HALFWORD: begin
        unique case(addr_offset[2:1])
          2'h0: merged_data = {data_ori[63:16], store_data[15:0]                 };
          2'h1: merged_data = {data_ori[63:32], store_data[31:16], data_ori[15:0]};
          2'h2: merged_data = {data_ori[63:48], store_data[47:32], data_ori[31:0]};
          2'h3: merged_data = {                 store_data[63:48], data_ori[47:0]};
          default: merged_data = 64'bx;
        endcase

        assert(addr_offset[0] == 1'b0)
        else
          $error("Address Misalign! inst_size = %0b, addr_offset = %0b", inst_size, addr_offset);
      end
      WORD: begin
        unique case(addr_offset[2])
          1'b0: merged_data = {data_ori[63:32], store_data[31:0]                 };
          1'b1: merged_data = {                 store_data[63:32], data_ori[31:0]};
          default: merged_data = 64'bx;
        endcase

        assert(addr_offset[1:0] == 2'b0)
        else
          $error("Address Misalign! inst_size = %0b, addr_offset = %0b", inst_size, addr_offset);
      end
      DWORD: begin
        merged_data = store_data;

        assert(addr_offset[2:0] == 3'b0)
        else
          $error("Address Misalign! inst_size = %0b, addr_offset = %0b", inst_size, addr_offset);
      end
      default: merged_data = 64'bx;
    endcase

    return merged_data;

  endfunction: store_merge_data

  function automatic logic[63:0] line_data_sel(logic[5:3] addr,
                                               logic[511:0] data);
    logic[63:0] return_data;

    unique case(addr)
      3'h0: return_data = data[63:0];
      3'h1: return_data = data[127:64];
      3'h2: return_data = data[191:128];
      3'h3: return_data = data[255:192];
      3'h4: return_data = data[319:256];
      3'h5: return_data = data[383:320];
      3'h6: return_data = data[447:384];
      3'h7: return_data = data[511:448];
      default: return_data = 64'bx;
    endcase

    return return_data;

  endfunction: line_data_sel

  //function automatic bit is_pow2(int data);
  //  return ((data & (data-1)) == 0);
  //endfunction

  function automatic int get_ecc_width(int data_width);
    int ecc_width;
    while((2**ecc_width) < (ecc_width + data_width + 1))  //  SEC
      ecc_width++;
    return (ecc_width+1); //  SECDED
  endfunction

endpackage
