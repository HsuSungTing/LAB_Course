#include <iostream>
#include <vector>
#include <utility> // for pair
#include <algorithm>

using namespace std;

#define MAX_POINTS 500
#define MAX_HULL 128

struct Point
{
    int x;
    int y;
};

// 全域 hull (改用 vector)
static vector<Point> hull;

// cross product (OA x OB)
int cross(const Point &O, const Point &A, const Point &B)
{
    return (int)(A.x - O.x) * (B.y - O.y) - (long long)(A.y - O.y) * (B.x - O.x);
}

void print_hull()
{
    cout << "(size=" << hull.size() << "):" << endl;
    for (size_t i = 0; i < hull.size(); ++i)
    {
        cout << "  (" << hull[i].x << ", " << hull[i].y << ")" << endl;
    }
    cout << endl;
}

// 判斷 p 是否在 hull 內部或邊界
bool inside_hull(const Point &p)
{
    if (hull.size() < 3)
        return false;
    size_t hs = hull.size();
    for (size_t i = 0; i < hs; ++i)
    {
        const Point &a = hull[i];
        const Point &b = hull[(i + 1) % hs];
        if (cross(a, b, p) < 0)
            return false;
    }
    return true;
}

// 判斷點 q 是否在線段 pr 上
bool on_segment(const Point &p, const Point &q, const Point &r)
{
    if (cross(p, r, q) != 0)
        return false;
    if (q.x < min(p.x, r.x) || q.x > max(p.x, r.x))
        return false;
    if (q.y < min(p.y, r.y) || q.y > max(p.y, r.y))
        return false;
    return true;
}

// 找右切點 (原 find_right_tangent)
// 回傳 pair<index, colinear_flag>
pair<int, bool> find_right_tangent(const Point &p)
{
    cout << "find_right_tangent: " << endl;
    int ans = -1;
    bool colinear_right_bool = false;
    size_t hs = hull.size();
    if (hs == 0)
        return {ans, colinear_right_bool};

    for (size_t i = 0; i < hs; ++i)
    {
        const Point &prev = hull[(i + hs - 1) % hs];
        const Point &cur = hull[i];
        const Point &next = hull[(i + 1) % hs];
        if (cross(cur, p, prev) > 0 && cross(cur, p, next) > 0)
        {
            colinear_right_bool = false;
            cout << "this not coline  ans = " << i << endl;
            cout << endl;
            ans = (int)i;
            break;
        }
        else if (cross(cur, p, prev) == 0 && cross(cur, p, next) > 0)
        {
            colinear_right_bool = true;
            cout << "coline ans = " << i << endl;
            cout << "prev.x: " << prev.x << " prev.y: " << prev.y << endl;
            cout << "cur.x: " << cur.x << " cur.y: " << cur.y << endl;
            cout << "cross(cur, p, prev):" << cross(cur, p, prev) << endl;
            cout << endl;
            ans = (int)i;
        }
    }
    return {ans, colinear_right_bool};
}

// 找左切點 (原 find_left_tangent)
// 回傳 pair<index, colinear_flag>
pair<int, bool> find_left_tangent(const Point &p)
{
    cout << "find_left_tangent: " << endl;
    int ans = -1;
    bool colinear_left_bool = false;
    size_t hs = hull.size();
    if (hs == 0)
        return {ans, colinear_left_bool};

    for (size_t i = 0; i < hs; ++i)
    {
        const Point &prev = hull[(i + hs - 1) % hs];
        const Point &cur = hull[i];
        const Point &next = hull[(i + 1) % hs];
        if (cross(p, cur, prev) > 0 && cross(p, cur, next) > 0)
        {
            colinear_left_bool = false;
            cout << "this not coline  ans = " << i << endl;
            cout << endl;
            ans = (int)i;
            break;
        }
        else if (cross(p, cur, next) == 0 && cross(p, cur, prev) > 0)
        {
            colinear_left_bool = true;
            cout << "coline ans = " << i << endl;
            cout << "next.x: " << next.x << " next.y: " << next.y << endl;
            cout << "cur.x: " << cur.x << " cur.y: " << cur.y << endl;
            cout << "cross(p, cur, next):" << cross(p, cur, next) << endl;
            cout << endl;
            ans = (int)i;
        }
    }
    return {ans, colinear_left_bool};
}

// 更新 hull 與 dropped[]，只 drop 真正不在 hull 上的點
// 參數: p, lt, rt, colinear flags, dropped vector (reference)
int update_hull_between_tangents(const Point &p, int lt, int rt,
                                 bool colinear_left_bool, bool colinear_right_bool,
                                 vector<Point> &dropped)
{
    int drop_num = 0;

    vector<Point> new_hull;
    new_hull.reserve(MAX_HULL);

    size_t hs = hull.size();
    if (hs == 0)
    {
        // hull empty, 直接加入 p
        new_hull.push_back(p);
        hull = new_hull;
        return drop_num;
    }

    // 起點
    int i = lt;
    if (colinear_left_bool)
        i = (lt + 1) % (int)hs;

    // 終點
    int end_idx = rt;
    if (colinear_right_bool)
        end_idx = (rt - 1 + (int)hs) % (int)hs;

    // 把 lt → rt 的點加進 new_hull（考慮繞一圈）
    while (true)
    {
        new_hull.push_back(hull[i]);
        if (i == end_idx)
            break;
        i = (i + 1) % (int)hs;
    }

    // 插入新點 p
    new_hull.push_back(p);

    // 更新 hull
    hull = new_hull;

    return drop_num;
}

// update_hull: 處理是否重複、是否在邊上或 inside，再找左右切點更新 hull
int update_hull(const Point &p, vector<Point> &dropped)
{
    int drop_num = 0;

    // 重複點或落在邊上
    for (size_t i = 0; i < hull.size(); ++i)
    {
        if (hull[i].x == p.x && hull[i].y == p.y)
        {
            dropped.push_back(p);
            return 1;
        }
    }
    for (size_t i = 0; i < hull.size(); ++i)
    {
        const Point &a = hull[i];
        const Point &b = hull[(i + 1) % hull.size()];
        if (on_segment(a, p, b))
        {
            dropped.push_back(p);
            return 1;
        }
    }
    if (inside_hull(p))
    {
        dropped.push_back(p);
        return 1;
    }

    auto left_ret = find_left_tangent(p);
    auto right_ret = find_right_tangent(p);
    int lt = left_ret.first;
    int rt = right_ret.first;
    bool colinear_left_bool = left_ret.second;
    bool colinear_right_bool = right_ret.second;

    cout << "(" << p.x << ", " << p.y << ")" << endl;
    cout << "lt:" << lt << " rt:" << rt << endl;
    if (lt >= 0 && lt < (int)hull.size())
    {
        cout << "hull[lt].x: " << hull[lt].x << " hull[lt].y: " << hull[lt].y << endl;
    }
    if (rt >= 0 && rt < (int)hull.size())
    {
        cout << "hull[rt].x: " << hull[rt].x << " hull[rt].y: " << hull[rt].y << endl;
    }
    cout << "colinear_left_bool: " << colinear_left_bool
         << " colinear_right_bool: " << colinear_right_bool << endl;

    drop_num = update_hull_between_tangents(p, lt, rt, colinear_left_bool, colinear_right_bool, dropped);
    return drop_num;
}

int main()
{
    // 測試用 points
    vector<Point> test_points = {
        {701, 434}, {732, 403}, {807, 734}, {701, 434}, {732, 403}, {807, 734}, {838, 72}, {732, 403}, {701, 434}, {838, 72}, {807, 734}, {807, 322}, {807, 322}, {701, 434}, {838, 72}, {807, 734}, {837, 696}, {701, 434}, {838, 72}, {837, 696}, {807, 734}};

    vector<Point> dropped;
    hull.clear();

    for (size_t i = 0; i < test_points.size(); ++i)
    {
        int drop_num = 0;
        if (hull.size() < 3)
        {
            hull.push_back(test_points[i]);
            drop_num = 0;
        }
        else
        {
            // 清空本次 dropped（你原本的 dropped 陣列會累積，這裡我們只列出本次被 drop 的）
            vector<Point> local_dropped;
            drop_num = update_hull(test_points[i], local_dropped);
            // 把 local_dropped 的內容存到全域 dropped（如果需要保存所有 dropped）
            for (const auto &pt : local_dropped)
                dropped.push_back(pt);
            // 印出 local_dropped
            for (const auto &pt : local_dropped)
            {
                cout << "  drop (" << pt.x << "," << pt.y << ")" << endl;
            }
        }

        cout << "After point (" << test_points[i].x << "," << test_points[i].y << "): drop_num=" << drop_num << endl;
        // 如果你想列出所有 dropped，可以印 dropped vector（此處只印本次）
        // 印出目前 hull
        cout << "Current hull: ";
        for (size_t k = 0; k < hull.size(); ++k)
        {
            cout << "(" << hull[k].x << "," << hull[k].y << ") ";
        }
        cout << endl
             << endl;
    }

    // 最後印出完整 hull 與被 drop 的點（若需要）
    cout << "Final hull: ";
    for (const auto &pt : hull)
        cout << "(" << pt.x << "," << pt.y << ") ";
    cout << endl;

    if (!dropped.empty())
    {
        cout << "All dropped points: ";
        for (const auto &pt : dropped)
            cout << "(" << pt.x << "," << pt.y << ") ";
        cout << endl;
    }

    return 0;
}
