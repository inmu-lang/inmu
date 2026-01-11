# 変数管理ロジック

INMU Stage 0 の変数管理システムの共通ロジックを定義します。

## データ構造

### 変数テーブル
変数は配列として管理されます：

```
variables[MAX_VARIABLES]
  ├─ [0]: 変数エントリ 0
  ├─ [1]: 変数エントリ 1
  └─ ...

各エントリ:
  ├─ name[MAX_VAR_NAME_LEN]  # 変数名（null終端文字列）
  └─ value                    # 変数の値（整数）

定数:
  MAX_VARIABLES = 256     # 最大変数数
  MAX_VAR_NAME_LEN = 32   # 変数名の最大長
```

### グローバル変数
```
var_count: 現在登録されている変数の数
```

## 関数詳細

### handle_let
**目的**: `let` 文を処理して変数を定義する

**入力**:
- buffer: テキストバッファ
- position: "let" の位置
- length: バッファ長

**出力**:
- consumed: 消費したバイト数

**処理フロー**:
```
1. consumed = 3 ("let" をスキップ)

2. skip_whitespace()
   consumed += スキップバイト数

3. 変数名をパース:
   (name, bytes) = parse_identifier(buffer + consumed)
   consumed += bytes

4. skip_whitespace()
   consumed += スキップバイト数

5. '=' 記号を確認:
   if buffer[consumed] != '=':
      エラー（構文エラー）
   consumed++

6. skip_whitespace()
   consumed += スキップバイト数

7. 式を評価:
   (value, bytes) = parse_expression_advanced(buffer + consumed)
   consumed += bytes

8. 変数を保存:
   set_variable(name, value)

9. return consumed
```

### set_variable
**目的**: 変数に値を設定（新規または更新）

**入力**:
- name: 変数名
- value: 設定する値

**出力**:
- なし

**処理**:
```
1. 既存の変数を検索:
   for i = 0 to var_count - 1:
      if variables[i].name == name:
         variables[i].value = value
         return

2. 新しい変数を追加:
   if var_count >= MAX_VARIABLES:
      エラー（変数数上限）
   
   variables[var_count].name = name をコピー
   variables[var_count].value = value
   var_count++
```

**注意**:
- 同じ名前の変数が既に存在する場合は値を更新
- 新しい変数の場合は末尾に追加

### get_variable
**目的**: 変数の値を取得

**入力**:
- name: 変数名

**出力**:
- value: 変数の値
- found: 変数が見つかったかどうか（0 or 1）

**処理**:
```
1. 変数を検索:
   for i = 0 to var_count - 1:
      if variables[i].name == name:
         return (variables[i].value, 1)

2. 見つからなかった場合:
   return (0, 0)
```

### find_variable_index
**目的**: 変数のインデックスを取得（内部ヘルパー関数）

**入力**:
- name: 変数名

**出力**:
- index: 変数のインデックス（見つからない場合は -1）

**処理**:
```
1. for i = 0 to var_count - 1:
      if variables[i].name == name:
         return i

2. return -1
```

### compare_string
**目的**: 2つの文字列を比較（内部ヘルパー関数）

**入力**:
- str1: 文字列1
- str2: 文字列2
- max_len: 最大比較長

**出力**:
- 0: 一致
- 非0: 不一致

**処理**:
```
1. for i = 0 to max_len - 1:
      if str1[i] != str2[i]:
         return 1
      if str1[i] == '\0':
         return 0  # 両方が同じ長さで終了

2. return 0  # すべて一致
```

## 使用例

### 例1: 単純な変数代入
```
入力: "let x = 10"

処理:
  1. "let" をスキップ
  2. skip_whitespace()
  3. parse_identifier() → "x"
  4. skip_whitespace()
  5. '=' を確認・スキップ
  6. skip_whitespace()
  7. parse_expression_advanced() → 10
  8. set_variable("x", 10)

結果:
  variables[0].name = "x"
  variables[0].value = 10
  var_count = 1
```

### 例2: 式を使った代入
```
入力: "let y = 5 + 3"

処理:
  1-6. 上記と同様
  7. parse_expression_advanced() → 8 (5 + 3 を評価)
  8. set_variable("y", 8)

結果:
  variables[1].name = "y"
  variables[1].value = 8
  var_count = 2
```

### 例3: 変数の更新
```
初期状態:
  variables[0] = {name: "x", value: 10}
  var_count = 1

入力: "let x = 20"

処理:
  set_variable("x", 20) が呼ばれる
  → 既存の変数 "x" が見つかる
  → variables[0].value を 20 に更新

結果:
  variables[0].name = "x"
  variables[0].value = 20  # 更新
  var_count = 1  # 変わらず
```

### 例4: 変数を参照する代入
```
初期状態:
  variables[0] = {name: "x", value: 10}
  var_count = 1

入力: "let z = x + 5"

処理:
  1-6. 変数名 "z" をパース
  7. parse_expression_advanced("x + 5")
     → get_variable("x") → 10
     → 10 + 5 = 15
  8. set_variable("z", 15)

結果:
  variables[0] = {name: "x", value: 10}
  variables[1] = {name: "z", value: 15}
  var_count = 2
```

## メモリレイアウト例（ARM64）

```assembly
.bss
.align 3
variables:
    .skip (32 + 8) * 256    # (name[32] + value[8]) * 256変数
                            # = 40 * 256 = 10,240 bytes

var_count:
    .skip 8                 # 8 bytes (64-bit integer)
```

## メモリレイアウト例（x86_64）

```assembly
.bss
.align 8
variables:
    .skip (32 + 8) * 256    # (name[32] + value[8]) * 256変数
                            # = 40 * 256 = 10,240 bytes

var_count:
    .skip 8                 # 8 bytes (64-bit integer)
```
