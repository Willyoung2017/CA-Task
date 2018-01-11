`include "defines.v"

module openmips(

	input	wire				    clk,
	input   wire					rst,
	
 
	input   wire[`RegBus]           rom_data_i,
	output  wire[`RegBus]           rom_addr_o,
	output  wire                    rom_ce_o,

	//杩炴帴鏁版嵁瀛樺偍鍣?
	input   wire[`RegBus]			ram_data_i,
	output  wire[`RegBus]			ram_addr_o,
	output  wire[`RegBus]			ram_data_o,
	output  wire					ram_we_o,
	output  wire[3:0]				ram_sel_o,
	output  wire 					ram_ce_o
	
);

	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//杩炴帴璇戠爜闃舵ID妯″潡鐨勮緭鍑轰笌ID/EX妯″潡鐨勮緭鍏?
	wire[`AluOpBus] id_aluop_o;
	wire[`AluFun3Bus] id_alufun3_o;
	wire[`AluFun7Bus] id_alufun7_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
	wire[`RegBus]  id_link_address_o;
	wire[`RegBus]  id_inst_o;
	
	//杩炴帴ID/EX妯″潡鐨勮緭鍑轰笌鎵ц闃舵EX妯″潡鐨勮緭鍏?
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluFun3Bus] ex_alufun3_i;
	wire[`AluFun7Bus] ex_alufun7_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;
	wire[`RegBus] ex_link_address_i;
	wire[`RegBus] ex_inst_i;
	
	//杩炴帴鎵ц闃舵EX妯″潡鐨勮緭鍑轰笌EX/MEM妯″潡鐨勮緭鍏?
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`AluFun3Bus] ex_alufun3_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg1_o;
	wire[`RegBus] ex_reg2_o;

 	//杩炴帴EX/MEM妯″潡鐨勮緭鍑轰笌璁垮瓨闃舵MEM妯″潡鐨勮緭鍏?
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`AluOpBus] mem_aluop_i;
	wire[`AluFun3Bus] mem_alufun3_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg1_i;
	wire[`RegBus] mem_reg2_i;

	//杩炴帴璁垮瓨闃舵MEM妯″潡鐨勮緭鍑轰笌MEM/WB妯″潡鐨勮緭鍏?
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	
	//杩炴帴MEM/WB妯″潡鐨勮緭鍑轰笌鍥炲啓闃舵鐨勮緭鍏?	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	
	//杩炴帴璇戠爜闃舵ID妯″潡涓庨?氱敤瀵勫瓨鍣≧egfile妯″潡
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;
  
    wire is_in_delayslot_i;
    wire is_in_delayslot_o;
    wire next_inst_in_delayslot_o;
    wire id_branch_flag_o;
    wire[`RegBus] branch_target_address;

    wire[5:0] stall;
    wire stallreq_from_id;    
    wire stallreq_from_ex;
  
  //pc_reg渚嬪寲
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
        .branch_flag_i(id_branch_flag_o),
        .branch_target_address_i(branch_target_address),    
		.pc(pc),
		.ce(rom_ce_o)	
			
	);
	
  assign rom_addr_o = pc;

  //IF/ID渚嬪寲
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.if_pc(pc),
		.stall(stall),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	//璇戠爜闃舵ID妯″潡
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),
        
		//.ex_aluop_i(ex_aluop_o),
		
		//澶勪簬鎵ц闃舵鐨勬寚浠よ鍐欏叆鐨勭洰鐨勫瘎瀛樺櫒淇℃伅
        .ex_aluop_i(ex_aluop_o),
		.ex_wreg_i(ex_wreg_o),
        .ex_wdata_i(ex_wdata_o),
        .ex_wd_i(ex_wd_o),

        //澶勪簬璁垮瓨闃舵鐨勬寚浠よ鍐欏叆鐨勭洰鐨勫瘎瀛樺櫒淇℃伅
        .mem_wreg_i(mem_wreg_o),
        .mem_wdata_i(mem_wdata_o),
        .mem_wd_i(mem_wd_o),
        .is_in_delayslot_i(is_in_delayslot_i),        //!!!!!!
		
		//閫佸埌regfile鐨勪俊鎭?
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//閫佸埌ID/EX妯″潡鐨勪俊鎭?
		.aluop_o(id_aluop_o),
		.alufun3_o(id_alufun3_o),
		.alufun7_o(id_alufun7_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.inst_o(id_inst_o),
		
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
        .branch_flag_o(id_branch_flag_o),
        .branch_target_address_o(branch_target_address),       
        .link_addr_o(id_link_address_o),
        
       .is_in_delayslot_o(id_is_in_delayslot_o),
    
       .stallreq(stallreq_from_id)        
	);

  //閫氱敤瀵勫瓨鍣≧egfile渚嬪寲
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	//ID/EX妯″潡
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		.stall(stall),

		//浠庤瘧鐮侀樁娈礗D妯″潡浼犻?掔殑淇℃伅
		.id_aluop(id_aluop_o),
		.id_alufun3(id_alufun3_o),
		.id_alufun7(id_alufun7_o),
		.id_inst(id_inst_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_link_address(id_link_address_o),
        .id_is_in_delayslot(id_is_in_delayslot_o),
        .next_inst_in_delayslot_i(next_inst_in_delayslot_o),    
		
		//浼犻?掑埌鎵ц闃舵EX妯″潡鐨勪俊鎭?
		.ex_aluop(ex_aluop_i),
		.ex_alufun3(ex_alufun3_i),
		.ex_alufun7(ex_alufun7_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_link_address(ex_link_address_i),
        .ex_is_in_delayslot(ex_is_in_delayslot_i),
        .is_in_delayslot_o(is_in_delayslot_i),
		.ex_inst(ex_inst_i)
	);		
	
	//EX妯″潡
	ex ex0(
		.rst(rst),
	
		//閫佸埌鎵ц闃舵EX妯″潡鐨勪俊鎭?
		.aluop_i(ex_aluop_i),
		.alufun3_i(ex_alufun3_i),
		.alufun7_i(ex_alufun7_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		.inst_i(ex_inst_i),
	  	.link_address_i(ex_link_address_i),
        .is_in_delayslot_i(ex_is_in_delayslot_i),      
	    
		//EX妯″潡鐨勮緭鍑哄埌EX/MEM妯″潡淇℃伅
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),

		.aluop_o(ex_aluop_o),
		.alufun3_o(ex_alufun3_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),

        .stallreq(stallreq_from_ex)    
	);

  //EX/MEM妯″潡
  ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	    .stall(stall),

		//鏉ヨ嚜鎵ц闃舵EX妯″潡鐨勪俊鎭?	
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_aluop(ex_aluop_o),
		.ex_alufun3(ex_alufun3_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),			

		//閫佸埌璁垮瓨闃舵MEM妯″潡鐨勪俊鎭?
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_aluop(mem_aluop_i),
		.mem_alufun3(mem_alufun3_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i)						       	
	);
	
  //MEM妯″潡渚嬪寲
	mem mem0(
		.rst(rst),
	
		//鏉ヨ嚜EX/MEM妯″潡鐨勪俊鎭?	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
	    .aluop_i(mem_aluop_i),
		.alufun3_i(mem_alufun3_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),

		//鏉ヨ嚜memory鐨勪俊鎭?
		.mem_data_i(ram_data_i),

		//閫佸埌MEM/WB妯″潡鐨勪俊鎭?
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		
		//閫佸埌memory鐨勪俊鎭?
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o)
	);

  //MEM/WB濡?虫健
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),
        .stall(stall),

		//鏉ヨ嚜璁垮瓨闃舵MEM妯″潡鐨勪俊鎭?
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
	
		//閫佸埌鍥炲啓闃舵鐨勪俊鎭?
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i)
									       	
	);
	
	ctrl ctrl0(
        .rst(rst),
    
        .stallreq_from_id(stallreq_from_id),
    
        //鏉ヨ嚜鎵ц闃舵鐨勬殏鍋滆姹?
        .stallreq_from_ex(stallreq_from_ex),

        .stall(stall)           
    );


endmodule