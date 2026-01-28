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
        //{plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
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

//Part 3 Seq Logic (要一起寫)
//EVAL_login
logic [2:0] EVAL_login_warn;
//EVAL_levelup
logic [2:0] EVAL_levelup_warn;

always_ff@(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
        //major signal
        {plyr_HP_q,plyr_mon_q,plyr_day_q,plyr_atk_q,plyr_def_q,plyr_EXP_q,plyr_MP_q}<=0;
        //EVAL_login (sat warn)
        EVAL_login_warn<=0; EVAL_login_done<=0;
        //EVAL_levelup
        EVAL_levelup_warn<=0; EVAL_levelup_done<=0;
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
            //case 0-0 no overflow
            if(Player_Info.Exp+512<=65535 && Player_Info.MP+1024<=65535)begin
                plyr_EXP_q<=plyr_EXP_q+512;
                plyr_MP_q<=plyr_MP_q+1024;
            end
            //case 0-1 overflow
            else begin
                EVAL_login_warn<=3'b101;    //sat warn
                if(Player_Info.Exp+512>65535)plyr_EXP_q<=65535;
                else plyr_EXP_q<=plyr_EXP_q+512;

                if(Player_Info.MP+1024>65535) plyr_MP_q<=65535;
                else plyr_MP_q<=plyr_MP_q+1024;
            end
        end
        //step 2 done
        EVAL_login_done<=1;
    end
    else if(cur_state==EVAL_levelup)begin
        //case 0 判定Exp 是否足夠
        if((mode_q==2'b00&&plyr_EXP_q<4095) || (mode_q==2'b01&&plyr_EXP_q<16383)
            || (mode_q==2'b10&&plyr_EXP_q<32767) && EVAL_levelup_done==1)begin 
            EVAL_levelup_warn<=3'b010; EVAL_levelup_done<=1;
        end
        //case 1 
        else if(EVAL_levelup_done==0)
        //case 2 
        else if(EVAL_levelup_done==0)
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

    // Stage 1
    // pairwise compare: (0,1), (2,3)
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

    // Stage 2
    // merge: (0,2) and (1,3)
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

    // Stage 3
    // middle adjustment: (1,2)
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