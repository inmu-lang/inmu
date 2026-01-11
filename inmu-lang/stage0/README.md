# Stage 0: アセンブリインタプリタ

INMU言語のブートストラップの第一段階。純粋なARM64/x86_64アセンブリで実装された基本的なインタプリタです。

## 🎯 目的

Stage 1のコンパイラ（INMU言語で書かれる）を実行できる基盤を提供します。CやRustなどの高級言語に依存せず、純粋なアセンブリのみで実装されています。

## ✅ 実装済み機能

- ✅ `print` コマンド - 文字列と変数の出力
- ✅ 変数システム - `let` による変数宣言と値の保存（最大256変数）
- ✅ 数値と変数の評価 - 変数の参照と数値リテラル
- ✅ ファイル読み込み - `.inmu` ファイルの読み込みと実行
- ✅ コメント対応 - `#` による行コメント
- ✅ ARM64 (Apple Silicon) サポート
- ✅ x86_64 (Intel Mac) サポート
- ✅ 基本的な構文解析

## 📁 ディレクトリ構造

```
stage0/
├── Makefile           # ビルド設定
├── README.md          # このファイル
├── inmu               # コンパイル済みバイナリ
└── src/
    └── mac/
        ├── arm64/
        │   ├── main.s
        │   └── include/
        │       └── print.s
        └── x86_64/
            ├── main.s
            └── include/
                └── print.s
```

## 🔨 ビルド方法

### 必要な環境

- macOS (Apple Silicon または Intel)
- Xcode Command Line Tools

### コンパイル

```bash
# 現在のアーキテクチャ用にビルド
make

# クリーン
make clean

# ユニバーサルバイナリを作成 (ARM64 + x86_64)
make universal
```

### インストール (オプション)

```bash
# /usr/local/bin にインストール
make install
```

## 🚀 使い方

### 基本的な実行

```bash
./inmu <filename.inmu>
```

### サンプルプログラムを実行

```bash
# Hello Worldプログラムを実行
./inmu ../examples/hello.inmu

# テストを実行
make test
```

## 📝 サポートされる構文

### Stage 0でサポートされるコマンド

#### print文
文字列や変数を標準出力に出力します。

```inmu
print "Hello, World!"
print "INMU Language"
print x
```

#### 変数宣言
`let`キーワードで変数を宣言し、数値を代入できます。

```inmu
let x = 42
let y = 100
let z = 999
```

#### コメント
`#`で始まる行はコメントとして無視されます。

```inmu
# これはコメント
print "実行される"
```

## 🔍 技術的な詳細

### 実装言語
- 純粋な ARM64/x86_64 アセンブリ
- macOSシステムコールを直接使用

### システムコール
- `SYS_READ` (3) - ファイル読み込み
- `SYS_WRITE` (4) - 標準出力
- `SYS_OPEN` (5) - ファイルオープン
- `SYS_CLOSE` (6) - ファイルクローズ
- `SYS_EXIT` (1) - プログラム終了

### アーキテクチャサポート
- **ARM64** (`src/mac/arm64/main.s`) - Apple Silicon (M1/M2/M3)
- **x86_64** (`src/mac/x86_64/main.s`) - Intel Mac

## 🛠️ 今後の拡張予定

Stage 1コンパイラを実行するために、以下の機能を追加予定:

- [ ] 式の評価と算術演算子 (`+`, `-`, `*`, `/`)
- [ ] 変数への再代入 (`x = x + 1`)
- [ ] 関数定義と呼び出し (`fn add(a, b) { ... }`)
- [ ] 制御構造 (`if`, `else`, `while`, `for`)
- [ ] 比較演算子 (`==`, `!=`, `<`, `>`, `<=`, `>=`)
- [ ] 論理演算子 (`&&`, `||`, `!`)
- [ ] 配列/リスト操作 (`[1, 2, 3]`, `arr[0]`)
- [ ] 文字列操作と連結
- [ ] 構造体/オブジェクト
- [ ] ファイル I/O 機能の拡張
- [ ] ブロック構文 (`{ ... }`)

## 🔗 関連ドキュメント

- [プロジェクト全体の README](../README.md)
- [ブートストラップ戦略](../BOOTSTRAP.md)
- [Stage 1 開発計画](../stage1/README.md)
- [言語仕様](../docs/language-spec.md)

## 🐛 デバッグ

### ファイルが開けない場合

```bash
# ファイルのパーミッションを確認
ls -la ../examples/hello.inmu

# 実行権限を確認
ls -la ./inmu
chmod +x ./inmu
```

### アーキテクチャを確認

```bash
# 現在のアーキテクチャを表示
uname -m

# バイナリのアーキテクチャを確認
file ./inmu
```

## 📄 ライセンス

親プロジェクトのライセンスに準拠します。
