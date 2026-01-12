# INMU Language Support for VS Code

INMU言語のためのVS Code拡張機能です。Language Server Protocol (LSP) を使用した強力な言語サポートを提供します。

## 機能

### 基本機能
- **シンタックスハイライト**: INMU言語のキーワード、文字列、コメントなどに色付け
- **コード補完**: キーワード、組み込み関数の自動補完（IntelliSense）
- **ホバー情報**: キーワードや関数にカーソルを合わせると説明を表示

### LSP機能
- **定義ジャンプ**: 変数や関数の定義へジャンプ（F12）
- **参照検索**: シンボルの全使用箇所を検索（Shift+F12）
- **ドキュメントシンボル**: ファイル内の全シンボルを一覧表示（Ctrl+Shift+O / Cmd+Shift+O）
- **診断機能**: リアルタイムで構文エラーや警告を表示
  - 変数宣言の構文チェック
  - 括弧の対応チェック
  - 未定義変数の検出
- **コードフォーマッティング**: 自動インデント整形（Shift+Alt+F / Shift+Option+F）

### 実行機能
- **ファイル実行**: コマンドパレット（Ctrl+Shift+P / Cmd+Shift+P）から `INMU: Run Current File` を選択して実行

## インストール方法

### 開発版のインストール

1. この拡張機能のディレクトリに移動:
```bash
cd vscode-inmu
```

2. 依存関係をインストール:
```bash
npm install
```

3. ビルド:
```bash
npm run compile
```

4. VS Codeで拡張機能をデバッグ:
   - VS Codeでこのディレクトリを開く
   - `F5`キーを押して拡張機能開発ホストを起動

### パッケージ化してインストール

```bash
# vsce (VS Code Extension Manager) をインストール
npm install -g @vscode/vsce

# パッケージ化
vsce package

# VSIXファイルをインストール
code --install-extension inmu-language-0.1.0.vsix
```

## 使い方

### 基本的な使い方

1. `.inmu`拡張子のファイルを開く
2. 自動的にINMU言語として認識される
3. コード入力時に補完候補が表示される

### LSP機能の使い方

- **定義へジャンプ**: 変数や関数の上で`F12`を押す
- **参照の検索**: 変数や関数の上で`Shift+F12`を押す
- **シンボル一覧**: `Ctrl+Shift+O` (Mac: `Cmd+Shift+O`) でファイル内のシンボルを表示
- **コードフォーマット**: `Shift+Alt+F` (Mac: `Shift+Option+F`) でコードを整形
- **ファイル実行**: `Ctrl+Shift+P` (Mac: `Cmd+Shift+P`) で `INMU: Run Current File` を選択

### サンプルコード

```inmu
# Hello World
print "Hello, INMU!"

# 変数宣言
let x = 42
let name = "INMU Language"

# 条件分岐
if x > 0 {
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

# 関数定義
fn add(a, b) {
    return a + b
}

let result = add(10, 20)
print result
```

## 補完できるキーワード

### 制御構造
- `let` - 変数宣言
- `if`, `else` - 条件分岐
- `while`, `for` - ループ
- `fn`, `return` - 関数定義

### 組み込み関数
- `print` - 出力
- `assert`, `assert_ne` - アサーション
- `debug`, `trace` - デバッグ出力

### 定数
- `true`, `false` - 真偽値

## 開発

### プロジェクト構造

```
vscode-inmu/
├── package.json              # 拡張機能の設定
├── tsconfig.json             # TypeScript設定
├── language-configuration.json # 言語設定（括弧、コメントなど）
├── syntaxes/
│   └── inmu.tmLanguage.json  # シンタックスハイライト定義
└── src/
    ├── extension.ts          # 拡張機能のエントリポイント
    └── server.ts             # LSPサーバー実装
```

### ビルドコマンド

```bash
# 依存関係のインストール
npm install

# コンパイル
npm run compile

# ウォッチモード（開発時）
npm run watch
```

### LSPサーバーの機能

現在実装されているLanguage Server Protocol機能：

1. **テキスト同期** - ドキュメントの変更を追跡
2. **診断** - リアルタイムでエラーや警告を表示
3. **補完** - IntelliSenseによる自動補完
4. **ホバー** - シンボルにマウスオーバー時の情報表示
5. **定義** - Go to Definition機能
6. **参照** - Find All References機能
7. **ドキュメントシンボル** - Outline/シンボル一覧
8. **フォーマッティング** - コード整形

## トラブルシューティング

### LSPサーバーが起動しない場合

1. TypeScriptのコンパイルエラーを確認:
```bash
npm run compile
```

2. `out/`ディレクトリに`extension.js`と`server.js`が生成されているか確認

3. VS Codeを再起動

### 構文ハイライトが効かない場合

- `.inmu`ファイルを開いている状態で、右下の言語モード表示をクリックし、「INMU」が選択されているか確認
- 選択されていない場合は、「言語モードの選択」から「INMU」を選択

## 今後の予定

- [ ] セマンティックトークンプロバイダー
- [ ] リネーム機能
- [ ] コードアクション（クイックフィックス）
- [ ] より高度な構文解析
- [ ] デバッガーサポート
- [ ] テスト実行サポート

## ライセンス

MIT

## 貢献

プルリクエストやイシューの報告を歓迎します！

## 関連リンク

- [INMU言語仕様](../inmu-lang/docs/language-spec.md)
- [Visual Studio Code API](https://code.visualstudio.com/api)
- [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)

## ライセンス

MIT

## 作者

INMU Language Project
