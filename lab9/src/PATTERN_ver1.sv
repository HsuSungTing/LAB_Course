// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+12*256)-1):(65536+0)];  


//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Login, Level_Up, Battle, Use_Skill, Check_Inactive};
    }
    function void set_seed(int seed);
        
        this.srandom(seed);
    endfunction
endclass

//================================================================
// initial
//================================================================
integer exe_lat,i_pat;
integer global_count;

initial begin 
	$readmemh (DRAM_p_r, golden_DRAM) ;
	reset_task ;
	global_count = 0 ;
    exe_lat=0 ;
	for (i_pat = 0 ; i_pat < 5 ; i_pat = i_pat + 1) begin 
		input_task ;
		wait_task ;
		// $display ("pass No.%d pattern", i_pat) ;
		global_count = global_count + 1 ;
	end
	$finish ;
end


task input_task ;  begin
    random_act act_r = new();
    Action act;
    int player_no;
    logic [3:0] mon;
    logic [4:0] day;
    int training_type;
    int mode;
    int mp_val[4];
    int monster_val[3];

    @(negedge clk);

    // === 1️⃣ 隨機決定行為 ===
    assert(act_r.randomize());
    act = act_r.act_id;

    // === 2️⃣ 共同隨機欄位 ===
    player_no = $urandom_range(0, 255);
    day       = $urandom_range(1, 31);
    mon       = $urandom_range(1, 12);
    training_type = $urandom_range(0, 3);
    mode          = $urandom_range(0, 2);

    for (int i=0; i<4; i++) mp_val[i] = $urandom_range(0, 65535);
    for (int i=0; i<3; i++) monster_val[i] = $urandom_range(0, 65535);

    // === 3️⃣ 初始化所有 valid 為 0 ===
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.mode_valid       = 0;
    inf.date_valid       = 0;
    inf.player_no_valid  = 0;
    inf.monster_valid    = 0;
    inf.MP_valid         = 0;
    inf.D                = 'dx;

    // === 4️⃣ 根據行為分支 ===
    case (act)

        // --------------------------------------------------------
        // 🧾  Logging
        // --------------------------------------------------------
        Login: begin
            // action_valid pulse
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = act;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // date_valid pulse
            @(negedge clk);
            inf.date_valid = 1;
            inf.D = {mon,day};
            @(negedge clk);
            inf.date_valid = 0;

            // player_no_valid pulse
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = player_no;
            @(negedge clk);
            inf.player_no_valid = 0;
        end

        // --------------------------------------------------------
        // ⬆️  Level Up
        // --------------------------------------------------------
        Level_Up: begin
            // action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = act;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // type_valid
            @(negedge clk);
            inf.type_valid = 1;
            inf.D = training_type;
            @(negedge clk);
            inf.type_valid = 0;

            // mode_valid
            @(negedge clk);
            inf.mode_valid = 1;
            inf.D = mode;
            @(negedge clk);
            inf.mode_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = player_no;
            @(negedge clk);
            inf.player_no_valid = 0;
        end

        // --------------------------------------------------------
        // ⚔️  Battle
        // --------------------------------------------------------
        Battle: begin
            // sel_action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = act;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = player_no;
            @(negedge clk);
            inf.player_no_valid = 0;

            // monster_valid (3 cycles)
            for (int i=0; i<3; i++) begin
                @(negedge clk);
                inf.monster_valid = 1;
                inf.D = monster_val[i];
                @(negedge clk);
                inf.monster_valid = 0;
            end
        end

        // --------------------------------------------------------
        // 🪄  Use Skill
        // --------------------------------------------------------
        Use_Skill: begin
            // sel_action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = act;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = player_no;
            @(negedge clk);
            inf.player_no_valid = 0;

            // MP_valid (4 cycles)
            for (int i=0; i<4; i++) begin
                @(negedge clk);
                inf.MP_valid = 1;
                inf.D = mp_val[i];
                @(negedge clk);
                inf.MP_valid = 0;
            end
        end

        // --------------------------------------------------------
        // 💤  Inactive
        // --------------------------------------------------------
        Check_Inactive: begin
            // sel_action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = act;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // date_valid
            @(negedge clk);
            inf.date_valid = 1;
            inf.D = date;
            @(negedge clk);
            inf.date_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = player_no;
            @(negedge clk);
            inf.player_no_valid = 0;
        end

    endcase

    // === 5️⃣ 清除所有信號 ===
    @(negedge clk);
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.mode_valid       = 0;
    inf.date_valid       = 0;
    inf.player_no_valid  = 0;
    inf.monster_valid    = 0;
    inf.MP_valid         = 0;
    inf.D                = 'dx;
end 
endtask 


task wait_task ; begin 
	exe_lat = -1 ;
	while (inf.out_valid !== 1) begin 
        exe_lat = exe_lat + 1;
        if(exe_lat>1000)begin
            $display("=====================");
            $display("mote than 1000 cycles");
            $display("=====================");
            $finish;
        end
        @(negedge clk);
	end
end endtask 

task reset_task ; begin 
	inf.rst_n            = 1;
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.mode_valid       = 0;
    inf.date_valid       = 0;
    inf.player_no_valid  = 0;
    inf.monster_valid    = 0;
    inf.MP_valid         = 0;
    inf.D                = 'dx;

    #(10) inf.rst_n = 0;
    #(10) inf.rst_n = 1;
end endtask
endprogram
