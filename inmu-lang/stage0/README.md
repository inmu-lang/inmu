# Stage 0: アセンブリインタプリタ

INMU言語のブートストラップの第一段階。純粋なARM64/x86_64アセンブリで実装された基本的なインタプリタです。

## 🎯 目的

Stage 1のコンパイラ（INMU言語で書かれる）を実行できる基盤を提供します。CやRustなどの高級言語に依存せず、純粋なアセンブリのみで実装されています。

## ✅ 実装済み機能

- ✅ `print` コマンド - 文字列、変数、および式の出力
- ✅ 変数システム - `let` による変数宣言と値の保存（最大256変数）
- ✅ **算術演算子** - `+`, `-`, `*`, `/` による式の評価
- ✅ **式の評価** - 変数参照、数値リテラル、算術式をサポート
- ✅ **括弧** - 式の優先順位制御に対応
- ✅ **制御構造** - `if/else/endif` による条件分岐
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
├── run_tests.sh       # テストスクリプト
└── src/
    ├── common/                 # 共通ロジック（ドキュメント）
    │   ├── README.md           # 共通化の説明
    │   ├── algorithm.md        # 全体アルゴリズム
    │   ├── constants.md        # 定数定義
    │   ├── parser.md           # パーサーロジック
    │   ├── expression.md       # 式評価ロジック
    │   ├── variables.md        # 変数管理ロジック
    │   └── control.md          # 制御構造ロジック
    ├── arch/                   # アーキテクチャ固有実装
    │   ├── arm64/              # ARM64実装 (Apple Silicon)
    │   │   ├── main.s
    │   │   └── include/
    │   │       ├── print.s       # 出力機能
    │   │       ├── variables.s   # 変数管理
    │   │       ├── expression.s  # 式評価と算術演算
    │   │       └── control.s     # 制御構造 (if/else)
    │   └── x86_64/             # x86_64実装 (Intel Mac)
    │       ├── main.s
    │       └── include/
    │           ├── print.s
    │           ├── variables.s
    │           ├── expression.s
    │           └── control.s
    └── mac/                    # 旧構造（後方互換性のため残存）
```

## アーキテクチャ設計

### 共通化戦略

1. **ロジックの文書化**: `src/common/` 配下に各モジュールのアルゴリズムを Markdown で文書化
2. **アーキテクチャ固有実装**: `src/arch/{ARCH}/` に ARM64 と x86_64 の実装を分離
3. **インターフェース統一**: 両アーキテクチャで同じ関数名とデータ構造を使用

詳細は [src/common/README.md](src/common/README.md) を参照してください。

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
make test              # 簡単なテスト
make test-all          # 全テストを実行
./run_tests.sh         # テストスクリプトを直接実行
./run_tests.sh --output # 出力付きでテスト実行
```

## 📝 サポートされる構文

### Stage 0でサポートされるコマンド

#### print文
文字列、変数、または算術式を標準出力に出力します。

```inmu
print "Hello, World!"
print "INMU Language"
print x
print 10 + 5
print x * 2
print (x + y) / 2
```

#### 変数宣言
`let`キーワードで変数を宣言し、数値または式を代入できます。

```inmu
let x = 42
let y = 100
let z = x + y
let result = (x + y) * 2
```

#### 算術演算
以下の算術演算子をサポートしています：
- `+` - 加算
- `-` - 減算
- `*` - 乗算
- `/` - 除算（整数除算）
- `()` - 括弧による優先順位制御

```inmu
let a = 10 + 5       # 15
let b = 20 - 8       # 12
let c = 6 * 7        # 42
let d = 100 / 4      # 25
let e = (10 + 5) * 2 # 30
```

#### 制御構造 (if/else)
条件分岐を使用できます（現在は `==` 比較のみサポート）：

```inmu
let x = 10

if x == 10
print "x is 10"
endif

if x == 5
print "x is 5"
else
print "x is not 5"
endif
```
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

## 🛠️ Stage 1に向けて必要な追加機能

Stage 1コンパイラを実装するために、以下の機能を今後追加予定:

### 優先度: 高
- [x] 式の評価と算術演算子 (`+`, `-`, `*`, `/`)
- [x] 制御構造の基礎 (`if`, `else`)
- [ ] 配列/リスト操作 (`[1, 2, 3]`, `arr[0]`, `push`, `pop`, `len`)
- [ ] 文字列操作 (`split`, `substring`, `concat`, `len`)

### 優先度: 中
- [ ] 関数定義と呼び出し (`fn add(a, b) { ... }`)
- [ ] より多くの比較演算子 (`!=`, `<`, `>`, `<=`, `>=`)
- [ ] 論理演算子 (`&&`, `||`, `!`)
- [ ] whileループ (`while condition { ... }`)

### 優先度: 低（Stage 1では不要な可能性）
- [ ] 構造体/オブジェクト
- [ ] forループ
- [ ] ファイル I/O 機能の拡張
- [ ] 変数への再代入 (`x = x + 1`)

### 現在の状況

現在、Stage 0は以下をサポートしています：
- ✅ 基本的な式の評価（算術演算、変数参照）
- ✅ 条件分岐（if/else）
- ✅ 変数の宣言と使用

Stage 1のコンパイラを実装するには、主に**配列操作**と**文字列操作**が必要です。これらがあれば、トークンのリストを扱い、文字列を解析してコンパイラを実装できます。

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
