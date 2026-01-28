module allocate_pkt(
    input  [1:0] prefer_chl,
    input        req_valid,
    input  [1:0] cur_pivot,
    input  [2:0] chl_0_cap, chl_1_cap, chl_2_cap,
    output reg [2:0] chl_0_cap_out, chl_1_cap_out, chl_2_cap_out,
    output reg [1:0] next_pivot,
    output reg [1:0] target_chl
);

    wire [2:0] chl_cap [0:2];
    assign chl_cap[0] = chl_0_cap;
    assign chl_cap[1] = chl_1_cap;
    assign chl_cap[2] = chl_2_cap;

    reg [1:0] pivot_0, pivot_1, pivot_2;
    reg [1:0] pref_sanitized;

    // sanitize prefer_chl -> 如果輸入是 3，就把它 clamp 或改為預設 0（可根據設計更改）
    always @(*) begin
        pref_sanitized = (prefer_chl > 2'd2) ? 2'd0 : prefer_chl;

        if (cur_pivot == 2'd3) begin
            pivot_0 = pref_sanitized;
        end else begin
            pivot_0 = cur_pivot;
        end

        // safe, no overflow
        pivot_1 = (pivot_0 == 2'd2) ? 2'd0 : (pivot_0 + 2'd1); // pivot_0 + 1 mod 3
        pivot_2 = (pivot_0 == 2'd0) ? 2'd2 : (pivot_0 - 2'd1); // pivot_0 + 2 mod 3
    end

    // allocation logic
    always @(*) begin
        // defensive defaults
        chl_0_cap_out = chl_0_cap;
        chl_1_cap_out = chl_1_cap;
        chl_2_cap_out = chl_2_cap;
        next_pivot    = cur_pivot;
        target_chl    = 2'd3; // 3 表示無法分配 / invalid

        if (!req_valid) begin
            // keep defaults (no allocation, no pivot change)
        end else begin
            // prefer channel (only if prefer is in 0..2)
            if ((prefer_chl <= 2'd2) && (chl_cap[prefer_chl] > 3'd0)) begin
                target_chl = prefer_chl;
                case (prefer_chl)
                    2'd0: chl_0_cap_out = chl_0_cap - 3'd1;
                    2'd1: chl_1_cap_out = chl_1_cap - 3'd1;
                    2'd2: chl_2_cap_out = chl_2_cap - 3'd1;
                endcase
                next_pivot = cur_pivot; // 不啟動 fallback，不更新 pivot
            end else begin
                // fallback 嘗試順序 pivot_0 -> pivot_1 -> pivot_2
                if (chl_cap[pivot_0] > 3'd0) begin
                    target_chl = pivot_0;
                    case (pivot_0)
                        2'd0: chl_0_cap_out = chl_0_cap - 3'd1;
                        2'd1: chl_1_cap_out = chl_1_cap - 3'd1;
                        2'd2: chl_2_cap_out = chl_2_cap - 3'd1;
                    endcase
                    // 成功時 next_pivot = pivot_0 + 1 mod 3
                    next_pivot = (pivot_0 == 2'd2) ? 2'd0 : (pivot_0 + 2'd1);
                end
                else if (chl_cap[pivot_1] > 3'd0) begin
                    target_chl = pivot_1;
                    case (pivot_1)
                        2'd0: chl_0_cap_out = chl_0_cap - 3'd1;
                        2'd1: chl_1_cap_out = chl_1_cap - 3'd1;
                        2'd2: chl_2_cap_out = chl_2_cap - 3'd1;
                    endcase
                    // pivot_1 == pivot_0 + 1, 所以 next_pivot 同樣設為 pivot_0 + 1 mod3
                    next_pivot = pivot_1;
                end
                else if (chl_cap[pivot_2] > 3'd0) begin
                    target_chl = pivot_2;
                    case (pivot_2)
                        2'd0: chl_0_cap_out = chl_0_cap - 3'd1;
                        2'd1: chl_1_cap_out = chl_1_cap - 3'd1;
                        2'd2: chl_2_cap_out = chl_2_cap - 3'd1;
                    endcase
                    // pivot_2 成功，依你原本意圖，成功時 next_pivot 仍為 pivot_0 + 1 mod3
                    next_pivot = (pivot_0 == 2'd2) ? 2'd0 : (pivot_0 + 2'd1);
                end
                else begin
                    // all fail -> fallback 無效，next_pivot = pivot_0 + 2 mod3
                    target_chl = 2'd3;
                    next_pivot = (pivot_0 == 2'd0) ? 2'd2 :
                                 (pivot_0 == 2'd1) ? 2'd0 : 2'd1;
                end
            end
        end
    end
endmodule
