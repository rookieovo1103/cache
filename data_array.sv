import cache_pkg::*;
module data_array(
    input  logic                      clk,

    input  logic                      rd_req_valid_i,                    //读请求vaild
    input  logic [CACHE_IDX_W-1:0]    rd_req_idx_i,                      //选择idx，也就是选中哪一个set
    input  logic [CACHE_BANK_N-1:0]   rd_req_bank_en_i,                  //选择bank，哪一个bank有效
    input  logic [CACHE_WAY_N-1:0]    rd_req_way_i,                      //选择way，也就是选择4个中的哪一条cacheline

    input  logic                      wr_req_valid_i,                    //写请求valid
    input  logic [CACHE_IDX_W-1:0]    wr_req_idx_i,                      //选择idx，选择写哪一个set
    input  logic [CACHE_BANK_N-1:0]   wr_req_bank_en_i,                  //选择bank，哪一个bank有效
    input  logic [CACHE_WAY_N-1:0]    wr_req_way_i,                      //选择way，4个中哪一个cacheline有效
    input  logic [CACHE_BANK_W-1:0]   wr_req_data_i [CACHE_BANK_N-1:0],  //data为[63:0][7:0]大小，也就是一个cacheline
    
    output logic [CACHE_BANK_W-1:0]   data_rd_o [CACHE_WAY_N-1:0],       //data为[63:0][3:0]大小
    output logic [BANK_ECC_W-1:0]     data_ecc_rd_o [CACHE_BANK_N-1:0]    //这个的结果链接到decode_64
);

    logic [CACHE_BANK_N-1:0]          ce;                                //抽象的片选信号，bank数量[7:0]
    logic [CACHE_WAY_N-1:0]           way_en;                            //way使能，[3:0]
    logic                             we;                                //使能信号，R：0 w:1
    logic [CACHE_IDX_W-1:0]           idx;                               //就是idx而已
    logic [CACHE_BANK_W-1:0]          r_data [CACHE_WAY_N-1:0][CACHE_BANK_N-1:0];//64bit 的bank，4路，每一路8个bank,三维数组
    logic [BANK_ECC_W-1:0]            r_data_ecc [CACHE_WAY_N-1:0][CACHE_BANK_N-1:0];
    logic [$clog2(CACHE_BANK_N)-1:0]  rd_bank_sel;                       //[2:0]的bank选择信号
    logic [$clog2(CACHE_WAY_N)-1:0]   rd_way_sel;                        //[1:0]的way选择信号
    logic                             req_from_lsu;                      //LSU的请求
    logic [CACHE_BANK_W-1:0]          lsu_data_rd [CACHE_WAY_N-1:0];     //
    logic [CACHE_BANK_W-1:0]          wb_data_rd  [CACHE_BANK_N/2-1:0];
    logic                             wb_first_req;
    logic [BANK_ECC_W-1:0]            data_encoder_ecc [CACHE_BANK_N-1:0];
    logic [BANK_ECC_W-1:0]            lsu_data_ecc_rd [CACHE_BANK_N-1:0];
    logic [BANK_ECC_W-1:0]            wb_data_ecc_rd [CACHE_BANK_N-1:0];

    generate
        for(genvar i=0; i<CACHE_WAY_N; i++) begin: g_data_way
            for(genvar j=0; j<CACHE_BANK_N; j++) begin: g_data_bank
                sram_model  #(
                    .DATA_W (CACHE_BANK_W),                             
                    .ADDR_W (CACHE_IDX_W),
                    .SINGLE_ERROR_INJ(1),
                    .DOUBLE_ERROR_INJ(0)
                ) u_data_ram(
                    .clk    (clk),
                    .ce     (ce[j]),    
                    .way_en (way_en[i]),
                    .we     (we),
                    .addr   (idx),
                    .w_data (wr_req_data_i[j]),
                    .r_data (r_data[i][j])
                );

                sram_model  #(
                    .DATA_W (BANK_ECC_W),                            
                    .ADDR_W (CACHE_IDX_W),
                    .SINGLE_ERROR_INJ(0),
                    .DOUBLE_ERROR_INJ(0)
                ) u_data_ecc_ram(
                    .clk    (clk),
                    .ce     (ce[j]),    
                    .way_en (way_en[i]),
                    .we     (we),
                    .addr   (idx),
                    .w_data (data_encoder_ecc[j]),
                    .r_data (r_data_ecc[i][j])
                );
            end
        end
    endgenerate

    generate
        for(genvar i=0; i<CACHE_BANK_N; i++) begin: g_ecc_encoder
            sec_ded_daec_encoder_64     data_ecc_encoder(
                .data_i     (wr_req_data_i[i]),
                .ecc_o      (data_encoder_ecc[i])
            );
        end
    endgenerate

    assign ce = {CACHE_BANK_N{rd_req_valid_i}} & rd_req_bank_en_i | 
                {CACHE_BANK_N{wr_req_valid_i}} & wr_req_bank_en_i ;
    assign way_en = {CACHE_WAY_N{rd_req_valid_i}} & rd_req_way_i | 
                    {CACHE_WAY_N{wr_req_valid_i}} & wr_req_way_i ;
    assign we = wr_req_valid_i;
    //assign idx = rd_req_valid_i ? rd_req_idx_i : wr_req_idx_i;
    assign idx = {CACHE_IDX_W{rd_req_valid_i}} & rd_req_idx_i |
                 {CACHE_IDX_W{wr_req_valid_i}} & wr_req_idx_i ;

    oh2bin #(CACHE_BANK_N)  u_bank_sel(
        .oh_i    (rd_req_bank_en_i),
        .bin_o   (rd_bank_sel)
    );

    assign req_from_lsu = &rd_req_way_i;

    generate
        for(genvar i=0; i<CACHE_WAY_N; i++) begin: g_bank_sel
            assign lsu_data_rd[i] = r_data[i][rd_bank_sel];
            assign lsu_data_ecc_rd[i] = r_data_ecc[i][rd_bank_sel]; 
        end
    endgenerate

    oh2bin #(CACHE_WAY_N)  u_way_sel(
        .oh_i    (rd_req_way_i),
        .bin_o   (rd_way_sel)
    );

    assign wb_first_req = rd_req_bank_en_i[0];

    generate
        for(genvar i=0; i<CACHE_BANK_N/2; i++) begin: g_way_sel
            assign wb_data_rd[i] = r_data[rd_way_sel][wb_first_req*4+i];
            assign wb_data_ecc_rd[i] = r_data_ecc[rd_way_sel][wb_first_req*4+i];
        end
    endgenerate

    assign data_rd_o     = req_from_lsu ? lsu_data_rd     : wb_data_rd;
    assign data_ecc_rd_o = req_from_lsu ? lsu_data_ecc_rd : wb_data_ecc_rd ;

endmodule