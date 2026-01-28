#include <bits/stdc++.h>
using namespace std;

const int N = 9;

// Sudoku board: 0 means empty
int board[N][N];

// 每個格子的候選數字集合
vector<int> candidates[N][N];

// 嘗試次數 counter
long long backtrackCounter = 0;

// 檢查某個數字是否能放在 (r,c)
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

// step 1: 找候選集合 (81 cycles)
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
                {
                    candidates[r][c].push_back(v);
                }
            }
        }
    }
}

// 嘗試填一輪 (row/col/box) 唯一候選
bool fillUniqueInRow()
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
                    changed = true;
                }
            }
        }
    }
    return changed;
}

// step 2: 填唯一候選 (27 cycles: row/col/box 各一輪)
void fillUnique()
{
    bool changed = true;
    while (changed)
    {
        changed = false;
        computeCandidates();
        if (fillUniqueInRow())
            changed = true;
        computeCandidates();
        if (fillUniqueInCol())
            changed = true;
        computeCandidates();
        if (fillUniqueInBox())
            changed = true;
    }
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
                        backtrackCounter++; // 嘗試計數
                        board[r][c] = v;
                        if (solveSudoku())
                            return true;
                        board[r][c] = 0;
                    }
                }
                return false; // no candidate works
            }
        }
    }
    return true; // solved
}

// Debug: 印盤面
void printBoard()
{
    for (int r = 0; r < N; r++)
    {
        for (int c = 0; c < N; c++)
        {
            cout << board[r][c] << " ";
        }
        cout << "\n";
    }
}

int main()
{
    // 測試輸入 (0 表示空格)
    int input[9][9] = {
        {6, 0, 0, 0, 0, 8, 9, 4, 0},
        {9, 0, 0, 0, 0, 6, 1, 0, 0},
        {0, 7, 0, 0, 4, 0, 0, 0, 0},

        {2, 0, 0, 6, 1, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 2, 0, 0},
        {0, 8, 9, 0, 0, 2, 0, 0, 0},

        {0, 0, 0, 0, 6, 0, 0, 0, 5},
        {0, 0, 0, 0, 0, 0, 0, 3, 0},
        {8, 0, 0, 0, 0, 1, 6, 0, 0}};

    memcpy(board, input, sizeof(board));

    // step 1 + step 2
    computeCandidates();
    fillUnique();

    // step 3
    solveSudoku();

    printBoard();

    cout << "\nBacktracking 嘗試次數: " << backtrackCounter << endl;

    return 0;
}
