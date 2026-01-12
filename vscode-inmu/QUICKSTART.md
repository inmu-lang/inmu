# INMU VSCode拡張機能 クイックスタートガイド

## セットアップ

### 1. 拡張機能のビルド

```bash
cd vscode-inmu
npm install
npm run compile
```

### 2. 拡張機能の起動

VS Codeで`vscode-inmu`フォルダを開き、`F5`キーを押すと、拡張機能開発ホストが起動します。

## 主な機能

### 1. シンタックスハイライト

`.inmu`ファイルを開くと、自動的にキーワードや文字列がハイライトされます。

### 2. コード補完（IntelliSense）

コードを入力すると、自動的に補完候補が表示されます：

- `let` - 変数宣言
- `if`, `else`, `while`, `for` - 制御構造
- `fn`, `return` - 関数定義
- `print`, `assert`, `debug` - 組み込み関数

### 3. 定義ジャンプ（Go to Definition）

変数や関数にカーソルを置いて：
- **Windows/Linux**: `F12`
- **macOS**: `F12`

### 4. 参照検索（Find All References）

変数や関数にカーソルを置いて：
- **Windows/Linux**: `Shift+F12`
- **macOS**: `Shift+F12`

### 5. シンボル一覧（Document Symbols）

ファイル内のすべての変数と関数を表示：
- **Windows/Linux**: `Ctrl+Shift+O`
- **macOS**: `Cmd+Shift+O`

### 6. コードフォーマット（Format Document）

コードを自動的に整形：
- **Windows/Linux**: `Shift+Alt+F`
- **macOS**: `Shift+Option+F`

### 7. ホバー情報

キーワードや組み込み関数にマウスカーソルを合わせると、説明が表示されます。

### 8. エラー診断

リアルタイムで構文エラーや警告を表示：
- 変数宣言の構文チェック
- 括弧の対応チェック
- 未定義変数の警告

### 9. ファイル実行

コマンドパレット（`Ctrl+Shift+P` / `Cmd+Shift+P`）を開き、
`INMU: Run Current File`を選択すると、現在のファイルを実行します。

## サンプルコード

以下のコードを`test.inmu`として保存して試してみてください：

```inmu
# 変数宣言
let x = 10
let y = 20

# 関数定義
fn add(a, b) {
    return a + b
}

# 関数呼び出し
let result = add(x, y)
print result

# 条件分岐
if result > 0 {
    print "Positive"
} else {
    print "Not positive"
}

# ループ
let i = 0
while i < 5 {
    print i
    i = i + 1
}
```

## LSP機能のデモ

1. **定義ジャンプ**: 上記コードの`result`にカーソルを置いて`F12`を押すと、定義（`let result = ...`）にジャンプします

2. **参照検索**: `x`にカーソルを置いて`Shift+F12`を押すと、すべての使用箇所が表示されます

3. **シンボル一覧**: `Ctrl+Shift+O` (Mac: `Cmd+Shift+O`) を押すと、`x`, `y`, `add`, `result`, `i`が一覧表示されます

4. **フォーマット**: インデントがバラバラなコードを`Shift+Alt+F` (Mac: `Shift+Option+F`) で整形できます

## トラブルシューティング

### LSPサーバーが起動しない

1. コンパイルエラーがないか確認:
   ```bash
   npm run compile
   ```

2. `out/extension.js`と`out/server.js`が存在するか確認

3. 拡張機能開発ホストを再起動（`F5`を再度押す）

### 言語が認識されない

1. ファイルの拡張子が`.inmu`になっているか確認
2. VS Codeの右下にある言語モードが「INMU」になっているか確認
3. なっていない場合は、言語モードをクリックして「INMU」を選択

## 次のステップ

- より複雑なINMUコードを書いてみる
- エラー診断機能を確認してみる
- 自分のプロジェクトでINMUファイルを作成してみる

詳細は[README.md](README.md)を参照してください。
