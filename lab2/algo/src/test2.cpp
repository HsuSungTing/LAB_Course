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

// step 1: 找整個board的候選集合 (81 cycles)
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

// step 2: 填唯一候選
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
                        // cout << "here: " << backtrackCounter << endl;
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
        {
            cout << board[r][c] << " ";
        }
        cout << "\n";
    }
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

        // 填入 board (Restore Scan Order → row-major 轉換)
        for (int i = 0; i < 81; i++)
        {
            int r = i / 9, c = i % 9;
            board[r][c] = nums[i];
        }

        backtrackCounter = 0;
        cout << "=== Puzzle " << puzzleIndex << " ===\n";

        // step 1 + step 2
        computeCandidates();
        fillUnique();

        // step 3
        solveSudoku();

        // printBoard();
        cout << "Backtracking trytime: " << backtrackCounter << "\n\n";
        puzzleIndex++;
    }

    return 0;
}