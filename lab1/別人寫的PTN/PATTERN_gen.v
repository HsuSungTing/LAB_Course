`define CYCLE_TIME 36.5

`ifdef RTL
	`define PATTERN_NUM 1
`endif
`ifdef GATE
	`define PATTERN_NUM 1
`endif

module PATTERN(
  // Output signals
    packets,
    channel_load,
    channel_capacity,
    KEY,
  // Input signals
    grant_channel 
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg [127:0] packets;
output reg  [11:0] channel_load;
output reg   [8:0] channel_capacity;
output reg  [63:0] KEY;

input [15:0] grant_channel;

//================================================================
// parameters & integer
//================================================================
integer SEED = 54871;
integer PATNUM = 52;
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
integer patcount;
integer PATNUM_FROM_FILE;
integer input_file, output_file;
integer k,i,j;

// Packet
parameter BIT_OF_PACKET = 16;
parameter NUM_OF_PACKET = 8;
// Channel
parameter BIT_OF_LOAD = 4;
parameter BIT_OF_CAP = 3;
parameter BIT_OF_CHANNEL = 2;
parameter NUM_OF_CHANNEL = 3;
parameter UNALLOCATED_CHANNEL = 3;
// Key
parameter BIT_OF_KEY = 64;
parameter BIT_OF_SUBKEY = 16;
parameter BIT_OF_GRANT = 2;

// Block
parameter BIT_OF_BLOCK = 32;
parameter NUM_OF_BLOCK = BIT_OF_PACKET*NUM_OF_PACKET/BIT_OF_BLOCK; // 4

// Round
parameter BIT_OF_ROR_IN_SUBKEY = 7;
parameter BIT_OF_ROR_IN_ENCRYPT = 7;
parameter BIT_OF_ROL_IN_ENCRYPT = 2;
parameter BIT_OF_ROR_IN_DECRYPT = 2;
parameter BIT_OF_ROL_IN_DECRYPT = 7;
parameter MODULO_NUM = 1 << 16;
parameter NUM_OF_ROUND = 4;
parameter NUM_OF_SUBKEY = BIT_OF_KEY/BIT_OF_SUBKEY; // 3

// String control
// Should use %0s
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";

//================================================================
// wire & registers 
//================================================================
reg [BIT_OF_PACKET-1:0] _original_packet  [0:NUM_OF_PACKET-1];
reg [BIT_OF_PACKET-1:0] _encrypted_packet [0:NUM_OF_PACKET-1];
reg [BIT_OF_PACKET-1:0] _decrypted_packet [0:NUM_OF_PACKET-1]; // Should be identical with _original_packet
reg [BIT_OF_LOAD-1:0] _channel_load[0:NUM_OF_CHANNEL-1];
reg [BIT_OF_CAP-1:0] _channel_cap  [0:NUM_OF_CHANNEL-1];
reg [BIT_OF_KEY-1:0] _KEY;

reg [BIT_OF_GRANT-1:0] golden_grant_channel[0:NUM_OF_PACKET-1];
reg [BIT_OF_GRANT*NUM_OF_PACKET-1:0] golden_grant_channel_combined;

// Calculation
reg[BIT_OF_SUBKEY-1:0] _subkeys[0:NUM_OF_SUBKEY-1]; // [0] --> lower 16bits from KEY

// Encryption Temp X and Y
reg[BIT_OF_SUBKEY-1:0] _encrypted_x[0:NUM_OF_BLOCK-1][0:NUM_OF_ROUND-1];
reg[BIT_OF_SUBKEY-1:0] _encrypted_y[0:NUM_OF_BLOCK-1][0:NUM_OF_ROUND-1];

// Decryption Temp X and Y
reg[BIT_OF_SUBKEY-1:0] _decrypted_x[0:NUM_OF_BLOCK-1][0:NUM_OF_ROUND-1];
reg[BIT_OF_SUBKEY-1:0] _decrypted_y[0:NUM_OF_BLOCK-1][0:NUM_OF_ROUND-1];

// Priority
integer _priority_score[0:NUM_OF_PACKET-1];
integer _sorted_packet_index[0:NUM_OF_PACKET-1];

// Allocation
reg[BIT_OF_CHANNEL-1:0] _allocation_channel[0:NUM_OF_PACKET-1];

// Mask
integer _mask_score[0:NUM_OF_PACKET-1];
integer _threshold[0:NUM_OF_PACKET-1];
reg _mask_mark[0:NUM_OF_PACKET-1]; // 1 : success, 0 : failed

// Global Balance
reg[BIT_OF_CHANNEL-1:0] _final_channel[0:NUM_OF_PACKET-1];
integer _total_channel_cap[0:NUM_OF_CHANNEL-1];
integer _total_channel_load[0:NUM_OF_CHANNEL-1];
reg[BIT_OF_CHANNEL-1:0] _rebalance_channel;
integer _rebalance_packet;
reg _rebalance_flag;

//================================================================
// clock
//================================================================
reg clk;
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
initial clk = 0;

//================================================================
// initial
//================================================================
initial begin
    file_initialization_task;

    repeat(5) @(negedge clk);

    // Directly debug
    display_full_seperator;
    $display("[INFO] Debug case");
    for(patcount=1; patcount<=2; patcount++) begin
        clear_all;
        if(patcount == 1) begin
            $display("[INFO] Debug ideal case from exercise pdf");
            debug_ideal_case_task;
        end
        else begin
            $display("[INFO] Debug ugly case from exercise pdf");
            debug_ugly_case_task;
        end
        calc_task(0);
        input_task;
        repeat(1) @(negedge clk);
        check_ans(0);
        repeat(2) @(negedge clk);
    end

    // From ta's file
    display_full_seperator;
    $display("[INFO] File case");
    for(patcount=0; patcount<PATNUM_FROM_FILE; patcount++) begin
        clear_all;
        get_input_file_task;
        calc_task(0);
        repeat(1) @(negedge clk);
        check_ans(0);
        repeat(2) @(negedge clk);
    end

    // Randomization
    display_full_seperator;
    $display("[INFO] Randomizaed case");
    for(patcount=0; patcount<PATNUM; patcount++) begin
        clear_all;
        random_task;
        calc_task(1);
        input_task;
        repeat(1) @(negedge clk);
        check_ans(1);
        repeat(2) @(negedge clk);
    end
    display_pass;
    repeat(3) @(negedge clk);
    display_full_seperator;
    $finish;
end

// ====================================
// Input
// ====================================
// File
task file_initialization_task; begin
    input_file=$fopen("../00_TESTBED/input.txt","r");
    output_file=$fopen("../00_TESTBED/output.txt","r");
    k = $fscanf(input_file, "%d", PATNUM_FROM_FILE);
end endtask

task debug_ideal_case_task; begin
    // Input
    _encrypted_packet[0] = 'h9a33;
    _encrypted_packet[1] = 'h791a;
    _encrypted_packet[2] = 'h3c2a;
    _encrypted_packet[3] = 'h524a;
    _encrypted_packet[4] = 'h5495;
    _encrypted_packet[5] = 'h4527;
    _encrypted_packet[6] = 'h5cd2;
    _encrypted_packet[7] = 'he040;

    _channel_load[0] = 'h2;
    _channel_load[1] = 'h7;
    _channel_load[2] = 'hd;

    _channel_cap[0] = 'h4;
    _channel_cap[1] = 'h4;
    _channel_cap[2] = 'h6;

    _KEY = 'he750_3a4f_51c0_bb1a;

    // Output
    golden_grant_channel[0] = 'd0;
    golden_grant_channel[1] = 'd0;
    golden_grant_channel[2] = 'd1;
    golden_grant_channel[3] = 'd1;
    golden_grant_channel[4] = 'd2;
    golden_grant_channel[5] = 'd2;
    golden_grant_channel[6] = 'd1;
    golden_grant_channel[7] = 'd2;
end endtask

task debug_ugly_case_task; begin
    // Input
    _encrypted_packet[0] = 'hc1e5;
    _encrypted_packet[1] = 'h56ac;
    _encrypted_packet[2] = 'h164a;
    _encrypted_packet[3] = 'h06fb;
    _encrypted_packet[4] = 'heee6;
    _encrypted_packet[5] = 'h8f3b;
    _encrypted_packet[6] = 'h5a15;
    _encrypted_packet[7] = 'h5649;

    _channel_load[0] = 'hd;
    _channel_load[1] = 'h1;
    _channel_load[2] = 'h8;

    _channel_cap[0] = 'h4;
    _channel_cap[1] = 'h0;
    _channel_cap[2] = 'h3;

    _KEY = 'haeee_bd3c_30ab_f5ae;

    // Output
    golden_grant_channel[0] = 'd2;
    golden_grant_channel[1] = 'd3;
    golden_grant_channel[2] = 'd3;
    golden_grant_channel[3] = 'd3;
    golden_grant_channel[4] = 'd3;
    golden_grant_channel[5] = 'd2;
    golden_grant_channel[6] = 'd3;
    golden_grant_channel[7] = 'd2;
end endtask

task get_input_file_task; begin
    for ( i = 0; i < 15; i++) begin
        if(i < 8)
            k = $fscanf(input_file, "%h", _encrypted_packet[i]);
        else if(i < 9)
            k = $fscanf(input_file, "%h", _KEY);
        else if(i < 12)
            k = $fscanf(input_file, "%h", _channel_load[i-9]);
        else
            k = $fscanf(input_file, "%h", _channel_cap[i-12]);
    end
    

    packets = {_encrypted_packet[7], _encrypted_packet[6], _encrypted_packet[5], _encrypted_packet[4], 
                _encrypted_packet[3], _encrypted_packet[2], _encrypted_packet[1], _encrypted_packet[0]};
    
    KEY = _KEY;

    channel_load = {_channel_load[2], _channel_load[1], _channel_load[0]};

    channel_capacity = {_channel_cap[2], _channel_cap[1], _channel_cap[0]};

    for ( i = 0; i < 8; i++) begin
        k = $fscanf(output_file, "%h", golden_grant_channel[i]);
    end
end endtask

task calc_task;
    input is_encryption;
begin
    gen_subkey_task;
    if(is_encryption)
        encrypt_packet_task;
    decrypt_packet_task;
    calc_priority_score_task;
    allocate_channel_task;
    calc_mask_task;
    rebalance_task(is_encryption);
end endtask

task input_task; begin

    packets = {_encrypted_packet[7], _encrypted_packet[6], _encrypted_packet[5], _encrypted_packet[4], 
                _encrypted_packet[3], _encrypted_packet[2], _encrypted_packet[1], _encrypted_packet[0]};
    
    KEY = _KEY;

    channel_load = {_channel_load[2], _channel_load[1], _channel_load[0]};

    channel_capacity = {_channel_cap[2], _channel_cap[1], _channel_cap[0]};

end endtask

// ====================================
// Check
// ====================================
task check_ans;
    input is_encryption;
begin
    if(is_encryption == 0) begin
        golden_grant_channel_combined = {golden_grant_channel[7],golden_grant_channel[6], golden_grant_channel[5], golden_grant_channel[4],
                                            golden_grant_channel[3],golden_grant_channel[2], golden_grant_channel[1], golden_grant_channel[0]};
    end
    else begin
        golden_grant_channel_combined = {_final_channel[7],_final_channel[6], _final_channel[5], _final_channel[4],
                                            _final_channel[3],_final_channel[2], _final_channel[1], _final_channel[0]};
    end
    if (grant_channel !== golden_grant_channel_combined) begin
        display_full_seperator;
        display_input_info;
        if(is_encryption) begin
            display_full_seperator;
            display_encryption;
        end
        display_full_seperator;
        display_decryption;
        display_full_seperator;
        display_process;
        display_full_seperator;
        $display("[ERROR] PATTERN NO.%4d", patcount);
        $display("[Your Grant Channel] : %4h", grant_channel);
        $display("[Your Grant Channel] : %16b", grant_channel);
        for(i=0 ; i<NUM_OF_PACKET ; i++) begin
            $display("  [#%2d] : %2b", i, grant_channel[(i*2)+:2]);
        end
        $write("\n");
        $display("[Gold Grant Channel] : %4h", golden_grant_channel_combined);
        $display("[Gold Grant Channel] : %16b", golden_grant_channel_combined);
        for(i=0 ; i<NUM_OF_PACKET ; i++) begin
            $display("  [#%2d] : %2b", i, golden_grant_channel_combined[(i*2)+:2]);
        end
        $write("\n");
        display_full_seperator;
        #(200);
        $finish;
    end
    else begin
        $display("%0sPASS PATTERN NO.%4d %0s",txt_blue_prefix, patcount, reset_color);
    end
end endtask

// ====================================
// Calculation
// ====================================
task clear_all; begin
    // Input
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _original_packet[i] = 'dx;
        _encrypted_packet[i] = 'dx;
        _decrypted_packet[i] = 'dx;
    end
    for(i=0 ; i<NUM_OF_CHANNEL ; i++) begin
        _channel_load[i] = 'dx;
        _channel_cap[i] = 'dx;
    end
    _KEY = 'dx;

    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        golden_grant_channel[i] = 'dx;
    end
    golden_grant_channel_combined = 'dx;

    // Calculation
    for(i=0 ; i<NUM_OF_SUBKEY ; i++) begin
        _subkeys[i] = 'dx;
    end

    // Encryption Temp X and Y
    for(i=0 ; i<NUM_OF_BLOCK ; i++) begin
        for(j=0 ; i<NUM_OF_ROUND ; i++) begin
            _encrypted_x[i][j] = 'dx;
            _encrypted_y[i][j] = 'dx;
        end
    end

    // Decryption Temp X and Y
    for(i=0 ; i<NUM_OF_BLOCK ; i++) begin
        for(j=0 ; i<NUM_OF_ROUND ; i++) begin
            _decrypted_x[i][j] = 'dx;
            _decrypted_y[i][j] = 'dx;
        end
    end

    // Priority
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _priority_score[i] = 'dx;
        _sorted_packet_index[i] = 'dx;
    end

    // Allocation
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _allocation_channel[i] = 'dx;
    end

    // Mask
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _mask_score[i] = 'dx;
        _threshold[i] = 'dx;
        _mask_mark[i] = 'dx;
    end


    // Global Balance
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _final_channel[i] = 'dx;
    end
    for(i=0 ; i<NUM_OF_CHANNEL ; i++) begin
        _total_channel_cap[i] = 'dx;
        _total_channel_load[i] = 'dx;
    end
    _rebalance_channel = 'dx;
    _rebalance_packet = 'dx;
    _rebalance_flag = 'dx;
end endtask;

task random_task;
    integer key_temp1;
    integer key_temp2;
begin
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _original_packet[i] = $random(SEED) & ((1 << BIT_OF_PACKET) - 1);
        _original_packet[i][6:5] = 2'($urandom_range(0, 2));
    end

    for(i=0 ; i<NUM_OF_CHANNEL ; i++) begin
        _channel_load[i] = $random(SEED) & ((1 << BIT_OF_LOAD) - 1);
        _channel_cap[i] = $random(SEED) & ((1 << BIT_OF_CAP) - 1);
    end

    key_temp1 = $random(SEED);
    key_temp2 = $random(SEED);
    _KEY = {key_temp1, key_temp2};
end endtask

task gen_subkey_task;
    reg[BIT_OF_SUBKEY-1:0] previous_key;
begin
    _subkeys[0] = _KEY[0+:BIT_OF_SUBKEY];
    previous_key = _subkeys[0];
    for(i=0 ; i<NUM_OF_SUBKEY-1 ; i++) begin
        _subkeys[i+1] = ((ROR_16bits(previous_key, BIT_OF_ROR_IN_SUBKEY) + 
            _KEY[(i+1)*BIT_OF_SUBKEY+:BIT_OF_SUBKEY]) % MODULO_NUM) ^ i;
        previous_key = _subkeys[i+1];
    end
end endtask

task encrypt_packet_task;
    reg[BIT_OF_SUBKEY-1:0] previous_x;
    reg[BIT_OF_SUBKEY-1:0] previous_y;
begin
    for(i=0 ; i<NUM_OF_BLOCK ; i++) begin
        // TODO : parameterize (not urgent)
        previous_x = _original_packet[i*2];
        previous_y = _original_packet[i*2+1];
        for(j=0 ; j<NUM_OF_ROUND ; j++) begin
            _encrypted_x[i][j] = ((ROR_16bits(previous_x, BIT_OF_ROR_IN_ENCRYPT) + $unsigned(previous_y)) % MODULO_NUM) ^_subkeys[j];
            _encrypted_y[i][j] = (ROL_16bits(previous_y, BIT_OF_ROL_IN_ENCRYPT)) ^ _encrypted_x[i][j];

            previous_y = _encrypted_y[i][j];
            previous_x = _encrypted_x[i][j];
        end
        _encrypted_packet[i*2] = previous_x;
        _encrypted_packet[i*2+1] = previous_y;
    end
end endtask

task decrypt_packet_task;
    reg[BIT_OF_SUBKEY-1:0] previous_x;
    reg[BIT_OF_SUBKEY-1:0] previous_y;
begin
    for(i=0 ; i<NUM_OF_BLOCK ; i++) begin
        // TODO : parameterize (not urgent)
        previous_x = _encrypted_packet[i*2];
        previous_y = _encrypted_packet[i*2+1];
        for(j=NUM_OF_ROUND-1 ; j>=0 ; j--) begin
            _decrypted_y[i][j] = (ROR_16bits(previous_y^previous_x, BIT_OF_ROR_IN_DECRYPT));
            _decrypted_x[i][j] = (ROL_16bits(($unsigned(previous_x^_subkeys[j]) - $unsigned(_decrypted_y[i][j])), BIT_OF_ROL_IN_DECRYPT)) % MODULO_NUM;

            previous_y = _decrypted_y[i][j];
            previous_x = _decrypted_x[i][j];
        end
        _decrypted_packet[i*2] = previous_x;
        _decrypted_packet[i*2+1] = previous_y;
    end
end endtask

task calc_priority_score_task;
    integer count;
    integer tmp;
begin
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        _priority_score[i] = get_priority_score(_decrypted_packet[i]);
        _sorted_packet_index[i] = i;
    end

    // Get the req_valid = 1
    count = 0;
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        if(_decrypted_packet[i][15] == 1) begin
            _sorted_packet_index[count] = i;
            count++;
        end
    end

    // Append the req_valid = 0
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        if(_decrypted_packet[i][15] == 0) begin
            _sorted_packet_index[count] = i;
            count++;
        end
    end

    for (i=0; i<NUM_OF_PACKET; i++) begin
        for (j=0; j<NUM_OF_PACKET-1-i; j++) begin
            if (_decrypted_packet[_sorted_packet_index[j]][15] && _decrypted_packet[_sorted_packet_index[j+1]][15]) begin
                if (_priority_score[_sorted_packet_index[j]] < _priority_score[_sorted_packet_index[j+1]] ||
                    (_priority_score[_sorted_packet_index[j]] == _priority_score[_sorted_packet_index[j+1]] &&
                    _sorted_packet_index[j] > _sorted_packet_index[j+1])) begin
                    tmp = _sorted_packet_index[j];
                    _sorted_packet_index[j] = _sorted_packet_index[j+1];
                    _sorted_packet_index[j+1] = tmp;
                end
            end
        end
    end
end endtask;

task allocate_channel_task;
    integer sub_index;
    reg[BIT_OF_CHANNEL-1:0] selected_channel;
    integer channel_to_count[0:NUM_OF_CHANNEL-1];
    reg[BIT_OF_CHANNEL-1:0] pivot;
    reg[BIT_OF_CHANNEL-1:0] fallback_list[0:NUM_OF_CHANNEL-1];
    reg is_succed;
    reg break_flg;
begin
    for (i=0; i<NUM_OF_PACKET; i++) begin
        _allocation_channel[i] = UNALLOCATED_CHANNEL;
    end
    for (i=0; i<NUM_OF_CHANNEL; i++) begin
        channel_to_count[i] = 0;
    end
    pivot = 'dx;
    is_succed = 'dx;
    for (i=0; i<NUM_OF_PACKET; i++) begin
        sub_index = _sorted_packet_index[i];
        if(_decrypted_packet[sub_index][15]) begin
            selected_channel = _decrypted_packet[sub_index][6:5];
            if(channel_to_count[selected_channel] < _channel_cap[selected_channel]) begin
                channel_to_count[selected_channel]++;
                _allocation_channel[sub_index] = selected_channel;
            end
            else begin
                // Select pivot
                if(pivot === 2'dx) begin
                    pivot = selected_channel;
                end
                else if(is_succed === 1) begin
                    pivot = (fallback_list[0]+1) % NUM_OF_CHANNEL;
                end
                else if(is_succed === 0) begin
                    pivot = (fallback_list[0]+2) % NUM_OF_CHANNEL;
                end
                // Fallback list based on pivot
                for (j=0; j<NUM_OF_CHANNEL; j++) begin
                    fallback_list[j] = (pivot+j) % NUM_OF_CHANNEL;
                end
                // Allocate
                break_flg = 0;
                is_succed = 0;
                for (j=0; j<NUM_OF_CHANNEL; j++) begin
                    selected_channel = fallback_list[j];
                    if(break_flg == 0) begin
                        if(channel_to_count[selected_channel] < _channel_cap[selected_channel]) begin
                            channel_to_count[selected_channel]++;
                            _allocation_channel[sub_index] = selected_channel;
                            break_flg = 1;
                            is_succed = 1;
                        end
                    end
                end
            end
        end
    end
end endtask;

task calc_mask_task; begin
    for (i=0; i<NUM_OF_PACKET; i++) begin
        _mask_score[i] = get_mask_score(_priority_score[i], _decrypted_packet[i], _allocation_channel[i]);
        _threshold[i] = 7 + (_channel_load[_allocation_channel[i]] / 3);
        _mask_mark[i] = _mask_score[i] < _threshold[i] ? 1 : 0;
    end
end endtask;

task rebalance_task;
    input is_encryption;
    reg[BIT_OF_CHANNEL-1:0] selected_channel;
    integer max_channel_load;
    integer max_channel;
    integer other_sum;

    integer selected_index;
    integer break_flg;

    reg[BIT_OF_CHANNEL-1:0] new_channel;
begin
    for (i=0; i<NUM_OF_CHANNEL; i++) begin
        _total_channel_load[i] = _channel_load[i];
        _total_channel_cap[i] = 0;
    end
    for (i=0; i<NUM_OF_PACKET; i++) begin
        selected_channel = _allocation_channel[i];
        _final_channel[i] = _allocation_channel[i];
        _total_channel_load[selected_channel]++;
        _total_channel_cap[selected_channel]++;
    end

    // Check if max channel is balanced or not
    max_channel_load = -1;
    max_channel = -1;
    for (i=0; i<NUM_OF_CHANNEL; i++) begin
        if (_total_channel_load[i] > max_channel_load) begin
            max_channel_load = _total_channel_load[i];
            max_channel      = i;
        end
    end

    other_sum = 0;
    for (i=0; i<NUM_OF_CHANNEL; i++) begin
        if (i != max_channel) begin
            other_sum = other_sum + _total_channel_load[i];
        end
    end
    _rebalance_channel = _total_channel_load[max_channel] > (other_sum/2) ? max_channel : 'dx;
    _rebalance_flag = _total_channel_load[max_channel] > (other_sum/2) ? 1 : 0;

    // Find the lowest rank packet to be balanced
    break_flg = 0;
    for (i=NUM_OF_PACKET-1; i>=0; i--) begin
        selected_index = _sorted_packet_index[i];
        if(break_flg == 0 &&
            _final_channel[selected_index] == _rebalance_channel &&
            _mask_mark[selected_index] == 1) begin
            _rebalance_packet = selected_index;
            break_flg = 1;
        end
    end

    // Rebalance
    break_flg = 0;
    for(i=1 ; i<NUM_OF_CHANNEL ; i++) begin
        new_channel = (_final_channel[_rebalance_packet]+i) % NUM_OF_CHANNEL;
        if (break_flg == 0 &&
            (_total_channel_cap[new_channel]+1) <= _channel_cap[new_channel] &&
            (_total_channel_load[new_channel]+1) < 2**BIT_OF_LOAD) begin // load < 16
            _final_channel[_rebalance_packet] = new_channel;
            break_flg = 1;
        end
    end
    // Drop the channel if the rebalancing is failed
    if(break_flg == 0) begin
        _final_channel[_rebalance_packet] = NUM_OF_CHANNEL;
    end

    // Set to golden
    if(is_encryption) begin
        for(i=0 ; i<NUM_OF_PACKET ; i++) begin
            golden_grant_channel[i] = _final_channel[i];
        end
    end
end endtask;

// ====================================
// Display
// ====================================
task display_input_info; begin
    $display("%0s[Input]%0s\n", txt_green_prefix, reset_color);

    $display("%0s[Encrypted Packets (True Input)]%0s\n", txt_green_prefix, reset_color);
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        $display("[#%2d] %4h (%5d)", i, _encrypted_packet[i], _encrypted_packet[i]);
    end
    $write("\n");

    $display("%0s[Channel Info]%0s\n", txt_green_prefix, reset_color);
    for(i=0 ; i<NUM_OF_CHANNEL ; i++) begin
        $display("[#%2d] Load : %5d", i, _channel_load[i]);
        $display("[#%2d] Cap  : %5d", i, _channel_cap[i]);
    end
    $write("\n");

    $display("%0s[Key]%0s : %16h (%-d)\n", txt_green_prefix, reset_color, _KEY, _KEY);
end endtask

task display_encryption; begin
    $display("%0s[Encryption]%0s\n", txt_yellow_prefix, reset_color);

    $display("%0s[Subkey]%0s\n", txt_yellow_prefix, reset_color);
    for(i=0 ; i<NUM_OF_SUBKEY ; i++) begin
        $display("[#%2d] %4h (%5d)", i, _subkeys[i], _subkeys[i]);
    end
    $write("\n");

    $display("%0s[Steps from encryption]%0s\n", txt_yellow_prefix, reset_color);
    for(i=0 ; i<NUM_OF_BLOCK ; i++) begin
        $display("[#%2d Block] from original {%4h, %4h}", i, _original_packet[i*2+1], _original_packet[i*2]);
        for(j=0 ; j<NUM_OF_ROUND ; j++) begin
            $display("  [#%2d Round] (y, x) -> (%4h %4h)", j, _encrypted_y[i][j], _encrypted_x[i][j]);
        end
    end
    $write("\n");
end endtask;

task display_decryption; begin
    $display("%0s[Decryption]%0s\n", txt_red_prefix, reset_color);

    $display("%0s[Subkey]%0s\n", txt_red_prefix, reset_color);
    for(i=0 ; i<NUM_OF_SUBKEY ; i++) begin
        $display("[#%2d] %4h (%5d)", i, _subkeys[i], _subkeys[i]);
    end
    $write("\n");

    $display("%0s[Original Packets]%0s\n", txt_red_prefix, reset_color);
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        $display("[#%2d] %4h (%5d)", i, _original_packet[i], _original_packet[i]);
    end
    $write("\n");

    $display("%0s[Decrypted Packets (Should be same as the original packets]%0s\n", txt_red_prefix, reset_color);
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        $display("[#%2d] %4h (%5d)", i, _decrypted_packet[i], _decrypted_packet[i]);
    end
    $write("\n");

    $display("%0s[Steps from decryption]%0s\n", txt_red_prefix, reset_color);
    for(i=0 ; i<NUM_OF_BLOCK ; i++) begin
        $display("[#%2d Block] from encrypted {%4h, %4h}", i, _encrypted_packet[i*2+1], _encrypted_packet[i*2]);
        for(j=NUM_OF_ROUND-1 ; j>=0 ; j--) begin
            $display("  [#%2d Round] (y, x) -> (%4h %4h)", j, _decrypted_y[i][j], _decrypted_x[i][j]);
        end
    end
    $write("\n");
end endtask;

task display_process;
    integer sub_index;
begin
    $display("%0s[Process]%0s\n", txt_blue_prefix, reset_color);

    $display("%0s[Priority Score]%0s\n", txt_blue_prefix, reset_color);
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        $display("[#%2d Packet] : %-d", i, _priority_score[i]);
    end
    $write("\n");
    $display("%0s[Sorted Index Table]%0s\n", txt_blue_prefix, reset_color);
    $display("[rank / packet / priority score / req_valid / prefer_channel ]");
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        sub_index = _sorted_packet_index[i];
        $display("[#%2d #%2d / %5d / %1d / %1d ]",
            i, sub_index, _priority_score[sub_index],
            _decrypted_packet[sub_index][15], _decrypted_packet[sub_index][6:5]);
    end
    $write("\n");
    $display("%0s[Original Index Table]%0s\n", txt_blue_prefix, reset_color);
    $display("[ packet / priority score / req_valid / allocation channel ]");
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        $display("[#%2d / %5d / %1d / %1d ]",
            i, _priority_score[i], _decrypted_packet[i][15], _allocation_channel[i]);
    end
    $write("\n");

    display_full_seperator;

    $display("%0s[Mask Score]%0s\n", txt_blue_prefix, reset_color);
    $display("%0s[Sorted Index Table]%0s\n", txt_blue_prefix, reset_color);
    $display("[ rank / packet / mask score / threshold / mark]");
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        sub_index = _sorted_packet_index[i];
        if(_mask_mark[sub_index])
            $display("[#%2d #%2d / %5d / %2d / success]", i, sub_index, _mask_score[sub_index], _threshold[sub_index]);
        else
            $display("[#%2d #%2d / %5d / %2d / failed ]", i, sub_index, _mask_score[sub_index], _threshold[sub_index]);
    end
    $write("\n");
    $display("%0s[Original Index Table]%0s\n", txt_blue_prefix, reset_color);
    $display("[ packet / mask score / threshold / mark]");
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        if(_mask_mark[i])
            $display("[#%2d / %5d / %2d / success]", i, _mask_score[i], _threshold[i]);
        else
            $display("[#%2d / %5d / %2d / failed ]", i, _mask_score[i], _threshold[i]);
    end
    $write("\n");

    display_full_seperator;

    $display("%0s[Total Channel Count]%0s\n", txt_blue_prefix, reset_color);
    for(i=0 ; i<NUM_OF_CHANNEL ; i++) begin
        $display("[#%2d] : %2d", i, _total_channel_cap[i]);
    end
    $write("\n");

    $display("%0s[Total Channel Load]%0s\n", txt_blue_prefix, reset_color);
    for(i=0 ; i<NUM_OF_CHANNEL ; i++) begin
        $display("[#%2d] : %2d", i, _total_channel_load[i]);
    end
    $write("\n");

    $display("%0s[Rebalanced Channel]%0s : %1d\n", txt_blue_prefix, reset_color, _rebalance_channel);
    $display("%0s[Rebalanced Packet ]%0s : %1d\n", txt_blue_prefix, reset_color, _rebalance_packet);
    $display("%0s[Rebalanced Flag]%0s : %1d\n", txt_blue_prefix, reset_color, _rebalance_flag);

    $display("%0s[Final Channel]%0s\n", txt_blue_prefix, reset_color);
    $display("%0s[Sorted Index Table]%0s\n", txt_blue_prefix, reset_color);
    $display("[ rank / packet / grant channel ]");
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        sub_index = _sorted_packet_index[i];
        $display("[#%2d / %5d / %1d ]",
            i, sub_index, _final_channel[sub_index]);
    end
    $write("\n");

    $display("%0s[Original Index Table]%0s\n", txt_blue_prefix, reset_color);
    $display("[ packet / grant channel ]");
    for(i=0 ; i<NUM_OF_PACKET ; i++) begin
        $display("[#%2d / %1d ]",
            i, _final_channel[i]);
    end
    $write("\n");

end endtask


task display_pass; begin
    display_full_seperator;
    $system("cols=`tput cols`; half=$((cols/2-6)); printf '%*sSuccess\\n' $half ''");
    display_full_seperator;
end endtask

// Operation Utility
function [15:0] ROR_16bits;
    input[15:0] data;
    input integer n;
begin
    ROR_16bits = (data >> n) | (data << (16 - n));
end
endfunction

function [15:0] ROL_16bits;
    input reg[15:0] data;
    input integer n;
begin
    ROL_16bits = (data << n) | (data >> (16 - n));
end
endfunction

function integer get_priority_score;
    input reg[BIT_OF_PACKET-1:0] in_packet;
    integer qos;
    integer pkt_len;
    integer congestion;
    integer src_hint;
    integer qos_signed;
    integer pkt_len_signed;
    integer congestion_signed;
    integer src_hint_signed;
begin
    qos_signed        = $signed(in_packet[14:13]);
    pkt_len_signed    = $signed(in_packet[12:9]);
    congestion_signed = $signed(in_packet[8:7]);
    src_hint_signed   = $signed(in_packet[4:2]);
    qos        = in_packet[1] ? qos_signed        : in_packet[14:13];
    pkt_len    = in_packet[1] ? pkt_len_signed    : in_packet[12:9];
    congestion = in_packet[1] ? congestion_signed : in_packet[8:7];
    src_hint   = in_packet[1] ? src_hint_signed   : in_packet[4:2];
    get_priority_score = in_packet[1] ?
        ($signed(qos)-2)*4 + ($signed(pkt_len)-8)*(-2) + (1-$signed(congestion))*3 + ($signed(src_hint)-4) :
        (qos-2)*4 + (pkt_len-8)*(-2) + (1-congestion)*3 + (src_hint-4);
end
endfunction

function integer get_mask_score;
    input integer priority_score;
    input reg[BIT_OF_PACKET-1:0] in_packet;
    input reg[BIT_OF_CHANNEL-1:0] allocated_channel;
begin
    get_mask_score = ((priority_score & 'd6) + in_packet[6:5] + (in_packet[4:2] ^ 'd3) + _channel_load[allocated_channel]) % 10;
end
endfunction

// Display Unitlity
task display_full_seperator; begin
    // Full
    $system("printf '%*s\\n' `tput cols` '' | tr ' ' '='");
    // Half
    // $system("cols=`tput cols`; half=$((cols/2-6)); printf '%*s\\n' $half ''");
end endtask

endmodule