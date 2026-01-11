# Assert Not Equal機能の実装

## 概要

テスト関数`assert_ne`（assert not equal）を実装します。式を評価して期待値と**等しくない**ことを確認し、等しい場合はエラーメッセージを表示してプログラムを終了します。

**実装状態**: ✅ 実装済み（assert.s内に`handle_assert_ne`関数として実装）

## 構文

```inmu
assert_ne(actual, not_expected)
```

### 例

```inmu
# 数値リテラルのassert_ne
assert_ne(10, 5)

# 算術式のassert_ne
assert_ne(5 + 3, 9)
assert_ne(10 - 2, 10)

# 変数を使ったassert_ne
let x = 10
assert_ne(x, 5)
assert_ne(x + 5, 10)

# 失敗例（等しいのでエラー）
assert_ne(5 + 3, 8)  # エラー: Assertion failed: expected NOT 8, but got 8
```

## 動作仕様

1. **成功時**（値が等しく**ない**場合）: 何も表示せず、次の行に進む
2. **失敗時**（値が等しい場合）: エラーメッセージを表示してプログラムを終了
   - エラーメッセージ形式: `Assertion failed: expected NOT <not_expected>, but got <actual>`
   - 終了コード: 1

## 実装アルゴリズム

基本的に`assert`と同じですが、比較ロジックが逆になります：
- 値が**等しくない**場合: 成功（バイト数を返す）
- 値が**等しい**場合: 失敗（エラーメッセージを表示して終了）

### ARM64/x86_64 共通ロジック

1. `assert_ne` キーワードをスキップ（9バイト）
2. 空白をスキップ
3. 開き括弧 `(` を確認・スキップ
4. 空白をスキップ
5. 実際の値（式）を評価（`evaluate_expression`または`parse_expression_advanced`関数を使用）
   - 結果を `x22` (ARM64) または スタック (x86_64) に保存
6. 空白をスキップ
7. カンマ `,` を確認・スキップ
8. 空白をスキップ
9. 期待しない値（式）を評価
   - 結果を `x23` (ARM64) または `rbx` (x86_64) に保存
10. 空白をスキップ
11. 閉じ括弧 `)` を確認・スキップ
12. 値を比較
    - 等しくない場合: 消費したバイト数を返す
    - 等しい場合: エラーメッセージを表示して終了

### エラーメッセージ

```
Assertion failed: expected NOT <not_expected>, but got <actual>
```

## メモリ使用

`assert`と同じバッファを再利用：
- エラーメッセージバッファ: 128バイト（.bssセクション内の`assert_error_buffer`）
- 数値→文字列変換バッファ: `assert_number_buf1`, `assert_number_buf2` (各32バイト)

## テストケース

テストファイル: `tests/test_assert_ne.inmu`

```inmu
print "=== Assert Not Equal Tests ==="

# Values that are not equal (should pass)
assert_ne(5, 10)
assert_ne(5 + 3, 9)
assert_ne(10 - 2, 10)

# Test with variables
let x = 10
assert_ne(x, 5)
assert_ne(x + 5, 10)

print "All assert_ne tests passed!"
```
