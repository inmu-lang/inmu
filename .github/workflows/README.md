# GitHub Actions Workflows

このディレクトリには、INMU言語プロジェクトのCI/CDワークフローが含まれています。

## ワークフロー一覧

### CI (`ci.yml`)

**トリガー**: 
- `main` / `develop` ブランチへのpush
- `main` / `develop` ブランチへのPull Request

**実行内容**:
- マルチプラットフォームテスト（Ubuntu、macOS、Windows）
- コードフォーマットチェック（`cargo fmt`）
- Lintチェック（`cargo clippy`）
- ユニットテスト（`cargo test`）
- 統合テスト（サンプルプログラムの実行）
- リリースバイナリのビルド（複数プラットフォーム）

### リリース - macOS ARM64 (`release-macos-arm64.yml`)

**トリガー**: GitHubでリリースが公開されたとき

**実行内容**:
- Apple Silicon (ARM64) 用バイナリのビルド
- テスト実行
- リリースアセットのアップロード (`inmu-macos-arm64.tar.gz`)

### リリース - macOS x86_64 (`release-macos-x86_64.yml`)

**トリガー**: GitHubでリリースが公開されたとき

**実行内容**:
- Intel Mac (x86_64) 用バイナリのビルド
- テスト実行
- リリースアセットのアップロード (`inmu-macos-x86_64.tar.gz`)

### リリース - マルチプラットフォーム (`release-multiplatform.yml`)

**トリガー**: GitHubでリリースが公開されたとき

**実行内容**:
- Linux (x86_64) 用バイナリのビルドとリリース
- Windows (x86_64) 用バイナリのビルドとリリース
- macOS (ARM64/x86_64) 用バイナリのビルドとリリース
- **VS Code拡張機能 (.vsix) のビルドとリリース**

## ビルド成果物

各プラットフォーム向けに以下のバイナリが生成されます：

- `inmu-macos-arm64.tar.gz` - macOS Apple Silicon版
- `inmu-macos-x86_64.tar.gz` - macOS Intel版
- `inmu-linux-x86_64.tar.gz` - Linux x86_64版
- `inmu-windows-x86_64.zip` - Windows x86_64版
- `inmu-language-x.x.x.vsix` - VS Code拡張機能

各アーカイブには以下が含まれます：
- `inmu` 実行可能ファイル（Windowsは`inmu.exe`）
- `README.md` - プロジェクト説明
- `Makefile` - ビルドツール
- `examples/` - サンプルプログラム
- `docs/` - ドキュメント

VS Code拡張機能（.vsix）は：
- VS Codeで直接インストール可能
- シンタックスハイライト、LSP機能、実行サポートを含む

## キャッシュ戦略

ビルド時間を短縮するため、以下をキャッシュしています：

- Cargoレジストリ (`~/.cargo/registry`)
- Cargoインデックス (`~/.cargo/git`)
- ビルド成果物 (`target/`)

## ローカルでの実行

GitHub Actionsと同じチェックをローカルで実行する場合：

**Unix系 (macOS/Linux):**
```bash
cd inmu-lang

# フォーマットチェック
make fmt

# Lint
make lint

# ビルド
make stage0

# テスト
make test
```

**Windows (PowerShell):**
```powershell
cd inmu-lang

# フォーマットチェック
cd stage0
cargo fmt -- --check

# Lint
cargo clippy -- -D warnings

# テスト
cargo test

# リリースビルド
cargo build --release

# 統合テスト
./target/release/inmu ../examples/hello.inmu
```

## リリースの作成方法

1. バージョンタグを作成
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

2. GitHubでリリースを作成
   - https://github.com/[user]/[repo]/releases/new
   - タグを選択
   - リリースノートを記述
   - "Publish release" をクリック

3. GitHub Actionsが自動的に：
   - 全プラットフォーム向けビルドを実行
   - テストを実行
   - バイナリをリリースに添付
   - **VS Code拡張機能 (.vsix) もリリースに添付**

## VS Code拡張機能のインストール

リリースからダウンロードした.vsixファイルをインストールする方法：

1. VS Codeを開く
2. 拡張機能ビュー（Ctrl+Shift+X / Cmd+Shift+X）を開く
3. 「…」メニュー → 「VSIXからのインストール...」
4. ダウンロードした.vsixファイルを選択

## トラブルシューティング

### ビルドが失敗する場合

- Cargo.lockファイルが最新かチェック
- キャッシュをクリアして再実行
- ローカルで`cargo clean`してから再ビルド

### テストが失敗する場合

- サンプルプログラムが正しく配置されているかチェック
- 期待される出力が変更されていないかチェック
