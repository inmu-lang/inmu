# Assert機能の実装

## 概要

テスト関数`assert`を実装します。式を評価して期待値と比較し、等しくない場合はエラーメッセージを表示してプログラムを終了します。

## 構文

```inmu
assert(actual, expected)
```

### 例

```inmu
# 数値リテラルのassert
assert(10, 10)

# 算術式のassert
assert(5 + 3, 8)
assert(10 - 2, 8)
assert(4 * 3, 12)
assert(20 / 4, 5)

# 変数を使ったassert
let x = 10
assert(x, 10)
assert(x + 5, 15)

# 複雑な式
let a = 5
let b = 3
assert(a + b, 8)
assert((a + b) * 2, 16)
```

## 動作仕様

1. **成功時**: 何も表示せず、次の行に進む
2. **失敗時**: エラーメッセージを表示してプログラムを終了
   - エラーメッセージ形式: `Assertion failed: expected <expected>, got <actual>`
   - 終了コード: 1

## 実装アルゴリズム

### ARM64/x86_64 共通ロジック

1. `assert` キーワードをスキップ（6バイト）
2. 空白をスキップ
3. 開き括弧 `(` を確認・スキップ
4. 空白をスキップ
5. 実際の値（式）を評価（`evaluate_expression`または`parse_expression_advanced`関数を使用）
   - 結果を `x22` (ARM64) または スタック (x86_64) に保存
6. 空白をスキップ
7. カンマ `,` を確認・スキップ
8. 空白をスキップ
9. 期待値（式）を評価
   - 結果を `x23` (ARM64) または `rbx` (x86_64) に保存
10. 空白をスキップ
11. 閉じ括弧 `)` を確認・スキップ
12. 値を比較
    - 等しい場合: 消費したバイト数を返す
    - 等しくない場合: エラーメッセージを表示して終了

### エラーメッセージ

```
Assertion failed: expected <expected>, got <actual>
```

## メモリ使用

- エラーメッセージバッファ: 128バイト（.bssセクション）
- 数値→文字列変換バッファ: 32バイト（既存のnumber_bufferを使用）

## 関数インターフェース

### handle_assert

**入力:**
- x0 (ARM64) / rdi (x86_64): バッファポインタ（"assert"の先頭）
- x1 (ARM64) / rsi (x86_64): 残りのバッファ長

**出力:**
- x0 (ARM64) / rax (x86_64): 消費したバイト数
- 失敗時: プログラムを終了コード1で終了

**使用レジスタ (ARM64):**
- x19: バッファポインタ（保存用）
- x20: 残りの長さ（保存用）
- x21: 消費バイト数カウンタ
- x22: 実際の値（actual）
- x23: 期待値（expected）
- x24: 一時保存用（evaluate_expression呼び出し前の位置）
- x25: 一時保存用（文字列変換の長さ）
- x26: (未使用だがスタックに保存)

**使用レジスタ (x86_64):**
- r12: バッファベースポインタ
- r13: バッファ長
- r15: 現在位置（"assert"の位置）
- r14: パース中の位置
- rbx: 期待値（expected）
- スタック: 実際の値（actual）を一時保存

## 依存関数

- `evaluate_expression` / `parse_expression_advanced`: 式を評価（expression.sで実装済み）
  - ARM64: `evaluate_expression`は`parse_expression_advanced`へのジャンプ
  - x86_64: 同様
- `number_to_string` (ARM64) / `number_to_string_x86` (x86_64): 数値を文字列に変換（assert.s内で実装済み）
- `skip_whitespace_assert` (x86_64): 空白スキップのヘルパー関数（assert.s内で実装済み）
- システムコール: `SYS_WRITE`, `SYS_EXIT`

## テストケース

テストファイル: `tests/test_assert.inmu`

```inmu
# Basic assertions
assert(10, 10)
assert(5 + 3, 8)
assert(10 - 2, 8)
assert(4 * 3, 12)
assert(20 / 4, 5)

# Variable assertions
let x = 10
assert(x, 10)
assert(x + 5, 15)

# Complex expressions
let a = 5
let b = 3
assert(a + b, 8)
assert((a + b) * 2, 16)

print "All assertions passed!"
```
