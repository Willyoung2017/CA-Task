`include "defines.v"

module ex(

	input wire					  rst,
	
	input wire[`RegBus]			  inst_i,
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluFun3Bus]       alufun3_i,
	input wire[`AluFun7Bus]		  alufun7_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]			  link_address_i,
	input wire					  is_in_delayslot_i,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]			  wdata_o,
	output reg					  stallreq,
	output wire[`AluOpBus]		  aluop_o,
	output wire[`AluFun3Bus]	  alufun3_o,
	output wire[`RegBus]		  mem_addr_o,
	output wire[`RegBus]		  reg2_o    
	
);

reg[`RegBus] logicout;
reg[`RegBus] shiftres;
reg[`RegBus] arithmeticres;
wire[`RegBus] reg2_i_mux;
wire[`RegBus] reg1_i_not;	
wire[`RegBus] result_sum;
wire ov_sum;
wire reg1_eq_reg2;
wire reg1_lt_reg2;

assign aluop_o = aluop_i;
assign alufun3_o = alufun3_i;
assign mem_addr_o = (aluop_i == `OP_LOAD) ? reg1_i + {{21{inst_i[31]}},inst_i[30:20]} : reg1_i + {{21{inst_i[31]}},inst_i[30:25],inst_i[11:7]};  
assign reg2_o = reg2_i;

always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`OP_OP_IMM:	begin
					case(alufun3_i)
						`FUNCT3_XORI:	begin
							logicout <= reg1_i ^ reg2_i;
						end
						`FUNCT3_ORI:	begin
							logicout <= reg1_i | reg2_i;
						end
						`FUNCT3_ANDI:	begin
							logicout <= reg1_i & reg2_i;
						end
						default:	begin
							logicout <= `ZeroWord;
						end
					endcase
				end
				`OP_OP:	begin
					case(alufun3_i)
						`FUNCT3_XOR:	begin
							logicout <= reg1_i ^ reg2_i;
							//$display("%d",233);
						end
						`FUNCT3_OR:		begin
							logicout <= reg1_i | reg2_i;
						end
						`FUNCT3_AND:	begin
							logicout <= reg1_i & reg2_i;
						end
						default:	begin
							logicout <= `ZeroWord;
						end
					endcase
				end
				default:	begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`OP_OP_IMM:	begin
					case(alufun3_i)
						`FUNCT3_SLLI:	begin
							shiftres <= reg1_i << reg2_i[4:0];
						end
						`FUNCT3_SRLI_SRAI:	begin
							case(alufun7_i)
								`FUNCT7_SRLI:	begin
									shiftres <= reg1_i >> reg2_i[4:0];
								end
								`FUNCT7_SRAI:	begin
									shiftres <= ({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]})) 
												| reg1_i >> reg2_i[4:0];
								end
								default:	begin
									shiftres <= `ZeroWord;
								end
							endcase
						end
						default:	begin
							shiftres <= `ZeroWord;
						end
					endcase
				end
				`OP_OP:	begin
					case(alufun3_i)
						`FUNCT3_SLL:	begin
							shiftres <= reg1_i << reg2_i[4:0];
						end
						`FUNCT3_SRL_SRA:		begin
							case(alufun7_i)
								`FUNCT7_SRL:	begin
									shiftres <= reg1_i >> reg2_i[4:0];
								end
								`FUNCT7_SRA:	begin
									shiftres <= ({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]})) 
												| reg1_i >> reg2_i[4:0];
								end
								default:	begin
									shiftres <= `ZeroWord;
								end
							endcase
						end
						default:	begin
							shiftres <= `ZeroWord;
						end
					endcase
				end
				default:	begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	assign reg2_i_mux = ((aluop_i == `OP_OP && alufun3_i == `FUNCT3_ADD_SUB && alufun7_i == `FUNCT7_SUB)  ||
						(aluop_i == `OP_OP && alufun3_i == `FUNCT3_SLT)) 
						? (~reg2_i)+1 : reg2_i;

	assign result_sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  
									
	assign reg1_lt_reg2 = ((aluop_i == `OP_OP && alufun3_i == `FUNCT3_SLT) || (aluop_i == `OP_OP_IMM && alufun3_i == `FUNCT3_SLTI)) ?
												 ((reg1_i[31] && !reg2_i[31]) || 
												 (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
			                   (reg1_i[31] && reg2_i[31] && result_sum[31]))
			                   :	(reg1_i < reg2_i);
  
    assign reg1_i_not = ~reg1_i;
							
	always @ (*) begin
		if(rst == `RstEnable) begin
			arithmeticres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`OP_OP_IMM:	begin
					case(alufun3_i)
						`FUNCT3_SLTI, `FUNCT3_SLTIU:	begin
							arithmeticres <= reg1_lt_reg2;
						end
						`FUNCT3_ADDI:		begin
							arithmeticres <= result_sum; 
						end
						default:	begin
							arithmeticres <= `ZeroWord;
						end
					endcase
				end
				`OP_OP:	begin
					case(alufun3_i)
						`FUNCT3_SLT, `FUNCT3_SLTU:	begin
							arithmeticres <= reg1_lt_reg2;
						end
						`FUNCT3_ADD_SUB:	begin
							case(alufun7_i)
								`FUNCT7_ADD:	begin
									arithmeticres <= result_sum; 
								end
								`FUNCT7_SUB:	begin
									arithmeticres <= result_sum; 
								end
								default:	begin
									arithmeticres <= `ZeroWord;
								end
							endcase
						end
						default:	begin
							arithmeticres <= `ZeroWord;
						end
					endcase
				end		
				default:	begin
					arithmeticres <= `ZeroWord;
				end
			endcase
		end
	end

always @ (*) begin
	wd_o <= wd_i;	 	 	
//	if(((aluop_i == `OP_OP && alufun3_i == `FUNCT3_ADD_SUB) || (aluop_i == `OP_OP_IMM && alufun3_i ==  `FUNCT3_ADDI)) && (ov_sum == 1'b1)) begin
//	 	wreg_o <= `WriteDisable;
//	end	else begin
		wreg_o <= wreg_i;
//	end
	case (aluop_i)
	 	`OP_LUI:	begin
			wdata_o <= reg1_i;
		end
		`OP_AUIPC:	begin
			wdata_o <= reg1_i;
		end
		`OP_JAL:	begin
			wdata_o <= link_address_i;
		end
		`OP_JALR:	begin
			wdata_o <= link_address_i;
		end
	 	`OP_OP_IMM:		begin
		 	case(alufun3_i)
				`FUNCT3_XORI, `FUNCT3_ORI, `FUNCT3_ANDI:	begin
	 				wdata_o <= logicout;
				end

				`FUNCT3_SLLI, `FUNCT3_SRLI_SRAI:	begin
					wdata_o <= shiftres;
				end
				`FUNCT3_ADDI, `FUNCT3_SLTI, `FUNCT3_SLTIU:
	 				wdata_o <= arithmeticres;
				default:	begin
					wdata_o <= `ZeroWord;
				end
		 	endcase
		 end
		`OP_OP:	begin
			case(alufun3_i)
				`FUNCT3_XOR, `FUNCT3_OR, `FUNCT3_AND:	begin
					wdata_o <= logicout; 
				end
				`FUNCT3_SLL, `FUNCT3_SRL_SRA:	begin
					wdata_o <= shiftres;
				end
				`FUNCT3_ADD_SUB, `FUNCT3_SLT, `FUNCT3_SLTU:	begin
					wdata_o <= arithmeticres;
				end
			endcase
		end
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	endcase
end	

endmodule