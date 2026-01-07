# INMU言語 ブートストラップ戦略

## 概要

INMU言語をRustのようにブートストラップ/セルフホスティングで開発するための戦略とロードマップ

## ブートストラップフェーズ

### Stage 0: アセンブリインタプリタ (現在)
**実装言語**: ARM64/x86_64 アセンブリ  
**状態**: 実装済み  
**機能**:
- 基本的な `print` コマンド
- ファイル読み込み
- 単純なパーサー

**役割**: Stage 1コンパイラを実行できるようにする

---

### Stage 1: ミニマルコンパイラ (次の目標)
**実装言語**: INMU言語 (Stage 0で実行)  
**目標**: セルフホスティング可能な最小限のコンパイラ

**必要な機能拡張** (Stage 0に追加):
- 変数宣言と代入
- 関数定義と呼び出し
- 条件分岐 (if/else)
- ループ (while/for)
- 基本的な型システム (int, string, bool)
- ファイル操作
- 文字列操作
- 配列/リスト

**実装するコンパイラ機能**:
- トークナイザー
- パーサー (AST生成)
- 意味解析
- アセンブリコード生成 (ARM64/x86_64)

**成果物**: `inmuc0` - INMU言語で書かれたコンパイラ (Stage 0で実行可能)

---

### Stage 2: セルフホスティング
**実装言語**: INMU言語  
**実行環境**: Stage 1でコンパイルされた `inmuc1`

**目標**:
1. `inmuc0` (INMU言語で書かれたコンパイラ) を `inmuc1` でコンパイル
2. 生成された `inmuc1` が `inmuc0` をコンパイルできることを検証
3. `inmuc1` == `inmuc2` を確認 (再現可能ビルド)

**検証方法**:
```bash
# Stage 0でStage 1コンパイラをビルド
./inmu compiler/stage1/inmuc.inmu > inmuc1.s
as -o inmuc1.o inmuc1.s
ld -o inmuc1 inmuc1.o -lSystem

# Stage 1でStage 1コンパイラを再ビルド (セルフホスト)
./inmuc1 compiler/stage1/inmuc.inmu > inmuc2.s
as -o inmuc2.o inmuc2.s
ld -o inmuc2 inmuc2.o -lSystem

# バイナリ比較
diff inmuc1 inmuc2
```

---

### Stage 3: 最適化コンパイラ
**実装言語**: INMU言語  
**実行環境**: セルフホストされた `inmuc`

**追加機能**:
- 最適化パス
- より高度な型システム
- マクロシステム
- モジュールシステム
- パッケージマネージャー
- エラーメッセージの改善
- デバッグ情報生成

---

## ディレクトリ構造

```
inmu-lang/
├── README.md
├── BOOTSTRAP.md           # このファイル
├── Makefile
│
├── stage0/                # アセンブリインタプリタ
│   ├── src/
│   │   ├── mac/
│   │   │   ├── arm64/
│   │   │   │   └── main.s
│   │   │   └── x86_64/
│   │   │       └── main.s
│   │   └── ...
│   ├── Makefile
│   └── tests/
│
├── stage1/                # ミニマルコンパイラ (INMU言語で実装)
│   ├── compiler/
│   │   ├── lexer.inmu
│   │   ├── parser.inmu
│   │   ├── codegen.inmu
│   │   └── main.inmu
│   ├── runtime/
│   │   └── stdlib.inmu
│   ├── tests/
│   └── Makefile
│
├── stage2/                # セルフホスティング版
│   ├── compiler/
│   ├── runtime/
│   └── tests/
│
├── stage3/                # 最適化版
│   ├── compiler/
│   ├── optimizer/
│   ├── stdlib/
│   └── tools/
│
├── examples/              # サンプルコード
│   ├── hello.inmu
│   ├── fibonacci.inmu
│   └── ...
│
└── docs/                  # ドキュメント
    ├── language-spec.md
    ├── compiler-design.md
    └── stdlib-api.md
```

---

## 開発の進め方

### フェーズ1: Stage 0の機能拡張 (1-2ヶ月)

1. **変数システム**
   ```inmu
   let x = 10
   let name = "INMU"
   ```

2. **関数定義**
   ```inmu
   fn add(a, b) {
       return a + b
   }
   ```

3. **制御構造**
   ```inmu
   if x > 0 {
       print "positive"
   } else {
       print "negative"
   }
   
   while i < 10 {
       print i
       i = i + 1
   }
   ```

4. **配列とループ**
   ```inmu
   let arr = [1, 2, 3, 4, 5]
   for item in arr {
       print item
   }
   ```

### フェーズ2: Stage 1コンパイラの実装 (3-4ヶ月)

1. **レキサー** (`lexer.inmu`)
   - トークン化
   - キーワード認識
   - 数値/文字列リテラル

2. **パーサー** (`parser.inmu`)
   - 再帰下降パーサー
   - AST構築

3. **コード生成** (`codegen.inmu`)
   - ARM64アセンブリ出力
   - レジスタ割り当て
   - 関数呼び出し規約

### フェーズ3: セルフホスティング達成 (1-2ヶ月)

1. コンパイラの検証
2. バグ修正
3. テストスイート整備

### フェーズ4: 最適化と拡張 (継続的)

1. 最適化パスの実装
2. 標準ライブラリの充実
3. ツールチェーンの整備

---

## 参考: Rustのブートストラップ

Rustも同様の戦略を採用:
1. **rustboot**: OCamlで実装された最初のRustコンパイラ
2. **rustc (stage0)**: Rustで書き直されたコンパイラ (rustbootでコンパイル)
3. **rustc (stage1)**: stage0でコンパイルされたコンパイラ (セルフホスト達成)
4. **rustc (stage2)**: stage1でコンパイルされたコンパイラ (検証用)

---

## 現在のステータス

- [x] Stage 0: 基本インタプリタ実装
- [ ] Stage 0: 機能拡張
  - [ ] 変数システム
  - [ ] 関数定義
  - [ ] 制御構造
  - [ ] 配列とループ
- [ ] Stage 1: コンパイラ実装
- [ ] Stage 2: セルフホスティング達成
- [ ] Stage 3: 最適化版

---

## マイルストーン

### マイルストーン1: Stage 0完成
**目標**: 2026年3月  
**成果物**: 完全な機能を持つINMUインタプリタ

### マイルストーン2: Stage 1完成
**目標**: 2026年6月  
**成果物**: INMU言語で書かれたコンパイラ

### マイルストーン3: セルフホスティング達成
**目標**: 2026年8月  
**成果物**: 自分自身をコンパイルできるINMUコンパイラ

### マイルストーン4: 安定版リリース
**目標**: 2026年12月  
**成果物**: プロダクションレディなINMUコンパイラ v1.0

---

## 関連ドキュメント

- [言語仕様](docs/language-spec.md)
- [コンパイラ設計](docs/compiler-design.md)
- [開発ガイド](docs/development.md)
