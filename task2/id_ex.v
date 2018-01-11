`include "defines.v"

module id_ex(

	input	wire				  clk,
	input	wire				  rst,
	input   wire[5:0]			  stall,
	
	//浠庤瘧鐮�?樁娈典紶閫掔殑淇℃伅
	input wire[`AluOpBus]         id_aluop,
	input wire[`AluFun3Bus]       id_alufun3,
	input wire[`AluFun7Bus]       id_alufun7,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,	
	input wire[`RegBus]           id_link_address,
	input wire                    id_is_in_delayslot,
	input wire                    next_inst_in_delayslot_i,
	input wire[`RegBus]			  id_inst,	
	//浼犻?掑埌鎵ц闃舵鐨勪俊�??
	output reg[`AluOpBus]         ex_aluop,
	output reg[`AluFun3Bus]       ex_alufun3,
	output reg[`AluFun7Bus]		  ex_alufun7,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           ex_reg2,
	output reg[`RegAddrBus]       ex_wd,
	output reg                    ex_wreg,
	output reg[`RegBus]           ex_link_address,
    output reg                    ex_is_in_delayslot,
	output reg                    is_in_delayslot_o,
	output reg[`RegBus]			  ex_inst	
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alufun3 <= `EXE_RESFUN3_NOP;
			ex_alufun7 <= `EXE_RESFUN7_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
		    is_in_delayslot_o <= `NotInDelaySlot;
			ex_inst <= `ZeroWord;		
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alufun3 <= `EXE_RESFUN3_NOP;
			ex_alufun7 <= `EXE_RESFUN7_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
	    	ex_is_in_delayslot <= `NotInDelaySlot;
	    	is_in_delayslot_o <= `NotInDelaySlot;
			ex_inst <= `ZeroWord;		
		end else if(stall[2] == `NoStop) begin		
	/*		if(id_is_in_delayslot == `InDelaySlot) begin
			ex_aluop <= `EXE_NOP_OP;
            ex_alufun3 <= `EXE_RESFUN3_NOP;
            ex_alufun7 <= `EXE_RESFUN7_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_wd <= `NOPRegAddr;
            ex_wreg <= `WriteDisable;
            ex_link_address <= `ZeroWord;
            ex_is_in_delayslot <= `NotInDelaySlot;  
            is_in_delayslot_o <= next_inst_in_delayslot_i;
			ex_inst <= `ZeroWord;	
            end else begin */
			ex_aluop <= id_aluop;
			ex_alufun3 <= id_alufun3;
			ex_alufun7 <= id_alufun7;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
	    	is_in_delayslot_o <= next_inst_in_delayslot_i;
			ex_inst <= id_inst;		
	    	end			
		end
	//end
	
endmodule