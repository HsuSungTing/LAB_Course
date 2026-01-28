#include <iostream>
using namespace std;

int grid[9][9] = {
    {6, 0, 0, 0, 0, 8, 9, 4, 0},
    {9, 0, 0, 0, 0, 6, 1, 0, 0},
    {0, 7, 0, 0, 4, 0, 0, 0, 0},

    {2, 0, 0, 6, 1, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 2, 0, 0},
    {0, 8, 9, 0, 0, 2, 0, 0, 0},

    {0, 0, 0, 0, 6, 0, 0, 0, 5},
    {0, 0, 0, 0, 0, 0, 0, 3, 0},
    {8, 0, 0, 0, 0, 1, 6, 0, 0}};

int solutionCount = 0;

bool isValid(int row, int col, int num)
{
    for (int x = 0; x < 9; x++)
    {
        if (grid[row][x] == num)
            return false;
        if (grid[x][col] == num)
            return false;
        if (grid[(row / 3) * 3 + x / 3][(col / 3) * 3 + x % 3] == num)
            return false;
    }
    return true;
}

// 修正後的函式，回傳 bool
bool solveSudoku(int row, int col)
{
    if (solutionCount > 1)
    {
        return false; // 找到多解，直接返回
    }

    if (row == 9)
    {
        solutionCount++;
        return false; // 找到一個解，但要繼續找第二個，所以回傳 false
    }

    int nextRow = (col == 8) ? row + 1 : row;
    int nextCol = (col + 1) % 9;

    if (grid[row][col] != 0)
    {
        // 如果這個格子已填，繼續下一個
        return solveSudoku(nextRow, nextCol);
    }
    else
    {
        for (int num = 1; num <= 9; num++)
        {
            if (isValid(row, col, num))
            {
                grid[row][col] = num;
                // 遞迴呼叫
                solveSudoku(nextRow, nextCol);
                grid[row][col] = 0;
            }
        }
    }
    return false; // 繼續尋找下一個解
}

int main()
{
    solveSudoku(0, 0);

    if (solutionCount == 0)
        cout << "此數獨無解" << endl;
    else if (solutionCount == 1)
        cout << "此數獨有唯一解" << endl;
    else
        cout << "此數獨不唯一 (至少兩個解)" << endl;

    return 0;
}