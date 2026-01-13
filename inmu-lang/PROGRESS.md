# INMU プロジェクト進捗状況

**更新日**: 2026年1月14日

## プロジェクト概要

INMU言語は、セルフホスティングを目指すプログラミング言語プロジェクトです。Rustのブートストラップ戦略に倣い、段階的に実装を進めています。

## 現在のステータス

### Stage 0: Rustインタプリタ ✅ (完了)

**実装言語**: Rust  
**状態**: 基本機能実装済み

#### 完了した機能
- [x] 基本的な`print`コマンド（文字列と数値）
- [x] 変数宣言と保存 (`let x = 42`)
- [x] 変数の参照 (`print x`)
- [x] **算術演算子** (`+`, `-`, `*`, `/`)
- [x] **比較演算子** (`==`)
- [x] **式の評価** (変数参照、数値リテラル、算術式)
- [x] **括弧** (式の優先順位制御)
- [x] **制御構造** (`if/else/endif` による条件分岐)
- [x] **アサーション** (`assert`, `assert_ne`)
- [x] コメント対応 (`//`, `/* */`)
- [x] ファイル読み込み
- [x] トークナイザー（字句解析）
- [x] パーサー（構文解析）
- [x] インタプリタ（実行エンジン）
- [x] クロスプラットフォーム対応（Rust製）

#### ファイル構成
```
stage0/
├── Cargo.toml             # Rustプロジェクト設定
├── src/
│   ├── main.rs            # エントリーポイント
│   ├── token.rs           # トークナイザー（字句解析）
│   ├── ast.rs             # AST定義
│   ├── parser.rs          # パーサー（構文解析）
│   └── interpreter.rs     # インタプリタ（実行エンジン）
└── target/
    └── release/
        └── inmu           # 実行可能バイナリ
```

#### Rust実装の利点
- **クロスプラットフォーム**: macOS、Linux、Windowsで同じコードが動作
- **メモリ安全性**: Rustコンパイラが安全性を保証
- **開発効率**: cargo、rustfmt、clippyなどの豊富なツールチェーン
- **パフォーマンス**: C言語と同等の実行速度
- **エラー処理**: 詳細なエラーメッセージ

### Stage 1: ミニマルコンパイラ 🚧 (実装中)

**実装言語**: INMU言語  
**実行環境**: Stage 0インタプリタ  
**状態**: コンパイラ本体の実装完了、Stage 0の機能拡張が必要

#### 完了した作業
- [x] レキサー実装 (`compiler/lexer.inmu`)
- [x] パーサー実装 (`compiler/parser.inmu`)
- [x] コード生成器実装 (`compiler/codegen.inmu`)
- [x] メインプログラム (`compiler/main.inmu`)
- [x] ランタイムライブラリ骨格 (`runtime/stdlib.inmu`)
- [x] テストケース作成 (5個)
- [x] ドキュメント整備
- [x] Makefile作成

#### 実装されたコンパイラ機能

**字句解析器 (Lexer)**:
- トークン化
- キーワード認識 (`let`, `fn`, `if`, `else`, `while`, `for`, `return`, etc.)
- 数値リテラル (整数、浮動小数点)
- 文字列リテラル (エスケープシーケンス対応)
- 演算子認識 (算術、比較、論理)
- コメントのスキップ

**構文解析器 (Parser)**:
- 再帰下降パーサー
- AST生成
- 演算子の優先順位処理
- 以下の構文をサポート:
  - 変数宣言 (`let x = 10`)
  - 関数定義 (`fn add(a, b) { ... }`)
  - 条件分岐 (`if`/`else`)
  - ループ (`while`)
  - return文
  - 式と演算

**コード生成器 (CodeGen)**:
- ARM64アセンブリ生成
- レジスタ割り当て (x9-x15を使用)
- スタックフレーム管理
- 関数呼び出し規約の実装
- 二項演算子のコード生成
- 制御フローのコード生成

#### テストケース
1. `test_arithmetic.inmu` - 算術演算
2. `test_functions.inmu` - 関数定義と呼び出し
3. `test_if.inmu` - 条件分岐
4. `test_while.inmu` - whileループ
5. `test_fibonacci.inmu` - フィボナッチ数列（再帰）

#### 次に必要な作業

**重要**: Stage 1コンパイラはINMU言語で書かれているため、Stage 0インタプリタがこれらの機能をサポートする必要があります。

**Stage 0への機能追加が必要**:
1. ✅ 変数宣言 - 完了
   ```inmu
   let x = 10
   ```

2. ✅ 式の評価と算術演算 - 完了
   ```inmu
   let result = x + 5
   let product = a * b
   print (x + y) * 2
   ```

3. ✅ 制御構造（if/else） - 完了
   ```inmu
   if x == 10
       print "x is 10"
   else
       print "x is not 10"
   endif
   ```

4. ✅ アサーション - 完了
   ```inmu
   assert(actual, expected)
   assert_ne(actual, expected)
   ```

5. 変数への再代入
   ```inmu
   x = x + 5
   ```

6. 関数定義と呼び出し
   ```inmu
   fn add(a, b) {
       return a + b
   }
   let result = add(10, 20)
   ```

7. ループ構造
   ```inmu
   while i < 10 {
       print i
       i = i + 1
   }
   ```

8. 配列操作
   ```inmu
   let arr = [1, 2, 3]
   print arr[0]
   arr.push(4)
   ```

9. ファイル操作
   ```inmu
   let content = read_file("input.txt")
   write_file("output.txt", "Hello")
   ```

### Stage 2: セルフホスティング ⏳ (未着手)

**目標**: Stage 1コンパイラ自身をコンパイルできるようにする

### Stage 3: 最適化コンパイラ ⏳ (未着手)

**目標**: 最適化とフル機能の実装

## マイルストーン

### ✅ マイルストーン 0: Stage 0完成 (2026年1月)
- [x] Rustインタプリタ実装
- [x] トークナイザーとパーサー
- [x] 基本的なprint機能
- [x] 変数システム
- [x] 式の評価と算術演算
- [x] 条件分岐（if/else/endif）
- [x] アサーション

### 🚧 マイルストーン 1: Stage 0機能拡張 (目標: 2026年3月)
- [x] 変数システム実装
- [x] 式の評価と算術演算
- [x] 制御構造 (if/else/endif)
- [x] 等価比較演算子 (`==`)
- [x] アサーション (`assert`, `assert_ne`)
- [ ] より多くの比較演算子 (`!=`, `<`, `>`, `<=`, `>=`)
- [ ] 論理演算子 (`&&`, `||`, `!`)
- [ ] whileループ
- [ ] 変数への再代入
- [ ] 関数定義と呼び出し
- [ ] 配列操作
- [ ] ファイルI/O拡張

### ⏳ マイルストーン 2: Stage 1完成 (目標: 2026年6月)
- [x] コンパイラ実装（INMU言語で）
- [ ] Stage 0でStage 1を実行
- [ ] テストスイート整備

### ⏳ マイルストーン 3: セルフホスティング達成 (目標: 2026年8月)
- [ ] inmuc1でinmuc0をコンパイル
- [ ] inmuc1 == inmuc2の検証
- [ ] 再現可能ビルド

### ⏳ マイルストーン 4: 安定版リリース (目標: 2026年12月)
- [ ] 最適化パス実装
- [ ] 標準ライブラリ充実
- [ ] v1.0リリース

## 開発優先順位

### 最優先 (今週)
1. ✅ Stage 0に変数システムを追加 - 完了
2. ✅ Stage 0に式の評価機能を追加（算術演算） - 完了
3. ✅ Stage 0にif/else実装 - 完了
4. Stage 0に変数への再代入機能を追加

### 高優先 (今月)
5. Stage 0により多くの比較演算子を追加 (`!=`, `<`, `>`, `<=`, `>=`)
6. Stage 0にwhileループ実装
7. Stage 0に関数定義機能を追加
8. Stage 1コンパイラをStage 0で実行してテスト

### 中優先 (来月)
8. 配列操作のサポート
9. 構造体のサポート
10. エラーハンドリングの改善

## プロジェクト統計

### コード量
- Stage 0 (Rust):
  - main.rs: ~50行
  - token.rs: ~260行
  - ast.rs: ~40行
  - parser.rs: ~400行
  - interpreter.rs: ~140行
  - **合計**: ~890行
- Stage 1 (INMU言語):
  - Lexer: ~360行
  - Parser: ~470行
  - CodeGen: ~430行
  - Main: ~50行
  - Tests: ~50行
  - **合計**: ~1,360行

### ドキュメント
- README.md
- BOOTSTRAP.md
- PROGRESS.md
- stage0/README.md
- language-spec.md (421行)
- compiler-design.md
- verification-guide.md

## リスク管理

### 現在のリスク

1. **Stage 0の機能追加** (中)
   - 解決策: Rustの型安全性を活用、ユニットテストの充実

2. **Stage 1コンパイラの複雑性** (高)
   - 解決策: 段階的な機能追加、詳細なテストケース

3. **時間不足** (中)
   - 解決策: 優先順位を明確化、MVP(Minimum Viable Product)重視

## 学習リソース

### 参考にしている資料
- "Crafting Interpreters" by Robert Nystrom
- Rust compiler bootstrap process
- "Writing An Interpreter In Go" by Thorsten Ball
- "Engineering a Compiler" by Cooper & Torczon

## 次のステップ

### 今週の作業
1. ✅ Stage 0のRust実装完成
2. ✅ 基本機能のテスト完了
3. 変数への再代入機能の実装

### 来週の作業
4. より多くの比較演算子の追加
5. 論理演算子の実装
6. whileループの実装
7. 関数定義の基本構造を設計

### 今月の目標
8. 関数呼び出しの実装
9. 配列の基本操作
10. Stage 1コンパイラの簡易版をStage 0で実行

## 貢献とフィードバック

プロジェクトへの貢献、バグ報告、機能提案を歓迎します！

## ライセンス

MIT License

---

**プロジェクトの進捗**: 約15% (Stage 0完了、Stage 1実装完了、Stage 0機能拡張が残っている)
