package axi_pkg;

  parameter AXI_ADDR_WIDTH  = 40;
  parameter DATA_WIDTH  = 128;
  parameter AXI_STRB_WIDTH  = DATA_WIDTH/8;  //16 bit
  parameter AXI_AWID_WIDTH  = 5;
  parameter AXI_BID_WIDTH   = AXI_AWID_WIDTH;
  parameter AXI_ARID_WIDTH  = 5;
  parameter AXI_RID_WIDTH   = AXI_ARID_WIDTH;

  typedef logic[AXI_ADDR_WIDTH-1:0] axi_addr_t;
  typedef logic[DATA_WIDTH-1:0] axi_data_t;
  typedef logic[AXI_STRB_WIDTH-1:0] axi_strb_t;
  typedef logic[AXI_AWID_WIDTH-1:0] axi_awid_t;
  typedef logic[AXI_BID_WIDTH-1:0]  axi_bid_t;
  typedef logic[AXI_ARID_WIDTH-1:0] axi_arid_t;
  typedef logic[AXI_RID_WIDTH-1:0]  axi_rid_t;
  typedef logic[1:0]                axi_len_t;
  typedef logic[2:0]                axi_size_t;
  typedef enum logic[1:0] {
    FIXED, INCR, WRAP
  }                                 axi_burst_t;//突发类型  
  typedef logic                     axi_lock_t;//锁定类型，与原子有关
  typedef logic[3:0]                axi_cache_t;//存储类型
  typedef logic[2:0]                axi_prot_t;//保护类型

  typedef enum logic[1:0] {
    OKAY, EXOKAY, SLVERR, DECERR
  }                                 axi_b_resp_t;

  //======================================================
  //                     AXI Channels
  //======================================================

  //------------------------------------------------------
  //  AXI Read Address (AR) Channel

  typedef struct packed {
    axi_arid_t    id;
    axi_addr_t    addr;
    axi_len_t     len;
    axi_size_t    size;
    axi_burst_t   burst;
    axi_lock_t    lock;
    axi_cache_t   cache;
    axi_prot_t    prot;
  } axi_ar_t;   /////////////////////////////////为什么这里没有ready valid信号呢,单独加在端口

  localparam AXI_AR_WIDTH = $bits(axi_ar_t);  /////这是什么语法，没找到，读总位宽

  //------------------------------------------------------
  //  AXI Read Data (R) Channel

  typedef struct packed {
    axi_rid_t   id;
    axi_data_t  data;
    logic[1:0]  resp;
    logic       last;
  } axi_r_t;

  localparam AXI_R_WIDTH = $bits(axi_r_t);

  //------------------------------------------------------
  //  AXI Write Address (AW) Channel

  typedef struct packed {
    axi_awid_t    id;
    axi_addr_t    addr;
    axi_len_t     len;
    axi_size_t    size;
    axi_burst_t   burst;
    axi_lock_t    lock;
    axi_cache_t   cache;
    axi_prot_t    prot;
  } axi_aw_t;

  localparam AXI_AW_WIDTH = $bits(axi_aw_t);

  //------------------------------------------------------
  //  AXI Write Data (W) Channel

  typedef struct packed {
    axi_data_t  data;
    axi_strb_t  strb;
    logic       last;
  } axi_w_t;

  localparam AXI_W_WIDTH = $bits(axi_w_t);

  //------------------------------------------------------
  //  AXI Write Response (B) Channel

  typedef struct packed {
    axi_bid_t    id;
    axi_b_resp_t resp;
  } axi_b_t;

  localparam AXI_B_WIDTH = $bits(axi_b_t);

endpackage
//ar aw  are output
//r w wb are input