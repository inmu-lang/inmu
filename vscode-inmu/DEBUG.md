# INMU VSCode拡張機能のデバッグ手順

## 問題: LSPが有効にならない場合のチェックリスト

### 1. コンパイルの確認

watchタスクが動いている場合、自動でコンパイルされます。手動で確認する場合：

```bash
cd vscode-inmu
npm run compile
```

`out/`ディレクトリに以下のファイルが存在することを確認：
- `out/extension.js`
- `out/server.js`

### 2. 拡張機能のデバッグ起動

#### 方法1: デバッグビューから起動（推奨）

1. VS Codeで`vscode-inmu`フォルダを開く
2. 左サイドバーの「実行とデバッグ」アイコンをクリック（または`Ctrl+Shift+D` / `Cmd+Shift+D`）
3. 上部のドロップダウンから「拡張機能の起動」を選択
4. 緑色の再生ボタンをクリック（または`F5`）

#### 方法2: F5キーで起動

1. VS Codeで`vscode-inmu`フォルダを開く
2. `F5`キーを押す

### 3. 拡張機能開発ホストでの確認

新しいVS Codeウィンドウ（タイトルに `[拡張機能開発ホスト]` と表示）が開きます。

#### 3-1. ログの確認

**拡張機能開発ホスト**のウィンドウで：

1. メニューから「ヘルプ」→「開発者ツールの切り替え」を選択
2. コンソールタブを開く
3. 以下のようなログが表示されるはずです：
   ```
   INMU Extension activating...
   Server module path: /path/to/vscode-inmu/out/server.js
   Starting INMU Language Server...
   INMU Language Server started successfully
   ```

4. エラーが表示されている場合は、そのメッセージを確認

#### 3-2. 出力パネルの確認

**拡張機能開発ホスト**のウィンドウで：

1. メニューから「表示」→「出力」を選択（または`Ctrl+Shift+U` / `Cmd+Shift+U`）
2. 右上のドロップダウンから「INMU Language Server」を選択
3. サーバーのログが表示されます：
   ```
   INMU Language Server initializing...
   INMU Language Server initialized successfully!
   ```

### 4. INMUファイルでテスト

**拡張機能開発ホスト**のウィンドウで：

1. `test-sample.inmu`を開く（または新しい`.inmu`ファイルを作成）
2. 以下を確認：

   ✅ **シンタックスハイライト**
   - キーワード（`let`, `if`, `while`など）が色付けされている
   - 文字列が色付けされている
   - コメント（`#`）が色付けされている

   ✅ **コード補完**
   - `pr`と入力して`Ctrl+Space`を押すと`print`が候補に出る
   - `le`と入力すると`let`が候補に出る

   ✅ **ホバー情報**
   - `print`や`let`にマウスカーソルを合わせると説明が表示される

   ✅ **定義ジャンプ**
   - 変数`result`の使用箇所にカーソルを置いて`F12`を押すと定義にジャンプ

   ✅ **参照検索**
   - 変数`x`にカーソルを置いて`Shift+F12`を押すと全使用箇所が表示される

   ✅ **シンボル一覧**
   - `Ctrl+Shift+O` (Mac: `Cmd+Shift+O`)で変数・関数の一覧が表示される

   ✅ **診断（エラー表示）**
   - 例えば`let z`（`=`なし）と書くと赤い波線が表示される

### 5. よくある問題と解決策

#### 問題1: "INMU Language Server が起動しました！" のメッセージが表示されない

**原因**: 拡張機能がactivateされていない

**解決策**:
1. `.inmu`ファイルを開いているか確認
2. ファイルが正しく`.inmu`拡張子になっているか確認
3. 右下の言語モード表示が「INMU」になっているか確認

#### 問題2: シンタックスハイライトは効くが、LSP機能が動かない

**原因**: LSPサーバーの起動エラー

**解決策**:
1. 開発者ツール（コンソール）でエラーメッセージを確認
2. `out/server.js`が存在するか確認
3. 拡張機能開発ホストを閉じて、再度`F5`で起動

#### 問題3: TypeScriptのコンパイルエラー

**解決策**:
```bash
cd vscode-inmu
npm install
npm run compile
```

エラーメッセージを確認し、TypeScriptファイルを修正

#### 問題4: node_modulesが見つからない

**解決策**:
```bash
cd vscode-inmu
rm -rf node_modules
npm install
npm run compile
```

### 6. デバッグのベストプラクティス

#### サーバー側のデバッグ

LSPサーバー（`server.ts`）をデバッグする場合：

1. 拡張機能開発ホストを起動（F5）
2. 元のVS Codeウィンドウで「実行とデバッグ」から「サーバーのデバッグ」を選択
3. 緑色の再生ボタンをクリック
4. `server.ts`にブレークポイントを設定できるようになります

#### ログの追加

コードに以下を追加してデバッグ：

```typescript
// extension.ts
console.log('Debug message');

// server.ts
connection.console.log('Server debug message');
```

### 7. 正常に動作している場合の確認

すべてが正しく動作している場合：

1. ✅ 開発者ツールのコンソールに起動メッセージが表示される
2. ✅ 出力パネルに「INMU Language Server」が表示され、ログが出力される
3. ✅ `.inmu`ファイルでシンタックスハイライトが効く
4. ✅ コード補完が動作する（`Ctrl+Space`）
5. ✅ ホバー情報が表示される
6. ✅ `F12`で定義ジャンプができる
7. ✅ `Shift+F12`で参照検索ができる
8. ✅ `Ctrl+Shift+O`でシンボル一覧が表示される
9. ✅ エラーのある行に赤い波線が表示される

### 8. それでも動かない場合

1. VS Codeを完全に再起動
2. `vscode-inmu/out`ディレクトリを削除して再コンパイル:
   ```bash
   rm -rf out
   npm run compile
   ```
3. VS Codeの拡張機能キャッシュをクリア:
   - VS Codeを終了
   - `~/.vscode/extensions`のキャッシュを確認
   - VS Codeを再起動

## 成功例のスクリーンショット

期待される動作：

1. **変数の定義ジャンプ**: `result`にカーソル→F12→`let result = add(x, y)`にジャンプ
2. **参照検索**: `x`にカーソル→Shift+F12→3箇所（定義、add呼び出し、if文）が表示
3. **補完**: `pr`と入力→`print`が候補に表示
4. **エラー**: `let broken`と入力→「変数宣言には '=' と初期値が必要です」エラー表示

これらが動作すれば、LSPは正常に機能しています！
