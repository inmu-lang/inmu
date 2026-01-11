# 制御構造ロジック

INMU Stage 0 の制御構造（if/else/endif）の共通ロジックを定義します。

## 概要

INMU Stage 0 は以下の制御構造をサポートします：

```
if <condition>
    <true-block>
else
    <false-block>
endif
```

条件式は現在、単純な比較のみをサポート：
- 式の評価結果が 0 でない場合: true
- 式の評価結果が 0 の場合: false

## 関数詳細

### parse_if_statement
**目的**: `if` 文を処理する

**入力**:
- x0 (ARM64) / r15 (x86_64): バッファポインタ（"if"の位置）
- x1 (ARM64) / - (x86_64): 残りのバッファ長

**出力**:
- x0 (ARM64) / rax (x86_64): 消費したバイト数

**処理フロー**:
```
1. consumed = 2 ("if" をスキップ)

2. skip_whitespace()
   consumed += スキップバイト数

3. 条件式を評価:
   (condition, bytes) = parse_expression_advanced(buffer + consumed)
   consumed += bytes

4. 改行をスキップ:
   skip_whitespace()
   consumed += スキップバイト数

5. if condition != 0:  # 条件が真
      a. true ブロックを実行:
         (bytes, has_else) = execute_until_else_or_endif(buffer + consumed)
         consumed += bytes
      
      b. if has_else:
         # else ブロックをスキップ
         bytes = skip_until_endif(buffer + consumed)
         consumed += bytes
   
   else:  # 条件が偽
      a. true ブロックをスキップ:
         (bytes, has_else) = skip_until_else_or_endif(buffer + consumed)
         consumed += bytes
      
      b. if has_else:
         # else ブロックを実行
         bytes = execute_until_endif(buffer + consumed)
         consumed += bytes

6. return consumed
```

**注意**: 実際の実装では、現在の if 文は比較演算子（`==`）をサポートしており、
`if <left_expr> == <right_expr>` の形式で条件を評価します。

### execute_until_else_or_endif
**目的**: `else` または `endif` に到達するまで実行

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- consumed: 消費したバイト数
- has_else: `else` が見つかったかどうか（0 or 1）

**処理**:
```
1. consumed = 0
2. nest_level = 0  # ネストレベル（入れ子の if に対応）

3. while consumed < length:
    a. skip_whitespace()
       consumed += スキップバイト数
    
    b. if match_keyword("if"):
       nest_level++  # 内側の if
       # この if 文を通常通り実行
       bytes = parse_if_statement(buffer + consumed)
       consumed += bytes
       nest_level--
       continue
    
    c. if match_keyword("else") and nest_level == 0:
       consumed += 4  # "else" をスキップ
       return (consumed, 1)  # else が見つかった
    
    d. if match_keyword("endif") and nest_level == 0:
       consumed += 5  # "endif" をスキップ
       return (consumed, 0)  # endif が見つかった
    
    e. # 通常の文を実行
       bytes = execute_statement(buffer + consumed)
       consumed += bytes

4. エラー（endif が見つからない）
```

### skip_until_else_or_endif
**目的**: `else` または `endif` まで実行せずにスキップ

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- consumed: 消費したバイト数
- has_else: `else` が見つかったかどうか（0 or 1）

**処理**:
```
1. consumed = 0
2. nest_level = 0

3. while consumed < length:
    a. skip_whitespace()
       consumed += スキップバイト数
    
    b. if match_keyword("if"):
       nest_level++
       consumed += 2  # "if" をスキップ
       continue
    
    c. if match_keyword("else") and nest_level == 0:
       consumed += 4
       return (consumed, 1)
    
    d. if match_keyword("endif"):
       if nest_level == 0:
          consumed += 5
          return (consumed, 0)
       else:
          nest_level--
          consumed += 5
    
    e. # 行をスキップ
       while consumed < length and buffer[consumed] != '\n':
          consumed++
       consumed++  # 改行もスキップ

4. エラー（endif が見つからない）
```

### execute_until_endif
**目的**: `endif` まで実行

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- consumed: 消費したバイト数

**処理**:
```
1. consumed = 0
2. nest_level = 0

3. while consumed < length:
    a. skip_whitespace()
       consumed += スキップバイト数
    
    b. if match_keyword("if"):
       nest_level++
       bytes = parse_if_statement(buffer + consumed)
       consumed += bytes
       nest_level--
       continue
    
    c. if match_keyword("endif") and nest_level == 0:
       consumed += 5
       return consumed
    
    d. # 通常の文を実行
       bytes = execute_statement(buffer + consumed)
       consumed += bytes

4. エラー（endif が見つからない）
```

### skip_until_endif
**目的**: `endif` まで実行せずにスキップ

**入力**:
- buffer: テキストバッファ
- length: バッファ長

**出力**:
- consumed: 消費したバイト数

**処理**:
```
1. consumed = 0
2. nest_level = 0

3. while consumed < length:
    a. skip_whitespace()
       consumed += スキップバイト数
    
    b. if match_keyword("if"):
       nest_level++
       consumed += 2
       continue
    
    c. if match_keyword("endif"):
       if nest_level == 0:
          consumed += 5
          return consumed
       else:
          nest_level--
          consumed += 5
    
    d. # 行をスキップ
       while consumed < length and buffer[consumed] != '\n':
          consumed++
       consumed++

4. エラー（endif が見つからない）
```

## 使用例

### 例1: 単純な if 文（条件が真）
```
入力:
  let x = 10
  if x
      print "x is non-zero"
  endif

処理:
  1. x = 10 を設定
  2. parse_if_statement() が呼ばれる
  3. parse_expression_advanced("x") → 10 (真)
  4. execute_until_else_or_endif() で print 文を実行
  5. endif で終了

出力:
  x is non-zero
```

### 例2: if/else 文（条件が偽）
```
入力:
  let x = 0
  if x
      print "x is non-zero"
  else
      print "x is zero"
  endif

処理:
  1. x = 0 を設定
  2. parse_if_statement() が呼ばれる
  3. parse_expression_advanced("x") → 0 (偽)
  4. skip_until_else_or_endif() で true ブロックをスキップ
  5. else が見つかる
  6. execute_until_endif() で else ブロックを実行
  7. endif で終了

出力:
  x is zero
```

### 例3: ネストした if 文
```
入力:
  let x = 10
  if x
      let y = 5
      if y
          print "both non-zero"
      endif
  endif

処理:
  1. x = 10 を設定
  2. 外側の parse_if_statement() が呼ばれる
  3. parse_expression_advanced("x") → 10 (真)
  4. execute_until_else_or_endif() で内部を実行:
     a. y = 5 を設定
     b. 内側の parse_if_statement() が呼ばれる (nest_level = 1)
     c. parse_expression_advanced("y") → 5 (真)
     d. print "both non-zero" を実行
     e. 内側の endif
  5. 外側の endif

出力:
  both non-zero
```

### 例4: 式を使った条件
```
入力:
  let x = 10
  if x + 5
      print "condition is true"
  endif

処理:
  1. x = 10 を設定
  2. parse_if_statement() が呼ばれる
  3. parse_expression_advanced("x + 5")
     → get_variable("x") = 10
     → 10 + 5 = 15 (真)
  4. print "condition is true" を実行

出力:
  condition is true
```

## 注意事項

1. **ネスト対応**: `nest_level` カウンタで入れ子の if をサポート
2. **endif 必須**: すべての if には対応する endif が必要
3. **else は任意**: else ブロックは省略可能
4. **条件式**: 現在は単純な式評価のみ（0 = false, 非0 = true）
5. **将来の拡張**: 比較演算子（<, >, ==, != など）は Stage 1 以降で実装予定
