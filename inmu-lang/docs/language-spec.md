# INMU言語仕様

## 概要

INMU言語は、セルフホスティングを目指すシンプルで実用的なプログラミング言語です。

## バージョン

- 仕様バージョン: 0.1.0 (Draft)
- 実装: Stage 0 (インタプリタ)

---

## 基本構文

### コメント

```inmu
# これは単行コメント

# 複数行のコメントは
# 複数の単行コメントで表現
```

### 変数宣言

```inmu
# 変数宣言
let x = 10
let name = "INMU"
let flag = true

# 再代入
x = 20
```

### データ型

- **整数**: `42`, `-10`, `0`
- **浮動小数点**: `3.14`, `-0.5`
- **文字列**: `"Hello"`, `'World'`
- **真偽値**: `true`, `false`
- **配列**: `[1, 2, 3]`, `["a", "b", "c"]`
- **ハッシュマップ**: `{key: "value", count: 10}`

---

## 演算子

### 算術演算子

```inmu
let a = 10 + 5    # 加算: 15
let b = 10 - 5    # 減算: 5
let c = 10 * 5    # 乗算: 50
let d = 10 / 5    # 除算: 2
let e = 10 % 3    # 剰余: 1
```

### 比較演算子

```inmu
x == y    # 等しい
x != y    # 等しくない
x > y     # より大きい
x < y     # より小さい
x >= y    # 以上
x <= y    # 以下
```

### 論理演算子

```inmu
x && y    # AND
x || y    # OR
!x        # NOT
```

---

## 制御構造

### if文

```inmu
if x > 0 {
    print "positive"
} else if x < 0 {
    print "negative"
} else {
    print "zero"
}
```

### while文

```inmu
let i = 0
while i < 10 {
    print i
    i = i + 1
}
```

### for文

```inmu
# 範囲ループ
for i in 0..10 {
    print i
}

# 配列ループ
let arr = [1, 2, 3, 4, 5]
for item in arr {
    print item
}

# インデックス付きループ
for i, item in arr {
    print "Index: " + i + ", Value: " + item
}
```

---

## 関数

### 関数定義

```inmu
fn add(a, b) {
    return a + b
}

# 型アノテーション付き
fn multiply(a: int, b: int) -> int {
    return a * b
}

# 可変長引数
fn sum(...args) {
    let total = 0
    for arg in args {
        total = total + arg
    }
    return total
}
```

### 関数呼び出し

```inmu
let result = add(10, 20)
print result  # 30

let product = multiply(5, 6)
print product  # 30
```

### 無名関数（ラムダ）

```inmu
let square = fn(x) { return x * x }
print square(5)  # 25

# 簡略記法
let double = fn(x) => x * 2
print double(10)  # 20
```

---

## 配列操作

```inmu
# 配列の作成
let arr = [1, 2, 3, 4, 5]

# 要素アクセス
print arr[0]  # 1

# 要素の変更
arr[0] = 10

# 配列メソッド
arr.push(6)           # 末尾に追加
let last = arr.pop()  # 末尾を削除して返す
let len = arr.len()   # 長さを取得

# スライス
let slice = arr[1:3]  # [2, 3]
```

---

## 文字列操作

```inmu
# 文字列連結
let greeting = "Hello" + " " + "World"

# 文字列補間
let name = "INMU"
let msg = "Welcome to {name}!"

# 文字列メソッド
let s = "hello"
print s.upper()      # "HELLO"
print s.lower()      # "hello"
print s.len()        # 5
print s.split("")    # ["h", "e", "l", "l", "o"]
```

---

## 構造体

```inmu
# 構造体定義
struct Point {
    x: int,
    y: int
}

# インスタンス作成
let p = Point { x: 10, y: 20 }

# フィールドアクセス
print p.x  # 10
p.y = 30

# メソッド定義
impl Point {
    fn distance(self) {
        return sqrt(self.x * self.x + self.y * self.y)
    }
}

# メソッド呼び出し
print p.distance()
```

---

## ファイル操作

```inmu
# ファイル読み込み
let content = read_file("input.txt")

# ファイル書き込み
write_file("output.txt", "Hello, World!")

# 行ごと読み込み
let lines = read_lines("data.txt")
for line in lines {
    print line
}
```

---

## モジュールシステム

```inmu
# math.inmu
fn add(a, b) {
    return a + b
}

fn subtract(a, b) {
    return a - b
}

# main.inmu
import math

print math.add(10, 5)      # 15
print math.subtract(10, 5)  # 5

# 特定の関数のみインポート
import { add, subtract } from math

print add(10, 5)  # 15
```

---

## エラーハンドリング

```inmu
# Result型
fn divide(a, b) -> Result<int, string> {
    if b == 0 {
        return Err("Division by zero")
    }
    return Ok(a / b)
}

# パターンマッチング
match divide(10, 2) {
    Ok(value) => print "Result: " + value,
    Err(msg) => print "Error: " + msg
}

# try-catch
try {
    let result = divide(10, 0)
    print result
} catch error {
    print "Caught error: " + error
}
```

---

## 標準ライブラリ

### 組み込み関数

```inmu
# 入出力
print(value)              # 標準出力
println(value)            # 標準出力 (改行付き)
input(prompt)             # 標準入力

# 型変換
int(value)                # 整数に変換
float(value)              # 浮動小数点に変換
string(value)             # 文字列に変換
bool(value)               # 真偽値に変換

# 型チェック
type_of(value)            # 型名を文字列で返す

# その他
len(collection)           # 長さを取得
range(start, end)         # 範囲生成
```

### 数学関数

```inmu
import math

math.abs(x)               # 絶対値
math.sqrt(x)              # 平方根
math.pow(x, y)            # べき乗
math.floor(x)             # 切り捨て
math.ceil(x)              # 切り上げ
math.round(x)             # 四捨五入
```

---

## メモリ管理

- 自動メモリ管理（ガベージコレクション）
- 参照カウント方式
- スコープベースのリソース管理

---

## 今後の拡張予定

- [ ] ジェネリクス
- [ ] トレイト（インターフェース）
- [ ] パターンマッチング
- [ ] 非同期処理（async/await）
- [ ] マクロシステム
- [ ] 並行処理
- [ ] FFI（Foreign Function Interface）

---

## 例: フィボナッチ数列

```inmu
fn fibonacci(n) {
    if n <= 1 {
        return n
    }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

for i in 0..10 {
    print "fib(" + i + ") = " + fibonacci(i)
}
```

## 例: クイックソート

```inmu
fn quicksort(arr) {
    if arr.len() <= 1 {
        return arr
    }
    
    let pivot = arr[arr.len() / 2]
    let left = []
    let middle = []
    let right = []
    
    for item in arr {
        if item < pivot {
            left.push(item)
        } else if item == pivot {
            middle.push(item)
        } else {
            right.push(item)
        }
    }
    
    return quicksort(left) + middle + quicksort(right)
}

let data = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
print quicksort(data)
```
