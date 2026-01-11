# Stage 1 Compiler Verification Guide
# Stage 1コンパイラの検証ガイド

## 現状の課題

Stage 1コンパイラはINMU言語で書かれていますが、現在のStage 0インタプリタは以下の機能をサポートしています：

### ✅ Stage 0で実装済み：
- `print`コマンド（文字列と変数）
- 変数宣言 (`let x = 42`)
- 変数の参照
- コメント (`#`)

### ❌ Stage 0で未実装：
- 式の評価と算術演算
- 関数定義と呼び出し
- 制御構造 (if/while)
- 配列と構造体

そのため、**Stage 1コンパイラを現時点で直接実行することはできません**。

## 検証方法

### 方法1: Pythonツールを使った検証（推奨・今すぐ可能）

Stage 1の各コンポーネントをPythonで再実装して動作確認します。

#### ステップ1: 検証ツールの実行

```bash
cd /path/to/inmu-lang
python3 tools/verify_stage1.py
```

このツールは以下を検証します：
- ✅ Lexer（字句解析器）の動作
- ✅ Stage 1ファイルのトークン解析
- ✅ 各ファイルの統計情報

#### ステップ2: テストケースの検証

```bash
# 個別のテストファイルを解析
python3 tools/verify_stage1.py stage1/tests/test_arithmetic.inmu
python3 tools/verify_stage1.py stage1/tests/test_functions.inmu
```

#### ステップ3: コンパイラの完全な再実装（オプション）

Pythonでコンパイラ全体を再実装し、ARM64アセンブリを生成して動作確認。

### 方法2: 静的解析（コードレビュー）

実行せずにコードの正しさを確認します。

#### チェックリスト

**Lexer (lexer.inmu)**:
- [ ] すべてのトークンタイプが定義されているか
- [ ] キーワードリストが完全か
- [ ] 文字列のエスケープ処理は正しいか
- [ ] 数値リテラル（整数・浮動小数点）をパースできるか
- [ ] 2文字演算子（==, !=, <=, など）を認識できるか

**Parser (parser.inmu)**:
- [ ] 文法規則が正しく実装されているか
- [ ] 演算子の優先順位は正しいか
- [ ] エラーハンドリングは適切か
- [ ] すべてのAST ノードタイプが定義されているか

**CodeGen (codegen.inmu)**:
- [ ] レジスタ割り当てロジックは正しいか
- [ ] 関数呼び出し規約は適切か
- [ ] スタックフレーム管理は正しいか
- [ ] 制御フローのラベル生成は適切か

### 方法3: Stage 0の拡張（本格的なアプローチ）

Stage 0インタプリタにINMU言語の機能を追加して、Stage 1を実行できるようにします。

#### 必要な機能の優先順位

**Phase 1: 基本データ構造**
1. ✅ 変数の宣言と代入 - 完了
2. 式の評価と算術演算
3. 数値と文字列の基本操作
4. 配列の作成とアクセス

**Phase 2: 制御フロー**
4. if/else文
5. whileループ
6. 関数定義と呼び出し

**Phase 3: オブジェクト**
7. 構造体（オブジェクト）のサポート
8. プロパティアクセス

#### 実装スケジュール

```
Week 1-2: ✅ 変数システム (let x = 10) - 完了
Week 3-4: 式の評価と算術演算 (x + y)
Week 5-6: 関数定義 (fn add(a, b) { ... })
Week 7-8: 制御構造 (if/while)
Week 9-10: 配列と構造体
Week 11-12: テストとデバッグ
```

## 推奨される検証フロー

```
┌─────────────────────────────────────┐
│ 1. Python検証ツールで基本動作確認  │
│    → Lexerが正しくトークン化できるか │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 2. 静的解析でコードレビュー         │
│    → ロジックの正しさを確認         │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 3. 簡易テストケースを手動実行      │
│    → 期待される出力を確認           │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│ 4. Stage 0を段階的に拡張            │
│    → 実際にStage 1を実行            │
└─────────────────────────────────────┘
```

## 今すぐできる検証

### 1. Lexerのテスト

```bash
# 検証ツールを実行
python3 tools/verify_stage1.py
```

### 2. 手動でトークン列を確認

`stage1/tests/test_arithmetic.inmu`の内容:
```inmu
let x = 10
let y = 20
let z = x + y
print z
```

期待されるトークン列:
```
KEYWORD 'let'
IDENTIFIER 'x'
OPERATOR '='
NUMBER '10'
KEYWORD 'let'
IDENTIFIER 'y'
OPERATOR '='
NUMBER '20'
...
```

### 3. ASTの構造を確認

期待されるAST:
```
Program
├── VariableDecl (x = 10)
├── VariableDecl (y = 20)
├── VariableDecl (z = x + y)
│   └── BinaryOp (+)
│       ├── Identifier (x)
│       └── Identifier (y)
└── ExpressionStatement
    └── FunctionCall (print)
        └── Identifier (z)
```

### 4. 期待されるアセンブリコード

```asm
.data
.text
.global _main

_main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    # let x = 10
    mov x9, #10
    str x9, [sp, #-8]
    
    # let y = 20
    mov x9, #20
    str x9, [sp, #-16]
    
    # let z = x + y
    ldr x9, [sp, #-8]      # load x
    ldr x10, [sp, #-16]    # load y
    add x9, x9, x10        # x + y
    str x9, [sp, #-24]     # store z
    
    # print z
    ldr x0, [sp, #-24]
    bl _print_int
    
    mov x0, #0
    ldp x29, x30, [sp], #16
    ret
```

## 次のステップ

1. **今日**: Pythonツールで基本検証
2. **今週**: Stage 0に変数システムを追加
3. **来週**: Stage 0に関数定義を追加
4. **来月**: Stage 1を実際に実行

## トラブルシューティング

### Q: Pythonツールがエラーになる
A: Python 3.7以上が必要です。`python3 --version`で確認してください。

### Q: Stage 1ファイルが見つからない
A: プロジェクトのルートディレクトリから実行してください。

### Q: どこから始めればいい？
A: まずPython検証ツールを実行してLexerの動作を確認しましょう。

## 参考資料

- [BOOTSTRAP.md](../BOOTSTRAP.md) - 全体戦略
- [PROGRESS.md](../PROGRESS.md) - 進捗状況
- [compiler-design.md](../docs/compiler-design.md) - 設計ドキュメント
