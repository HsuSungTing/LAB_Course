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