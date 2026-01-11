# INMU Stage 0 全体アルゴリズム

このドキュメントは、INMU Stage 0 インタプリタの全体的なアルゴリズムと実行フローを説明します。

## システム概要

INMU Stage 0 は、純粋なアセンブリで実装された最小限のインタプリタです。以下の特徴があります：

- ファイルからINMUプログラムを読み込み
- トークンベースの簡易パーサー
- 実行時変数管理
- 式の動的評価
- 基本的な制御フロー

## プログラム実行フロー

### 1. 起動とファイル読み込み

```
main():
    1. コマンドライン引数をチェック
       if argc < 2:
          使用方法を表示して終了
    
    2. argv[1] からファイル名を取得
    
    3. ファイルをオープン (O_RDONLY)
       if オープン失敗:
          エラーメッセージを表示して終了
       fd = ファイルディスクリプタ
    
    4. ファイル内容を file_buffer に読み込み
       read(fd, file_buffer, 4096)
       bytes_read = 読み込んだバイト数
    
    5. ファイルをクローズ
       close(fd)
    
    6. インタプリタを実行
       execute_inmu(file_buffer, bytes_read)
    
    7. 正常終了
       exit(0)
```

### 2. メインインタプリタループ

```
execute_inmu(buffer, length):
    1. 変数テーブルを初期化
       var_count = 0
    
    2. position = 0
    
    3. while position < length:
        a. ホワイトスペースをスキップ
           bytes = skip_whitespace(buffer + position)
           position += bytes
        
        b. if position >= length:
              break  # ファイル終端
        
        c. 現在の文字を取得
           char = buffer[position]
        
        d. コメントチェック
           if char == '#':
              bytes = skip_comment(buffer + position)
              position += bytes
              continue
        
        e. キーワード判定と処理
           if match_keyword("print"):
              bytes = handle_print(buffer + position, length - position)
              position += bytes
           
           else if match_keyword("let"):
              bytes = handle_let(buffer + position, length - position)
              position += bytes
           
           else if match_keyword("if"):
              bytes = handle_if(buffer + position, length - position)
              position += bytes
           
           else:
              # 不明なトークン、スキップまたはエラー
              position++
    
    4. 終了
```

### 3. print 文の処理

```
handle_print(buffer, length):
    1. "print" キーワードをスキップ (5 bytes)
       consumed = 5
    
    2. ホワイトスペースをスキップ
       consumed += skip_whitespace(buffer + consumed)
    
    3. 出力内容を判定
       char = buffer[consumed]
       
       a. 文字列リテラルの場合 (char == '"'):
          - consumed++ (開始クォートをスキップ)
          - 文字列の終わりまで探索
          - 見つかった文字列を出力
          - consumed を更新
       
       b. 式の場合:
          - (value, bytes) = parse_expression_advanced(buffer + consumed)
          - consumed += bytes
          - value を数値として出力
    
    4. 改行を出力
       write(STDOUT, "\n", 1)
    
    5. return consumed
```

### 4. let 文の処理

```
handle_let(buffer, length):
    1. "let" キーワードをスキップ (3 bytes)
       consumed = 3
    
    2. ホワイトスペースをスキップ
       consumed += skip_whitespace(buffer + consumed)
    
    3. 変数名をパース
       (name, bytes) = parse_identifier(buffer + consumed)
       consumed += bytes
    
    4. ホワイトスペースをスキップ
       consumed += skip_whitespace(buffer + consumed)
    
    5. '=' をチェック
       if buffer[consumed] != '=':
          エラー: 構文エラー
       consumed++
    
    6. ホワイトスペースをスキップ
       consumed += skip_whitespace(buffer + consumed)
    
    7. 式を評価
       (value, bytes) = parse_expression_advanced(buffer + consumed)
       consumed += bytes
    
    8. 変数に値を保存
       set_variable(name, value)
    
    9. return consumed
```

### 5. if 文の処理

```
handle_if(buffer, length):
    1. "if" キーワードをスキップ (2 bytes)
       consumed = 2
    
    2. ホワイトスペースをスキップ
       consumed += skip_whitespace(buffer + consumed)
    
    3. 条件式を評価
       (condition, bytes) = parse_expression_advanced(buffer + consumed)
       consumed += bytes
    
    4. ホワイトスペースをスキップ（改行含む）
       consumed += skip_whitespace(buffer + consumed)
    
    5. 条件判定と実行
       if condition != 0:  # 真
          a. true ブロックを実行
             (bytes, has_else) = execute_until_else_or_endif(buffer + consumed)
             consumed += bytes
          
          b. if has_else:
                # else ブロックをスキップ
                bytes = skip_until_endif(buffer + consumed)
                consumed += bytes
       
       else:  # 偽
          a. true ブロックをスキップ
             (bytes, has_else) = skip_until_else_or_endif(buffer + consumed)
             consumed += bytes
          
          b. if has_else:
                # else ブロックを実行
                bytes = execute_until_endif(buffer + consumed)
                consumed += bytes
    
    6. return consumed
```

### 6. 式の評価

```
parse_expression_advanced(buffer, length):
    # エントリポイント
    return parse_add_sub(buffer, length)

parse_add_sub(buffer, length):
    1. 左辺 = parse_mul_div(buffer, length)
       consumed = 消費バイト数
    
    2. loop:
        a. skip_whitespace()
        b. if buffer[consumed] == '+':
              consumed++
              右辺 = parse_mul_div(buffer + consumed)
              左辺 = 左辺 + 右辺
              consumed += 消費バイト数
        c. else if buffer[consumed] == '-':
              consumed++
              右辺 = parse_mul_div(buffer + consumed)
              左辺 = 左辺 - 右辺
              consumed += 消費バイト数
        d. else:
              break
    
    3. return (左辺, consumed)

parse_mul_div(buffer, length):
    1. 左辺 = parse_primary(buffer, length)
       consumed = 消費バイト数
    
    2. loop:
        a. skip_whitespace()
        b. if buffer[consumed] == '*':
              consumed++
              右辺 = parse_primary(buffer + consumed)
              左辺 = 左辺 * 右辺
              consumed += 消費バイト数
        c. else if buffer[consumed] == '/':
              consumed++
              右辺 = parse_primary(buffer + consumed)
              if 右辺 == 0:
                  エラー: ゼロ除算
              左辺 = 左辺 / 右辺
              consumed += 消費バイト数
        d. else:
              break
    
    3. return (左辺, consumed)

parse_primary(buffer, length):
    1. skip_whitespace()
    
    2. char = buffer[0]
    
    3. if char が数字:
          return parse_number(buffer, length)
    
    4. if char が英字またはアンダースコア:
          (name, bytes) = parse_identifier(buffer, length)
          value = get_variable(name)
          return (value, bytes)
    
    5. if char == '(':
          consumed = 1  # '(' をスキップ
          (value, bytes) = parse_expression_advanced(buffer + consumed)
          consumed += bytes
          skip_whitespace()
          if buffer[consumed] != ')':
              エラー: 閉じ括弧がない
          consumed++
          return (value, consumed)
    
    6. エラー: 無効な式
```

## データ構造

### 変数テーブル
```
struct VariableEntry {
    char name[32];      // 変数名
    int64_t value;      // 値
}

VariableEntry variables[256];  // 最大256変数
int var_count = 0;             // 現在の変数数
```

### バッファ
```
char file_buffer[4096];        // ファイル内容
char number_buffer[32];        // 数値変換用バッファ
```

## システムコール使用箇所

### macOS システムコール

1. **open**: ファイルオープン
   - ARM64: `svc #0x80` (syscall 5)
   - x86_64: `syscall` (0x2000005)

2. **read**: ファイル読み込み
   - ARM64: `svc #0x80` (syscall 3)
   - x86_64: `syscall` (0x2000003)

3. **write**: 標準出力への書き込み
   - ARM64: `svc #0x80` (syscall 4)
   - x86_64: `syscall` (0x2000004)

4. **close**: ファイルクローズ
   - ARM64: `svc #0x80` (syscall 6)
   - x86_64: `syscall` (0x2000006)

5. **exit**: プロセス終了
   - ARM64: `svc #0x80` (syscall 1)
   - x86_64: `syscall` (0x2000001)

## エラーハンドリング

現在のエラーハンドリング戦略：

1. **ファイルオープンエラー**: エラーメッセージを表示して exit(1)
2. **構文エラー**: 未実装（多くの場合、単に無視される）
3. **未定義変数**: 0 を返す
4. **ゼロ除算**: 未実装（未定義動作）

## 将来の拡張

Stage 1 以降で実装予定：

1. **比較演算子**: `<`, `>`, `==`, `!=`, `<=`, `>=`
2. **論理演算子**: `and`, `or`, `not`
3. **ループ**: `while`, `for`
4. **関数**: 関数定義と呼び出し
5. **エラーハンドリング**: 適切なエラーメッセージと行番号表示
6. **型システム**: 文字列、配列など
