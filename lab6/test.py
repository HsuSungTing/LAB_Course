# poker_best_hand.py
from itertools import combinations
from collections import Counter

# -------------------------
# 辅助函数：牌与输入格式
# -------------------------
# card: represented as tuple (rank, suit)
# rank: 2..14 (where 11=J,12=Q,13=K,14=A)
# suit: 0..3 (clubs, diamonds, hearts, spades) - suits have no ranking per spec

RANK_STR = {11:'J',12:'Q',13:'K',14:'A'}
SUIT_STR = {0:'C',1:'D',2:'H',3:'S'}

def card_to_str(card):
    r,s = card
    rstr = str(r) if r<=10 else RANK_STR[r]
    return f"{rstr}{SUIT_STR[s]}"

def parse_card(s):
    """
    parse string to (rank,suit).
    accepted formats:
      - "AS" "10H" "2C" "KD"
    Suit letters: C,D,H,S (case-insensitive)
    """
    s = s.strip().upper()
    if len(s) < 2:
        raise ValueError("invalid card string")
    suit_ch = s[-1]
    rank_s = s[:-1]
    suit_map = {'C':0,'D':1,'H':2,'S':3}
    if suit_ch not in suit_map:
        raise ValueError("invalid suit")
    suit = suit_map[suit_ch]
    if rank_s == 'A': rank = 14
    elif rank_s == 'K': rank = 13
    elif rank_s == 'Q': rank = 12
    elif rank_s == 'J': rank = 11
    else:
        rank = int(rank_s)
    return (rank, suit)

# -------------------------
# 牌型判定与比较
# -------------------------
# Hand ranking order (bigger is better):
# 9: Royal Flush
# 8: Straight Flush
# 7: Four of a Kind
# 6: Full House
# 5: Flush
# 4: Straight
# 3: Three of a Kind
# 2: Two Pair
# 1: One Pair
# 0: High Card
#
# For tie-breaking, each hand type returns a tuple of decisive ranks in descending
# order so natural tuple comparison works.

def is_straight(ranks):
    """
    ranks: list of distinct ranks sorted descending (e.g., [14,13,12,11,10])
    Return (True, high_rank_for_comparing) or (False, None).
    Handle wheel (A-2-3-4-5) as high_rank = 5.
    """
    # Remove duplicates but we assume input 5-card ranks (may have duplicates if called wrongly)
    r = sorted(set(ranks), reverse=True)
    if len(r) < 5:
        return (False, None)
    # Check sequences among unique ranks - but for 5-card detection, we need contiguous 5
    # For our use we will expect exactly 5 cards; so check consecutive or wheel.
    r5 = sorted(ranks)
    # normal check (we assume exactly 5 ranks)
    sorted_desc = sorted(ranks, reverse=True)
    # Handle wheel: A,2,3,4,5 -> treat as 5-high straight
    if sorted_desc == [14,5,4,3,2]:
        return (True, 5)
    # otherwise check descending consecutive
    high = sorted_desc[0]
    expected = [high - i for i in range(5)]
    if sorted_desc == expected:
        return (True, high)
    return (False, None)

def evaluate_5cards(cards):
    """
    cards: list of 5 cards, each (rank,suit)
    Return: (hand_rank_value, tiebreaker_tuple, human_readable_string)
    Higher tuple compares larger hands.
    """
    ranks = [c[0] for c in cards]
    suits = [c[1] for c in cards]
    rank_counts = Counter(ranks)
    counts_sorted = sorted(rank_counts.items(), key=lambda x: (-x[1], -x[0]))
    # counts_sorted: list of (rank, count) sorted by count desc, then rank desc

    # Check flush
    flush = len(set(suits)) == 1

    # Check straight
    is_str, straight_high = is_straight(sorted(ranks, reverse=True))

    # Straight Flush / Royal Flush
    if flush and is_str:
        if straight_high == 14:
            # A-high straight flush = Royal Flush
            return (9, (14,), "Royal Flush")
        else:
            return (8, (straight_high,), f"Straight Flush high {straight_high}")

    # Four of a Kind
    if counts_sorted[0][1] == 4:
        four_rank = counts_sorted[0][0]
        kicker = max(r for r in ranks if r != four_rank)
        return (7, (four_rank, kicker), f"Four of a Kind {four_rank} kicker {kicker}")

    # Full House (3 + 2)
    if counts_sorted[0][1] == 3 and counts_sorted[1][1] == 2:
        trip = counts_sorted[0][0]
        pair = counts_sorted[1][0]
        return (6, (trip, pair), f"Full House {trip} over {pair}")

    # Flush (not straight)
    if flush:
        sorted_ranks = tuple(sorted(ranks, reverse=True))
        return (5, sorted_ranks, f"Flush {sorted_ranks}")

    # Straight (not flush)
    if is_str:
        return (4, (straight_high,), f"Straight high {straight_high}")

    # Three of a Kind
    if counts_sorted[0][1] == 3:
        trip_rank = counts_sorted[0][0]
        kickers = sorted((r for r in ranks if r != trip_rank), reverse=True)
        return (3, (trip_rank, kickers[0], kickers[1]), f"Three of a Kind {trip_rank} kickers {kickers}")

    # Two Pair
    if counts_sorted[0][1] == 2 and counts_sorted[1][1] == 2:
        high_pair = max(counts_sorted[0][0], counts_sorted[1][0])
        low_pair = min(counts_sorted[0][0], counts_sorted[1][0])
        kicker = max(r for r in ranks if r != high_pair and r != low_pair)
        return (2, (high_pair, low_pair, kicker), f"Two Pair {high_pair} {low_pair} kicker {kicker}")

    # One Pair
    if counts_sorted[0][1] == 2:
        pair_rank = counts_sorted[0][0]
        kickers = sorted((r for r in ranks if r != pair_rank), reverse=True)
        return (1, (pair_rank, kickers[0], kickers[1], kickers[2]), f"One Pair {pair_rank} kickers {kickers}")

    # High Card
    sorted_ranks = tuple(sorted(ranks, reverse=True))
    return (0, sorted_ranks, f"High Card {sorted_ranks}")

# -------------------------
# 对 7 张牌枚举 21 个组合，取最大
# -------------------------
def best_hand_from_seven(seven_cards):
    """
    seven_cards: list of 7 (rank,suit)
    Return:
      best_eval: (hand_rank_value, tiebreaker_tuple, description)
      best_five_cards: list of 5 cards
    """
    best_eval = None
    best_combo = None
    for combo in combinations(seven_cards, 5):
        eval_tuple = evaluate_5cards(list(combo))
        # For comparison, compare (hand_rank_value, tiebreaker_tuple) lexicographically
        key = (eval_tuple[0], eval_tuple[1])
        if best_eval is None or key > (best_eval[0], best_eval[1]):
            best_eval = eval_tuple
            best_combo = combo
    return best_eval, list(best_combo)

# -------------------------
# 多玩家比较并找出赢家（可能并列）
# -------------------------
def find_winners(players_seven_cards):
    """
    players_seven_cards: list where each element is a list of 7 cards for one player
    Return:
      winners: list of indices (0-based) of winners
      best_evals: list of best_eval tuples per player (hand_rank_value, tiebreaker, desc)
      best_fives: list of best five-card lists per player
    """
    best_evals = []
    best_fives = []
    for seven in players_seven_cards:
        ev, five = best_hand_from_seven(seven)
        best_evals.append(ev)
        best_fives.append(five)

    # find max across players
    # compare by (hand_rank_value, tiebreaker_tuple)
    keys = [(ev[0], ev[1]) for ev in best_evals]
    max_key = max(keys)
    winners = [i for i,k in enumerate(keys) if k == max_key]
    return winners, best_evals, best_fives

# 假設上面的程式碼都已經存在 (evaluate_5cards, best_hand_from_seven, find_winners, parse_card等)

if __name__ == "__main__":
    # -------------------------
    # 這裡示範 9 位玩家
    # 你可以改成你要的實際牌
    # -------------------------
    # 公共牌 (flop + turn + river)
    community = [
        parse_card("QH"),
        parse_card("JH"),
        parse_card("10H"),
        parse_card("2C"),
        parse_card("3D")
    ]

    # 9 位玩家的 hole cards (每人兩張)
    # 以下只是示範，你可以自行替換
    hole_cards_list = [
        ["AH", "KH"],  # Player 0
        ["AD", "AC"],  # Player 1
        ["4C", "4D"],  # Player 2
        ["9H", "9S"],  # Player 3
        ["7H", "8H"],  # Player 4
        ["5C", "6C"],  # Player 5
        ["AS", "QD"],  # Player 6
        ["KD", "KC"],  # Player 7
        ["3H", "3C"]   # Player 8
    ]

    # 將每位玩家的 2 張 + 5 張公共牌 = 7 張
    players_seven_cards = []
    for i in range(9):
        hole = [parse_card(c) for c in hole_cards_list[i]]
        seven = hole + community
        players_seven_cards.append(seven)

    # 比較並找出贏家(可多人平手)
    winners, best_evals, best_fives = find_winners(players_seven_cards)

    # 印出結果
    for i, (ev, five) in enumerate(zip(best_evals, best_fives)):
        print(f"Player {i}: best hand -> {ev[2]} (rank={ev[0]}, tiebreak={ev[1]})")
        print("  cards:", ' '.join(card_to_str(c) for c in five))

    print("Winners:", winners)