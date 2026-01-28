`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;


class Type_and_mode;
    Training_Type f_type;
    Mode f_mode;
endclass

Type_and_mode fm_info = new();

//for spec 3
logic [1:0] train_type_q;

//train_type_q
always_ff @(posedge clk)begin 
    if(inf.type_valid==1) train_type_q<=inf.D.d_type[0];  
    else train_type_q<=train_type_q;
end

//coverage
//spec 1
covergroup cover_group_type_spec1
    @(posedge clk iff inf.type_valid);
    option.at_least = 200 ;     
    train_type: coverpoint inf.D.d_type[0] {
        bins train_type_bins[] = {2'd0, 2'd1, 2'd2, 2'd3};
    }
endgroup
cover_group_type_spec1 cover_group_type_spec1_inst =new();

//spec 2
covergroup cover_group_mode_spec2 
    @(posedge clk iff inf.mode_valid);
    option.at_least = 200 ;     
    mode: coverpoint inf.D.d_mode[0] {
        bins mode_bins[] = {2'd0, 2'd1, 2'd2};
    }
endgroup
cover_group_mode_spec2 cover_group_mode_spec2_inst =new();

//spec 3
covergroup cover_group_type_and_mode_spec3 
    @(posedge clk iff inf.mode_valid==1);
    option.at_least = 200 ;     
    train_type_spec3: coverpoint train_type_q {
        bins train_type_spec3_bins[] = {2'd0, 2'd1, 2'd2, 2'd3};
    }
    mode_spec3: coverpoint inf.D.d_mode[0] {
        bins mode_spec3_bins[] = {2'd0, 2'd1, 2'd2};
    }
    train_type_X_mode_spec3: cross train_type_spec3, mode_spec3;
endgroup
cover_group_type_and_mode_spec3 cover_group_type_and_mode_spec3_inst =new();

//spec 5 sel_action transition
covergroup cover_group_sel_action_spec5 
    @(posedge clk iff inf.sel_action_valid);
    option.at_least = 200;
    act_X_act: coverpoint inf.D.d_act[0] {
        bins act_X_act_bins[] = (3'h0,3'h1,3'h2,3'h3,3'h4=>3'h0,3'h1,3'h2,3'h3,3'h4);
    }
endgroup
cover_group_sel_action_spec5 cover_group_sel_action_spec5_inst =new();

//spec 4 player_no auto bin max
covergroup cover_group_player_no_spec4
    @(posedge clk iff inf.player_no_valid);
    option.at_least = 2 ;
    option.auto_bin_max = 256 ;
    player_no: coverpoint inf.D.d_player_no[0];
endgroup
cover_group_player_no_spec4 cover_group_player_no_spec4_inst =new();

//spec 6 MP list auto bin max
covergroup cover_group_mp_spec6
    @(posedge clk iff inf.MP_valid);
    option.at_least = 1 ;
    option.auto_bin_max = 32 ;
    mp: coverpoint inf.D.d_attribute[0];
endgroup
cover_group_mp_spec6 cover_group_mp_spec6_inst =new();

//spec 7 warn msg 5 kinds
covergroup cover_group_warnmsg_spec7 
    @(posedge clk iff inf.out_valid);
    option.at_least = 20 ;
    warnmsg: coverpoint inf.warn_msg {
        bins warnmsg_bins[] = {3'h0, 3'h1, 3'h2, 3'h3, 3'h4, 3'h5};
    }
endgroup
cover_group_warnmsg_spec7 cover_group_warnmsg_spec7_inst =new();


//1. All outputs signals should be zero after reset.
property SPEC_1_rst;
    @(posedge inf.rst_n) 1 |-> @(posedge clk) (inf.out_valid===0 && inf.complete===0 && inf.warn_msg===0 && inf.AR_VALID===0 && inf.AR_ADDR===0 && inf.R_READY===0 && inf.AW_VALID===0 && inf.AW_ADDR===0 && inf.W_VALID===0 && inf.W_DATA===0 && inf.B_READY===0);
endproperty

//2. Latency should be less than 1000 cycles for each operation.
property SPEC_2_login;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Login) ##[1:4] inf.date_valid ##[1:4] inf.player_no_valid |-> ##[1:999] inf.out_valid;
endproperty

property SPEC_2_levelup;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Level_Up) ##[1:4] inf.type_valid ##[1:4] inf.mode_valid ##[1:4] inf.player_no_valid |-> ##[1:999] inf.out_valid;
endproperty

property SPEC_2_battle;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Battle) ##[1:4] inf.player_no_valid ##[1:4] inf.monster_valid[->3] |-> ##[1:999] inf.out_valid;
endproperty

property SPEC_2_skill;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Use_Skill) ##[1:4] inf.player_no_valid ##[1:4] inf.MP_valid[->4] |-> ##[1:999] inf.out_valid;
endproperty

property SPEC_2_inactive;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Check_Inactive) ##[1:4] inf.date_valid ##[1:4] inf.player_no_valid |-> ##[1:999] inf.out_valid;
endproperty


//3. If action is completed (complete=1), err_msg should be 2'b0 (no_err).
property SPEC_3_warnmsg;
    @(negedge clk) ((inf.out_valid!==0) && (inf.complete===1)) |-> inf.warn_msg===No_Warn; 
endproperty


//4. Next input valid will be valid 1-4 cycles after previous input valid fall.
property SPEC_4_login;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Login) |-> ##[1:4] inf.date_valid  ##[1:4] inf.player_no_valid; 
endproperty

property SPEC_4_levelup;
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Level_Up) |-> ##[1:4] inf.type_valid ##[1:4] inf.mode_valid ##[1:4] inf.player_no_valid ; 
endproperty

property SPEC_4_battle;     
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Battle) |-> ##[1:4] inf.player_no_valid ##[1:4] inf.monster_valid ##[1:4] inf.monster_valid ##[1:4] inf.monster_valid; 
endproperty

property SPEC_4_skill;      
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Use_Skill) |-> ##[1:4] inf.player_no_valid ##[1:4] inf.MP_valid ##[1:4] inf.MP_valid ##[1:4] inf.MP_valid ##[1:4] inf.MP_valid; 
endproperty

property SPEC_4_inactive;   
    @(posedge clk) (inf.sel_action_valid===1 && inf.D.d_act[0]===Check_Inactive) |-> ##[1:4] inf.date_valid ##[1:4] inf.player_no_valid; 
endproperty

//5. All input valid signals won't overlap with each other.
property SPEC_5_sel_action_valid;
    @(posedge clk) (inf.sel_action_valid===1) |-> 
        !(inf.type_valid || inf.mode_valid || inf.date_valid || 
          inf.player_no_valid || inf.monster_valid || inf.MP_valid); 
endproperty

property SPEC_5_type_valid;
    @(posedge clk) (inf.type_valid===1) |-> 
        !(inf.sel_action_valid || inf.mode_valid || inf.date_valid || 
          inf.player_no_valid || inf.monster_valid || inf.MP_valid); 
endproperty

property SPEC_5_mode_valid;
    @(posedge clk) (inf.mode_valid===1) |-> 
        !(inf.sel_action_valid || inf.type_valid || inf.date_valid || 
          inf.player_no_valid || inf.monster_valid || inf.MP_valid); 
endproperty

property SPEC_5_date_valid;
    @(posedge clk) (inf.date_valid===1) |-> 
        !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || 
          inf.player_no_valid || inf.monster_valid || inf.MP_valid); 
endproperty

property SPEC_5_player_no_valid;
    @(posedge clk) (inf.player_no_valid===1) |-> 
        !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || 
          inf.date_valid || inf.monster_valid || inf.MP_valid); 
endproperty

property SPEC_5_monster_valid;
    @(posedge clk) (inf.monster_valid===1) |-> 
        !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || 
          inf.date_valid || inf.player_no_valid || inf.MP_valid); 
endproperty

property SPEC_5_MP_valid;
    @(posedge clk) (inf.MP_valid===1) |-> 
        !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || 
          inf.date_valid || inf.player_no_valid || inf.monster_valid); 
endproperty


//6. Out_valid can only be high for exactly one cycle.
property SPEC_6_outvalid;
    @(posedge clk) (inf.out_valid===1) |=> (inf.out_valid===0); 
endproperty

//7. Next operation will be valid 1-4 cycles after out_valid fall.
property SPEC_7_next_input;
    @(posedge clk) (inf.out_valid===1) ##(1) (inf.out_valid===0) |-> ##[0:3] (inf.sel_action_valid==1); 
endproperty

//8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
property SPEC_8_MON;
    @(posedge clk) (inf.date_valid===1) |-> inf.D.d_date[0].M inside {[1:12]}; 
endproperty

property SPEC_8_DAY;
    @(posedge clk)
    (inf.date_valid === 1) |->
        (
            (inf.D.d_date[0].M inside {1,3,5,7,8,10,12} &&
             inf.D.d_date[0].D inside {[1:31]}) ||

            (inf.D.d_date[0].M inside {4,6,9,11} &&
             inf.D.d_date[0].D inside {[1:30]}) ||

            (inf.D.d_date[0].M == 2 &&
             inf.D.d_date[0].D inside {[1:28]})
        );
endproperty

//9. AR_VALID signal should not overlap with the AW_VALID signal.  
property SPEC_9_AR_AW;
    @(posedge clk) !(inf.AR_VALID && inf.AW_VALID);
endproperty

//* assert -------------------------------------------------------------

// spec 1
assert property(SPEC_1_rst) else print_Assertion_spec1();

// spec 2
assert property(SPEC_2_login)   else print_Assertion_spec2();
assert property(SPEC_2_levelup) else print_Assertion_spec2();
assert property(SPEC_2_battle)  else print_Assertion_spec2();
assert property(SPEC_2_skill)   else print_Assertion_spec2();
assert property(SPEC_2_inactive)else print_Assertion_spec2();

// spec 3
assert property(SPEC_3_warnmsg) else print_Assertion_spec3();

// spec 4
assert property(SPEC_4_login)    else print_Assertion_spec4();
assert property(SPEC_4_levelup)  else print_Assertion_spec4();
assert property(SPEC_4_battle)   else print_Assertion_spec4();
assert property(SPEC_4_skill)    else print_Assertion_spec4();
assert property(SPEC_4_inactive) else print_Assertion_spec4();

// spec 5
assert property(SPEC_5_sel_action_valid)else print_Assertion_spec5();
assert property(SPEC_5_type_valid)      else print_Assertion_spec5();
assert property(SPEC_5_mode_valid)      else print_Assertion_spec5();
assert property(SPEC_5_monster_valid)   else print_Assertion_spec5();
assert property(SPEC_5_date_valid)      else print_Assertion_spec5();
assert property(SPEC_5_MP_valid)        else print_Assertion_spec5();
assert property(SPEC_5_player_no_valid) else print_Assertion_spec5();

// spec 6
assert property(SPEC_6_outvalid) else print_Assertion_spec6();

// spec 7
assert property(SPEC_7_next_input) else print_Assertion_spec7();

// spec 8
assert property(SPEC_8_MON) else print_Assertion_spec8();
assert property(SPEC_8_DAY) else print_Assertion_spec8();

// spec 9
assert property(SPEC_9_AR_AW) else print_Assertion_spec9();

//* display task
task print_Assertion_spec1;
    $display("                 ========================                     ");
    $display("                 Assertion 1 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec2;
    $display("                 ========================                     ");
    $display("                 Assertion 2 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec3;
    $display("                 ========================                     ");
    $display("                 Assertion 3 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec4;
    $display("                 ========================                     ");
    $display("                 Assertion 4 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec5;
    $display("                 ========================                     ");
    $display("                 Assertion 5 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec6;
    $display("                 ========================                     ");
    $display("                 Assertion 6 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec7;
    $display("                 ========================                     ");
    $display("                 Assertion 7 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec8;
    $display("                 ========================                     ");
    $display("                 Assertion 8 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
task print_Assertion_spec9;
    $display("                 ========================                     ");
    $display("                 Assertion 9 is violated                     ");
    $display("                 ========================                     ");
    $fatal;
endtask
endmodule