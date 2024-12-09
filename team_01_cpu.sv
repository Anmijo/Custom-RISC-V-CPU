// Top testbenching Level

`default_nettype none

module cpu (
  input  logic[31:0] instruction,
  input logic hz100, reset, pc_enable,
  input logic [31:0]store,
  output logic [15:0]combined_control,
  output logic [31:0]alu_result, write_data, load, write_to_mem, pc, next_pc,
  output logic auipc
);

//program counter signals
logic [31:0]pc_add, pc_offset;

//Alu Signals
logic [31:0]imm; // alu_result;
logic negative, zero, overflow;

//Register Signals
logic [31:0]read_data1, read_data2;

//mux output signals
logic [31:0] mux_to_alu, mux_to_write, mux_to_mux;

//Sequential Signals
logic nRst, enable, clk;

//Control Signals
logic [1:0]data_width, jump;
logic [2:0]branch;
logic mem_read, mem_to_reg, mem_write, alu_src, reg_write;
logic [3:0] alu_op;

//Branch/Jump Signals
logic branch_enable;

logic [31:0] random;
logic [6:0] count;
logic [31:0]ssdec_data;

assign nRst = reset;
assign clk = hz100;

//counter c0(.clk(hz100), .nrst(nRst), .enable(1'b1), .clear(1'b0), .wrap(1'b1), .max(7'd99), .count(count), .at_max(clk));
program_counter p0(.next_pc(next_pc), .pc(pc), .clk(clk), .nRst(nRst));
control_unit c2(.opcode(instruction[6:0]), .funct3(instruction[14:12]), .bit_30(instruction[30]), .datawidth(data_width), 
                .jump(jump), .branch(branch), .memread(mem_read), .memntoreg(mem_to_reg), .memwrite(mem_write), .alusrc(alu_src), 
                .regwrite(reg_write), .aluop(alu_op), .auipc(auipc));
adder a3(.in1(pc), .in2(32'd4), .sum(pc_add));
mux m4(.in1(mux_to_write), .in2(pc_add), .select(|jump), .out(write_data));
register_file r5(.clk(clk), .nRst(nRst), .regWrite(reg_write), .readReg1(instruction[19:15]), .readReg2(instruction[24:20]),
                 .writeReg(instruction[11:7]), .writeData(write_data), .readData1(read_data1), .readData2(read_data2));
immediate_generator ig6(.instr(instruction), .imm(imm));
mux m7(.in1(read_data2), .in2(imm), .select(alu_src), .out(mux_to_alu));
alu al8(.aluOp(alu_op), .readData1(read_data1), .readData2(mux_to_alu), .zero(zero), .negative(negative), .overflow(overflow), .aluResult(alu_result));
data_memory dm9(.address(alu_result), .writedata(read_data2), .datawidth(data_width), .MemWrite(mem_write), .MemRead(mem_read),
                .data_i(store), .readdata(load), .address_DM(), .writedata_o(write_to_mem),
                .read_o(), .write_o());
mux m10(.in1(alu_result), .in2(store), .select(mem_to_reg), .out(mux_to_write));
branch_logic b11(.branch(branch), .negative(negative), .zero(zero), .branch_enable(branch_enable));
adder a12(.in1(pc), .in2(imm << 1), .sum(pc_offset));
mux m13(.in1(pc_add), .in2(pc_offset), .select(jump[0] | branch_enable), .out(mux_to_mux));
// mux m14(.in1(mux_to_mux), .in2(alu_result), .select(jump[1]), .out(next_pc));
always_comb begin
  if (pc_enable) begin
    next_pc = jump[1] ? alu_result : mux_to_mux;
  end else begin
    next_pc = pc;
  end
end

assign combined_control = {data_width, jump, branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src, reg_write};

endmodule
