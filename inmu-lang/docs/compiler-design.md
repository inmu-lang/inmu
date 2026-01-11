# INMU Compiler Design Document

## コンパイラアーキテクチャ

### 概要

INMU Stage 1コンパイラは、3つの主要なフェーズで構成されています：

1. **字句解析 (Lexical Analysis)** - ソースコードをトークン列に変換
2. **構文解析 (Syntax Analysis)** - トークン列から抽象構文木(AST)を構築
3. **コード生成 (Code Generation)** - ASTからターゲットコード(ARM64アセンブリ)を生成

### データフロー

```
Source Code (String)
    ↓
┌───────────────┐
│  Lexer        │
│  (字句解析器)  │
└───────┬───────┘
        │
    Tokens[]
        │
        ↓
┌───────────────┐
│  Parser       │
│  (構文解析器)  │
└───────┬───────┘
        │
      AST
        │
        ↓
┌───────────────┐
│  CodeGen      │
│ (コード生成器)  │
└───────┬───────┘
        │
Assembly Code (String)
```

## 字句解析器 (Lexer)

### 役割

- 入力文字列をトークンの列に変換
- 空白文字とコメントの除去
- 識別子、リテラル、演算子、キーワードの認識

### トークンの種類

| カテゴリ | トークン | 例 |
|---------|---------|-----|
| キーワード | `let`, `fn`, `if`, `while`, `return` | `let x = 10` |
| 識別子 | `IDENTIFIER` | `myVariable`, `add` |
| 数値 | `NUMBER` | `42`, `3.14` |
| 文字列 | `STRING` | `"Hello"` |
| 演算子 | `OPERATOR` | `+`, `-`, `==`, `<=` |
| 括弧 | `LPAREN`, `RPAREN`, `LBRACE`, `RBRACE` | `(`, `)`, `{`, `}` |
| 区切り文字 | `COMMA`, `SEMICOLON` | `,`, `;` |

### アルゴリズム

1. 文字列を先頭から1文字ずつ走査
2. 現在の文字に基づいてトークンタイプを決定
3. トークンの終わりまで文字を収集
4. Tokenオブジェクトを生成してリストに追加
5. 文字列の終わりまで繰り返し

### 実装の詳細

```inmu
struct Lexer {
    source: string,    # 入力文字列
    pos: int,          # 現在の位置
    line: int,         # 現在の行番号
    column: int        # 現在の列番号
}

fn next_token(lexer) -> Token {
    skip_whitespace(lexer)
    
    let ch = current_char(lexer)
    
    if is_digit(ch) {
        return read_number(lexer)
    } else if is_alpha(ch) {
        return read_identifier(lexer)
    } else if ch == '"' || ch == "'" {
        return read_string(lexer)
    } else {
        return read_operator(lexer)
    }
}
```

## 構文解析器 (Parser)

### 役割

- トークン列を解析してASTを構築
- 文法エラーの検出
- 演算子の優先順位の適用

### AST ノード型

```inmu
# プログラム全体
Program {
    statements: Statement[]
}

# 文
VariableDecl { name: string, init: Expression }
Function { name: string, params: string[], body: Block }
IfStatement { condition: Expression, then_branch: Statement, else_branch: Statement? }
WhileStatement { condition: Expression, body: Block }
ReturnStatement { value: Expression? }
ExpressionStatement { expression: Expression }

# 式
BinaryOp { operator: string, left: Expression, right: Expression }
UnaryOp { operator: string, operand: Expression }
FunctionCall { function: Expression, arguments: Expression[] }
Identifier { name: string }
NumberLiteral { value: string }
StringLiteral { value: string }
```

### 文法規則

```
program         → statement* EOF

statement       → varDecl
                | fnDecl
                | ifStmt
                | whileStmt
                | returnStmt
                | exprStmt
                | block

varDecl         → "let" IDENTIFIER ("=" expression)?
fnDecl          → "fn" IDENTIFIER "(" params? ")" block
ifStmt          → "if" expression block ("else" (ifStmt | block))?
whileStmt       → "while" expression block
returnStmt      → "return" expression?
exprStmt        → expression

expression      → assignment
assignment      → logicalOr ("=" assignment)?
logicalOr       → logicalAnd ("||" logicalAnd)*
logicalAnd      → equality ("&&" equality)*
equality        → relational (("==" | "!=") relational)*
relational      → additive (("<" | ">" | "<=" | ">=") additive)*
additive        → multiplicative (("+" | "-") multiplicative)*
multiplicative  → unary (("*" | "/" | "%") unary)*
unary           → ("-" | "!") unary | postfix
postfix         → primary ("(" arguments? ")")*
primary         → NUMBER | STRING | IDENTIFIER | "true" | "false"
                | "(" expression ")" | "[" (expression ("," expression)*)? "]"
```

### パーサーの実装方法

再帰下降パーサー (Recursive Descent Parser) を使用：

```inmu
fn parse_expression(parser) -> Expression {
    return parse_assignment(parser)
}

fn parse_assignment(parser) -> Expression {
    let left = parse_logical_or(parser)
    
    if match_value(parser, "=") {
        advance_token(parser)
        let right = parse_assignment(parser)
        return Assignment { left: left, right: right }
    }
    
    return left
}

fn parse_binary_op(parser, parse_next, operators) -> Expression {
    let left = parse_next(parser)
    
    while current_token_in(parser, operators) {
        let op = current_token(parser).value
        advance_token(parser)
        let right = parse_next(parser)
        left = BinaryOp { operator: op, left: left, right: right }
    }
    
    return left
}
```

## コード生成器 (CodeGen)

### 役割

- ASTからARM64アセンブリコードを生成
- レジスタ割り当て
- スタックフレーム管理
- 関数呼び出し規約の実装

### ARM64 レジスタ使用規約

| レジスタ | 用途 | 呼び出し規約 |
|---------|------|------------|
| x0-x7   | 引数/戻り値 | Caller-saved |
| x8      | 間接結果レジスタ | Caller-saved |
| x9-x15  | 一時レジスタ | Caller-saved |
| x16-x17 | プラットフォーム用 | - |
| x18     | 予約 | - |
| x19-x28 | Callee-saved | Callee-saved |
| x29     | フレームポインタ | Callee-saved |
| x30     | リンクレジスタ | - |
| sp (x31)| スタックポインタ | - |

### 関数のプロローグとエピローグ

**プロローグ:**
```asm
function_name:
    stp x29, x30, [sp, #-16]!  # FP, LRを保存
    mov x29, sp                 # FPを設定
    # ローカル変数用のスタック確保
```

**エピローグ:**
```asm
    mov x0, <return_value>      # 戻り値をx0に設定
    ldp x29, x30, [sp], #16     # FP, LRを復元
    ret                         # 呼び出し元に戻る
```

### 式の評価

式の評価は後順走査 (Post-order Traversal) で行います：

```inmu
fn generate_binary_op(codegen, expr) -> Register {
    let left_reg = generate_expression(codegen, expr.left)
    let right_reg = generate_expression(codegen, expr.right)
    
    emit(codegen, "add " + left_reg + ", " + left_reg + ", " + right_reg)
    
    free_register(right_reg)
    return left_reg
}
```

### 変数とスタック管理

変数はスタック上に配置され、オフセットで管理されます：

```
スタックレイアウト:
+------------------+  <- x29 (FP)
| 戻りアドレス (LR)|
+------------------+
| 旧FP (x29)       |
+------------------+
| ローカル変数 1   |  <- [sp, #-8]
+------------------+
| ローカル変数 2   |  <- [sp, #-16]
+------------------+  <- sp
```

### 制御フロー

**if文の生成:**
```asm
    <条件式の評価>
    cmp <cond_reg>, #0
    b.eq else_label         # 偽ならelse/endへ
    <then節>
    b end_label
else_label:
    <else節>
end_label:
```

**while文の生成:**
```asm
loop_label:
    <条件式の評価>
    cmp <cond_reg>, #0
    b.eq end_label          # 偽なら終了
    <ループ本体>
    b loop_label
end_label:
```

## 最適化

### 現在の実装

Stage 1では最適化は最小限です：

- 定数畳み込み (未実装)
- デッドコード除去 (未実装)
- レジスタ割り当ての改善 (未実装)

### 将来の拡張

- ピープホール最適化
- 共通部分式除去 (CSE)
- ループ最適化
- インライン展開

## エラーハンドリング

### 字句エラー

- 未知の文字
- 終了していない文字列
- 不正な数値リテラル

### 構文エラー

- 予期しないトークン
- 括弧の不一致
- 不完全な文

### 意味エラー

- 未定義の変数
- 型の不一致 (将来の拡張)
- 引数の数の不一致

## テスト戦略

### ユニットテスト

各モジュール (Lexer, Parser, CodeGen) を個別にテスト

### 統合テスト

完全なプログラムをコンパイルして実行結果を検証

### リグレッションテスト

既知のバグが再発しないことを確認

## 参考文献

- "Crafting Interpreters" by Robert Nystrom
- "Engineering a Compiler" by Keith Cooper & Linda Torczon
- ARM Architecture Reference Manual
- Compiler Design: Virtual Machines" by Reinhard Wilhelm & Helmut Seidl
