`timescale 1ms / 100us

module tb_cpu ();

    // Testbench parameters
    localparam CLK_PERIOD = 10; // 100 Hz clk
    
    logic tb_checking_outputs; 
    integer tb_test_num;
    string tb_test_case;

    // DUT ports
   
    //inputs
    logic [31:0] tb_instruction_signal, tb_store;
    logic tb_clk, tb_reset, tb_pc_enable;

    //outputs
    //logic [1:0] tb_datawidth;
    //logic [1:0] tb_jump;
    //logic [2:0] tb_branch;
    //logic tb_memread;
    //logic tb_memntoreg;
    //logic [3:0] tb_aluop; // {bit[31],bit[30], bit[14:12]}
    //logic tb_memwrite;
    //logic tb_alusrc;
    //logic tb_regwrite;

    logic[15:0] tb_combined_output;
    logic tb_auipc;
    logic [31:0] tb_alu_result, tb_write_data, tb_write_to_mem, tb_load, tb_pc, tb_next_pc;

    //Clock Generation
    always begin
        tb_clk = 0;
        #(CLK_PERIOD / 2);
        tb_clk = 1;
        #(CLK_PERIOD / 2);
    end

    //instruction tasks
    task addi_test;
        tb_instruction_signal = 32'h00100093; // addi x1 , x0,  1
    endtask

    task addi_or_test;
        tb_instruction_signal = 32'h00100113; // addi x2, x0, 1
    endtask

    task or_test;
        tb_instruction_signal = 32'h0020e1b3; // or x3, x1, x2
    endtask
    
    task lui_test;
        tb_instruction_signal = 32'hfffff237; // lui x4, 0xfffff
    endtask

    task slt_test;
        tb_instruction_signal = 32'h0020a2b3; // slt x5, x1, x2
    endtask

    task beq_test;
        tb_instruction_signal = 32'h00209463; // beq x1,x2, loop
    endtask

    task jal_test;
        tb_instruction_signal = 32'h008000EF; // jal x1, 8
    endtask

    task jump_skip;
        tb_instruction_signal = 32'h00108313; // addi x6, x1, 1
    endtask

    task jalr_test;
        tb_instruction_signal = 32'h008000E7; // jalr x1, 8(x0)
    endtask

    task lw_test;
        tb_pc_enable = 1'b0;
        tb_store = 32'd1;
        tb_instruction_signal = 32'h0000a483;
        #CLK_PERIOD;
        tb_pc_enable = 1'b1;
    endtask

    task sb_test;
        tb_pc_enable = 1'b0;
        tb_instruction_signal = 32'h00938023;
        #CLK_PERIOD;
        tb_pc_enable = 1'b1;
    endtask

    task reset_test;
        tb_reset = 0;
        #CLK_PERIOD;
        @(negedge tb_clk);
        tb_reset = 1;
        @(posedge tb_clk);
    endtask



    // Task to check control unit output output
    // task checkOutput;
    // input logic [15:0] expected_output; 
    // input string string_ouptut_name; 
    // begin
    //     tb_checking_outputs = 1'b1; 
    //     if(tb_combined_output == expected_output)
    //         $info("Correct output for: %s.", string_ouptut_name);
    //     else
    //         $error("Incorrect Output. Expected: %b, Actual: %b", expected_output, tb_combined_output);
    //     #(1);
    //     tb_checking_outputs = 1'b0;  
    // end
    // endtask

    // DUT Portmap
    cpu DUT(.instruction(tb_instruction_signal),
                .hz100(tb_clk),
                .reset(tb_reset),
                .combined_control(tb_combined_output),
                .alu_result(tb_alu_result),
                .write_data(tb_write_data),
                .store(tb_store),
                .load(tb_load),
                .write_to_mem(tb_write_to_mem),
                .pc(tb_pc),
                .next_pc(tb_next_pc),
                .pc_enable(tb_pc_enable),
                .auipc(tb_auipc)
                ); 

    // Main Test Bench Process
    initial begin
        // Signal dump
        $dumpfile("dump.vcd");
        $dumpvars; 

        // Initialize test bench signals

        tb_test_num = -1;
        tb_test_case = "Initializing";

        tb_instruction_signal = 32'h0;
        tb_clk = 0;
        tb_reset = 1;
        tb_pc_enable = 1'b1;
        tb_checking_outputs = 1'b0;
        tb_store = 32'b0;


        // Wait some time before starting first test case
        #(0.1);

        // ************************************************************************
        // Test Case 0: Reset
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 0: Reset";
        $display("\n\n%s", tb_test_case);

        reset_test();

        // Wait for a bit before checking for correct functionality
        
        #(CLK_PERIOD); 
        

        // checkOutput({2'b0,2'b0,3'b0,1'b0,1'b0,4'b0,1'b0,1'b0,1'b1},"Rtype");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}

        // ************************************************************************
        // Test Case 1: addi 
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 1: addi";
        $display("\n\n%s", tb_test_case);

        addi_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}
    
        // ************************************************************************
        // Test Case 2: or
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 2: or";
        $display("\n\n%s", tb_test_case);

        addi_or_test();

        #(CLK_PERIOD); 

        or_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}

        // ************************************************************************
        // Test Case 3: lui
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 3: lui";
        $display("\n\n%s", tb_test_case);

        lui_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}


        // ************************************************************************
        // Test Case 4: SLT
        // ************************************************************************
        tb_test_num += 1;   
        tb_test_case = "Test Case 4: slt";
        $display("\n\n%s", tb_test_case);

        slt_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}
            
        // ************************************************************************
        // Test Case 5: beq
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 5: beq";
        $display("\n\n%s", tb_test_case);

        beq_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}

        // ************************************************************************
        // Test Case 6: jal
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 2: jal";
        $display("\n\n%s", tb_test_case);

        jal_test();

        #CLK_PERIOD;

        jump_skip();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}
    
        // ************************************************************************
        // Test Case 7: jalr
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 7: jalr";
        $display("\n\n%s", tb_test_case);

        jalr_test();

        #CLK_PERIOD;

        jump_skip();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}

        // ************************************************************************
        // Test Case 8: lw
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 8: lw";
        $display("\n\n%s", tb_test_case);

        lw_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}

        // ************************************************************************
        // Test Case 9: sb
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 9: sb";
        $display("\n\n%s", tb_test_case);

        sb_test();

        // Wait for a bit before checking for correct functionality
        #(CLK_PERIOD); 

        // checkOutput({2'b0,2'b0,3'b0,1'b1,1'b1,4'b0,1'b0,1'b1,1'b1},"ItypeL");
   
        // {[1:0] tb_datawidth, [1:0] tb_jump, [2:0] tb_branch, tb_memread, tb_memntoreg, [3:0] tb_aluop, tb_memwrite, tb_alusrc, tb_regwrite;}
    
        $finish; 
    end

endmodule 