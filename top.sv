// FPGA Top Level

`default_nettype none

module top (
  // I/O ports
  input  logic hwclk, hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

//Counter Signals
logic [31:0] pc;

//Alu Signals
logic [31:0] Immediate, AluResult;
logic Negative, Zero, Overflow;

//Register File Signals
logic [31:0] instruction, WriteData, ReadData1, ReadData2;

//MUX Output Signals
logic [31:0] MemToReg_Out, JB_address;

//Request Unit Signals
logic [31:0] FetchedInstr, InstrAddress, FetchedData, DataAddress, DataToWrite, cpu_dat_i, cpu_dat_o, adr_i, DataToReg;
logic DataRead, DataWrite, read_i, write_i, ru_busy_o, busy_o, dhit;
logic[3:0] sel_i;

//Control Signals
logic [3:0] AluOP;
logic [2:0] Branch;
logic [1:0] Jump, DataWidth;
logic MemRead, MemToReg, MemWrite, AluSRC, RegWrite, AUIPC, branch_enable;

//Sequential Signals
logic ihit, clk, nRST;

//Keypad/LCD Signals
logic keyvalid, assembly_en;
logic [127:0] shift_reg, unsorted;
logic [7:0] data_received;
logic [7:0]lcd_display_data;

//Assembly File Signals
logic asm_read_i, asm_write_i;
logic [31:0] asm_write_data, asm_data_adr;

//FSM Signals
logic fsm_read_i, fsm_write_i;
logic [31:0] fsm_write_data, fsm_data_adr;
logic [2:0] fsm_state;


assign nRST = ~pb[15];

logic register_en;
logic dm_enable;

logic shift;
logic [31:0] num_int;
assign red = strobe;

logic strobe;
// logic [31:0] ssdec_data;
logic [16:0] count;

logic [31:0] next_pc;
logic pc_enable;

// ALU : DONE
alu ALU0 (.AluOP(AluOP),
          .Data1(AUIPC ? pc : ReadData1),
          .Data2(AluSRC ? Immediate : ReadData2),
          .Zero(Zero),
          .Negative(Negative),
          .Overflow(Overflow),
          .AluResult(AluResult)
);

// BRANCH LOGIC : DONE 
branch_logic BL0 (.Branch(Branch),
                  .Negative(Negative),
                  .Zero(Zero),
                  .Enable(branch_enable)
);

// CONTROL UNIT : DONE
control_unit CU0 (.opcode(instruction[6:0]), 
                  .funct3(instruction[14:12]),
                  .bit30(instruction[30]),
                  .datawidth(DataWidth),
                  .jump(Jump),
                  .branch(Branch),
                  .memread(MemRead),
                  .mem_to_reg(MemToReg),
                  .mem_write(MemWrite),
                  .alusrc(AluSRC),
                  .regwrite(RegWrite),
                  .aluop(AluOP),
                  .auipc(AUIPC)
);

// COUNTER (for clock) : DONE
assign clk = hwclk;
counter c0(.clk(hwclk), 
           .nrst(nRST), 
           .enable(1'b1), 
           .clear(1'b0), 
           .wrap(1'b1), 
           .max(17'd99999), 
           .count(count), 
           .at_max(strobe));


// Data Memory
data_memory DM0 (.clk(clk),
                 .nRST(nRST),
                 .address(AluResult),
                 .writedata(ReadData2),
                 .datawidth(DataWidth),
                 .MemWrite(MemWrite),
                 .MemRead(MemRead),
                 .data_i(FetchedData),
                 .readdata(DataToReg),
                 .address_DM(asm_data_adr),
                 .writedata_o(asm_write_data),
                 .DataRead(asm_read_i),
                 .DataWrite(asm_write_i),
                 .dhit(dhit),
                 .ihit(ihit),
                 .enable(dm_enable)
);

// FSM : DONE 
fsm f0(.clk(clk),
       .nRST(nRST),
       .data(data_received),
       .keyvalid(keyvalid),
       .done(dhit),
       .read_data(FetchedData),
       .Instruction(FetchedInstr),
       .write_i(fsm_write_i),
       .read_i(fsm_read_i),
       .write_data(fsm_write_data),
       .data_adr(fsm_data_adr),
       .read_adr(32'h400),
       .write_adr(32'h200),
       .num_adr(32'h300),
       .MemWrite(MemWrite),
       .pc_enable(assembly_en),
       .display(lcd_display_data),
       .fsm_state(fsm_state),
       .lcd_en(shift)
);

// IMMEDIATE GENERATOR : DONE
immediate_generator IG0 (.Instr(instruction),
                         .Imm(Immediate)
);

// INSTRUCTION MEMORY
instruction_memory IM0 (.clk(clk),
                        .nRST(nRST),
                        .ihit(ihit),
                        .hold(MemRead && !dm_enable),
                        .pc_enable(pc_enable),
                        .pc(pc),
                        .FetchedInstr(FetchedInstr),
                        .address_IM(InstrAddress),
                        .instruction(instruction)
);

// KEYPAD : DONE
keypad K0 (.clk(clk),
           .nRST(nRST),
           .rows(pb[3:0]),
           .cols(left[7:4]),
           .data(data_received),
           .keyvalid(keyvalid),
           .enable(strobe)
);

// LCD : DONE
lcd1602 LCD0 (.clk(hwclk), 
              .rst(nRST), 
              .row_1(unsorted), 
              .row_2(shift_reg), 
              .lcd_en(left[2]), 
              .lcd_rw(left[1]), 
              .lcd_rs(left[0]), 
              .lcd_data(right[7:0])
); 

// MUXES 
mux M1 (.in1(MemToReg_Out), 
        .in2(pc + 32'd4), 
        .select(|Jump), 
        .out(WriteData)
);

mux M2 (.in1(AluResult), 
        .in2(DataToReg), 
        .select(MemToReg), 
        .out(MemToReg_Out)
);

// PROGRAM COUNTER : DONE
program_counter PC0 (.clk(clk),
                     .nRST(nRST),
                     .enable(pc_enable),
                     .new_pc(next_pc),
                     .pc(pc)
);

// RAM : DONE
ram R0 (.clk(clk), 
        .nRST(nRST),
        .read_i(read_i),
        .write_i(write_i),
        .adr_i(adr_i[11:0]),
        .cpu_dat_i(cpu_dat_i),
        .cpu_dat_o(cpu_dat_o),
        .busy_o(busy_o),
        .sel_i(sel_i)
);

// REGISTER FILE : DONE
register_file RF0 (.clk(clk), 
                   .nRST(nRST), 
                   .RegWrite(register_en), 
                   .ReadReg1(instruction[19:15]), 
                   .ReadReg2(instruction[24:20]),
                   .WriteReg(instruction[11:7]),
                   .WriteData(WriteData),
                   .ReadData1(ReadData1),
                   .ReadData2(ReadData2)
);

// REQUEST UNIT : DONE
request_unit RU0 (.clk(clk),
                  .nRST(nRST),
                  .InstrRead(assembly_en),
                  .DataRead(DataRead),
                  .DataWrite(DataWrite),
                  .DataAddress(DataAddress),
                  .InstrAddress(InstrAddress >> 2),
                  .DataToWrite(DataToWrite),
                  .ihit(ihit),
                  .dhit(dhit),
                  .FetchedInstr(FetchedInstr),
                  .FetchedData(FetchedData),
                  .busy_o(busy_o),
                  .cpu_dat_o(cpu_dat_o),
                  .write_i(write_i),
                  .read_i(read_i),
                  .adr_i(adr_i),
                  .cpu_dat_i(cpu_dat_i),
                  .sel_i(sel_i)
);

// SHIFT REGISTER 1 (for LCD row 1) : DONE
shift_reg SR0 (.clk(clk), 
               .nRST(nRST), 
               .char_in(DataToWrite[7:0]), 
               .shift_register(unsorted), 
               .enable(dhit && fsm_state == 3'b001)
);

// SHIFT REGISTER 2 (for LCD row 2) : DONE
shift_reg SR1 (.clk(clk), 
               .nRST(nRST), 
               .char_in(lcd_display_data[7:0]), 
               .shift_register(shift_reg), 
               .enable(shift)
);

// SSDEC : DONE
// assign ssdec_data = 32'b0;

// ssdec s16(.enable(1'b1), .in(ssdec_data[3:0]), .out(ss0[6:0]));
// ssdec s17(.enable(1'b1), .in(ssdec_data[7:4]), .out(ss1[6:0]));
// ssdec s18(.enable(1'b1), .in(ssdec_data[11:8]), .out(ss2[6:0]));
// ssdec s19(.enable(1'b1), .in(ssdec_data[15:12]), .out(ss3[6:0]));
// ssdec s20(.enable(1'b1), .in(ssdec_data[19:16]), .out(ss4[6:0]));
// ssdec s21(.enable(1'b1), .in(ssdec_data[23:20]), .out(ss5[6:0]));
// ssdec s22(.enable(1'b1), .in(ssdec_data[27:24]), .out(ss6[6:0]));
// ssdec s23(.enable(1'b1), .in(ssdec_data[31:28]), .out(ss7[6:0]));

// ASSEMBLY OR FSM
always_comb begin
    if (assembly_en) begin
        DataRead    = asm_read_i;
        DataWrite   = asm_write_i;
        DataAddress = asm_data_adr;
        DataToWrite = asm_write_data;
    end else begin
        DataRead    = fsm_read_i;
        DataWrite   = fsm_write_i;
        DataAddress = fsm_data_adr;
        DataToWrite = fsm_write_data;
    end
end

// REGISTER ENABLE LOGIC
always_comb begin
    if (RegWrite) begin
        if (MemRead) begin
            register_en = dm_enable;
        end else begin
            register_en = 1'b1;
        end
    end else begin
        register_en = 1'b0;
    end
end

// Next PC based on current instruction
always_comb begin
    if (Jump[1]) begin
        next_pc = AluResult;
    end else if (Jump[0] || branch_enable) begin
        next_pc = pc + $signed(Immediate);
    end else begin
        next_pc = pc + 32'd4;
    end
end

endmodule