# INMU Language - Stage 0 (Rust Implementation)

Rustで実装されたINMU言語のインタプリタです。

## ビルド方法

```bash
cd stage0
cargo build --release
```

## 使い方

```bash
./target/release/inmu <filename.inmu>
```

または、ルートディレクトリのMakefileから：

```bash
cd ..
make stage0
./inmu examples/hello.inmu
```

## 実装された機能

- ✅ `print` - 式の出力（文字列と数値）
- ✅ `let` - 変数宣言と代入
- ✅ 算術演算子 (`+`, `-`, `*`, `/`)
- ✅ 比較演算子 (`==`)
- ✅ 式の評価（括弧、演算子の優先順位）
- ✅ `if/else/endif` - 条件分岐
- ✅ `assert(actual, expected)` - アサーション
- ✅ `assert_ne(actual, expected)` - 不等アサーション
- ✅ コメント
  - 単一行: `//`
  - 複数行: `/* ... */`

## Rust実装の利点

- **クロスプラットフォーム**: macOS、Linux、Windowsで同じコードが動作
- **メモリ安全**: Rustのコンパイラが安全性を保証
- **メンテナンス性**: 読みやすく、修正しやすいコード
- **パフォーマンス**: Cと同等の高速性
- **エラー処理**: 詳細なエラーメッセージとスタックトレース
- **開発効率**: cargo、rustfmt、clipper等の充実したツールチェーン

## テスト

サンプルプログラムで動作確認：

```bash
# ビルド後のテスト
./target/release/inmu ../examples/hello.inmu
./target/release/inmu ../examples/arithmetic.inmu
./target/release/inmu ../examples/variables.inmu
./target/release/inmu ../examples/test_assert.inmu
./target/release/inmu ../examples/control.inmu
```

## アーキテクチャ

- `main.rs` - エントリーポイント、ファイル読み込み、各モジュールの統合
- `token.rs` - トークナイザー（字句解析）
- `ast.rs` - AST（抽象構文木）の定義
- `parser.rs` - パーサー（構文解析）
- `interpreter.rs` - インタプリタ（実行エンジン）

## Stage 1への展望

Rustの実装を基に、Stage 1コンパイラ実行のために以下を追加予定：

- [ ] 関数定義と呼び出し (`fn`, `return`)
- [ ] ループ構造 (`while`, `for`)
- [ ] 配列/リスト
- [ ] 文字列操作関数
- [ ] ファイル入出力
- [ ] より高度な型システム
- [ ] REPLモード（オプション）
