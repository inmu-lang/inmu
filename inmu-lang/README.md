# INMU Programming Language

ARM64アセンブリで実装されたシンプルなプログラミング言語インタプリタです。

## 特徴

- **Pure Assembly**: CやRustを使わず、ARM64アセンブリのみで実装
- **macOS対応**: Apple Silicon (M1/M2/M3) Mac用に最適化
- **シンプル**: 最小限の機能で動作するインタプリタ

## ビルド方法

```bash
make
```

## 使い方

```bash
./inmu examples/hello.inmu
```

または:

```bash
inmu examples/hello.inmu
```

## サンプルコード

`examples/hello.inmu`:
```
print "Hello, INMU Language!"
```

## 実装詳細

### アーキテクチャ

- **レクサー/パーサー**: シンプルなキーワード検索ベース
- **システムコール**: macOS ARM64のシステムコールを直接使用
  - `SYS_OPEN` (5): ファイルオープン
  - `SYS_READ` (3): ファイル読み込み
  - `SYS_WRITE` (4): 標準出力への書き込み
  - `SYS_CLOSE` (6): ファイルクローズ

### 現在サポートされている機能

- `print` コマンド: メッセージを出力

## インストール

システム全体で使えるようにインストール:

```bash
sudo make install
```

これで `/usr/local/bin/inmu` にインストールされ、どこからでも `inmu` コマンドが使えます。

## 技術仕様

- **言語**: ARM64 Assembly
- **アセンブラ**: GNU Assembler (as)
- **リンカ**: ld
- **対応OS**: macOS (Apple Silicon)
- **ファイルサイズ制限**: 4096バイト

## ライセンス

MIT License
