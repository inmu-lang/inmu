import * as path from 'path';
import { workspace, ExtensionContext, window, commands, Terminal } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient;
let terminal: Terminal | undefined;

export function activate(context: ExtensionContext) {
  console.log('INMU Extension activating...');
  
  // LSPサーバーのパスを指定
  const serverModule = context.asAbsolutePath(
    path.join('out', 'server.js')
  );
  
  console.log('Server module path:', serverModule);

  // サーバーのデバッグオプション
  const debugOptions = { execArgv: ['--nolazy', '--inspect=6009'] };

  // サーバーオプション（起動とデバッグ）
  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: debugOptions
    }
  };

  // クライアントオプション
  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'inmu' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.inmu')
    }
  };

  // Language Clientを作成して起動
  client = new LanguageClient(
    'inmuLanguageServer',
    'INMU Language Server',
    serverOptions,
    clientOptions
  );

  client.start();

  // INMUファイルを実行するコマンド
  const runFileCommand = commands.registerCommand('inmu.runFile', () => {
    const editor = window.activeTextEditor;
    if (!editor) {
      window.showErrorMessage('アクティブなエディタがありません');
      return;
    }

    if (editor.document.languageId !== 'inmu') {
      window.showErrorMessage('INMUファイルではありません');
      return;
    }

    const filePath = editor.document.uri.fsPath;
    
    // ターミナルを作成または再利用
    if (!terminal || terminal.exitStatus !== undefined) {
      terminal = window.createTerminal('INMU');
    }
    
    terminal.show();
    
    // INMUコンパイラのパスを検索
    const workspaceFolders = workspace.workspaceFolders;
    if (workspaceFolders) {
      // inmu-langフォルダを探す
      for (const folder of workspaceFolders) {
        const inmuPath = path.join(folder.uri.fsPath, 'inmu');
        terminal.sendText(`${inmuPath} "${filePath}"`);
        return;
      }
    }
    
    // デフォルトのinmuコマンドを使用
    terminal.sendText(`inmu "${filePath}"`);
  });

  context.subscriptions.push(runFileCommand);

  window.showInformationMessage('INMU Language Server が起動しました！');
}

export function deactivate(): Thenable<void> | undefined {
  if (terminal) {
    terminal.dispose();
  }
  
  if (!client) {
    return undefined;
  }
  return client.stop();
}
