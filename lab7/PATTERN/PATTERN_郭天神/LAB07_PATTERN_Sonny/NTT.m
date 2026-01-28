close all; clear; clc;
%% NTT 128
%{
this MATLAB code is for ICLAB 2025_fall LAB07

SOME VARIABLE DECLARATION:
#########################################################
x_org: 
    original random x
#########################################################
x_golden: 
    each stage answer, x_golden(:, 1) = x_org,
x_golden(:,2) = stage1_ans, x_golden(:,3) = stage2_ans, ...
x_golden(:,8) = final_answer.
#########################################################
x_hardware: 
    validation for hardware algorithm with pseudo code
#########################################################
validation: 
    does x_golden match x_hardware with each stage?
#########################################################
PATTERN_NUM: 
    how much pattern you want
#########################################################
DEBUG_YES: 
    if DEBUG_YES == 1, you can type your own input in line 36
    else, x will be random number in 0:16
%}
%% some parameter
GMB = readtable("GMb.txt");
GMB = table2array(GMB);
QOI = 12287;
Q = 12289;
PATTERN_NUM = 100;
DEBUG_YES = 0;
%% FILE OPEN
NTT_file_input = fopen("NTT_input.txt", "w");
NTT_file_golden = fopen("NTT_golden_ans.txt", "w");
%% START LOOP
for cur_pat = 1:PATTERN_NUM
    %% some input setting
    if(DEBUG_YES)
        x_org = [];
    else
        % you can add some corner case in here if you want
        x_org = randi([0 15], 128, 1 );
    end
    
    x_golden = x_org;
    x = x_org;
    %% file I/O for input
    fprintf(NTT_file_input, "PATTERN: %d \n", cur_pat);
    for i = 1:128
        fprintf(NTT_file_input, "%d \n", x_org(i));
    end
    %% main calculation for golden answer
    t = 128;
    % pseudo code from .pdf
    for m = [1, 2, 4, 8, 16, 32, 64]
        ht = t/2;
        j1 = 1;
        for i = 1:m
            % disp(j1);
            % disp(['m+i = ', num2str(m+i)])
            s = GMB(m+i);
            j2 = j1+ht;
            for j = j1:j2-1
                % disp(['j = ', num2str(j)])
                % disp(['j+ht = ', num2str(j+ht)])
                u = x(j);
                v = modq_mul(x(j+ht), s);
                x(j) = mod(u+v, Q);
                x(j+ht) = mod(u-v, Q);
            end
            j1 = j1+t;
        end
        x_golden = [x_golden x];
        t = ht;
    end
    %% Hardware algorithm validation
    x_hardware = zeros(128, 8);
    x_hardware(:, 1) = x_org;
    % with 64
    ht = 64;
    stage = 1;
    count_i = 2;
    s = GMB(count_i);
    for m = 1:ht
        u = x_hardware(m, stage);
        v = modq_mul(x_hardware(m+ht, stage), s);
        x_hardware(m, stage+1) = mod(u+v, Q);
        x_hardware(m+ht, stage+1) = mod(u-v, Q);
    end
    
    % with 32
    ht = 32;
    stage = 2;
    count_i = count_i + 1;
    s = GMB(count_i);
    for m = 1:ht
        u = x_hardware(m, stage);
        v = modq_mul(x_hardware(m+ht, stage), s);
        x_hardware(m, stage+1) = mod(u+v, Q);
        x_hardware(m+ht, stage+1) = mod(u-v, Q);
    end
    count_i = count_i + 1;
    s = GMB(count_i);
    for m = 65:65+ht-1
        u = x_hardware(m, stage);
        v = modq_mul(x_hardware(m+ht, stage), s);
        x_hardware(m, stage+1) = mod(u+v, Q);
        x_hardware(m+ht, stage+1) = mod(u-v, Q);
    end
    
    % with 16
    ht = 16;
    stage = 3;
    for iii = 1:ht*2:127
        count_i = count_i + 1;
        s = GMB(count_i);
        % disp(iii)
        for m = iii:iii+ht-1
            % disp(m)
            % disp(m+ht)
            u = x_hardware(m, stage);
            v = modq_mul(x_hardware(m+ht, stage), s);
            x_hardware(m, stage+1) = mod(u+v, Q);
            x_hardware(m+ht, stage+1) = mod(u-v, Q);
        end
    end
    % with 8
    ht = 8;
    stage = 4;
    for iii = 1:ht*2:127
        count_i = count_i + 1;
        s = GMB(count_i);
        % disp(iii)
        for m = iii:iii+ht-1
            % disp(m)
            % disp(m+ht)
            u = x_hardware(m, stage);
            v = modq_mul(x_hardware(m+ht, stage), s);
            x_hardware(m, stage+1) = mod(u+v, Q);
            x_hardware(m+ht, stage+1) = mod(u-v, Q);
        end
    end
    % with 4
    ht = 4;
    stage = 5;
    for iii = 1:ht*2:127
        count_i = count_i + 1;
        s = GMB(count_i);
        % disp(iii)
        for m = iii:iii+ht-1
            % disp(m)
            % disp(m+ht)
            u = x_hardware(m, stage);
            v = modq_mul(x_hardware(m+ht, stage), s);
            x_hardware(m, stage+1) = mod(u+v, Q);
            x_hardware(m+ht, stage+1) = mod(u-v, Q);
        end
    end
    % with 2
    ht = 2;
    stage = 6;
    for iii = 1:ht*2:127
        count_i = count_i + 1;
        s = GMB(count_i);
        % disp(iii)
        for m = iii:iii+ht-1
            % disp(m)
            % disp(m+ht)
            u = x_hardware(m, stage);
            v = modq_mul(x_hardware(m+ht, stage), s);
            x_hardware(m, stage+1) = mod(u+v, Q);
            x_hardware(m+ht, stage+1) = mod(u-v, Q);
        end
    end
    % with 1
    ht = 1;
    stage = 7;
    for iii = 1:ht*2:127
        count_i = count_i + 1;
        s = GMB(count_i);
        % disp(iii)
        for m = iii:iii+ht-1
            % disp(m)
            % disp(m+ht)
            u = x_hardware(m, stage);
            v = modq_mul(x_hardware(m+ht, stage), s);
            x_hardware(m, stage+1) = mod(u+v, Q);
            x_hardware(m+ht, stage+1) = mod(u-v, Q);
        end
    end
    
    
    
    %% Build in self testing
    validation = x_golden == x_hardware;
    if(any(~validation))
        disp('ERROR: there are some thing wrong!!!');
    else
        disp(['Success: Pass pattern ' num2str(cur_pat)]);
    end
    %% file I/O for output
    fprintf(NTT_file_golden, "PATTERN: %d \n", cur_pat);
    for i = 1:128
        fprintf(NTT_file_golden, "%d \n", x_golden(i, 8));
    end
%% END LOOP
end

%% FILE CLOSE
fclose(NTT_file_input);
fclose(NTT_file_golden);
%% function declaration
function z = modq_mul(a,b)
    QOI = 12287;
    Q = 12289;
    R = 2^16;
    x = a*b;
    y = mod((x*QOI), R);
    z = floor((x+y*Q)/R);

    if(z >= Q)  z = z-Q;
    else        z = z;
    end
end
