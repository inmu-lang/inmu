# Stage 1 コンパイラ開発計画

## 概要

Stage 1は、INMU言語で書かれた最初のコンパイラです。Stage 0（アセンブリインタプリタ）上で実行され、INMU言語からアセンブリコードを生成します。

## アーキテクチャ

```
┌─────────────┐
│ source.inmu │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Lexer     │  トークン化
│ (lexer.inmu)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Parser    │  AST構築
│(parser.inmu)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Codegen   │  アセンブリ生成
│(codegen.inmu)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  output.s   │  ARM64/x86_64
└─────────────┘
```

## ファイル構成

```
stage1/
├── compiler/
│   ├── main.inmu       # エントリーポイント
│   ├── lexer.inmu      # トークナイザー
│   ├── parser.inmu     # パーサー
│   ├── ast.inmu        # AST定義
│   ├── codegen.inmu    # コード生成
│   └── error.inmu      # エラーハンドリング
├── runtime/
│   └── stdlib.inmu     # 標準ライブラリ
├── tests/
│   ├── lexer_test.inmu
│   ├── parser_test.inmu
│   └── codegen_test.inmu
├── examples/
│   ├── simple.inmu     # シンプルな例
│   ├── fibonacci.inmu  # フィボナッチ
│   └── factorial.inmu  # 階乗
└── Makefile
```

## 実装フェーズ

### フェーズ1: レキサー実装

**ファイル**: `lexer.inmu`

**トークン種類**:
```inmu
# 識別子とキーワード
IDENT, LET, FN, IF, ELSE, WHILE, FOR, RETURN

# リテラル
INT, FLOAT, STRING, TRUE, FALSE

# 演算子
PLUS, MINUS, STAR, SLASH, PERCENT
EQ, NEQ, LT, GT, LTE, GTE
AND, OR, NOT

# デリミタ
LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET
COMMA, SEMICOLON, COLON, ARROW

# その他
EOF, NEWLINE
```

**実装例**:
```inmu
# Token構造体
struct Token {
    type: string,
    value: string,
    line: int,
    column: int
}

# Lexer構造体
struct Lexer {
    source: string,
    position: int,
    line: int,
    column: int
}

# トークン化
fn tokenize(source: string) -> [Token] {
    let lexer = Lexer { 
        source: source, 
        position: 0, 
        line: 1, 
        column: 1 
    }
    
    let tokens = []
    
    while !lexer.is_eof() {
        lexer.skip_whitespace()
        
        if lexer.is_eof() {
            break
        }
        
        let token = lexer.next_token()
        tokens.push(token)
    }
    
    return tokens
}
```

---

### フェーズ2: パーサー実装

**ファイル**: `parser.inmu`, `ast.inmu`

**AST ノード定義**:
```inmu
# 式ノード
struct IntLiteral { value: int }
struct StringLiteral { value: string }
struct Identifier { name: string }
struct BinaryOp { left: Expr, op: string, right: Expr }
struct FunctionCall { name: string, args: [Expr] }

# 文ノード
struct LetStatement { name: string, value: Expr }
struct IfStatement { condition: Expr, then: [Stmt], else: [Stmt] }
struct WhileStatement { condition: Expr, body: [Stmt] }
struct ReturnStatement { value: Expr }
struct FunctionDef { name: string, params: [string], body: [Stmt] }

# プログラム
struct Program { statements: [Stmt] }
```

**パーサー実装**:
```inmu
struct Parser {
    tokens: [Token],
    position: int
}

fn parse(tokens: [Token]) -> Program {
    let parser = Parser { tokens: tokens, position: 0 }
    let statements = []
    
    while !parser.is_eof() {
        let stmt = parser.parse_statement()
        statements.push(stmt)
    }
    
    return Program { statements: statements }
}

# 再帰下降パーサー
fn parse_statement(parser: Parser) -> Stmt {
    let token = parser.current()
    
    if token.type == "LET" {
        return parser.parse_let_statement()
    } else if token.type == "FN" {
        return parser.parse_function_def()
    } else if token.type == "IF" {
        return parser.parse_if_statement()
    } else if token.type == "WHILE" {
        return parser.parse_while_statement()
    } else if token.type == "RETURN" {
        return parser.parse_return_statement()
    } else {
        return parser.parse_expression_statement()
    }
}
```

---

### フェーズ3: コード生成

**ファイル**: `codegen.inmu`

**レジスタ割り当て**:
- ARM64: x0-x7 (引数/戻り値), x19-x28 (保存レジスタ)
- スタックフレーム管理

**実装例**:
```inmu
struct CodeGen {
    output: string,
    label_counter: int,
    stack_offset: int
}

fn generate_code(ast: Program) -> string {
    let gen = CodeGen { output: "", label_counter: 0, stack_offset: 0 }
    
    # プロローグ
    gen.emit(".global _main")
    gen.emit(".align 2")
    gen.emit("_main:")
    gen.emit("    stp x29, x30, [sp, #-16]!")
    gen.emit("    mov x29, sp")
    
    # 各文のコード生成
    for stmt in ast.statements {
        gen.generate_statement(stmt)
    }
    
    # エピローグ
    gen.emit("    mov x0, #0")
    gen.emit("    ldp x29, x30, [sp], #16")
    gen.emit("    ret")
    
    return gen.output
}

fn generate_expression(gen: CodeGen, expr: Expr) {
    if expr is IntLiteral {
        gen.emit("    mov x0, #" + expr.value)
    } else if expr is BinaryOp {
        gen.generate_expression(expr.left)
        gen.emit("    str x0, [sp, #-16]!")  # push
        gen.generate_expression(expr.right)
        gen.emit("    ldr x1, [sp], #16")    # pop
        
        if expr.op == "+" {
            gen.emit("    add x0, x1, x0")
        } else if expr.op == "-" {
            gen.emit("    sub x0, x1, x0")
        } else if expr.op == "*" {
            gen.emit("    mul x0, x1, x0")
        }
    }
}
```

---

## コンパイラの使用方法

### 開発中（Stage 0で実行）

```bash
# Stage 0インタプリタでコンパイラを実行
cd inmu-lang
./inmu stage1/compiler/main.inmu input.inmu > output.s

# アセンブルとリンク
as -o output.o output.s
ld -o output output.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _main

# 実行
./output
```

### ビルドシステム統合後

```bash
# Stage 1コンパイラをビルド
make stage1

# コンパイラを使用
./inmuc1 program.inmu -o program
./program
```

---

## テスト戦略

### ユニットテスト

```inmu
# tests/lexer_test.inmu
fn test_tokenize_numbers() {
    let tokens = tokenize("42 3.14")
    assert(tokens.len() == 2)
    assert(tokens[0].type == "INT")
    assert(tokens[0].value == "42")
    assert(tokens[1].type == "FLOAT")
    assert(tokens[1].value == "3.14")
}

fn test_tokenize_operators() {
    let tokens = tokenize("+ - * /")
    assert(tokens.len() == 4)
    assert(tokens[0].type == "PLUS")
    assert(tokens[1].type == "MINUS")
    assert(tokens[2].type == "STAR")
    assert(tokens[3].type == "SLASH")
}
```

### 統合テスト

```bash
# test.sh
#!/bin/bash

echo "Testing simple arithmetic..."
echo 'print 1 + 2' > test.inmu
./inmuc1 test.inmu > test.s
as -o test.o test.s
ld -o test test.o -lSystem
./test
# Expected: 3

echo "Testing function definition..."
echo 'fn add(a, b) { return a + b }' > test.inmu
echo 'print add(10, 20)' >> test.inmu
./inmuc1 test.inmu > test.s
# ... compile and run
# Expected: 30
```

---

## マイルストーン

### M1.1: レキサー完成 (2週間)
- [ ] トークナイザー実装
- [ ] すべてのトークンタイプ対応
- [ ] ユニットテスト作成

### M1.2: パーサー完成 (3週間)
- [ ] AST定義
- [ ] 再帰下降パーサー実装
- [ ] エラーハンドリング

### M1.3: コード生成 (4週間)
- [ ] 基本式のコード生成
- [ ] 制御構造のコード生成
- [ ] 関数呼び出し規約

### M1.4: 統合とテスト (2週間)
- [ ] 統合テスト
- [ ] バグ修正
- [ ] ドキュメント整備

---

## Stage 0に必要な機能拡張

Stage 1コンパイラを実装するには、Stage 0に以下の機能が必要です:

1. **構造体**
2. **配列操作** (push, pop, len, indexing)
3. **文字列操作** (split, substring, len)
4. **ファイルI/O** (read_file, write_file)
5. **関数定義と呼び出し**
6. **制御構造** (if/else, while, for)
7. **変数とスコープ**

これらの機能は、Stage 0の拡張として先に実装する必要があります。
