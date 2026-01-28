#include <stdio.h>
#include <stdlib.h>

#define MAX_POINTS 500
#define MAX_HULL 128
// 差drop
typedef struct
{
    int x, y;
} Point;

Point hull[MAX_HULL];
int hull_size = 0;

// cross product (OA x OB)
long long cross(Point O, Point A, Point B)
{
    return (long long)(A.x - O.x) * (B.y - O.y) -
           (long long)(A.y - O.y) * (B.x - O.x);
}

// 判斷 p 是否在 hull 內部或邊界
int inside_hull(Point p)
{
    if (hull_size < 3)
        return 0;
    for (int i = 0; i < hull_size; i++)
    {
        Point a = hull[i];
        Point b = hull[(i + 1) % hull_size];
        if (cross(a, b, p) < 0)
            return 0; // 在外側
    }
    return 1; // 全部都 >=0 → 在內部或邊界
}

// 判斷點 q 是否在線段 pr 上
int on_segment(Point p, Point q, Point r)
{
    if (cross(p, r, q) != 0) // 不共線
        return 0;
    if (q.x < (p.x < r.x ? p.x : r.x) || q.x > (p.x > r.x ? p.x : r.x))
        return 0;
    if (q.y < (p.y < r.y ? p.y : r.y) || q.y > (p.y > r.y ? p.y : r.y))
        return 0;
    return 1;
}

// 找左切點
int find_left_tangent(Point p, bool &colinear_left_bool)
{
    for (int i = 0; i < hull_size; i++)
    {
        Point prev = hull[(i - 1 + hull_size) % hull_size];
        Point cur = hull[i];
        Point next = hull[(i + 1) % hull_size];
        if (cross(p, cur, prev) == 0 || cross(p, cur, next) == 0)
        {
            colinear_left_bool = 1;
            printf("find colinear left tang");
            return i;
        }
        else if (cross(p, cur, prev) > 0 && cross(p, cur, next) > 0)
        {
            colinear_left_bool = 0;
            printf("find normal left tang");
            return i;
        }
    }
    return -1;
}

// 找右切點
int find_right_tangent(Point p, bool &colinear_right_bool)
{
    for (int i = 0; i < hull_size; i++)
    {
        Point prev = hull[(i - 1 + hull_size) % hull_size];
        Point cur = hull[i];
        Point next = hull[(i + 1) % hull_size];
        if (cross(cur, p, prev) == 0 || cross(cur, p, next) == 0)
        {
            colinear_right_bool = 1;
            printf("find colinear right tang");
            return i;
        }
        else if (cross(cur, p, prev) > 0 && cross(cur, p, next) > 0)
        {
            colinear_right_bool = 0;
            printf("find normal right tang");
            return i;
        }
    }
    return 0;
}

// 插入新點 p
int update_hull(Point p, Point dropped[])
{
    int drop_num = 0;

    // 1. 如果和 hull 中某個點重合，直接 drop
    for (int i = 0; i < hull_size; i++)
    {
        if (hull[i].x == p.x && hull[i].y == p.y)
        {
            dropped[drop_num++] = p;
            return drop_num;
        }
    }

    // 2. 如果在 hull 的邊上，直接 drop
    for (int i = 0; i < hull_size; i++)
    {
        Point a = hull[i];
        Point b = hull[(i + 1) % hull_size];
        if (on_segment(a, p, b))
        {
            dropped[drop_num++] = p;
            return drop_num;
        }
    }

    // 3. 如果在 hull 內部或邊界，也 drop
    if (inside_hull(p))
    {
        dropped[drop_num++] = p;
        return drop_num;
    }

    // 4. 正常情況 → 更新凸包
    bool colinear_left_bool, colinear_right_bool;
    int lt = find_left_tangent(p, colinear_left_bool);
    int rt = find_right_tangent(p, colinear_right_bool);

    int new_size = 0;
    Point new_hull[MAX_HULL];

    // 走 rt → lt 範圍
    for (int i = rt;; i = (i + 1) % hull_size)
    {
        Point prev = hull[(i - 1 + hull_size) % hull_size];
        Point cur = hull[i];
        Point next = hull[(i + 1) % hull_size];

        // 特別檢查：如果 cur 在找切點時與新點共線，drop 掉 cur
        if (cross(p, cur, prev) == 0 || cross(p, cur, next) == 0)
        {
            dropped[drop_num++] = cur;
        }
        else
        {
            new_hull[new_size++] = cur;
        }

        if (i == lt)
            break;
    }

    // 收集 lt+1 ~ rt-1 的點（照舊被 drop）
    for (int i = (lt + 1) % hull_size; i != rt; i = (i + 1) % hull_size)
    {
        dropped[drop_num++] = hull[i];
    }

    // 插入新點
    new_hull[new_size++] = p;

    // 更新 hull
    for (int i = 0; i < new_size; i++)
        hull[i] = new_hull[i];
    hull_size = new_size;
    return drop_num;
}

int main()
{
    FILE *fp = fopen("./case3_result/input.txt", "r");
    if (!fp)
    {
        printf("Error: cannot open input.txt\n");
        return 1;
    }
    FILE *out_fp = fopen("./case3_result/output.txt", "w");
    if (!out_fp)
    {
        printf("Error: cannot open output.txt\n");
        fclose(fp);
        return 1;
    }

    int pt_num;
    fscanf(fp, "%d", &pt_num);

    Point p;
    Point dropped[MAX_POINTS];

    for (int i = 0; i < pt_num; i++)
    {
        fscanf(fp, "%d %d", &p.x, &p.y);
        int drop_num = 0;

        if (hull_size < 3)
        {
            hull[hull_size++] = p;
            drop_num = 0;
        }
        else
        {
            drop_num = update_hull(p, dropped);
        }

        fprintf(out_fp, "After point %d (%d,%d): drop_num=%d\n", i + 1, p.x, p.y, drop_num);
        printf("After point %d (%d,%d): drop_num=%d\n", i + 1, p.x, p.y, drop_num);

        for (int k = 0; k < drop_num; k++)
        {
            fprintf(out_fp, "  drop (%d,%d)\n", dropped[k].x, dropped[k].y);
            printf("  drop (%d,%d)\n", dropped[k].x, dropped[k].y);
        }
    }

    fclose(fp);
    fclose(out_fp);
    return 0;
}
