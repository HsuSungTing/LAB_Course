#include <iostream>
#include <vector>

using namespace std;

int k = 5; // 元素范围 0~4
int n = 2; // 二元组合

vector<int> sequence;

// DFS 生成 De Bruijn 序列
void db(int t, int p, vector<int>& a) {
    if (t > n) {
        if (n % p == 0) {
            for (int i = 1; i <= p; ++i)
                sequence.push_back(a[i]);
        }
    } else {
        a[t] = a[t - p];
        db(t + 1, p, a);
        for (int j = a[t - p] + 1; j < k; ++j) {
            a[t] = j;
            db(t + 1, t, a);
        }
    }
}

int main() {
    vector<int> a(n * k, 0); // 临时数组
    db(1,1,a);

    // 输出 De Bruijn 序列
    cout << "Generated array (length " << sequence.size() << "):" << endl;
    for (int i = 0; i < sequence.size(); ++i) {
        cout << sequence[i];
        if (i != sequence.size() - 1) cout << ",";
    }
    cout << endl;
    return 0;
}
