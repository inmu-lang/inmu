# パーサーロジック

INMU Stage 0 のパーサーの共通ロジックを定義します。

## メイン実行ループ

### execute_inmu
**目的**: INMUプログラムを実行する

**入力**:
- buffer: プログラムテキストへのポインタ
- length: バッファの長さ（バイト数）

**処理フロー**:
```
1. position = 0 で初期化
2. while position < length:
    a. skip_whitespace() でホワイトスペースをスキップ
    b. 現在位置の文字を取得
    c. キーワードを判定:
       - "print" → handle_print() を呼び出し
       - "let"   → handle_let() を呼び出し
       - "if"    → handle_if() を呼び出し
       - "#"     → skip_comment() を呼び出し
       - それ以外 → 次の文字へ
    d. position を更新
3. 終了
```

**注意点**:
- コメント（#で始まる行）は改行まで無視
- 空白行は自動的にスキップされる
- 各ステートメントは改行で区切られる

## ホワイトスペース処理

### skip_whitespace
**目的**: スペース、タブ、改行をスキップする

**入力**:
- buffer: テキストバッファ
- position: 現在の位置
- length: バッファ長

**出力**:
- スキップしたバイト数

**処理**:
```
1. count = 0
2. while position + count < length:
    a. char = buffer[position + count]
    b. if char == ' ' or char == '\t' or char == '\n':
       count++
    c. else:
       break
3. return count
```

## コメント処理

### skip_comment
**目的**: # から改行までをスキップ

**入力**:
- buffer: テキストバッファ
- position: 現在の位置（# の位置）
- length: バッファ長

**出力**:
- スキップしたバイト数

**処理**:
```
1. count = 0
2. while position + count < length:
    a. char = buffer[position + count]
    b. count++
    c. if char == '\n':
       break
3. return count
```

## キーワード判定

### match_keyword
**目的**: バッファの現在位置が特定のキーワードと一致するか判定

**入力**:
- buffer: テキストバッファ
- position: 現在の位置
- keyword: 比較するキーワード文字列
- keyword_len: キーワードの長さ

**出力**:
- 一致する場合: true (1)
- 一致しない場合: false (0)

**処理**:
```
1. 残りバッファ長が keyword_len より小さい場合、false を返す
2. i = 0 から keyword_len まで:
    a. if buffer[position + i] != keyword[i]:
       return false
3. キーワード直後が英数字またはアンダースコアの場合、false を返す
   （"print" と "printer" を区別するため）
4. return true
```

## 数値のパース

### parse_number
**目的**: 現在位置から整数をパースする

**入力**:
- buffer: テキストバッファ
- position: 現在の位置
- length: バッファ長

**出力**:
- value: パースされた数値
- consumed: 消費したバイト数

**処理**:
```
1. value = 0
2. count = 0
3. while position + count < length:
    a. char = buffer[position + count]
    b. if char >= '0' and char <= '9':
       value = value * 10 + (char - '0')
       count++
    c. else:
       break
4. return (value, count)
```

## 識別子（変数名）のパース

### parse_identifier
**目的**: 変数名をパースする

**入力**:
- buffer: テキストバッファ
- position: 現在の位置
- length: バッファ長

**出力**:
- name: 変数名（文字列）
- consumed: 消費したバイト数

**処理**:
```
1. count = 0
2. 最初の文字が英字またはアンダースコアでなければエラー
3. while position + count < length:
    a. char = buffer[position + count]
    b. if char が英数字またはアンダースコア:
       name[count] = char
       count++
    c. else:
       break
4. name[count] = '\0' (null終端)
5. return (name, count)
```

**制約**:
- 変数名は英字またはアンダースコアで始まる
- 2文字目以降は英数字またはアンダースコア
- 最大32文字
