#include <bits/stdc++.h>
using namespace std;

const int N = 9;

// Sudoku board: 0 means empty
int board[N][N];

// 每個格子的候選數字集合
vector<int> candidates[N][N];

// 嘗試次數 counter
long long backtrackCounter = 0;

// 檢查某個數字是否能放在該位置(check row, col, box)
bool canPlace(int r, int c, int val)
{
    for (int i = 0; i < N; i++)
    {
        if (board[r][i] == val)
            return false; // row
        if (board[i][c] == val)
            return false; // col
    }
    int br = (r / 3) * 3, bc = (c / 3) * 3;
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 3; j++)
            if (board[br + i][bc + j] == val)
                return false; // box
    return true;
}

// 初始化候選集合
void computeCandidates()
{
    for (int r = 0; r < N; r++)
    {
        for (int c = 0; c < N; c++)
        {
            candidates[r][c].clear();
            if (board[r][c] != 0)
                continue; // 已填好的格子不用
            for (int v = 1; v <= 9; v++)
            {
                if (canPlace(r, c, v))
                    candidates[r][c].push_back(v);
            }
        }
    }
}

// 當填入 val 時，更新 (r,c) 與相關格子的候選
void updateCandidates(int r, int c, int val)
{
    // 該格清空
    candidates[r][c].clear();

    // 更新 row
    for (int j = 0; j < N; j++)
    {
        if (board[r][j] == 0)
        {
            auto &cand = candidates[r][j];
            cand.erase(remove(cand.begin(), cand.end(), val), cand.end());
        }
    }
    // 更新 col
    for (int i = 0; i < N; i++)
    {
        if (board[i][c] == 0)
        {
            auto &cand = candidates[i][c];
            cand.erase(remove(cand.begin(), cand.end(), val), cand.end());
        }
    }
    // 更新 box
    int br = (r / 3) * 3, bc = (c / 3) * 3;
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            int rr = br + i, cc = bc + j;
            if (board[rr][cc] == 0)
            {
                auto &cand = candidates[rr][cc];
                cand.erase(remove(cand.begin(), cand.end(), val), cand.end());
            }
        }
    }
}

// 填只有一個候選的格子
bool fillSingleCandidate()
{
    bool changed = false;
    for (int r = 0; r < N; r++)
    {
        for (int c = 0; c < N; c++)
        {
            if (board[r][c] == 0 && candidates[r][c].size() == 1)
            {
                int val = candidates[r][c][0];
                board[r][c] = val;
                updateCandidates(r, c, val);
                changed = true;
            }
        }
    }
    return changed;
}

bool fillUniqueInRow() // 9 個 row 都會檢查到，而且是輪流逐一檢查。
{
    bool changed = false;
    for (int r = 0; r < N; r++)
    {
        for (int v = 1; v <= 9; v++)
        {
            int pos = -1, count = 0;
            for (int c = 0; c < N; c++)
            {
                if (board[r][c] == 0 &&
                    find(candidates[r][c].begin(), candidates[r][c].end(), v) != candidates[r][c].end())
                {
                    pos = c;
                    count++;
                }
            }
            if (count == 1)
            {
                board[r][pos] = v;
                updateCandidates(r, pos, v);
                changed = true;
            }
        }
    }
    return changed;
}

bool fillUniqueInCol()
{
    bool changed = false;
    for (int c = 0; c < N; c++)
    {
        for (int v = 1; v <= 9; v++)
        {
            int pos = -1, count = 0;
            for (int r = 0; r < N; r++)
            {
                if (board[r][c] == 0 &&
                    find(candidates[r][c].begin(), candidates[r][c].end(), v) != candidates[r][c].end())
                {
                    pos = r;
                    count++;
                }
            }
            if (count == 1)
            {
                board[pos][c] = v;
                updateCandidates(pos, c, v);
                changed = true;
            }
        }
    }
    return changed;
}

bool fillUniqueInBox()
{
    bool changed = false;
    for (int br = 0; br < 3; br++)
    {
        for (int bc = 0; bc < 3; bc++)
        {
            for (int v = 1; v <= 9; v++)
            {
                int posR = -1, posC = -1, count = 0;
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        int r = br * 3 + i, c = bc * 3 + j;
                        if (board[r][c] == 0 &&
                            find(candidates[r][c].begin(), candidates[r][c].end(), v) != candidates[r][c].end())
                        {
                            posR = r;
                            posC = c;
                            count++;
                        }
                    }
                }
                if (count == 1)
                {
                    board[posR][posC] = v;
                    updateCandidates(posR, posC, v);
                    changed = true;
                }
            }
        }
    }
    return changed;
}

// step 2: 填唯一候選
void fillUnique()
{
    int while_cnt = 0;
    bool changed = true;
    while (changed)
    {
        while_cnt++;
        changed = false;
        // if (fillSingleCandidate())
        //     changed = true;
        if (fillUniqueInRow())
            changed = true;
        if (fillUniqueInCol())
            changed = true;
        if (fillUniqueInBox())
            changed = true;
    }
    cout << "while_cnt: " << while_cnt << endl;
}

// step 3: backtracking 解剩下的
bool solveSudoku()
{
    for (int r = 0; r < N; r++)
    {
        for (int c = 0; c < N; c++)
        {
            if (board[r][c] == 0)
            {
                for (int v = 1; v <= 9; v++)
                {
                    if (canPlace(r, c, v))
                    {
                        backtrackCounter++;
                        board[r][c] = v;
                        if (solveSudoku())
                            return true;
                        board[r][c] = 0; // 回溯
                    }
                }
                return false;
            }
        }
    }
    return true;
}

// Debug: 印盤面
void printBoard()
{
    for (int r = 0; r < N; r++)
    {
        for (int c = 0; c < N; c++)
            cout << board[r][c] << " ";
        cout << "\n";
    }
}

// 🔹 檢查是否填滿
bool isSolved()
{
    for (int r = 0; r < N; r++)
        for (int c = 0; c < N; c++)
            if (board[r][c] == 0)
                return false;
    return true;
}

int main()
{
    ifstream fin("input.txt");
    if (!fin)
    {
        cerr << "無法開啟 input.txt\n";
        return 1;
    }

    string line;
    int puzzleIndex = 1;
    int dont_need_backtrack_cnt = 0;

    while (getline(fin, line))
    {
        if (line.empty())
            continue;

        stringstream ss(line);
        vector<int> nums;
        int x;
        while (ss >> x)
            nums.push_back(x);

        if (nums.size() != 81)
        {
            cerr << "第 " << puzzleIndex << " 行資料錯誤 (不是81個數字)\n";
            continue;
        }

        // 填入 board
        for (int i = 0; i < 81; i++)
        {
            int r = i / 9, c = i % 9;
            board[r][c] = nums[i];
        }

        backtrackCounter = 0;
        cout << "=== Puzzle " << puzzleIndex << " ===\n";

        // step 1 + step 2
        computeCandidates();
        fillSingleCandidate();
        fillUnique();
        printBoard();
        if (isSolved())
        {
            dont_need_backtrack_cnt++;
            cout << "don't need backtracking\n\n";
        }
        else
        {
            solveSudoku();
            cout << "Backtracking trytime: " << backtrackCounter << "\n\n";
        }
        puzzleIndex++;
    }
    cout << "dont_need_backtrack_cnt: " << dont_need_backtrack_cnt << endl;
    return 0;
}
