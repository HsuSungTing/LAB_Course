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
logic INPUT_done, dram_read_done;
logic EVAL_login_done, EVAL_levelup_done, EVAL_battle_done;
logic EVAL_skill_done, EVAL_inactive_done;

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
            if(EVAL_login_done==1) next_state = OUTPUT_warn;
            else next_state = EVAL_login;
        end
        EVAL_levelup: begin
            if(EVAL_levelup_done==1) next_state = OUTPUT_warn;
            else next_state = EVAL_levelup;
        end
        EVAL_battle: begin
            if(EVAL_battle_done==1) next_state = OUTPUT_warn;
            else next_state = EVAL_battle;
        end
        EVAL_skill: begin
            if(EVAL_skill_done==1) next_state = OUTPUT_warn;
            else next_state = EVAL_skill;
        end
        EVAL_inactive: begin
            if(EVAL_inactive_done==1) next_state = OUTPUT_warn;
            else next_state = EVAL_inactive;
        end
        OUTPUT_warn: begin
        end
        CLEAR: begin
        end
        default: next_state = IDLE;
    endcase
end

//Part 3 Seq Logic (input reg & take input tag)
logic [3:0] data_mon_q; logic [4:0] data_day_q;
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
        data_mon_q<=0; data_day_q<=0; got_date<=0;
    end
    else if(inf.date_valid==1)begin 
        data_mon_q<=inf.D.d_date[8:5]; data_day_q<=inf.D.d_date[4:0]; got_date<=1;
    end
    else if(cur_state==CLEAR)begin 
        data_mon_q<=0; data_day_q<=0; got_date<=0;
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
    else if(inf.type_valid==1)begin 
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
logic [7:0] plyr_mon_q, plyr_day_q;

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
        inf.R_READY<=0;  
        {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
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
                {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=inf.R_DATA;
                dram_read_done<=1;
                inf.R_READY<=0;
            end
            //case 3: wait for R handshake done
            else if((inf.R_VALID!=1 || inf.R_READY!=1) && AR_done==1)begin
                dram_read_done<=0;
                inf.R_READY<=1;
            end
        end
    end
    else if(cur_state==CLEAR)begin
        //DRAM read (AR)
        inf.AR_VALID<=0; AR_done<=0; inf.AR_ADDR<=0;
        //DRAM read (R)
        inf.R_READY<=0;  
        {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
    end
end

//Part 3 Seq Logic (要一起寫)
logic [2:0] EVAL_login_warn;
always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        //EVAL_login
        EVAL_login_warn<=0; EVAL_login_done<=0;
        //
    end
    else if(cur_state==EVAL_login)begin
        //case 0 no overflow
        if(Player_Info.Exp+512>65535 || Player_Info.MP+1024>65535)
        //case 1 overflow
        else begin
        end
    end
end
endmodule