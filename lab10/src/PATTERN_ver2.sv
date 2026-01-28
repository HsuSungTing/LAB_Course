// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

// parameters & integer
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PAT_NUM = 10000 ;
// wire & registers 
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

class random_train_type;                    //random_train_type: class name
    randc int train_type;
    constraint train_type_constraint{train_type inside {[0:3]};}
endclass
random_train_type train_type_rand = new();  //void'(train_type_rand.randomize());

//Part 2-1: signals
integer exe_lat,i_pat;
integer global_cnt;     //to control random input

//Part 2-2 (input sig)
logic [2:0] act_queue [0:24];
Action in_sel_action;
int in_player_no;
logic [3:0] in_mon;
logic [4:0] in_day;
int in_training_type, in_mode;
logic [15:0] in_mp_val[0:3];
int in_monster_val[3];

//Part 2-3 Sig (for gold ans)
logic [15:0] gold_plyr_MP, gold_plyr_EXP, gold_plyr_def, gold_plyr_atk, gold_plyr_HP;
logic [7:0] gold_plyr_day, gold_plyr_mon;
logic gold_complete;
Warn_Msg gold_warn_msg;

//for EVAL_loggin & EVAL_inactive
logic gold_cts_date, gold_more_90DAYS;

//for EVAL_levelup
logic [15:0] tmp_val;
logic [1:0]  tmp_idx;
integer i, j;
logic [15:0] sorted_val[0:3];
logic [15:0] sorted_idx[0:3];
integer A2_minus_A0, A3_minus_A1;
logic [19:0] gold_attribute_sum;
logic [15:0] gold_delta_MP, gold_delta_HP, gold_delta_atk, gold_delta_def;

//for EVAL_battle
integer gold_dmg_to_mons, gold_dmg_to_plyr;
integer gold_mons_HP_temp, gold_plyr_HP_temp;

//for EVAL_skill
logic [15:0] gold_sorted_mp [0:3];
logic [19:0] sum_all, sum_3, sum_2, sum_1;

initial begin
    act_queue = '{3'd0,3'd0,3'd1,3'd0,3'd2,
                  3'd0,3'd3,3'd0,3'd4,3'd1,
                  3'd1,3'd2,3'd1,3'd3,3'd1,
                  3'd4,3'd2,3'd2,3'd3,3'd2,
                  3'd4,3'd3,3'd3,3'd4,3'd4};
end

initial begin 
	$readmemh (DRAM_p_r, golden_DRAM) ;
	reset_task ;
	global_cnt = 0 ;
    exe_lat=0 ;
	for (i_pat = 0 ; i_pat < PAT_NUM ; i_pat = i_pat + 1) begin 
		input_task ;
        cal_task ;
		wait_task;
        check_task;
		$display ("pass No.%d pattern, lat= %0d", i_pat, exe_lat) ;
		global_cnt = global_cnt + 1 ;
	end
    pass_task;
	$finish ;
end

task make_random_input; begin
    //in_sel_action
    if(act_queue[global_cnt%25]==0)     in_sel_action =Login;
    else if(act_queue[global_cnt%25]==1)in_sel_action =Level_Up;
    else if(act_queue[global_cnt%25]==2)in_sel_action =Battle;
    else if(act_queue[global_cnt%25]==3)in_sel_action =Use_Skill;
    else if(act_queue[global_cnt%25]==4)in_sel_action =Check_Inactive;

    //in_train_type
    void'(train_type_rand.randomize());
    in_training_type=train_type_rand.train_type;
end
endtask

task input_task ;  begin
    random_act act_r = new();
    @(negedge clk);

    // === step 1 隨機決定行為 ===
    //assert(act_r.randomize());
    //in_sel_action = act_r.act_id;
    make_random_input;
    
    // === step 2 隨機產生input ===
    in_player_no = $urandom_range(0, 255);
    in_day       = $urandom_range(1, 28);
    in_mon       = $urandom_range(1, 12);
    //in_training_type = $urandom_range(0, 3);
    in_mode          = $urandom_range(0, 2);

    for (int i=0; i<4; i++) in_mp_val[i] = $urandom_range(0, 65535);
    for (int i=0; i<3; i++) in_monster_val[i] = $urandom_range(44535, 65535);

    // === step 3 初始化所有 valid 為 0 ===
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.mode_valid       = 0;
    inf.date_valid       = 0;
    inf.player_no_valid  = 0;
    inf.monster_valid    = 0;
    inf.MP_valid         = 0;
    inf.D                = 'dx;

    // === step 4 根據行為分支 ===
    case (in_sel_action)
        // 🧾  Logging
        Login: begin
            // action_valid pulse
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = in_sel_action;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // date_valid pulse
            @(negedge clk);
            inf.date_valid = 1;
            inf.D = {in_mon,in_day};
            @(negedge clk);
            inf.date_valid = 0;

            // player_no_valid pulse
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = in_player_no;
            @(negedge clk);
            inf.player_no_valid = 0;
        end

        // ⬆️  Level Up
        Level_Up: begin
            // action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = in_sel_action;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // type_valid
            @(negedge clk);
            inf.type_valid = 1;
            inf.D = in_training_type;
            @(negedge clk);
            inf.type_valid = 0;

            // mode_valid
            @(negedge clk);
            inf.mode_valid = 1;
            inf.D = in_mode;
            @(negedge clk);
            inf.mode_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = in_player_no;
            @(negedge clk);
            inf.player_no_valid = 0;
        end

        // ⚔️  Battle
        Battle: begin
            // sel_action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = in_sel_action;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = in_player_no;
            @(negedge clk);
            inf.player_no_valid = 0;

            // monster_valid (3 cycles)
            for (int i=0; i<3; i++) begin
                @(negedge clk);
                inf.monster_valid = 1;
                inf.D = in_monster_val[i];
                @(negedge clk);
                inf.monster_valid = 0;
            end
        end

        // 🪄  Use Skill
        Use_Skill: begin
            // sel_action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = in_sel_action;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = in_player_no;
            @(negedge clk);
            inf.player_no_valid = 0;

            // MP_valid (4 cycles)
            for (int i=0; i<4; i++) begin
                @(negedge clk);
                inf.MP_valid = 1;
                inf.D = in_mp_val[i];
                @(negedge clk);
                inf.MP_valid = 0;
            end
        end

        // 💤  Inactive
        Check_Inactive: begin
            // sel_action_valid
            @(negedge clk);
            inf.sel_action_valid = 1;
            inf.D = in_sel_action;
            @(negedge clk);
            inf.sel_action_valid = 0;

            // date_valid
            @(negedge clk);
            inf.date_valid = 1;
            inf.D = {in_mon,in_day};
            @(negedge clk);
            inf.date_valid = 0;

            // player_no_valid
            @(negedge clk);
            inf.player_no_valid = 1;
            inf.D = in_player_no;
            @(negedge clk);
            inf.player_no_valid = 0;
        end
    endcase

    // === step 5 清除所有信號 ===
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

task cal_task; begin
    //讀DRAM (INPUT_and_dram_read)
    gold_plyr_MP [15:0]= {golden_DRAM[65536+(in_player_no*12)+1],golden_DRAM[65536+(in_player_no*12)]};
	gold_plyr_EXP[15:0]= {golden_DRAM[65536+(in_player_no*12)+3],golden_DRAM[65536+(in_player_no*12)+2]};
	gold_plyr_def[15:0]= {golden_DRAM[65536+(in_player_no*12)+5],golden_DRAM[65536+(in_player_no*12)+4]};
	gold_plyr_atk[15:0]= {golden_DRAM[65536+(in_player_no*12)+7],golden_DRAM[65536+(in_player_no*12)+6]};
	gold_plyr_day [7:0]= golden_DRAM[65536+(in_player_no*12)+8];
	gold_plyr_mon [7:0]= golden_DRAM[65536+(in_player_no*12)+9];
	gold_plyr_HP [15:0]= {golden_DRAM[65536+(in_player_no*12)+11],golden_DRAM[65536+(in_player_no*12)+10]};
    gold_complete=1;        //預設
    gold_warn_msg=No_Warn;  //預設
    //===for debug===
    $display("GOLDEN PLAYER DATA: pat= %0d, sel_action= %0d",i_pat,in_sel_action);
    $display("Player No      = %0d", in_player_no);
    $display("HP   (gold)    = %0d", gold_plyr_HP);
    $display("MP   (gold)    = %0d", gold_plyr_MP);
    $display("ATK  (gold)    = %0d", gold_plyr_atk);
    $display("DEF  (gold)    = %0d", gold_plyr_def);
    $display("EXP  (gold)    = %0d", gold_plyr_EXP);
    $display("MON  (gold)    = %0d", gold_plyr_mon);
    $display("DAY  (gold)    = %0d", gold_plyr_day);
    $display("=================================================================");
    //===============
    case(in_sel_action)
        Login: begin
            gold_cts_date=0; gold_more_90DAYS=0;
            // step 0-1 判定是否連續登入 / 是否超過 90 天
            check_cts_date_or_more_90DAYS(
                gold_plyr_mon[3:0],gold_plyr_day[4:0],
                in_mon,in_day,gold_cts_date,gold_more_90DAYS
            );
            // step 0-2 EXP / MP overflow 保護
            // 若連續登入，EXP+512，MP+1024
            if (gold_cts_date) begin
                if(gold_plyr_EXP + 512>65535)begin 
                    gold_plyr_EXP = 65535;
                    gold_warn_msg=Saturation_Warn; gold_complete=0;
                end
                else gold_plyr_EXP = gold_plyr_EXP + 16'd512;
                if(gold_plyr_MP  + 1024 > 65535)begin
                    gold_plyr_MP  = 65535;
                    gold_warn_msg=Saturation_Warn; gold_complete=0;
                end
                else gold_plyr_MP  = gold_plyr_MP  + 16'd1024;
            end
            // 回寫到 DRAM
            golden_DRAM[65536+(in_player_no*12)+2] = gold_plyr_EXP[7:0];
            golden_DRAM[65536+(in_player_no*12)+3] = gold_plyr_EXP[15:8];
            golden_DRAM[65536+(in_player_no*12)+0] = gold_plyr_MP[7:0];
            golden_DRAM[65536+(in_player_no*12)+1] = gold_plyr_MP[15:8];
            // step 1 更新日期
            gold_plyr_mon = in_mon;   gold_plyr_day = in_day;
            golden_DRAM[65536+(in_player_no*12)+8] = gold_plyr_day;
            golden_DRAM[65536+(in_player_no*12)+9] = gold_plyr_mon;
        end	      
        Level_Up: begin
            //step 0 check EXP
            if(gold_plyr_EXP<4095&&in_mode==2'b00)begin
                gold_warn_msg=Exp_Warn; gold_complete=0;
            end
            else if(gold_plyr_EXP<16383&&in_mode==2'b01)begin
                gold_warn_msg=Exp_Warn; gold_complete=0;
            end
            else if(gold_plyr_EXP<32767&&in_mode==2'b10)begin
                gold_warn_msg=Exp_Warn; gold_complete=0;
            end
            else begin
                //step 1 find_delta
                find_delta;
                //===for debug===
                $display("gold_delta_MP    = %0d", gold_delta_MP);
                $display("gold_delta_HP    = %0d", gold_delta_HP);
                $display("gold_delta_atk   = %0d", gold_delta_atk);
                $display("gold_delta_def   = %0d", gold_delta_def);
                //===============
                //step 2 更新attri
                if(in_mode==2'b00) begin
                    // MP
                    if((gold_plyr_MP + gold_delta_MP - (gold_delta_MP>>2)) > 65535) begin
                        gold_plyr_MP = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_MP = gold_plyr_MP + gold_delta_MP - (gold_delta_MP>>2);
                    // HP
                    if((gold_plyr_HP + gold_delta_HP - (gold_delta_HP>>2)) > 65535) begin
                        gold_plyr_HP = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_HP = gold_plyr_HP + gold_delta_HP - (gold_delta_HP>>2);
                    // ATK
                    if((gold_plyr_atk + gold_delta_atk - (gold_delta_atk>>2)) > 65535) begin
                        gold_plyr_atk = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_atk = gold_plyr_atk + gold_delta_atk - (gold_delta_atk>>2);
                    // DEF
                    if((gold_plyr_def + gold_delta_def - (gold_delta_def>>2)) > 65535) begin
                        gold_plyr_def = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_def = gold_plyr_def + gold_delta_def - (gold_delta_def>>2);
                end
                else if(in_mode==2'b01) begin
                    // MP
                    if((gold_plyr_MP + gold_delta_MP) > 65535) begin
                        gold_plyr_MP = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_MP = gold_plyr_MP + gold_delta_MP;
                    // HP
                    if((gold_plyr_HP + gold_delta_HP) > 65535) begin
                        gold_plyr_HP = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_HP = gold_plyr_HP + gold_delta_HP;
                    // ATK
                    if((gold_plyr_atk + gold_delta_atk) > 65535) begin
                        gold_plyr_atk = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_atk = gold_plyr_atk + gold_delta_atk;
                    // DEF
                    if((gold_plyr_def + gold_delta_def) > 65535) begin
                        gold_plyr_def = 65535; gold_warn_msg = Saturation_Warn; gold_complete = 0;
                    end
                    else gold_plyr_def = gold_plyr_def + gold_delta_def;
                end
                else if(in_mode==2'b10)begin
                    if((gold_plyr_MP+gold_delta_MP+(gold_delta_MP>>2)) >65535)begin 
                        gold_plyr_MP=65535; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end
                    else gold_plyr_MP=gold_plyr_MP+gold_delta_MP+(gold_delta_MP>>2);
                    if((gold_plyr_HP+gold_delta_HP+(gold_delta_HP>>2)) >65535)begin 
                        gold_plyr_HP=65535; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end
                    else gold_plyr_HP=gold_plyr_HP+gold_delta_HP+(gold_delta_HP>>2);
                    if((gold_plyr_atk+gold_delta_atk+(gold_delta_atk>>2)) >65535)begin 
                        gold_plyr_atk=65535; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end
                    else gold_plyr_atk=gold_plyr_atk+gold_delta_atk+(gold_delta_atk>>2);
                    if((gold_plyr_def+gold_delta_def+(gold_delta_def>>2)) >65535)begin 
                        gold_plyr_def=65535; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end
                    else gold_plyr_def=gold_plyr_def+gold_delta_def+(gold_delta_def>>2);
                end
                //step 3 check sta warn
                // 回寫到 DRAM
                golden_DRAM[65536+(in_player_no*12)+0] = gold_plyr_MP[7:0];
                golden_DRAM[65536+(in_player_no*12)+1] = gold_plyr_MP[15:8];
                golden_DRAM[65536+(in_player_no*12)+10]= gold_plyr_HP[7:0];
                golden_DRAM[65536+(in_player_no*12)+11]= gold_plyr_HP[15:8];
                golden_DRAM[65536+(in_player_no*12)+6] = gold_plyr_atk[7:0];
                golden_DRAM[65536+(in_player_no*12)+7] = gold_plyr_atk[15:8];
                golden_DRAM[65536+(in_player_no*12)+4] = gold_plyr_def[7:0];
                golden_DRAM[65536+(in_player_no*12)+5] = gold_plyr_def[15:8];
            end
        end	      	  
        Battle: begin
            //in_monster_val[0] mons atk
            //in_monster_val[1] mons def
            //in_monster_val[2] mons HP
            if(gold_plyr_HP==0) begin
                gold_warn_msg=HP_Warn; gold_complete=0;
            end
            else begin
                //step 0
                if(in_monster_val[0]>gold_plyr_def)gold_dmg_to_plyr= in_monster_val[0] - gold_plyr_def;
                else gold_dmg_to_plyr=0;
                if(gold_plyr_atk>in_monster_val[1])gold_dmg_to_mons= gold_plyr_atk - in_monster_val[1];
                else gold_dmg_to_mons=0;
                
                //step 1
                if(gold_dmg_to_plyr>0) begin
                    if(gold_dmg_to_plyr>gold_plyr_HP) gold_plyr_HP_temp=0;
                    else gold_plyr_HP_temp = gold_plyr_HP - gold_dmg_to_plyr;
                end
                else gold_plyr_HP_temp=gold_plyr_HP;

                if(gold_dmg_to_mons>0) begin
                    if(gold_dmg_to_mons>in_monster_val[2]) gold_mons_HP_temp=0;
                    else gold_mons_HP_temp = in_monster_val[2] - gold_dmg_to_mons;
                end
                else gold_mons_HP_temp =in_monster_val[2];
                //===for debug===
                $display("gold_dmg_to_plyr    = %0d",gold_dmg_to_plyr);
                $display("gold_dmg_to_mons    = %0d",gold_dmg_to_mons);
                $display("gold_plyr_HP_temp   = %0d",gold_plyr_HP_temp);
                $display("gold_mons_HP_temp   = %0d",gold_mons_HP_temp);
                //===============
                //step 2
                //win
                if(gold_plyr_HP_temp>0 && gold_mons_HP_temp<=0) begin
                    gold_plyr_EXP = gold_plyr_EXP + 2048;
                    gold_plyr_MP  = gold_plyr_MP  + 2048;
                    gold_plyr_HP  = gold_plyr_HP_temp;
                    if(gold_plyr_EXP>65535) begin
                        gold_plyr_EXP=65535;
                        gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end
                    if(gold_plyr_MP>65535) begin
                        gold_plyr_MP=65535;
                        gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end
                end
                //lose
                else if(gold_plyr_HP_temp<=0) begin
                    if(gold_plyr_EXP < 2048) begin
                        gold_plyr_EXP=0; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end 
                    else gold_plyr_EXP = gold_plyr_EXP - 2048;

                    if(gold_plyr_atk < 2048) begin
                        gold_plyr_atk=0; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end 
                    else gold_plyr_atk = gold_plyr_atk - 2048;

                    if(gold_plyr_def < 2048) begin
                        gold_plyr_def=0; gold_warn_msg=Saturation_Warn; gold_complete=0;
                    end 
                    else gold_plyr_def = gold_plyr_def - 2048;

                    gold_plyr_HP = 0;
                end
                //tie
                else begin
                    gold_plyr_HP = gold_plyr_HP_temp;
                end
                // --- 更新 DRAM ---
                golden_DRAM[65536+(in_player_no*12)+0] = gold_plyr_MP[7:0];
                golden_DRAM[65536+(in_player_no*12)+1] = gold_plyr_MP[15:8];
                golden_DRAM[65536+(in_player_no*12)+2] = gold_plyr_EXP[7:0];
                golden_DRAM[65536+(in_player_no*12)+3] = gold_plyr_EXP[15:8];
                golden_DRAM[65536+(in_player_no*12)+4] = gold_plyr_def[7:0];
                golden_DRAM[65536+(in_player_no*12)+5] = gold_plyr_def[15:8];
                golden_DRAM[65536+(in_player_no*12)+6] = gold_plyr_atk[7:0];
                golden_DRAM[65536+(in_player_no*12)+7] = gold_plyr_atk[15:8];
                golden_DRAM[65536+(in_player_no*12)+10] = gold_plyr_HP[7:0];
                golden_DRAM[65536+(in_player_no*12)+11] = gold_plyr_HP[15:8];
            end
        end
        Use_Skill: begin
            // step 0: 對 in_mp_val[0:3] 排序，由小到大
            sort_mp_val( 
                .in0(in_mp_val[0]), .in1(in_mp_val[1]),
                .in2(in_mp_val[2]), .in3(in_mp_val[3]),
                .out0(gold_sorted_mp[0]), .out1(gold_sorted_mp[1]),
                .out2(gold_sorted_mp[2]), .out3(gold_sorted_mp[3])
            );
            //===for debug===
            $display("[Use_Skill] Sorted MP = %0d, %0d, %0d, %0d",
                    gold_sorted_mp[0], gold_sorted_mp[1], gold_sorted_mp[2], gold_sorted_mp[3]);
            //===============
            // step 1: 安全累加，使用 int 避免 16-bit overflow
            sum_all = gold_sorted_mp[0] + gold_sorted_mp[1] + gold_sorted_mp[2] + gold_sorted_mp[3];
            sum_3   = gold_sorted_mp[0] + gold_sorted_mp[1] + gold_sorted_mp[2];
            sum_2   = gold_sorted_mp[0] + gold_sorted_mp[1];
            sum_1   = gold_sorted_mp[0];

            //===for debug===
            $display("[Use_Skill] Sum_all = %0d, Sum_3 = %0d, Sum_2 = %0d, Sum_1 = %0d",
                    sum_all, sum_3, sum_2, sum_1);
            // ==============
            // step 2: 根據 HP 扣除 MP
            if (sum_all <= gold_plyr_MP) begin
                gold_plyr_MP = gold_plyr_MP - sum_all;
                $display("here 1");
            end
            else if (sum_3 <= gold_plyr_MP) begin
                gold_plyr_MP = gold_plyr_MP - sum_3;
                $display("here 2");
            end
            else if (sum_2 <= gold_plyr_MP) begin
                gold_plyr_MP = gold_plyr_MP - sum_2;
                $display("here 3");
            end
            else if (sum_1 <= gold_plyr_MP) begin
                gold_plyr_MP = gold_plyr_MP - sum_1;
                $display("here 4");
            end
            else begin
                gold_warn_msg = MP_Warn; gold_complete = 0;
            end
            // --- 更新 DRAM ---
            golden_DRAM[65536+(in_player_no*12)+0] = gold_plyr_MP[7:0];
            golden_DRAM[65536+(in_player_no*12)+1] = gold_plyr_MP[15:8];
        end
        Check_Inactive: begin
            gold_cts_date=0; gold_more_90DAYS=0;
            // step 0-1 判定是否超過90天沒登入
            check_cts_date_or_more_90DAYS(
                gold_plyr_mon,gold_plyr_day,
                in_mon,in_day,gold_cts_date,gold_more_90DAYS
            );
            //step 0-2 如果有的話就拉起warn
            if(gold_more_90DAYS==1)begin
                gold_warn_msg=Date_Warn; gold_complete=0;
            end
            else begin
                gold_warn_msg=No_Warn; gold_complete=1;
            end
        end	      
    endcase
    //===for bebug===
    $display("GOLDEN PLAYER DATA: pat= %0d, sel_action= %0d",i_pat,in_sel_action);
    $display("Player No      = %0d", in_player_no);
    $display("HP   (gold)    = %0d", gold_plyr_HP);
    $display("MP   (gold)    = %0d", gold_plyr_MP);
    $display("ATK  (gold)    = %0d", gold_plyr_atk);
    $display("DEF  (gold)    = %0d", gold_plyr_def);
    $display("EXP  (gold)    = %0d", gold_plyr_EXP);
    $display("MON  (gold)    = %0d", gold_plyr_mon);
    $display("DAY  (gold)    = %0d", gold_plyr_day);
    $display("gold_complete  = %0d", gold_complete);
    $display("gold_warn_msg  = %0d", gold_warn_msg);
    $display("=================================================================");
    //===============
end
endtask

task find_delta;
begin
    stable_sort_stats_with_index(
        .stat0(gold_plyr_MP), .stat1(gold_plyr_HP), 
        .stat2(gold_plyr_atk),.stat3(gold_plyr_def), 
        .sorted_val0(sorted_val[0]),.sorted_val1(sorted_val[1]),
        .sorted_val2(sorted_val[2]),.sorted_val3(sorted_val[3]),
        .sorted_idx0(sorted_idx[0]),.sorted_idx1(sorted_idx[1]),
        .sorted_idx2(sorted_idx[2]),.sorted_idx3(sorted_idx[3])
    );
    A2_minus_A0=sorted_val[2]-sorted_val[0];
    A3_minus_A1=sorted_val[3]-sorted_val[1];
    gold_attribute_sum=(gold_plyr_MP+gold_plyr_HP+gold_plyr_atk+gold_plyr_def);
    if(in_training_type==0)begin
        //A
        gold_delta_MP= gold_attribute_sum>>3;
        gold_delta_HP= gold_attribute_sum>>3;
        gold_delta_atk=gold_attribute_sum>>3;
        gold_delta_def=gold_attribute_sum>>3;
    end
    else if(in_training_type==1)begin
        gold_delta_MP=0;    gold_delta_HP=0;
        gold_delta_atk=0;   gold_delta_def=0;
        //B
        if(sorted_idx[0]==0)gold_delta_MP=A2_minus_A0;
        else if(sorted_idx[0]==1)gold_delta_HP=A2_minus_A0;
        else if(sorted_idx[0]==2)gold_delta_atk=A2_minus_A0;
        else if(sorted_idx[0]==3)gold_delta_def=A2_minus_A0;

        if(sorted_idx[1]==0)gold_delta_MP=A3_minus_A1;
        else if(sorted_idx[1]==1)gold_delta_HP=A3_minus_A1;
        else if(sorted_idx[1]==2)gold_delta_atk=A3_minus_A1;
        else if(sorted_idx[1]==3)gold_delta_def=A3_minus_A1;
    end
    else if(in_training_type==2)begin
        gold_delta_MP=0;    gold_delta_HP=0;
        gold_delta_atk=0;   gold_delta_def=0;
        if(gold_plyr_MP<16383) gold_delta_MP=16383-gold_plyr_MP;
        if(gold_plyr_HP<16383) gold_delta_HP=16383-gold_plyr_HP;
        if(gold_plyr_atk<16383) gold_delta_atk=16383-gold_plyr_atk;
        if(gold_plyr_def<16383) gold_delta_def=16383-gold_plyr_def;
    end
    else if(in_training_type==3)begin
        if((3000+((65535-gold_plyr_MP)>>4))<5047) gold_delta_MP=(3000+((65535-gold_plyr_MP)>>4));
        else gold_delta_MP=5047;
        if((3000+((65535-gold_plyr_HP)>>4))<5047) gold_delta_HP=(3000+((65535-gold_plyr_HP)>>4));
        else gold_delta_HP=5047;
        if((3000+((65535-gold_plyr_atk)>>4))<5047) gold_delta_atk=(3000+((65535-gold_plyr_atk)>>4));
        else gold_delta_atk=5047;
        if((3000+((65535-gold_plyr_def)>>4))<5047) gold_delta_def=(3000+((65535-gold_plyr_def)>>4));
        else gold_delta_def=5047;
    end
end
endtask

task check_cts_date_or_more_90DAYS(
    input  [3:0] gold_plyr_mon,
    input  [4:0] gold_plyr_day,
    input  [3:0] in_mon,
    input  [4:0] in_day,
    output        cts_date,
    output        more_90DAYS
);
    integer cur_mon_extend;
    integer cur_month_to_day;
    integer prev_month_to_day;
begin
    //====== 日期是否跨年 ======
    if ({gold_plyr_mon, gold_plyr_day}>{in_mon, in_day}) cur_mon_extend= in_mon + 12;
    else cur_mon_extend= in_mon;

    case (gold_plyr_mon)
        1:  prev_month_to_day =   0;
        2:  prev_month_to_day =  31;
        3:  prev_month_to_day =  59;
        4:  prev_month_to_day =  90;
        5:  prev_month_to_day = 120;
        6:  prev_month_to_day = 151;
        7:  prev_month_to_day = 181;
        8:  prev_month_to_day = 212;
        9:  prev_month_to_day = 243;
        10: prev_month_to_day = 273;
        11: prev_month_to_day = 304;
        12: prev_month_to_day = 334;

        13: prev_month_to_day = 365;
        14: prev_month_to_day = 396;
        15: prev_month_to_day = 424;
        16: prev_month_to_day = 455;
        17: prev_month_to_day = 485;
        18: prev_month_to_day = 516;
        19: prev_month_to_day = 546;
        20: prev_month_to_day = 577;
        21: prev_month_to_day = 608;
        22: prev_month_to_day = 638;
        23: prev_month_to_day = 669;
        24: prev_month_to_day = 699;
    endcase
    //====== 計算 previous player ======
    case (cur_mon_extend)
        1:  cur_month_to_day =   0;
        2:  cur_month_to_day =  31;
        3:  cur_month_to_day =  59;
        4:  cur_month_to_day =  90;
        5:  cur_month_to_day = 120;
        6:  cur_month_to_day = 151;
        7:  cur_month_to_day = 181;
        8:  cur_month_to_day = 212;
        9:  cur_month_to_day = 243;
        10: cur_month_to_day = 273;
        11: cur_month_to_day = 304;
        12: cur_month_to_day = 334;

        13: cur_month_to_day = 365;
        14: cur_month_to_day = 396;
        15: cur_month_to_day = 424;
        16: cur_month_to_day = 455;
        17: cur_month_to_day = 485;
        18: cur_month_to_day = 516;
        19: cur_month_to_day = 546;
        20: cur_month_to_day = 577;
        21: cur_month_to_day = 608;
        22: cur_month_to_day = 638;
        23: cur_month_to_day = 669;
        24: cur_month_to_day = 699;
    endcase
    //====== 加上當月日期 ======
    cur_month_to_day  = cur_month_to_day  + in_day;
    prev_month_to_day = prev_month_to_day + gold_plyr_day;
    //====== 輸出 ======
    more_90DAYS = (cur_month_to_day - prev_month_to_day > 90);
    cts_date    = (cur_month_to_day == prev_month_to_day + 1);
    //===for debug===
    $display("gold_plyr_mon: %0d",gold_plyr_mon);
    $display("gold_plyr_day: %0d",gold_plyr_day);
    $display("in_mon: %0d",in_mon);
    $display("in_day: %0d",in_day);
    $display("cur_month_to_day: %0d",cur_month_to_day);
    $display("prev_month_to_day: %0d",prev_month_to_day);
    $display("more_90DAYS: %0d",more_90DAYS);
    $display("cts_date: %0d",cts_date);
    //===============
end
endtask

task sort_mp_val(
    input  logic [15:0] in0,
    input  logic [15:0] in1,
    input  logic [15:0] in2,
    input  logic [15:0] in3,
    output logic [15:0] out0,
    output logic [15:0] out1,
    output logic [15:0] out2,
    output logic [15:0] out3
);
    integer i, j;
    logic [15:0] arr[0:3];
    logic [15:0] temp;

    begin
        arr[0] = in0;
        arr[1] = in1;
        arr[2] = in2;
        arr[3] = in3;
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 3 - i; j = j + 1) begin
                if (arr[j] > arr[j+1]) begin
                    temp     = arr[j];
                    arr[j]   = arr[j+1];
                    arr[j+1] = temp;
                end
            end
        end
        out0 = arr[0];
        out1 = arr[1];
        out2 = arr[2];
        out3 = arr[3];
    end
endtask

// Stable sort task (不改動原始變數)
task stable_sort_stats_with_index(
    input  logic [15:0] stat0, // MP
    input  logic [15:0] stat1, // HP
    input  logic [15:0] stat2, // ATK
    input  logic [15:0] stat3, // DEF
    output logic [15:0] sorted_val0,
    output logic [15:0] sorted_val1,
    output logic [15:0] sorted_val2,
    output logic [15:0] sorted_val3,
    output logic [1:0]  sorted_idx0,
    output logic [1:0]  sorted_idx1,
    output logic [1:0]  sorted_idx2,
    output logic [1:0]  sorted_idx3
);
    // 先複製輸入到輸出變數
    sorted_val0 = stat0; sorted_idx0 = 2'd0;
    sorted_val1 = stat1; sorted_idx1 = 2'd1;
    sorted_val2 = stat2; sorted_idx2 = 2'd2;
    sorted_val3 = stat3; sorted_idx3 = 2'd3;
    // Bubble sort（stable）直接操作輸出變數
    for(i=0; i<3; i=i+1) begin
        for(j=0; j<3-i; j=j+1) begin
            case(j)
                0: if(sorted_val0 > sorted_val1) begin
                        tmp_val = sorted_val0; sorted_val0 = sorted_val1; sorted_val1 = tmp_val;
                        tmp_idx = sorted_idx0; sorted_idx0 = sorted_idx1; sorted_idx1 = tmp_idx;
                   end
                1: if(sorted_val1 > sorted_val2) begin
                        tmp_val = sorted_val1; sorted_val1 = sorted_val2; sorted_val2 = tmp_val;
                        tmp_idx = sorted_idx1; sorted_idx1 = sorted_idx2; sorted_idx2 = tmp_idx;
                   end
                2: if(sorted_val2 > sorted_val3) begin
                        tmp_val = sorted_val2; sorted_val2 = sorted_val3; sorted_val3 = tmp_val;
                        tmp_idx = sorted_idx2; sorted_idx2 = sorted_idx3; sorted_idx3 = tmp_idx;
                   end
            endcase
        end
    end
endtask

task check_task; begin 
	if (inf.warn_msg !== gold_warn_msg || inf.complete !== gold_complete) begin 
        $display("==========================================================================") ;
		$display("                            Wrong Answer                                  ") ;
        $display("==========================================================================") ;
		$finish ;
	end
end endtask 

task pass_task ; begin 
    $display("==========================================================================") ;
	$display("                            Congratulations                               ") ;
    $display("==========================================================================") ;
end endtask 

task wait_task ; begin 
	exe_lat = -1 ;
	while (inf.out_valid !== 1) begin 
        exe_lat = exe_lat + 1;
        if(exe_lat>1000)begin
            $display("==============================");
            $display("latency mote than 1000 cycles");
            $display("==============================");
            //$finish;
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

    // #(50);
	// if((inf.out_valid !== 1'd0)||(inf.warn_msg !== No_Warn)||(inf.complete !== 0)) begin
	// 	$display("--------------------------------------------------");
	// 	$display("       	All outputs set to 0 when reset    		");
	// 	$display("--------------------------------------------------");
	// 	$finish;
	// end
end endtask

endprogram