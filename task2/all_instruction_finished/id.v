`include "defines.v"

module id(

	input wire					  rst,
	input wire[`InstAddrBus]	  pc_i,
	input wire[`InstBus]          inst_i,
	input wire					  is_in_delayslot_i,
	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,
	
	input wire[`AluOpBus]		  ex_aluop_i,
	input wire             		  ex_wreg_i,
	input wire[`RegBus]			  ex_wdata_i,
	input wire[`RegAddrBus]		  ex_wd_i,

	input wire					  mem_wreg_i,
	input wire[`RegBus]			  mem_wdata_i,
	input wire[`RegAddrBus]		  mem_wd_i,
	//閫佸埌regfile鐨勪俊锟???
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//閫佸埌鎵ц闃舵鐨勪俊锟???
	output reg[`AluOpBus]         aluop_o,
	output reg[`AluFun3Bus]       alufun3_o,
	output reg[`AluFun7Bus]       alufun7_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg 					  next_inst_in_delayslot_o,
	output reg 					  branch_flag_o,
	output reg[`RegBus]			  branch_target_address_o,
	output reg[`RegBus]			  link_addr_o,
	output reg					  is_in_delayslot_o,
	output wire					  stallreq,
	output wire[`RegBus]		  inst_o		
);

  wire[6:0] op = inst_i[6:0];
  wire[5:0] op1 = inst_i[11:7]; 
  wire[3:0] op2 = inst_i[14:12]; // func3
  wire[4:0] op3 = inst_i[19:15]; 
  wire[7:0] op4 = inst_i[31:25]; // func7
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;

  reg[`RegBus]	imm;
  reg instvalid;
  
  reg stallreq_for_reg1_loadrelate;

  reg stallreq_for_reg2_loadrelate;

  wire pre_inst_is_load;

  assign pc_plus_4 = pc_i + 4;
  assign pc_plus_8 = pc_i + 8;
  assign inst_o = inst_i;
  assign pre_inst_is_load = (ex_aluop_i == `OP_LOAD) ? 1'b1 : 1'b0;
  assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alufun3_o <= `EXE_RESFUN3_NOP;
			alufun7_o <= `EXE_RESFUN7_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= `ZeroWord;		
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
		end else if(is_in_delayslot_i == `InDelaySlot) begin //
			aluop_o <= `EXE_NOP_OP;
			alufun3_o <= `EXE_RESFUN3_NOP;
			alufun7_o <= `EXE_RESFUN7_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= `ZeroWord;		
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot; //
	  	end else begin
			aluop_o <= `EXE_NOP_OP;
			alufun3_o <= `EXE_RESFUN3_NOP;
			alufun7_o <= `EXE_RESFUN7_NOP;
			wd_o <= inst_i[11:7];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[19:15];
			reg2_addr_o <= inst_i[24:20];		
			imm <= `ZeroWord;		
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;		
		  case (op)
		  	`OP_LUI:	begin
				wreg_o <= `WriteEnable;		
				aluop_o <= `OP_LUI;
				reg1_read_o <= 1'b0;	
				reg2_read_o <= 1'b0;	  	
				imm <= {inst_i[31:12],12'h0};		
				wd_o <= inst_i[11:7];
				instvalid <= `InstValid;		
			end
			`OP_AUIPC:	begin
				wreg_o <= `WriteEnable;
				aluop_o <= `OP_AUIPC;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				imm <= {inst_i[31:12],12'h0} + pc_i;
				wd_o <= inst_i[11:7];
				instvalid <= `InstValid;
			end
			`OP_JAL:	begin
				wreg_o <= `WriteEnable;
				aluop_o <= `OP_JAL;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				imm <= {{11{inst_i[31]}},inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};
				wd_o <= inst_i[11:7];
				link_addr_o <= pc_plus_4;
				branch_flag_o <= `Branch;
				next_inst_in_delayslot_o <= `InDelaySlot;
				branch_target_address_o <= {{11{inst_i[31]}},inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0} + pc_i;
				instvalid <= `InstValid;
			end	
			`OP_JALR:	begin
				wreg_o <= `WriteEnable;
				aluop_o <= `OP_JALR;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0;
				imm <= {{21{inst_i[31]}},inst_i[30:20]};
				wd_o <= inst_i[11:7];
				link_addr_o <= pc_plus_4;
				branch_flag_o <= `Branch;
				branch_target_address_o <= reg1_o + {{21{inst_i[31]}},inst_i[30:20]};
				next_inst_in_delayslot_o <= `InDelaySlot;
				instvalid <= `InstValid;
			end	
			`OP_BRANCH: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `OP_BRANCH;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1; 
				imm <= {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
				instvalid <= `InstValid;
				case(op2)
					`FUNCT3_BEQ:	begin
						alufun3_o <= `FUNCT3_BEQ;
						if(reg1_o == reg2_o) begin
							branch_target_address_o <= pc_i + {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
							branch_flag_o <= `Branch;
							next_inst_in_delayslot_o <= `InDelaySlot;
						end
					end
					`FUNCT3_BNE:	begin
						alufun3_o <= `FUNCT3_BNE;
						if(reg1_o != reg2_o) begin
							branch_target_address_o <= pc_i + {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
							branch_flag_o <= `Branch;
							next_inst_in_delayslot_o <= `InDelaySlot;
						end
					end
					`FUNCT3_BLT:	begin
						alufun3_o <= `FUNCT3_BLT;
						if((reg1_o[31] && !reg2_o[31]) || ((!reg1_o[31] && !reg2_o[31]) && reg1_o < reg2_o) || ((reg1_o[31] && reg2_o[31]) && reg1_o > reg2_o)) begin
							branch_target_address_o <= pc_i + {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
							branch_flag_o <= `Branch;
							next_inst_in_delayslot_o <= `InDelaySlot;
						end
					end
					`FUNCT3_BGE:	begin
						alufun3_o <= `FUNCT3_BGE;
						if((!reg1_o[31] && reg2_o[31]) || ((!reg1_o[31] && !reg2_o[31]) && (reg1_o >= reg2_o)) || ((reg1_o[31] && reg2_o[31]) && (reg1_o <= reg2_o))) begin
							branch_target_address_o <= pc_i + {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
							branch_flag_o <= `Branch;
							next_inst_in_delayslot_o <= `InDelaySlot;
						end
					end
					`FUNCT3_BLTU:	begin
						alufun3_o <= `FUNCT3_BLTU;
						if(reg1_o < reg2_o) begin
							branch_target_address_o <= pc_i + {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
							branch_flag_o <= `Branch;
							next_inst_in_delayslot_o <= `InDelaySlot;
						end
					end
					`FUNCT3_BGEU:	begin
						alufun3_o <= `FUNCT3_BGEU;
						if(reg1_o >= reg2_o) begin
							branch_target_address_o <= pc_i + {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
							branch_flag_o <= `Branch;
							next_inst_in_delayslot_o <= `InDelaySlot;
						end
					end
					default:			begin
		    		end
				endcase
			end
			`OP_LOAD:	begin
				wreg_o <= `WriteEnable;
				aluop_o <= `OP_LOAD;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0; 
				//imm <= {{21{inst_i[31]}},inst_i[30:20]};
				wd_o <= inst_i[11:7];
				instvalid <= `InstValid;
				case(op2)
					`FUNCT3_LB:	begin
						alufun3_o <= `FUNCT3_LB;
					end
					`FUNCT3_LH:	begin
						alufun3_o <= `FUNCT3_LH;
					end
					`FUNCT3_LW: begin
						alufun3_o <= `FUNCT3_LW;
					end
					`FUNCT3_LBU: begin
						alufun3_o <= `FUNCT3_LBU;
					end
					`FUNCT3_LHU: begin
						alufun3_o <= `FUNCT3_LHU;
					end
					default:			begin
		    		end
			     endcase
			    end
			`OP_STORE: begin
				wreg_o <= `WriteDisable;
				aluop_o <= `OP_STORE;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1; 
				//imm <= {{21{inst_i[31]}},inst_i[30:25],inst_i[11:7]};
				instvalid <= `InstValid;
				case(op2)
					`FUNCT3_SB:	begin
						alufun3_o <= `FUNCT3_SB;
					end
					`FUNCT3_SH:	begin
						alufun3_o <= `FUNCT3_SH;
					end
					`FUNCT3_SW:	begin
						alufun3_o <= `FUNCT3_SW;
					end
					default:			begin
		    		end
			 endcase
			end
			`OP_OP_IMM: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `OP_OP_IMM;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b0; 
				imm <= {{21{inst_i[31]}},inst_i[30:20]};
				wd_o <= inst_i[11:7];
				instvalid <= `InstValid;
				case(op2)
					`FUNCT3_ADDI:	begin
						alufun3_o <= `FUNCT3_ADDI;
					end
					`FUNCT3_SLTI:	begin
						alufun3_o <= `FUNCT3_SLTI;
					end
					`FUNCT3_SLTIU:	begin
						alufun3_o <= `FUNCT3_SLTIU;
					end
					`FUNCT3_XORI:	begin
						alufun3_o <= `FUNCT3_XORI;
					end
					`FUNCT3_ORI:	begin
						alufun3_o <= `FUNCT3_ORI;
					end   
					`FUNCT3_ANDI:	begin
						alufun3_o <= `FUNCT3_ANDI;
					end 
					`FUNCT3_SLLI:	begin
						alufun3_o <= `FUNCT3_SLLI;
						imm <= {27'b0,inst_i[24:20]};
						reg2_read_o <= 1'b0; 
					end
					`FUNCT3_SRLI_SRAI:	begin
						alufun3_o <= `FUNCT3_SRLI_SRAI;
						case(op4)
							`FUNCT7_SRLI:	begin
								alufun7_o <= `FUNCT7_SRLI;
								imm <= {27'b0,inst_i[24:20]};
								reg2_read_o <= 1'b0; 
							end
							`FUNCT7_SRAI:	begin 
								alufun7_o <= `FUNCT7_SRAI;
								imm <= {27'b0,inst_i[24:20]};
								reg2_read_o <= 1'b0; 
							end
							default:			begin
		    				end
						endcase
					end
				default:			begin
		    	end
				endcase
			end
			`OP_OP: begin
				wreg_o <= `WriteEnable;
				aluop_o <= `OP_OP;
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1; 
				wd_o <= inst_i[11:7];
				instvalid <= `InstValid;
				case(op2)
					`FUNCT3_ADD_SUB:	begin
						alufun3_o <= `FUNCT3_ADD_SUB;
						case(op4)
							`FUNCT7_ADD:	begin
								alufun7_o <= `FUNCT7_ADD;
							end
							`FUNCT7_SUB:	begin
								alufun7_o <= `FUNCT7_SUB;
							end
							default:			begin
		    				end
					   endcase
					end
					`FUNCT3_SLL:	begin
						alufun3_o <= `FUNCT3_SLL;
					end     
					`FUNCT3_SLT:	begin
						alufun3_o <= `FUNCT3_SLT;     
					end
					`FUNCT3_SLTU:	begin
						alufun3_o <= `FUNCT3_SLTU;   
					end
					`FUNCT3_XOR:	begin
						alufun3_o <= `FUNCT3_XOR;
					end
					`FUNCT3_SRL_SRA:	begin
						alufun3_o <= `FUNCT3_SRL_SRA;
						case(op4) 
							`FUNCT7_SRL:	begin
								alufun7_o <= `FUNCT7_SRL;
							end
							`FUNCT7_SRA:	begin
								alufun7_o <= `FUNCT7_SRA;
							end
							default:			begin
		    				end 
					   endcase
					end
					`FUNCT3_OR:   begin
						alufun3_o <= `FUNCT3_OR;
					end   
					`FUNCT3_AND:	begin
						alufun3_o <= `FUNCT3_AND;
					end
					default:			begin
		    		end
			     endcase
			 end
			`OP_MISC_MEM: begin
				aluop_o <= `OP_MISC_MEM;
				case(op2)
					`FUNCT3_FENCE: begin
						alufun3_o <= `FUNCT3_FENCE;
					end
					`FUNCT3_FENCEI:	begin
						alufun3_o <= `FUNCT3_FENCEI;
					end
					default:			begin
		    		end
			     endcase
			end							 
		    default:			begin
		    end
		  endcase		  //case op			
		end       //if
	end        //always
	


	always @ (*) begin
			stallreq_for_reg1_loadrelate <= `NoStop;	
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;	
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  	stallreq_for_reg1_loadrelate <= `Stop;							
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o) && (reg1_addr_o != 0)) begin
			reg1_o <= ex_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o) && (reg1_addr_o != 0)) begin
			reg1_o <= mem_wdata_i; 			
	  end else if(reg1_read_o == 1'b1) begin
	  		reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  		reg1_o <= imm;
	  end else begin
	    	reg1_o <= `ZeroWord;
	  end
	end
	
	always @ (*) begin
			stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1) begin
		 	stallreq_for_reg2_loadrelate <= `Stop;			
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o) && (reg2_addr_o != 0)) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o) && (reg2_addr_o != 0)) begin
			reg2_o <= mem_wdata_i;			
	  end else if(reg2_read_o == 1'b1) begin
	  		reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  		reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	end
	
endmodule