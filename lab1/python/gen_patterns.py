#!/usr/bin/env python3
"""
ICLAB Lab1 test case generator for MPCA

Generates:
- input.txt  (hex): packet0..packet7 (encrypted 16-bit), KEY (64-bit),
                   channel_load0..2, channel_capacity0..2
- output.txt (0~3): grant_channel0..7
"""

import argparse
import random
from typing import List, Tuple

# ----------------------------
# Bit helpers
# ----------------------------
def rol16(x: int, r: int) -> int:
    x &= 0xFFFF
    r %= 16
    return ((x << r) | (x >> (16 - r))) & 0xFFFF

def ror16(x: int, r: int) -> int:
    x &= 0xFFFF
    r %= 16
    return ((x >> r) | (x << (16 - r))) & 0xFFFF

def twos_to_int(x: int, width: int) -> int:
    """Interpret unsigned x of 'width' bits as signed two's complement."""
    mask = (1 << width) - 1
    x &= mask
    signbit = 1 << (width - 1)
    return x - (1 << width) if (x & signbit) else x

# ----------------------------
# SPECK32/64 (R=4, α=7, β=2)
# Key schedule per lab text:
#   Let KEY be 64-bit.
#   K0 = low 16 bits
#   l[0] = next 16, l[1] = next 16, l[2] = highest 16
#   K1 = (ROR7(K0) + l[0]) ^ 0
#   K2 = (ROR7(K1) + l[1]) ^ 1
#   K3 = (ROR7(K2) + l[2]) ^ 2
# ----------------------------
def speck_round_keys_4(key64: int) -> List[int]:
    k0 = key64 & 0xFFFF
    l0 = (key64 >> 16) & 0xFFFF
    l1 = (key64 >> 32) & 0xFFFF
    l2 = (key64 >> 48) & 0xFFFF
    K = [0, 0, 0, 0]
    K[0] = k0
    K[1] = (ror16(K[0], 7) + l0) & 0xFFFF
    K[1] ^= 0  # round const
    K[2] = (ror16(K[1], 7) + l1) & 0xFFFF
    K[2] ^= 1
    K[3] = (ror16(K[2], 7) + l2) & 0xFFFF
    K[3] ^= 2
    return K

def speck32_encrypt_4_rounds(x0: int, y0: int, rkeys: List[int]) -> Tuple[int, int]:
    # x,y are 16-bit words; returns (x4,y4)
    x, y = x0 & 0xFFFF, y0 & 0xFFFF
    for r in range(4):
        x = (ror16(x, 7) + y) & 0xFFFF
        x ^= rkeys[r]
        y = rol16(y, 2) ^ x
    return x & 0xFFFF, y & 0xFFFF

def speck32_decrypt_4_rounds(x4: int, y4: int, rkeys: List[int]) -> Tuple[int, int]:
    x, y = x4 & 0xFFFF, y4 & 0xFFFF
    for r in reversed(range(4)):
        y = ror16(y ^ x, 2)
        x = rol16(((x ^ rkeys[r]) - y) & 0xFFFF, 7)
    return x & 0xFFFF, y & 0xFFFF

# ----------------------------
# Packet pack/unpack (16-bit)
# [15] req_valid (1b)
# [14:13] qos (2b)
# [12:9]  pkt_len (4b)
# [8:7]   congestion (2b)
# [6:5]   prefer_ch (2b, use 0..2)
# [4:2]   src_hint (3b)
# [1]     mode (1b)
# [0]     reserved (0)
# ----------------------------
def pack_packet(req_valid:int, qos:int, pkt_len:int, congestion:int,
                prefer_ch:int, src_hint:int, mode:int) -> int:
    w = 0
    w |= (req_valid & 0x1) << 15
    w |= (qos & 0x3) << 13
    w |= (pkt_len & 0xF) << 9
    w |= (congestion & 0x3) << 7
    w |= (prefer_ch & 0x3) << 5
    w |= (src_hint & 0x7) << 2
    w |= (mode & 0x1) << 1
    # bit0 reserved = 0
    return w & 0xFFFF

def unpack_fields(word: int):
    req_valid  = (word >> 15) & 0x1
    qos        = (word >> 13) & 0x3
    pkt_len    = (word >> 9)  & 0xF
    congestion = (word >> 7)  & 0x3
    prefer_ch  = (word >> 5)  & 0x3
    src_hint   = (word >> 2)  & 0x7
    mode       = (word >> 1)  & 0x1
    return req_valid, qos, pkt_len, congestion, prefer_ch, src_hint, mode

# ----------------------------
# Priority score (matches examples in handout)
#   score = (qos-2)*4 + (pkt_len-8)*(-2) + (1-congestion)*3 + (src_hint-4)
# mode==1 => interpret qos(2b), pkt_len(4b), congestion(2b), src_hint(3b) as signed
# req_valid, prefer_ch are always unsigned
# ----------------------------
def priority_score(word: int) -> int:
    req_valid, qos_u, pkt_len_u, cong_u, prefer_u, src_u, mode = unpack_fields(word)

    if mode == 1:
        qos = twos_to_int(qos_u, 2)
        pkt_len = twos_to_int(pkt_len_u, 4)
        cong = twos_to_int(cong_u, 2)
        src = twos_to_int(src_u, 3)
    else:
        qos = qos_u
        pkt_len = pkt_len_u
        cong = cong_u
        src = src_u

    term_qos = (qos - 2) * 4
    term_len = (pkt_len - 8) * (-2)
    term_cong = (1 - cong) * 3
    term_src = (src - 4)
    score = term_qos + term_len + term_cong + term_src

    # print("==== priority_score debug ====")
    # print(f"word = 0x{word:04x}, mode = {mode}, req_valid = {req_valid}")
    # print(f"raw fields: qos_u={qos_u}, pkt_len_u={pkt_len_u}, cong_u={cong_u}, src_u={src_u}")
    # print(f"interpreted: qos={qos}, pkt_len={pkt_len}, cong={cong}, src={src}")
    # print(f"terms: qos_term={term_qos}, len_term={term_len}, cong_term={term_cong}, src_term={term_src}")
    # print(f"priority_score = {score}")
    # print("==============================")

    return score


# ----------------------------
# Mask policy
#   mask_score = ((priority & 0x6) + prefer_ch + (src_hint ^ 0x3) + init_load[ch]) % 10
#   threshold  = 7 + (init_load[ch] // 3)   # integer division
#   mask_fail if mask_score >= threshold
# ----------------------------
def mask_check(word: int, assigned_ch: int, init_load: List[int], prio: int) -> bool:
    _, _, _, _, prefer_u, src_u, _ = unpack_fields(word)
    mask_score = ((prio & 0x6) + prefer_u + (src_u ^ 0x3) + (init_load[assigned_ch] & 0xF)) % 10
    threshold = 7 + (init_load[assigned_ch] // 3)
    return mask_score >= threshold

# ----------------------------
# Allocation + Rebalance
# ----------------------------
def allocate_and_rebalance(packets_plain: List[int],
                           init_load: List[int],
                           capacity: List[int]) -> List[int]:
    n = 8
    # Precompute priority
    prios = [priority_score(w) for w in packets_plain]
    # Sort indices: valid first, higher prio first, smaller index first
    indices = list(range(n))
    def sort_key(i):
        req_valid = (packets_plain[i] >> 15) & 0x1
        return (-req_valid, -prios[i], i)
    indices.sort(key=sort_key)

    # Initial allocation
    grant = [3] * n  # 0..2 or 3 for unallocated
    assigned_count = [0, 0, 0]  # number of newly assigned packets per channel
    pivot = None
    for i in indices:
        req_valid, _, _, _, prefer_ch, _, _ = unpack_fields(packets_plain[i])
        if req_valid == 0:
            grant[i] = 3
            continue
        # try preferred channel if capacity allows
        if assigned_count[prefer_ch] < capacity[prefer_ch]:
            grant[i] = prefer_ch
            assigned_count[prefer_ch] += 1
        else:
            # fallback with dynamic RR starting from pivot
            if pivot is None:
                pivot = prefer_ch
            order = [(pivot + d) % 3 for d in range(3)]
            placed = False
            for ch in order:
                if assigned_count[ch] < capacity[ch]:
                    grant[i] = ch
                    assigned_count[ch] += 1
                    placed = True
                    break
            if placed:
                pivot = (pivot + 1) % 3
            else:
                grant[i] = 3
                pivot = (pivot + 2) % 3

    # Mask step (does not free resources)
    mask_failed = [False] * n
    for i in range(n):
        if grant[i] in (0, 1, 2):
            mf = mask_check(packets_plain[i], grant[i], init_load, prios[i])
            mask_failed[i] = mf

    # Global rebalance (at most once)
    total_load = [init_load[c] + assigned_count[c] for c in range(3)]
    max_ch = max(range(3), key=lambda c: total_load[c])
    other_sum = total_load[(max_ch + 1) % 3] + total_load[(max_ch + 2) % 3]
    # trigger condition: total[max] > half of other two (integer half)
    if total_load[max_ch] > (other_sum // 2):
        # choose lowest priority in overloaded channel (exclude mask_failed)
        # scan from low-priority end (reverse of 'indices')
        victim = None
        for i in reversed(indices):
            if grant[i] == max_ch and not mask_failed[i]:
                victim = i
                break
        if victim is not None:
            # Try move to (max_ch+1)%3 then (max_ch+2)%3
            moved = False
            for d in (1, 2):
                tgt = (max_ch + d) % 3
                # Check capacity and new load<16
                if assigned_count[tgt] + 1 <= capacity[tgt] and (init_load[tgt] + assigned_count[tgt] + 1) < 16:
                    # move
                    assigned_count[grant[victim]] -= 1
                    grant[victim] = tgt
                    assigned_count[tgt] += 1
                    moved = True
                    break
            if not moved:
                # drop the victim
                assigned_count[grant[victim]] -= 1
                grant[victim] = 3
        # else: no eligible victim -> do nothing

    return grant

# ----------------------------
# Pattern generation
# ----------------------------
def random_packet() -> int:
    req_valid  = random.choices([0, 1], weights=[1, 4])[0]
    qos        = random.randint(0, 3)
    pkt_len    = random.randint(0, 15)
    congestion = random.randint(0, 3)
    prefer_ch  = random.randint(0, 2)  # 0..2 only
    src_hint   = random.randint(0, 7)
    mode       = random.randint(0, 1)
    return pack_packet(req_valid, qos, pkt_len, congestion, prefer_ch, src_hint, mode)

def gen_one_pattern():
    # plaintext packets
    packets_plain = [random_packet() for _ in range(8)]
    # key and subkeys
    key64 = random.getrandbits(64)
    rkeys = speck_round_keys_4(key64)
    # encrypt in four 32-bit blocks: blk[b] = { packet[2b+1] (high), packet[2b] (low) }
    packets_enc = [0] * 8
    for b in range(4):
        x0 = packets_plain[2*b]     # low
        y0 = packets_plain[2*b + 1] # high
        x4, y4 = speck32_encrypt_4_rounds(x0, y0, rkeys)
        packets_enc[2*b]     = x4
        packets_enc[2*b + 1] = y4
    # channel_load (3 x 4-bit), channel_capacity (3 x 3-bit)
    ch_load = [random.randint(0, 15) for _ in range(3)]
    ch_cap  = [random.randint(0, 7)  for _ in range(3)]
    # compute expected grant from plaintext + loads/caps
    grant = allocate_and_rebalance(packets_plain, ch_load[:], ch_cap[:])
    return packets_enc, key64, ch_load, ch_cap, grant

def write_files(num: int, input_path: str, output_path: str, seed: int = None):
    if seed is not None:
        random.seed(seed)
    patterns = [gen_one_pattern() for _ in range(num)]

    # input.txt
    with open(input_path, "w") as fi:
        fi.write(f"{num}\n\n")
        for idx, (pkts_enc, key64, ch_load, ch_cap, grant) in enumerate(patterns):
            for w in pkts_enc:
                fi.write(f"{w:04x}\n")
            fi.write(f"{key64:016x}\n")
            for v in ch_load:
                fi.write(f"{v:x}\n")
            for v in ch_cap:
                fi.write(f"{v:x}\n")
            if idx != num - 1:
                fi.write("\n")

    # output.txt
    with open(output_path, "w") as fo:
        for p_idx, (_, _, _, _, grant) in enumerate(patterns):
            for g in grant:
                fo.write(f"{g}\n")
            if p_idx != num - 1:
                fo.write("\n")
# ----------------------------
# Built-in document test cases
# ----------------------------
def test_one_case1():
    packets_enc = [
        0x9a33, 0x791a, 0x3c2a, 0x524a,
        0x5495, 0x4527, 0x5cd2, 0xe040
    ]
    key64 = 0xe7503a4f51c0bb1a
    ch_load = [0x2, 0x7, 0xd]  # channel_load0..2
    ch_cap  = [0x4, 0x4, 0x6]  # channel_capacity0..2

    rkeys = speck_round_keys_4(key64)
    packets_plain = [0] * 8
    for b in range(4):
        x4 = packets_enc[2*b]     # low
        y4 = packets_enc[2*b + 1] # high
        x0, y0 = speck32_decrypt_4_rounds(x4, y4, rkeys)
        packets_plain[2*b]     = x0
        packets_plain[2*b + 1] = y0

    print("Decrypted packets (plain):")
    for i, w in enumerate(packets_plain):
        print(f"  pkt[{i}] = {w:04x}")

    prios = [priority_score(w) for w in packets_plain]
    print("\nPriority scores:")
    for i, p in enumerate(prios):
        print(f"  pkt[{i}] = {p}")

    grant = allocate_and_rebalance(packets_plain, ch_load[:], ch_cap[:])
    print("\nGrant result:")
    for i, g in enumerate(grant):
        print(f"  pkt[{i}] -> ch{g if g != 3 else 'DROP'}")

def test_one_case2():
    packets_enc = [
        0xc1e5, 0x56ac, 0x164a, 0x06fb,
        0xeee6, 0x8f3b, 0x5a15, 0x5649
    ]
    key64 = 0xaeeebd3c30abf5ae
    ch_load = [0xd, 0x1, 0x8]  # channel_load0..2
    ch_cap  = [0x4, 0x0, 0x3]  # channel_capacity0..2

    rkeys = speck_round_keys_4(key64)
    packets_plain = [0] * 8
    for b in range(4):
        x4 = packets_enc[2*b]     # low
        y4 = packets_enc[2*b + 1] # high
        x0, y0 = speck32_decrypt_4_rounds(x4, y4, rkeys)
        packets_plain[2*b]     = x0
        packets_plain[2*b + 1] = y0

    print("Decrypted packets (plain):")
    for i, w in enumerate(packets_plain):
        print(f"  pkt[{i}] = {w:04x}")

    prios = [priority_score(w) for w in packets_plain]
    print("\nPriority scores:")
    for i, p in enumerate(prios):
        print(f"  pkt[{i}] = {p}")

    grant = allocate_and_rebalance(packets_plain, ch_load[:], ch_cap[:])
    print("\nGrant result:")
    for i, g in enumerate(grant):
        print(f"  pkt[{i}] -> ch{g if g != 3 else 'DROP'}")

def main():
    ap = argparse.ArgumentParser(description="Generate MPCA input/output patterns.")
    ap.add_argument("-n", "--num", type=int, default=10004, help="number of patterns")
    ap.add_argument("--seed", type=int, default=None, help="random seed")
    ap.add_argument("-i", "--input", default="input.txt", help="output path for input.txt")
    ap.add_argument("-o", "--output", default="output.txt", help="output path for output.txt")
    ap.add_argument("--test1", action="store_true", help="run built-in test with fixed input")
    ap.add_argument("--test2", action="store_true", help="run built-in test with fixed input")
    args = ap.parse_args()
    if args.test1:
        test_one_case1()
    elif args.test2:
        test_one_case2()
    else:
        write_files(args.num, args.input, args.output, args.seed)
        print(f"Done. Wrote {args.input} and {args.output} for {args.num} patterns.")


if __name__ == "__main__":
    main()
    
