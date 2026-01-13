# INMU Programming Language

[![Stage 0 Tests](https://github.com/YOUR_USERNAME/inmu/actions/workflows/test-stage0.yml/badge.svg)](https://github.com/YOUR_USERNAME/inmu/actions/workflows/test-stage0.yml)

ARM64アセンブリで実装され、Rustのようなブートストラップ戦略でセルフホスティングを目指すプログラミング言語です。

## 🎯 プロジェクトの目標

- **セルフホスティング**: INMU言語で書かれたコンパイラが自分自身をコンパイルできる
- **クロスプラットフォーム**: Rust実装により、Windows/macOS/Linux全てで動作
- **教育的価値**: コンパイラとブートストラップの仕組みを学べる

## 📚 ブートストラップ戦略

詳細は [BOOTSTRAP.md](BOOTSTRAP.md) を参照してください。

### Stage 0: Rustインタプリタ ✅ (現在)
- **実装**: Rust
- **役割**: Stage 1コンパイラを実行できる基盤
- **状態**: 基本機能実装済み（クロスプラットフォーム対応）

### Stage 1: セルフホストコンパイラ 🚧 (待機中)
- **実装**: INMU言語（実装完了）
- **実行**: Stage 0上で動作（機能拡張待ち）
- **出力**: ARM64/x86_64 アセンブリ
- **状態**: コンパイラコードは完成、Stage 0の機能拡張待ち

### Stage 2: 検証済みセルフホスト 📋 (計画中)
- **実装**: INMU言語
- **実行**: Stage 1でコンパイル
- **検証**: Stage 1 == Stage 2

### Stage 3: 最適化コンパイラ 📋 (計画中)
- **追加**: 最適化パス、標準ライブラリ拡充

## 🚀 クイックスタート

### 必要な環境

- Rust (1.70以降)
- make (Unix系) または PowerShell (Windows)

### ビルド方法

**Unix系 (macOS/Linux):**
```bash
# Stage 0インタプリタをビルド
make

# または直接cargo
cd stage0 && cargo build --release
```

**Windows (PowerShell):**
```powershell
# makeがある場合
make

# または直接cargo
cd stage0
cargo build --release
Copy-Item target/release/inmu.exe ../inmu.exe
```

### 使い方

**Unix系:**
```bash
# サンプルプログラムを実行
./inmu examples/hello.inmu
```

**Windows:**
```powershell
# サンプルプログラムを実行
.\inmu.exe examples\hello.inmu
```

### サンプルコード

`examples/hello.inmu`:
```inmu
print "Hello, INMU Language!"
print "Welcome to Assembly!"
```

## 📖 ドキュメント

- [ブートストラップ戦略](BOOTSTRAP.md) - 開発戦略とロードマップ
- [言語仕様](docs/language-spec.md) - INMU言語の文法と機能
- [Stage 1開発計画](stage1/README.md) - コンパイラ実装の詳細

## 🏗️ プロジェクト構造

```
inmu-lang/
├── stage0/          # Rustインタプリタ
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs
│       ├── token.rs
│       ├── ast.rs
│       ├── parser.rs
│       └── interpreter.rs
├── stage1/          # セルフホストコンパイラ (INMU言語)
│   ├── compiler/
│   ├── runtime/
│   └── tests/
├── stage2/          # 検証用
├── stage3/          # 最適化版
├── examples/        # サンプルコード
├── docs/            # ドキュメント
└── Makefile         # クロスプラットフォームビルド
```

## 🔧 開発状況

### 現在実装済み (Stage 0 - Rust版)
- [x] 基本的な `print` コマンド（文字列、数値、式）
- [x] 変数システム（`let` で宣言）
- [x] **算術演算** (`+`, `-`, `*`, `/`) と括弧のサポート
- [x] **比較演算** (`==`)
- [x] **式の評価** - 変数参照、数値リテラル、複雑な算術式
- [x] **制御構造** - `if/else/endif` による条件分岐
- [x] **アサーション** - `assert`, `assert_ne`
- [x] コメント対応 (`//`, `/* */`)
- [x] ファイル読み込み
- [x] **クロスプラットフォーム** - Windows/macOS/Linux対応

### 次の実装予定 (Stage 1コンパイラに必要)
- [ ] **配列操作** - リスト作成、インデックスアクセス、push/pop/len
- [ ] **文字列操作** - split, substring, concat, len
- [ ] 関数定義と呼び出し (オプション)
- [ ] whileループ (オプション)
- [ ] より多くの比較演算子 (`!=`, `<`, `>`, `<=`, `>=`)

### Stage 0の現在の状況

基本的なコンパイラを書くための核となる機能（算術、条件分岐）は実装済みです。
Stage 1のコンパイラを実装するには、主に**配列**と**文字列操作**が必要です。
- [ ] 配列操作とループ
- [ ] 文字列操作の拡張

### Stage 1実装予定
- [ ] レキサー (トークナイザー)
- [ ] パーサー (AST構築)
- [ ] コード生成 (ARM64アセンブリ)

## 📅 マイルストーン

| マイルストーン | 目標時期 | 状態 |
|--------------|---------|------|
| Stage 0 基本実装 | 2026年1月 | ✅ 完了 |
| Stage 0 機能拡張 | 2026年3月 | 🚧 進行中 |
| Stage 1 コンパイラ | 2026年6月 | 📋 計画中 |
| セルフホスティング達成 | 2026年8月 | 📋 計画中 |
| v1.0 リリース | 2026年12月 | 📋 計画中 |

## 🛠️ 技術仕様

- **言語**: ARM64/x86_64 Assembly → INMU Language
- **アセンブラ**: GNU Assembler (as)
- **リンカ**: ld
- **対応OS**: macOS (Apple Silicon & Intel)

## 📦 インストール

システム全体で使えるようにインストール:

```bash
sudo make install
```

これで `/usr/local/bin/inmu` にインストールされます。

## 🤝 参考プロジェクト

- **Rust**: OCamlで実装 → Rustで書き直し → セルフホスト
- **Go**: Cで実装 → Goで書き直し → セルフホスト
- **PyPy**: Pythonで実装 → RPythonで書き直し → セルフホスト

## 📄 ライセンス

MIT License
