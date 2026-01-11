# 式評価ロジック

INMU Stage 0 の式評価（Expression Evaluation）の共通ロジックを定義します。

## 概要

式評価は以下の演算子をサポートします：
- 加算: `+`
- 減算: `-`
- 乗算: `*`
- 除算: `/`
- 括弧: `(` と `)`

演算子の優先順位：
1. 括弧 `()` - 最高
2. 乗算 `*`, 除算 `/` - 高
3. 加算 `+`, 減算 `-` - 低

## アルゴリズム構造

再帰下降パーサー（Recursive Descent Parser）を使用：

```
parse_expression_advanced()
  └─ parse_add_sub()        # 加算・減算レベル
      └─ parse_mul_div()    # 乗算・除算レベル
          └─ parse_primary() # 基本要素（数値、変数、括弧）
```

## 関数詳細

### parse_expression_advanced
**目的**: 式全体を評価する（エントリポイント）

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- value: 計算結果
- consumed: 消費したバイト数

**処理**:
```
parse_add_sub() を呼び出す
```

### parse_add_sub
**目的**: 加算・減算の評価

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- value: 計算結果
- consumed: 消費したバイト数

**処理**:
```
1. 左辺 = parse_mul_div() で最初の項を取得
2. consumed = 消費バイト数

3. loop:
    a. skip_whitespace()
    b. 演算子をチェック:
       - '+' の場合:
         i.  consumed++ (演算子をスキップ)
         ii. skip_whitespace()
         iii. 右辺 = parse_mul_div()
         iv. 左辺 = 左辺 + 右辺
         v.  consumed += 消費バイト数
       - '-' の場合:
         i.  consumed++ (演算子をスキップ)
         ii. skip_whitespace()
         iii. 右辺 = parse_mul_div()
         iv. 左辺 = 左辺 - 右辺
         v.  consumed += 消費バイト数
       - それ以外:
         break
         
4. return (左辺, consumed)
```

### parse_mul_div
**目的**: 乗算・除算の評価

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- value: 計算結果
- consumed: 消費したバイト数

**処理**:
```
1. 左辺 = parse_primary() で最初の項を取得
2. consumed = 消費バイト数

3. loop:
    a. skip_whitespace()
    b. 演算子をチェック:
       - '*' の場合:
         i.  consumed++ (演算子をスキップ)
         ii. skip_whitespace()
         iii. 右辺 = parse_primary()
         iv. 左辺 = 左辺 * 右辺
         v.  consumed += 消費バイト数
       - '/' の場合:
         i.  consumed++ (演算子をスキップ)
         ii. skip_whitespace()
         iii. 右辺 = parse_primary()
         iv. if 右辺 == 0:
                 エラー（ゼロ除算）
         v.  左辺 = 左辺 / 右辺
         vi. consumed += 消費バイト数
       - それ以外:
         break
         
4. return (左辺, consumed)
```

### parse_primary
**目的**: 基本要素（数値、変数、括弧式）を評価

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- value: 計算結果
- consumed: 消費したバイト数

**処理**:
```
1. skip_whitespace()
2. 現在の文字を判定:

   a. 数字 ('0'-'9') の場合:
      - parse_number() で数値をパース
      - return (数値, consumed)
   
   b. 英字またはアンダースコアの場合:
      - parse_identifier() で変数名を取得
      - get_variable(変数名) で変数の値を取得
      - if 変数が未定義:
          エラー
      - return (変数値, consumed)
   
   c. 開き括弧 '(' の場合:
      - consumed = 1 (括弧をスキップ)
      - skip_whitespace()
      - value = parse_expression_advanced() で括弧内を再帰的に評価
      - consumed += 消費バイト数
      - skip_whitespace()
      - 閉じ括弧 ')' を確認
      - if 閉じ括弧がない:
          エラー
      - consumed++ (閉じ括弧をスキップ)
      - return (value, consumed)
   
   d. それ以外:
      - エラー（無効な式）

3. return (value, consumed)
```

## 使用例

### 例1: 単純な加算
```
入力: "3 + 5"
処理:
  parse_add_sub()
    ├─ parse_mul_div() → parse_primary() → 3
    ├─ '+' 検出
    └─ parse_mul_div() → parse_primary() → 5
  結果: 3 + 5 = 8
```

### 例2: 優先順位
```
入力: "2 + 3 * 4"
処理:
  parse_add_sub()
    ├─ parse_mul_div() → parse_primary() → 2
    ├─ '+' 検出
    └─ parse_mul_div()
        ├─ parse_primary() → 3
        ├─ '*' 検出
        └─ parse_primary() → 4
        結果: 3 * 4 = 12
  結果: 2 + 12 = 14
```

### 例3: 括弧
```
入力: "(2 + 3) * 4"
処理:
  parse_add_sub()
    └─ parse_mul_div()
        ├─ parse_primary()
        │   └─ '(' 検出 → parse_add_sub()
        │       ├─ parse_primary() → 2
        │       ├─ '+' 検出
        │       └─ parse_primary() → 3
        │       結果: 5
        ├─ '*' 検出
        └─ parse_primary() → 4
        結果: 5 * 4 = 20
```

### 例4: 変数参照
```
入力: "x + 10" (x = 5 として)
処理:
  parse_add_sub()
    ├─ parse_mul_div() → parse_primary() → get_variable("x") → 5
    ├─ '+' 検出
    └─ parse_mul_div() → parse_primary() → 10
  結果: 5 + 10 = 15
```
