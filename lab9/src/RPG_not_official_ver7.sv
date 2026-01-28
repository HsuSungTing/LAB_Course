module RPG(input clk, INF.RPG_inf inf);
import usertype::*;

//Part 1 FSM (& FSM tag)
typedef enum logic [3:0]{
    IDLE ,
	INPUT_and_dram_read ,
	EVAL_login ,
    EVAL_levelup ,
    EVAL_battle ,
    EVAL_skill ,
    EVAL_inactive ,
    EVAL_dram_write,
    OUTPUT_warn ,
	CLEAR
} state_t ;


state_t  cur_state, next_state ;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

//Part 1 FSM tag
logic [2:0] sel_action_q;
logic INPUT_done, dram_read_done, dram_write_done;
logic EVAL_login_done, EVAL_levelup_done, EVAL_battle_done;
logic EVAL_skill_done, EVAL_inactive_done;

logic [1:0] EVAL_levelup_cnt;
logic [1:0] EVAL_battle_cnt;
logic [1:0] EVAL_skill_cnt;

always_comb begin
    case(cur_state)
        IDLE: begin
            if(inf.sel_action_valid==1'b1) next_state=INPUT_and_dram_read;
            else next_state=IDLE;
        end
        INPUT_and_dram_read: begin
            if(INPUT_done==1'b1&& dram_read_done==1'b1)begin 
                case(sel_action_q)
                    0: next_state=EVAL_login;
                    1: next_state=EVAL_levelup;
                    2: next_state=EVAL_battle;
                    3: next_state=EVAL_skill;
                    4: next_state=EVAL_inactive;
                    default: next_state=EVAL_login;
                endcase
            end
            else next_state=INPUT_and_dram_read;
        end
        EVAL_login: begin
            next_state=EVAL_dram_write;
        end
        EVAL_levelup: begin
            if(EVAL_levelup_done==1 || EVAL_levelup_cnt==1) next_state=EVAL_dram_write;
            else next_state=EVAL_levelup;
        end
        EVAL_battle: begin
            if(EVAL_battle_done==1 || EVAL_battle_cnt==2) next_state=EVAL_dram_write;
            else next_state=EVAL_battle;
        end
        EVAL_skill: begin
            if(EVAL_skill_done==1 || EVAL_skill_cnt==1) next_state=EVAL_dram_write;
            else next_state = EVAL_skill;
        end
        EVAL_inactive: begin
            next_state=EVAL_dram_write;
        end
        EVAL_dram_write: begin
            if(dram_write_done==1) next_state=OUTPUT_warn;
            else next_state=EVAL_dram_write;
        end
        OUTPUT_warn: next_state = CLEAR;
        CLEAR: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

//Part 3 Seq Logic (input reg & take input tag)
logic [3:0] date_mon_q; logic [4:0] date_day_q;
logic [5:0] player_no_q;
logic [1:0] train_type_q;
logic [1:0] mode_q;
logic [15:0] mons_atk_q, mons_def_q, mons_HP_q;
logic [15:0] MP_list_q [0:3];

//take input tag
logic got_sel_action, got_date, got_player_no, got_train_type, got_mode;
logic [2:0] mons_in_cnt, mp_in_cnt;

//sel_action
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        sel_action_q<=0;    got_sel_action<=0;  
    end
    else if(inf.sel_action_valid==1)begin 
        sel_action_q<=inf.D.d_act[0];   got_sel_action<=1; 
    end
    else if(cur_state==CLEAR)begin 
        sel_action_q<=0;    got_sel_action<=0; 
    end
end
//date
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        date_mon_q<=0; date_day_q<=0; got_date<=0;
    end
    else if(inf.date_valid==1)begin 
        date_mon_q<=inf.D.d_date[8:5]; date_day_q<=inf.D.d_date[4:0]; got_date<=1;
    end
    else if(cur_state==CLEAR)begin 
        date_mon_q<=0; date_day_q<=0; got_date<=0;
    end
end
//player_no
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        player_no_q<=0;     got_player_no<=0;
    end
    else if(inf.player_no_valid==1)begin 
        player_no_q<=inf.D.d_player_no[0];     got_player_no<=1;
    end
    else if(cur_state==CLEAR)begin 
        player_no_q<=0;     got_player_no<=0;
    end
end
//train_type
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        train_type_q<=0;    got_train_type<=0; 
    end
    else if(inf.type_valid==1)begin 
        train_type_q<=inf.D.d_type[0]; got_train_type<=1; 
    end
    else if(cur_state==CLEAR)begin 
        train_type_q<=0;    got_train_type<=0; 
    end
end
//mode
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        mode_q<=0;    got_mode<=0; 
    end
    else if(inf.mode_valid==1)begin 
        mode_q<=inf.D.d_mode[0];    got_mode<=1; 
    end
    else if(cur_state==CLEAR)begin 
        mode_q<=0;    got_mode<=0; 
    end
end
//monster
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        mons_in_cnt<=0; mons_atk_q<=0; mons_def_q<=0;  mons_HP_q=0; 
    end
    else if(inf.monster_valid==1)begin
        mons_in_cnt<=mons_in_cnt+1;
        if(mons_in_cnt==0) mons_atk_q<=inf.D.d_attribute[0]; 
        else if(mons_in_cnt==1) mons_def_q<=inf.D.d_attribute[0];  
        else if(mons_in_cnt==2) mons_HP_q=inf.D.d_attribute[0]; 
    end
    else if(cur_state==CLEAR)begin
        mons_in_cnt<=0; mons_atk_q<=0; mons_def_q<=0;  mons_HP_q=0;
    end
end
//MP
integer i,j;
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin 
        for(i=0;i<4;i=i+1) MP_list_q [i]<=0;
        mp_in_cnt<=0;
    end
    else if(inf.MP_valid==1)begin
        mp_in_cnt<=mp_in_cnt+1;
        MP_list_q [mp_in_cnt]<=inf.D.d_attribute[0];
    end
    else if(cur_state==CLEAR)begin
        for(i=0;i<4;i=i+1) MP_list_q [i]<=0;
        mp_in_cnt<=0;
    end
end
//player_no接收完後, 就可以開始讀dram, 有多種valid，每次成立就收進來
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        INPUT_done<=0; 
    end
    else if(cur_state==INPUT_and_dram_read)begin
        //login
        if(got_sel_action==1 && got_date==1 && got_player_no==1)INPUT_done<=1;  
        //level up
        else if(got_sel_action==1&&got_train_type==1&&got_mode==1&&got_player_no==1)INPUT_done<=1;
        //battle
        else if(got_sel_action==1&&got_player_no==1&&mons_in_cnt>=3)INPUT_done<=1;
        //skill
        else if(got_sel_action==1&&got_player_no==1&&mp_in_cnt>=4)INPUT_done<=1;
        //inactive
        else if(got_sel_action==1 && got_date==1 && got_player_no==1)INPUT_done<=1;
    end
    else if(cur_state==CLEAR)begin
        INPUT_done<=0; 
    end
end

//Part 2 Comb Logic
Player_Info player_sig;     //sv format
logic [15:0] plyr_HP_q, plyr_atk_q, plyr_def_q, plyr_EXP_q, plyr_MP_q;
logic [3:0] plyr_mon_q; logic [4:0] plyr_day_q;

always_comb begin
    player_sig.HP=plyr_HP_q;        player_sig.Exp=plyr_EXP_q;
    player_sig.Attack=plyr_atk_q;   player_sig.Defense=plyr_def_q;  
    player_sig.M=plyr_mon_q;        player_sig.D=plyr_day_q;        
    player_sig.MP=plyr_MP_q;
end

//Part 3 Seq Logic dram read (R & AR)
logic AR_done;
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        //DRAM read (AR)
        inf.AR_VALID<=0; AR_done<=0; inf.AR_ADDR<=0;
        //DRAM read (R)
        inf.R_READY<=0; dram_read_done<=0;
        //{plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
    end
    else if(cur_state==INPUT_and_dram_read)begin
        if(got_player_no==1)begin
            //case 0: AR handshake done
            if((inf.AR_VALID==1 && inf.AR_READY==1) && AR_done==0)begin
                inf.AR_ADDR<=0;
                AR_done<=1;
                inf.AR_VALID<=0;
            end
            //case 1: wait for AR handshake
            else if((inf.AR_VALID!=1 || inf.AR_READY!=1) && AR_done==0)begin
                inf.AR_ADDR<=17'h10000+(12*player_no_q);
                AR_done<=0;
                inf.AR_VALID<=1;
            end
            //case 2: R handshake done
            else if((inf.R_VALID==1 && inf.R_READY==1) && AR_done==1)begin
                //{plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=inf.R_DATA;
                dram_read_done<=1;
                inf.R_READY<=0;
            end
            //case 3: wait for R handshake done
            else if((inf.R_VALID!=1 || inf.R_READY!=1) && AR_done==1)begin
                inf.R_READY<=1;
            end
        end
    end
    else if(cur_state==CLEAR)begin
        //DRAM read (AR)
        inf.AR_VALID<=0; AR_done<=0; inf.AR_ADDR<=0;
        //DRAM read (R)
        inf.R_READY<=0; dram_read_done<=0;
        //{plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
    end
end

//Part 3 Seq Logic dram read (AW & W & B)
logic AW_done, W_done;
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        //DRAM write (AW)
        inf.AW_VALID<=0;    inf.AW_ADDR<=0; AW_done<=0;
        //DRAM write (W)
        inf.W_VALID<=0;     inf.W_DATA<=0;  W_done<=0;
        //DRAM write (B)
        inf.B_READY<=0;     dram_write_done<=0;
    end
    else if(cur_state==EVAL_dram_write)begin
        //case 0: AW handshake done
        if((inf.AW_VALID==1 && inf.AW_READY==1) && AW_done==0)begin
            inf.AW_ADDR<=0;
            AW_done<=1; 
            inf.AW_VALID<=0;
        end
        //case 1: wait for AW handshake
        else if((inf.AW_VALID!=1 || inf.AW_READY!=1) && AW_done==0 )begin
            inf.AW_ADDR<=17'h10000+(12*player_no_q);
            AW_done<=0;
            inf.AW_VALID<=1;
        end
        //case 2: W handshake done
        else if((inf.W_VALID==1 && inf.W_READY==1) && AW_done==1 && W_done==0)begin
            inf.W_DATA<=0;
            W_done<=1;
            inf.W_VALID<=0;
        end
        //case 3: wait for W handshake 
        else if((inf.W_VALID!=1 || inf.W_READY!=1) && AW_done==1 && W_done==0 )begin
            inf.W_DATA<={plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q};
            W_done<=0;
            inf.W_VALID<=1;
        end
        //case 4: B handshake done
        else if((inf.B_VALID==1 && inf.B_READY==1) && AW_done==1 && W_done==1 && dram_write_done==0)begin
            dram_write_done<=1;
            inf.B_READY<=0;
        end
        //case 5: wait for B handshake
        else if((inf.B_VALID!=1 || inf.B_READY!=1) && AW_done==1 && W_done==1 && dram_write_done==0)begin
            inf.B_READY<=1;
        end
    end
    else if(cur_state==CLEAR)begin
        //DRAM write (AW)
        inf.AW_VALID<=0;    inf.AW_ADDR<=0; AW_done<=0;
        //DRAM write (W)
        inf.W_VALID<=0;     inf.W_DATA<=0;  W_done<=0;
        //DRAM write (B)
        inf.B_READY<=0;     dram_write_done<=0;
    end
end

//Part 2 Comb Logic (連續兩天的部分要判斷)
logic cts_bool, more_than_90days;
check_date check_date_inst(
    .prev_mon(plyr_mon_q),
    .prev_day(plyr_day_q),
    .cur_mon(date_mon_q),
    .cur_day(date_day_q),
    .cts_bool(cts_bool),
    .more_than_90days(more_than_90days)
);
//Part 2 Comb Logic for EVAL_levelup
logic [15:0] find_delta_in [0:3];
logic [15:0] Delta_MP,Delta_HP,Delta_ATK,Delta_DEF;
logic [15:0] sorted_MP [0:3]; //for EVAL_skill
//只是為了共用sort而已
always_comb begin
    if(cur_state==EVAL_levelup)begin    //EVAL_levelup
        find_delta_in[0]=plyr_MP_q;  find_delta_in[1]=plyr_HP_q;
        find_delta_in[2]=plyr_atk_q; find_delta_in[3]=plyr_def_q;
    end
    else begin                          //EVAL_skill
        find_delta_in[0]=MP_list_q[0]; find_delta_in[1]=MP_list_q[1];
        find_delta_in[2]=MP_list_q[2]; find_delta_in[3]=MP_list_q[3];
    end
end

find_delta find_delta_inst(
    .type_in(train_type_q),
    .MP(find_delta_in[0]),  .HP(find_delta_in[1]),
    .ATK(find_delta_in[2]), .DEF(find_delta_in[3]),

    .Delta_MP(Delta_MP),    .Delta_HP(Delta_HP),
    .Delta_ATK(Delta_ATK),  .Delta_DEF(Delta_DEF),

    .sorted_A0(sorted_MP[0]),.sorted_A1(sorted_MP[1]),
    .sorted_A2(sorted_MP[2]),.sorted_A3(sorted_MP[3])
);

logic [15:0] Out_MP,Out_HP,Out_ATK,Out_DEF;
logic [15:0] Delta_MP_q, Delta_HP_q, Delta_ATK_q, Delta_DEF_q;
logic EVAL_levelup_satwarn_bool;

apply_delta apply_delta_inst(
    .mode_in(mode_q),
    .MP(plyr_MP_q),.HP(plyr_HP_q),.ATK(plyr_atk_q),.DEF(plyr_def_q),

    .Delta_MP(Delta_MP_q),  .Delta_HP(Delta_HP_q),
    .Delta_ATK(Delta_ATK_q),.Delta_DEF(Delta_DEF_q),

    .Out_MP(Out_MP),    .Out_HP(Out_HP),
    .Out_ATK(Out_ATK),  .Out_DEF(Out_DEF),
    .satwarn(EVAL_levelup_satwarn_bool)
);

//Part 2 Comb Logic EVAL_skill
logic [19:0] four_mp_sum;
logic [18:0] three_mp_sum;
logic [17:0] two_mp_sum;
logic [15:0] total_MP_consumed;
logic [15:0] sorted_MP_q [0:3];
always_comb begin
    two_mp_sum=sorted_MP_q[0]+sorted_MP_q[1];
    three_mp_sum=two_mp_sum+sorted_MP_q[2];
    four_mp_sum=three_mp_sum+sorted_MP_q[3];

    if(four_mp_sum<plyr_MP_q)   total_MP_consumed=four_mp_sum;
    else if(three_mp_sum<plyr_MP_q) total_MP_consumed=three_mp_sum;
    else if(two_mp_sum<plyr_MP_q)   total_MP_consumed=two_mp_sum;
    else if(sorted_MP_q[0]<plyr_MP_q) total_MP_consumed=sorted_MP_q[0];
    else total_MP_consumed=0;   //can't use any MP
end

//Part 2 Comb Logic EVAL_battle
//step 1
logic [15:0] dmg_to_plyr_q, dmg_to_mons_q;
logic [15:0] dmg_to_plyr_d, dmg_to_mons_d;
always_comb begin   //用comb logic
    if(mons_atk_q>=plyr_def_q) dmg_to_plyr_d=(mons_atk_q-plyr_def_q);
    else dmg_to_plyr_d=0;
    if(plyr_atk_q>=mons_def_q) dmg_to_mons_d=(plyr_atk_q-mons_def_q);
    else dmg_to_mons_d=0;
end
//step 2
logic [15:0] plyr_temp_HP_q, mons_temp_HP_q;
logic [15:0] plyr_temp_HP_d, mons_temp_HP_d;
always_comb begin
    if(dmg_to_plyr_q>=0) begin
        if(dmg_to_plyr_q>=plyr_HP_q) plyr_temp_HP_d=0;
        else plyr_temp_HP_d=plyr_HP_q-dmg_to_plyr_q;
    end
    else plyr_temp_HP_d=plyr_HP_q;

    if(dmg_to_mons_q>=0) begin
        if(dmg_to_mons_q>=mons_HP_q) mons_temp_HP_d=0;
        else mons_temp_HP_d=mons_HP_q-dmg_to_mons_q;
    end
    else mons_temp_HP_d=mons_HP_q;
end
//step 3
logic win_sat_bool, lose_sat_bool;
logic [15:0] plyr_EXP_d, plyr_MP_d, plyr_HP_d, plyr_atk_d, plyr_def_d;

always_comb begin
    if(plyr_temp_HP_q>0 && mons_temp_HP_q<=0)begin      //win 
        //sat_bool
        if(plyr_EXP_q+2048>65535 || plyr_MP_q+2048>65535)win_sat_bool=1;
        else win_sat_bool=0;
        lose_sat_bool=0;
        //plyr
        if(plyr_EXP_q+2048>65535) plyr_EXP_d=65535; //sat
        else plyr_EXP_d=plyr_EXP_q+2048;
        if(plyr_MP_q+2048>65535) plyr_MP_d=65535;   //sat
        else plyr_MP_d=plyr_MP_q+2048;
        plyr_HP_d=plyr_temp_HP_q;
        plyr_atk_d=plyr_atk_q;  plyr_def_d=plyr_def_q;
    end
    else if(plyr_temp_HP_q<=0)begin                     //lose
        //sat_bool
        if(plyr_EXP_q<2048 || plyr_atk_q<2048 || plyr_def_q<2048) lose_sat_bool=1;
        else lose_sat_bool=0;
        win_sat_bool=0;
        //plyr
        if(plyr_EXP_q<2048) plyr_EXP_d=0;
        else plyr_EXP_d=plyr_EXP_q-2048;
        if(plyr_atk_q<2048) plyr_atk_d=0;
        else plyr_atk_d=plyr_atk_q-2048;
        if(plyr_def_q<2048) plyr_def_d=0;
        else plyr_def_d=plyr_def_q-2048;
        plyr_HP_d=0;    plyr_MP_d=plyr_MP_q;
    end
    //tie
    else begin      //if(plyr_temp_HP_q>0 && mons_temp_HP_q>0)
        //sat
        win_sat_bool=0;     lose_sat_bool=0;
        //plyr
        plyr_atk_d=plyr_atk_q;  plyr_def_d=plyr_def_q;
        plyr_MP_d=plyr_MP_q;    plyr_HP_d=plyr_temp_HP_q;
        plyr_EXP_d=plyr_EXP_q;
    end
end

//Part 3 Seq Logic (要一起寫)
//EVAL_login (1 cycle)
Warn_Msg EVAL_login_warn;

//EVAL_levelup (2 cycle)
Warn_Msg EVAL_levelup_warn;

//EVAL_battle (3 cycles)
Warn_Msg EVAL_battle_warn;

//EVAL_skill (2 cycle)
Warn_Msg EVAL_skill_warn;

//EVAL_inactive (1 cycle)
Warn_Msg EVAL_inactive_warn;

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        //major signal
        {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
        //EVAL_login 
        EVAL_login_warn<=No_Warn; EVAL_login_done<=0;
        //EVAL_levelup
        EVAL_levelup_cnt<=0; EVAL_levelup_warn<=No_Warn; EVAL_levelup_done<=0;
        Delta_MP_q<=0; Delta_HP_q<=0; Delta_ATK_q<=0; Delta_DEF_q<=0;
        //EVAL_battle
        EVAL_battle_cnt<=0; EVAL_battle_warn<=No_Warn; EVAL_battle_done<=0;
        dmg_to_plyr_q<=0; dmg_to_mons_q<=0;
        plyr_temp_HP_q<=0;  mons_temp_HP_q<=0;
        plyr_EXP_q<=0; plyr_MP_q<=0; plyr_atk_q<=0; plyr_def_q<=0; plyr_HP_q<=0;
        //EVAL_skill (2 cycle)
        for(j=0;j<4;j=j+1) sorted_MP_q[j]<=0;
        EVAL_skill_cnt<=0;  EVAL_skill_warn<=No_Warn; EVAL_skill_done<=0;
        //EVAL_inactive
        EVAL_inactive_warn<=No_Warn; EVAL_inactive_done<=0;
    end
    else if(cur_state==INPUT_and_dram_read)begin
        if(got_player_no==1)begin
            //case 2: R handshake done
            if((inf.R_VALID==1 && inf.R_READY==1) && AR_done==1)begin
                {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=inf.R_DATA;
            end
        end
    end
    else if(cur_state==EVAL_login)begin
        //step 0  更新 date
        plyr_mon_q<=date_mon_q; plyr_day_q<=date_day_q;
        //step 1  更新 EXP or MP (如果連續登入的話)
        if(cts_bool==1)begin
            //case 0-0 no overflow 直接相加並更新
            if(player_sig.Exp+512<=65535 && player_sig.MP+1024<=65535)begin
                plyr_EXP_q<=plyr_EXP_q+512; plyr_MP_q<=plyr_MP_q+1024;
            end
            //case 0-1 overflow 避免0verfloiw後更新
            else begin
                EVAL_login_warn<=Saturation_Warn;    //sat warn
                if(player_sig.Exp+512>65535)plyr_EXP_q<=65535;
                else plyr_EXP_q<=plyr_EXP_q+512;

                if(player_sig.MP+1024>65535) plyr_MP_q<=65535;
                else plyr_MP_q<=plyr_MP_q+1024;
            end
        end
        //step 2 done
        EVAL_login_done<=1;
    end
    else if(cur_state==EVAL_levelup)begin
        EVAL_levelup_cnt<=EVAL_levelup_cnt+1;
        //case 0 判定Exp 是否足夠
        if((mode_q==2'b00&&plyr_EXP_q<4095)||(mode_q==2'b01&&plyr_EXP_q<16383) || 
        (mode_q==2'b10&&plyr_EXP_q<32767)&&EVAL_levelup_done==0&&EVAL_levelup_cnt==0) begin 
            EVAL_levelup_warn<=Exp_Warn;    //Exp_Warn 
            EVAL_levelup_done<=1;
        end
        //case 1 計算attribute的delta
        else if(EVAL_levelup_cnt==0 && EVAL_levelup_done==0)begin
            Delta_MP_q<=Delta_MP;   Delta_HP_q<=Delta_HP;
            Delta_ATK_q<=Delta_ATK; Delta_DEF_q<=Delta_DEF;
        end
        //case 2 計算更新後的attribute並更新
        else if(EVAL_levelup_cnt==1 && EVAL_levelup_done==0)begin
            plyr_MP_q<=Out_MP;      plyr_HP_q<=Out_HP;
            plyr_atk_q<=Out_ATK;    plyr_def_q<=Out_DEF;
            if(EVAL_levelup_satwarn_bool==1) EVAL_levelup_warn<=Saturation_Warn;
            else EVAL_levelup_warn<=No_Warn;
            EVAL_levelup_done<=1;
        end
    end
    else if(cur_state==EVAL_battle) begin
        EVAL_battle_cnt<=EVAL_battle_cnt+1;
        if(EVAL_battle_cnt==0)begin     //用comb logic
            //step 0 check HP (如果是0就直接HP warn)
            if(plyr_HP_q==0)begin 
                EVAL_battle_warn<=HP_Warn;  EVAL_battle_done<=1;
            end
            //step 1
            dmg_to_plyr_q<=dmg_to_plyr_d;  dmg_to_mons_q<=dmg_to_mons_d;
        end
        else if(EVAL_battle_cnt==1 && EVAL_battle_done==0)begin
            plyr_temp_HP_q<=plyr_temp_HP_d; mons_temp_HP_q<=mons_temp_HP_d;
        end
        else if(EVAL_battle_cnt==2 && EVAL_battle_done==0)begin 
            //step 1 update plyr           
            plyr_MP_q<=plyr_MP_d;   plyr_HP_q<=plyr_HP_d;
            plyr_atk_q<=plyr_atk_d; plyr_def_q<=plyr_def_d;
            plyr_EXP_q<=plyr_EXP_d;
            //step 2 update warn
            if(win_sat_bool==1 || lose_sat_bool==1)EVAL_battle_warn<=Saturation_Warn;
            else EVAL_battle_warn<=No_Warn;
        end
    end
    else if(cur_state==EVAL_skill)begin
        EVAL_skill_cnt<=EVAL_skill_cnt+1;
        //step 0 sort
        if(EVAL_skill_cnt==0)begin
            for(j=0;j<4;j=j+1) sorted_MP_q[j]<=sorted_MP[j];
        end
        //step 1 find_ max skill num with min_mp
        else if(EVAL_skill_cnt==1)begin
            EVAL_skill_done<=1;
            if(total_MP_consumed==0)EVAL_skill_warn<=MP_Warn;   //無法使用任何skill(故MP不變)
            else plyr_MP_q<=plyr_MP_q-total_MP_consumed;        //可使用MP, MP更新
        end
    end
    else if(cur_state==EVAL_inactive)begin
        EVAL_inactive_done<=1;
        if(more_than_90days==1 && EVAL_inactive_done==0)begin
            EVAL_inactive_warn<=Date_Warn;
        end
        else EVAL_inactive_warn<=No_Warn;
    end
    else if(cur_state==CLEAR)begin
        //major signal
        {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
        //EVAL_login 
        EVAL_login_warn<=No_Warn; EVAL_login_done<=0;
        //EVAL_levelup
        EVAL_levelup_cnt<=0; EVAL_levelup_warn<=No_Warn; EVAL_levelup_done<=0;
        Delta_MP_q<=0; Delta_HP_q<=0; Delta_ATK_q<=0; Delta_DEF_q<=0;
        //EVAL_battle
        EVAL_battle_cnt<=0; EVAL_battle_warn<=No_Warn; EVAL_battle_done<=0;
        dmg_to_plyr_q<=0; dmg_to_mons_q<=0;
        plyr_temp_HP_q<=0;  mons_temp_HP_q<=0;
        plyr_EXP_q<=0; plyr_MP_q<=0; plyr_atk_q<=0; plyr_def_q<=0; plyr_HP_q<=0;
        //EVAL_skill (2 cycle)
        for(j=0;j<4;j=j+1) sorted_MP_q[j]<=0;
        EVAL_skill_cnt<=0;  EVAL_skill_warn<=No_Warn; EVAL_skill_done<=0;
        //EVAL_inactive
        EVAL_inactive_warn<=No_Warn; EVAL_inactive_done<=0;
    end
end

//OUTPUT logic
Warn_Msg output_warn_d;
logic complete_d;
always_comb begin
    case(sel_action_q)
        0: begin
            output_warn_d=EVAL_login_warn;
            if(EVAL_login_warn!=No_Warn) complete_d=0;
            else complete_d=1;
        end
        1: begin
            output_warn_d=EVAL_levelup_warn;
            if(EVAL_levelup_warn!=No_Warn) complete_d=0;
            else complete_d=1;
        end
        2: begin
            output_warn_d=EVAL_battle_warn;
            if(EVAL_battle_warn!=No_Warn) complete_d=0;
            else complete_d=1;
        end
        3: begin
            output_warn_d=EVAL_skill_warn;
            if(EVAL_skill_warn!=No_Warn) complete_d=0;
            else complete_d=1;
        end
        4: begin
            output_warn_d=EVAL_inactive_warn;
            if(EVAL_inactive_warn!=No_Warn) complete_d=0;
            else complete_d=1;
        end
        default: begin
            output_warn_d=EVAL_inactive_warn;
            if(EVAL_inactive_warn!=No_Warn) complete_d=0;
            else complete_d=1;
        end
    endcase
end

//Part 3 Seq Logic OUTPUT
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        inf.out_valid<=0; inf.warn_msg<=0; inf.complete<=0;
    end
    else if(cur_state==OUTPUT_warn)begin
        inf.out_valid<=1; 
        inf.warn_msg<=output_warn_d; inf.complete<=complete_d;
    end
    else begin
        inf.out_valid<=0; inf.warn_msg<=0; inf.complete<=0;
    end
end
endmodule

module check_date(
    input  logic [3:0] prev_mon,
    input  logic [4:0] prev_day,
    input  logic [3:0] cur_mon,
    input  logic [4:0] cur_day,
    output logic cts_bool,
    output logic more_than_90days
);
    logic [4:0] cur_mon_extend;
    always_comb begin
        if({cur_mon,cur_day}<{prev_mon,prev_day})cur_mon_extend=cur_mon+12;
        else cur_mon_extend=cur_mon;
    end

    logic [9:0] cur_month_to_day;
    logic [9:0] prev_month_to_day;
    always_comb begin
        case(cur_mon_extend)
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
            default: cur_month_to_day = 0;
        endcase
    end
    always_comb begin
        case(prev_mon)
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
            default: prev_month_to_day = 0;
        endcase
    end
    
    logic [9:0] cur_total_day, pre_total_day; 
    always_comb begin
        cur_total_day=cur_month_to_day + cur_day;
        pre_total_day=prev_month_to_day + prev_day; 
        if(pre_total_day+1==cur_total_day) cts_bool=1;
        else cts_bool=0;
        if(cur_total_day-pre_total_day>90) more_than_90days=1;
        else more_than_90days=0;
    end
endmodule

module find_delta (
    input  logic [1:0] type_in,
    input  logic [15:0] MP,
    input  logic [15:0] HP,
    input  logic [15:0] ATK,
    input  logic [15:0] DEF,

    output logic [15:0] Delta_MP,
    output logic [15:0] Delta_HP,
    output logic [15:0] Delta_ATK,
    output logic [15:0] Delta_DEF,

    output logic [15:0] sorted_A0,
    output logic [15:0] sorted_A1,
    output logic [15:0] sorted_A2,
    output logic [15:0] sorted_A3
);
    //type A
    logic [15:0] out_attr_arr_A [0:3];    //MP, HP, ATK, DEF
    logic [15:0] result_A;
    assign result_A=(MP+HP+ATK+DEF)>>3;
    //===切===

    always_comb begin
        out_attr_arr_A[0]=result_A;
        out_attr_arr_A[1]=result_A;
        out_attr_arr_A[2]=result_A;
        out_attr_arr_A[3]=result_A;
    end
    //type B
    logic [15:0] A0,A1,A2,A3;
    logic [1:0] char_A0, char_A1, char_A2, char_A3;
    merge_sort_4 sort_inst(
        .in0(MP), .in1(HP), .in2(ATK), .in3(DEF),
        .in_char0(2'd0), .in_char1(2'd1), .in_char2(2'd2), .in_char3(2'd3),
        .out0(A0), .out1(A1), .out2(A2), .out3(A3),
        .out_char0(char_A0), .out_char1(char_A1), .out_char2(char_A2), .out_char3(char_A3)
    );
    //===切===
    
    logic [15:0] out_attr_arr_B [0:3];    //MP, HP, ATK, DEF
    logic [15:0] A2_minus_A0, A3_minus_A1; 
    always_comb begin
        A2_minus_A0 = A2 - A0;
        A3_minus_A1 = A3 - A1;

        out_attr_arr_B[0] = 0;  // 預設清零（避免 latch）
        out_attr_arr_B[1] = 0;
        out_attr_arr_B[2] = 0;
        out_attr_arr_B[3] = 0;

        case ({char_A0,char_A1})
            // ------- char_A0 = 0 -------
            {2'd0,2'd1}: begin
                out_attr_arr_B[0] = A2_minus_A0;
                out_attr_arr_B[1] = A3_minus_A1;
            end
            {2'd0,2'd2}: begin
                out_attr_arr_B[0] = A2_minus_A0;
                out_attr_arr_B[2] = A3_minus_A1;
            end
            {2'd0,2'd3}: begin
                out_attr_arr_B[0] = A2_minus_A0;
                out_attr_arr_B[3] = A3_minus_A1;
            end
            // ------- char_A0 = 1 -------
            {2'd1,2'd0}: begin
                out_attr_arr_B[1] = A2_minus_A0;
                out_attr_arr_B[0] = A3_minus_A1;
            end
            {2'd1,2'd2}: begin
                out_attr_arr_B[1] = A2_minus_A0;
                out_attr_arr_B[2] = A3_minus_A1;
            end
            {2'd1,2'd3}: begin
                out_attr_arr_B[1] = A2_minus_A0;
                out_attr_arr_B[3] = A3_minus_A1;
            end
            // ------- char_A0 = 2 -------
            {2'd2,2'd0}: begin
                out_attr_arr_B[2] = A2_minus_A0;
                out_attr_arr_B[0] = A3_minus_A1;
            end
            {2'd2,2'd1}: begin
                out_attr_arr_B[2] = A2_minus_A0;
                out_attr_arr_B[1] = A3_minus_A1;
            end
            {2'd2,2'd3}: begin
                out_attr_arr_B[2] = A2_minus_A0;
                out_attr_arr_B[3] = A3_minus_A1;
            end
            // ------- char_A0 = 3 -------
            {2'd3,2'd0}: begin
                out_attr_arr_B[3] = A2_minus_A0;
                out_attr_arr_B[0] = A3_minus_A1;
            end
            {2'd3,2'd1}: begin
                out_attr_arr_B[3] = A2_minus_A0;
                out_attr_arr_B[1] = A3_minus_A1;
            end
            {2'd3,2'd2}: begin
                out_attr_arr_B[3] = A2_minus_A0;
                out_attr_arr_B[2] = A3_minus_A1;
            end
        endcase
    end

    //type C
    logic [15:0] out_attr_arr_C [0:3];    //MP, HP, ATK, DEF
    always_comb begin
        if(MP<16383) out_attr_arr_C[0]=16383-MP;
        else out_attr_arr_C[0]=0;
        if(HP<16383) out_attr_arr_C[1]=16383-HP;
        else out_attr_arr_C[1]=0;
        if(ATK<16383) out_attr_arr_C[2]=16383-ATK;
        else out_attr_arr_C[2]=0;
        if(DEF<16383) out_attr_arr_C[3]=16383-DEF;
        else out_attr_arr_C[3]=0;
    end
    //===切===

    //type D
    logic [15:0] out_attr_arr_D_temp [0:3];
    logic [15:0] out_attr_arr_D [0:3];
    assign out_attr_arr_D_temp[0]= 3000+((65535-MP)>>4);
    assign out_attr_arr_D_temp[1]= 3000+((65535-HP)>>4);
    assign out_attr_arr_D_temp[2]= 3000+((65535-ATK)>>4);
    assign out_attr_arr_D_temp[3]= 3000+((65535-DEF)>>4);
    //===切===

    assign out_attr_arr_D[0]=(out_attr_arr_D_temp[0]>5047)? 5047:out_attr_arr_D_temp[0];
    assign out_attr_arr_D[1]=(out_attr_arr_D_temp[1]>5047)? 5047:out_attr_arr_D_temp[1];
    assign out_attr_arr_D[2]=(out_attr_arr_D_temp[2]>5047)? 5047:out_attr_arr_D_temp[2];
    assign out_attr_arr_D[3]=(out_attr_arr_D_temp[3]>5047)? 5047:out_attr_arr_D_temp[3];
    //out sig
    always_comb begin
        case(type_in)
            0:begin
                Delta_MP=out_attr_arr_A[0]; Delta_HP=out_attr_arr_A[1];
                Delta_ATK=out_attr_arr_A[2];Delta_DEF=out_attr_arr_A[3];
            end
            1:begin
                Delta_MP=out_attr_arr_B[0]; Delta_HP=out_attr_arr_B[1];
                Delta_ATK=out_attr_arr_B[2];Delta_DEF=out_attr_arr_B[3];
            end
            2:begin
                Delta_MP=out_attr_arr_C[0]; Delta_HP=out_attr_arr_C[1];
                Delta_ATK=out_attr_arr_C[2];Delta_DEF=out_attr_arr_C[3];
            end
            3:begin
                Delta_MP=out_attr_arr_D[0]; Delta_HP=out_attr_arr_D[1];
                Delta_ATK=out_attr_arr_D[2];Delta_DEF=out_attr_arr_D[3];
            end
            default:begin
                Delta_MP=out_attr_arr_A[0]; Delta_HP=out_attr_arr_A[1];
                Delta_ATK=out_attr_arr_A[2];Delta_DEF=out_attr_arr_A[3];
            end
        endcase
    end
    //sorted sig
    always_comb begin
        sorted_A0=A0;   sorted_A1=A1;
        sorted_A2=A2;   sorted_A3=A3;
    end
endmodule

module merge_sort_4(
    input  logic [15:0] in0, in1, in2, in3,
    input  logic [1:0]  in_char0, in_char1, in_char2, in_char3,
    output logic [15:0] out0, out1, out2, out3,
    output logic [1:0]  out_char0, out_char1, out_char2, out_char3
);
    // INTERNAL WIRES (values & tokens)
    logic [15:0] inter1 [3:0];
    logic [15:0] inter2 [3:0];
    logic [15:0] inter3 [3:0];

    logic [1:0] inter1_char [3:0];
    logic [1:0] inter2_char [3:0];
    logic [1:0] inter3_char [3:0];

    // Stage 1 pairwise compare: (0,1), (2,3)
    comparator comp1_1(
        .a(in0), .b(in1),
        .a_char(in_char0), .b_char(in_char1),
        .min_out(inter1[0]), .max_out(inter1[1]),
        .min_char(inter1_char[0]), .max_char(inter1_char[1])
    );

    comparator comp1_2(
        .a(in2), .b(in3),
        .a_char(in_char2), .b_char(in_char3),
        .min_out(inter1[2]), .max_out(inter1[3]),
        .min_char(inter1_char[2]), .max_char(inter1_char[3])
    );

    // Stage 2 merge: (0,2) and (1,3)
    comparator comp2_1(
        .a(inter1[0]), .b(inter1[2]),
        .a_char(inter1_char[0]), .b_char(inter1_char[2]),
        .min_out(inter2[0]), .max_out(inter2[2]),
        .min_char(inter2_char[0]), .max_char(inter2_char[2])
    );

    comparator comp2_2(
        .a(inter1[1]), .b(inter1[3]),
        .a_char(inter1_char[1]), .b_char(inter1_char[3]),
        .min_out(inter2[1]), .max_out(inter2[3]),
        .min_char(inter2_char[1]), .max_char(inter2_char[3])
    );

    // Stage 3 middle adjustment: (1,2)
    comparator comp3_1(
        .a(inter2[1]), .b(inter2[2]),
        .a_char(inter2_char[1]), .b_char(inter2_char[2]),
        .min_out(inter3[1]), .max_out(inter3[2]),
        .min_char(inter3_char[1]), .max_char(inter3_char[2])
    );

    // retain boundary elements
    assign inter3[0] = inter2[0];
    assign inter3[3] = inter2[3];
    assign inter3_char[0] = inter2_char[0];
    assign inter3_char[3] = inter2_char[3];

    // Outputs (sorted order)
    assign out0 = inter3[0];
    assign out1 = inter3[1];
    assign out2 = inter3[2];
    assign out3 = inter3[3];

    assign out_char0 = inter3_char[0];
    assign out_char1 = inter3_char[1];
    assign out_char2 = inter3_char[2];
    assign out_char3 = inter3_char[3];
endmodule

module comparator(
    input  logic [15:0] a, b,           // 16-bit inputs
    input  logic [1:0]  a_char, b_char, // 2-bit tie-break token
    output logic [15:0] min_out, max_out,
    output logic [1:0]  min_char, max_char
);
    always_comb begin
        if (a > b) begin
            max_out  = a;  max_char = a_char;
            min_out  = b;  min_char = b_char;
        end
        else if (a < b) begin
            max_out  = b;  max_char = b_char;
            min_out  = a;  min_char = a_char;
        end
        else begin  // tie-break by token (smaller token = larger)
            if (a_char < b_char) begin
                max_out  = b;  max_char = b_char;
                min_out  = a;  min_char = a_char;
            end
            else begin
                max_out  = a;  max_char = a_char;
                min_out  = b;  min_char = b_char;
            end
        end
    end
endmodule

module apply_delta (
    input  logic [1:0]  mode_in,          // 0,1,2 三种类型
    input  logic [15:0] MP,
    input  logic [15:0] HP,
    input  logic [15:0] ATK,
    input  logic [15:0] DEF,

    input  logic [15:0] Delta_MP,
    input  logic [15:0] Delta_HP,
    input  logic [15:0] Delta_ATK,
    input  logic [15:0] Delta_DEF,

    output logic [15:0] Out_MP,
    output logic [15:0] Out_HP,
    output logic [15:0] Out_ATK,
    output logic [15:0] Out_DEF,
    output logic        satwarn           // saturation warning
);
    logic [15:0] qMP, qHP, qATK, qDEF;
    logic [18:0] tmp_MP, tmp_HP, tmp_ATK, tmp_DEF;
    assign qMP  = Delta_MP  >> 2;
    assign qHP  = Delta_HP  >> 2;
    assign qATK = Delta_ATK >> 2;
    assign qDEF = Delta_DEF >> 2;

    always_comb begin // apply delta according to type
        case (mode_in)
            2'd0: begin
                tmp_MP  = MP  + Delta_MP  - qMP;
                tmp_HP  = HP  + Delta_HP  - qHP;
                tmp_ATK = ATK + Delta_ATK - qATK;
                tmp_DEF = DEF + Delta_DEF - qDEF;
            end
            2'd1: begin
                tmp_MP  = MP  + Delta_MP;
                tmp_HP  = HP  + Delta_HP;
                tmp_ATK = ATK + Delta_ATK;
                tmp_DEF = DEF + Delta_DEF;
            end
            2'd2: begin
                tmp_MP  = MP  + Delta_MP  + qMP;
                tmp_HP  = HP  + Delta_HP  + qHP;
                tmp_ATK = ATK + Delta_ATK + qATK;
                tmp_DEF = DEF + Delta_DEF + qDEF;
            end
            default: begin
                tmp_MP  = MP;   tmp_HP  = HP;
                tmp_ATK = ATK;  tmp_DEF = DEF;
            end
        endcase

        // saturation + satwarn
        if(tmp_MP > 65535 || tmp_HP > 65535 || tmp_ATK > 65535 || tmp_DEF > 65535)satwarn = 1'b1;
        else satwarn = 1'b0;

        if (tmp_MP > 65535) Out_MP  = 65535;
        else Out_MP = tmp_MP;
        if (tmp_HP > 65535) Out_HP  = 65535;
        else Out_HP = tmp_HP;
        if (tmp_ATK > 65535) Out_ATK = 65535;
        else Out_ATK = tmp_ATK;
        if (tmp_DEF > 65535) Out_DEF = 65535;
        else Out_DEF = tmp_DEF;
    end
endmodule