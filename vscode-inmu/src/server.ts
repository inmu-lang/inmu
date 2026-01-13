import {
  createConnection,
  TextDocuments,
  Diagnostic,
  DiagnosticSeverity,
  ProposedFeatures,
  InitializeParams,
  DidChangeConfigurationNotification,
  CompletionItem,
  CompletionItemKind,
  TextDocumentPositionParams,
  TextDocumentSyncKind,
  InitializeResult,
  HoverParams,
  Hover,
  MarkupKind,
  DefinitionParams,
  Location,
  ReferenceParams,
  DocumentSymbolParams,
  SymbolInformation,
  SymbolKind,
  DocumentFormattingParams,
  TextEdit,
  Range,
  Position
} from 'vscode-languageserver/node';

import { TextDocument } from 'vscode-languageserver-textdocument';

// Language Server Connectionを作成
const connection = createConnection(ProposedFeatures.all);

// テキストドキュメント管理
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

// シンボルテーブル（変数や関数の定義を保存）
interface Symbol {
  name: string;
  kind: 'variable' | 'function';
  uri: string;
  line: number;
  character: number;
  documentation?: string; // JSDocスタイルのコメント
}

const symbolTable: Map<string, Symbol[]> = new Map();

connection.onInitialize((params: InitializeParams) => {
  connection.console.log('INMU Language Server initializing...');
  const capabilities = params.capabilities;

  // クライアントの機能をチェック
  hasConfigurationCapability = !!(
    capabilities.workspace && !!capabilities.workspace.configuration
  );
  hasWorkspaceFolderCapability = !!(
    capabilities.workspace && !!capabilities.workspace.workspaceFolders
  );
  hasDiagnosticRelatedInformationCapability = !!(
    capabilities.textDocument &&
    capabilities.textDocument.publishDiagnostics &&
    capabilities.textDocument.publishDiagnostics.relatedInformation
  );

  const result: InitializeResult = {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      completionProvider: {
        resolveProvider: true,
        triggerCharacters: ['.', ' ']
      },
      hoverProvider: true,
      definitionProvider: true,
      referencesProvider: true,
      documentSymbolProvider: true,
      documentFormattingProvider: true
    }
  };

  if (hasWorkspaceFolderCapability) {
    result.capabilities.workspace = {
      workspaceFolders: {
        supported: true
      }
    };
  }
  return result;
});

connection.onInitialized(() => {
  connection.console.log('INMU Language Server initialized successfully!');
  if (hasConfigurationCapability) {
    connection.client.register(DidChangeConfigurationNotification.type, undefined);
  }
  if (hasWorkspaceFolderCapability) {
    connection.workspace.onDidChangeWorkspaceFolders(_event => {
      connection.console.log('Workspace folder change event received.');
    });
  }
});

// ドキュメント変更時に診断を実行
documents.onDidChangeContent(change => {
  updateSymbolTable(change.document);
  validateTextDocument(change.document);
});

// シンボルテーブルの更新
function updateSymbolTable(textDocument: TextDocument): void {
  const uri = textDocument.uri;
  const text = textDocument.getText();
  const lines = text.split(/\r?\n/);
  
  // このドキュメントのシンボルをクリア
  for (const [name, symbols] of symbolTable.entries()) {
    const filtered = symbols.filter(s => s.uri !== uri);
    if (filtered.length === 0) {
      symbolTable.delete(name);
    } else {
      symbolTable.set(name, filtered);
    }
  }

  // 新しいシンボルを登録
  let pendingDocComment: string | undefined;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();
    
    // JSDocスタイルのコメントを検出
    if (trimmed.startsWith('/**')) {
      // 複数行のコメントを収集
      const docLines: string[] = [];
      let j = i;
      
      while (j < lines.length) {
        const commentLine = lines[j].trim();
        docLines.push(commentLine);
        
        if (commentLine.endsWith('*/')) {
          break;
        }
        j++;
      }
      
      // コメントをパースして整形
      pendingDocComment = docLines
        .map(l => l.replace(/^\/\*\*/, '').replace(/\*\/$/, '').replace(/^\s*\*\s?/, ''))
        .filter(l => l.trim().length > 0)
        .join('\n')
        .trim();
      
      i = j; // コメント終了位置まで進める
      continue;
    }
    
    // 変数宣言を検出: let varname = ...
    const letMatch = line.match(/^\s*let\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=/);
    if (letMatch) {
      const name = letMatch[1];
      const character = line.indexOf(name);
      const symbol: Symbol = {
        name,
        kind: 'variable',
        uri,
        line: i,
        character,
        documentation: pendingDocComment
      };
      
      const existing = symbolTable.get(name) || [];
      existing.push(symbol);
      symbolTable.set(name, existing);
      
      pendingDocComment = undefined; // コメントを消費
      continue;
    }

    // 関数定義を検出: fn funcname(...) { ... }
    const fnMatch = line.match(/^\s*fn\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/);
    if (fnMatch) {
      const name = fnMatch[1];
      const character = line.indexOf(name);
      const symbol: Symbol = {
        name,
        kind: 'function',
        uri,
        line: i,
        character,
        documentation: pendingDocComment
      };
      
      const existing = symbolTable.get(name) || [];
      existing.push(symbol);
      symbolTable.set(name, existing);
      
      pendingDocComment = undefined; // コメントを消費
      continue;
    }
    
    // コメント以外の行が来たらpendingDocCommentをクリア
    if (trimmed && !trimmed.startsWith('#') && !trimmed.startsWith('//')) {
      pendingDocComment = undefined;
    }
  }
}

async function validateTextDocument(textDocument: TextDocument): Promise<void> {
  const text = textDocument.getText();
  const diagnostics: Diagnostic[] = [];

  // 簡単な構文チェック例
  const lines = text.split(/\r?\n/);
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();
    
    // コメント行や空行はスキップ
    if (trimmed.startsWith('#') || trimmed === '') {
      continue;
    }
    
    // let文の後に=がない場合
    if (trimmed.match(/^\s*let\s+\w+\s*$/) && !line.includes('=')) {
      const diagnostic: Diagnostic = {
        severity: DiagnosticSeverity.Error,
        range: {
          start: { line: i, character: 0 },
          end: { line: i, character: line.length }
        },
        message: `変数宣言には '=' と初期値が必要です`,
        source: 'inmu'
      };
      diagnostics.push(diagnostic);
    }

    // 括弧の対応チェック
    const openBraces = (line.match(/{/g) || []).length;
    const closeBraces = (line.match(/}/g) || []).length;
    const openParens = (line.match(/\(/g) || []).length;
    const closeParens = (line.match(/\)/g) || []).length;
    
    if (openParens > closeParens) {
      const lastOpenParen = line.lastIndexOf('(');
      const diagnostic: Diagnostic = {
        severity: DiagnosticSeverity.Error,
        range: {
          start: { line: i, character: lastOpenParen },
          end: { line: i, character: lastOpenParen + 1 }
        },
        message: `閉じ括弧 ')' が不足しています`,
        source: 'inmu'
      };
      diagnostics.push(diagnostic);
    } else if (closeParens > openParens) {
      const firstCloseParen = line.indexOf(')');
      const diagnostic: Diagnostic = {
        severity: DiagnosticSeverity.Error,
        range: {
          start: { line: i, character: firstCloseParen },
          end: { line: i, character: firstCloseParen + 1 }
        },
        message: `開き括弧 '(' が不足しています`,
        source: 'inmu'
      };
      diagnostics.push(diagnostic);
    }

    // if文の構文チェック（ブロック形式とendif形式の両方をサポート）
    if (trimmed.startsWith('if ') && !trimmed.includes('{')) {
      // endif形式かどうかをチェック
      let hasEndif = false;
      for (let j = i + 1; j < lines.length; j++) {
        const futureLine = lines[j].trim();
        if (futureLine === 'endif') {
          hasEndif = true;
          break;
        }
        // 次のif文や他のブロックが始まったら探索終了
        if (futureLine.startsWith('if ') || futureLine.startsWith('fn ')) {
          break;
        }
      }
      
      // endifがない場合のみ警告
      if (!hasEndif) {
        const diagnostic: Diagnostic = {
          severity: DiagnosticSeverity.Warning,
          range: {
            start: { line: i, character: 0 },
            end: { line: i, character: line.length }
          },
          message: `if文にはブロック '{' または 'endif' が必要です`,
          source: 'inmu'
        };
        diagnostics.push(diagnostic);
      }
    }

    // 未定義の変数の使用を検出（簡易版）
    // 変数宣言行はスキップ
    if (!trimmed.startsWith('let ')) {
      // 文字列リテラルを一時的に除去してから変数をチェック
      let lineWithoutStrings = line.replace(/"[^"]*"/g, '""').replace(/'[^']*'/g, "''");
      
      // 変数名を抽出
      const varUsageMatches = lineWithoutStrings.matchAll(/\b([a-zA-Z_][a-zA-Z0-9_]*)\b/g);
      
      for (const match of varUsageMatches) {
        const varName = match[1];
        const varIndex = match.index!;
        
        // キーワードや組み込み関数でない場合
        const keywords = ['let', 'if', 'else', 'elsif', 'endif', 'while', 'endwhile', 'for', 'fn', 'return', 'print', 'assert', 'assert_ne', 'debug', 'trace', 'true', 'false'];
        
        if (!keywords.includes(varName)) {
          // このドキュメント内で定義されているかチェック
          const symbols = symbolTable.get(varName);
          const definedInThisFile = symbols?.some(s => s.uri === textDocument.uri);
          
          if (!definedInThisFile) {
            const diagnostic: Diagnostic = {
              severity: DiagnosticSeverity.Warning,
              range: {
                start: { line: i, character: varIndex },
                end: { line: i, character: varIndex + varName.length }
              },
              message: `変数 '${varName}' が定義されていない可能性があります`,
              source: 'inmu'
            };
            diagnostics.push(diagnostic);
          }
        }
      }
    }
  }

  connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
}

// 補完機能
connection.onCompletion(
  (_textDocumentPosition: TextDocumentPositionParams): CompletionItem[] => {
    return [
      // キーワード
      {
        label: 'let',
        kind: CompletionItemKind.Keyword,
        detail: '変数宣言',
        documentation: '新しい変数を宣言します。\n例: let x = 10'
      },
      {
        label: 'if',
        kind: CompletionItemKind.Keyword,
        detail: '条件分岐',
        documentation: '条件分岐を行います。\n例: if x > 0 { ... }'
      },
      {
        label: 'else',
        kind: CompletionItemKind.Keyword,
        detail: 'else節',
        documentation: 'if文のelse節です。'
      },
      {
        label: 'endif',
        kind: CompletionItemKind.Keyword,
        detail: 'if文の終了',
        documentation: 'if文を終了します。'
      },
      {
        label: 'while',
        kind: CompletionItemKind.Keyword,
        detail: 'whileループ',
        documentation: '条件が真の間ループします。\n例: while i < 10 { ... }'
      },
      {
        label: 'for',
        kind: CompletionItemKind.Keyword,
        detail: 'forループ',
        documentation: 'forループを実行します。'
      },
      {
        label: 'fn',
        kind: CompletionItemKind.Keyword,
        detail: '関数定義',
        documentation: '関数を定義します。\n例: fn add(x, y) { ... }'
      },
      {
        label: 'return',
        kind: CompletionItemKind.Keyword,
        detail: '戻り値',
        documentation: '関数から値を返します。'
      },
      // 組み込み関数
      {
        label: 'print',
        kind: CompletionItemKind.Function,
        detail: '出力関数',
        documentation: '値を出力します。\n例: print "Hello, World!"',
        insertText: 'print '
      },
      {
        label: 'assert',
        kind: CompletionItemKind.Function,
        detail: 'アサーション',
        documentation: '2つの値が等しいことを確認します。\n例: assert x == 10',
        insertText: 'assert '
      },
      {
        label: 'assert_ne',
        kind: CompletionItemKind.Function,
        detail: '非等価アサーション',
        documentation: '2つの値が等しくないことを確認します。\n例: assert_ne x != 0\n等しい場合はエラーを出力します。',
        insertText: 'assert_ne '
      },
      {
        label: 'debug',
        kind: CompletionItemKind.Function,
        detail: 'デバッグ出力',
        documentation: 'デバッグ情報を出力します。開発中のトラブルシューティングに使用します。\n例: debug x',
        insertText: 'debug '
      },
      {
        label: 'trace',
        kind: CompletionItemKind.Function,
        detail: 'トレース出力',
        documentation: 'トレース情報を出力します。実行フローを追跡するのに使用します。\n例: trace "checkpoint"',
        insertText: 'trace '
      },
      // 型
      {
        label: 'true',
        kind: CompletionItemKind.Constant,
        detail: '真偽値',
        documentation: 'ブール値の真'
      },
      {
        label: 'false',
        kind: CompletionItemKind.Constant,
        detail: '真偽値',
        documentation: 'ブール値の偽'
      }
    ];
  }
);

// 補完アイテムの詳細解決
connection.onCompletionResolve(
  (item: CompletionItem): CompletionItem => {
    return item;
  }
);

// ホバー時の情報提供
connection.onHover(
  (params: HoverParams): Hover | null => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
      return null;
    }

    const text = document.getText();
    const offset = document.offsetAt(params.position);
    
    // 簡易的なワード抽出
    const beforeText = text.substring(0, offset);
    const afterText = text.substring(offset);
    const wordMatch = /(\w+)$/.exec(beforeText);
    const wordAfter = /^(\w*)/.exec(afterText);
    
    if (!wordMatch) {
      return null;
    }

    const word = wordMatch[1] + (wordAfter ? wordAfter[1] : '');

    // キーワードと組み込み関数のホバー情報
    const hoverInfo: Record<string, string> = {
      'let': '**変数宣言**\n\n変数を宣言して値を代入します。\n\n```inmu\nlet x = 42\nlet name = "INMU"\n```',
      'if': '**条件分岐**\n\n条件式が真の場合にブロックを実行します。\n\n```inmu\nif x > 0 {\n  print "positive"\n}\n```',
      'else': '**else節**\n\nif文の条件が偽の場合に実行されるブロックです。\n\n```inmu\nif x > 0 {\n  print "positive"\n} else {\n  print "not positive"\n}\n```',
      'endif': '**if文の終了**\n\nif文のブロックを終了します。',
      'while': '**whileループ**\n\n条件が真の間、ブロックを繰り返し実行します。\n\n```inmu\nwhile i < 10 {\n  print i\n  i = i + 1\n}\n```',
      'for': '**forループ**\n\n指定された回数だけブロックを繰り返し実行します。',
      'fn': '**関数定義**\n\n新しい関数を定義します。\n\n```inmu\nfn add(x, y) {\n  return x + y\n}\n```',
      'return': '**戻り値**\n\n関数から値を返します。\n\n```inmu\nfn get_value() {\n  return 42\n}\n```',
      'print': '**出力関数**\n\n値を標準出力に表示します。\n\n```inmu\nprint "Hello, World!"\nprint x\nprint x + y\n```\n\n**引数:**\n- 任意の値（文字列、数値、式など）',
      'assert': '**アサーション（等価性チェック）**\n\n2つの値が等しいことを検証します。\n等しくない場合はエラーを出力します。\n\n```inmu\nassert x == 10\nassert result == expected\n```\n\n**引数:**\n- 比較式（`==` を使用）',
      'assert_ne': '**アサーション（非等価性チェック）**\n\n2つの値が等しくないことを検証します。\n等しい場合はエラーを出力します。\n\n```inmu\nassert_ne x != 0\nassert_ne result != wrong_value\n```\n\n**引数:**\n- 比較式（`!=` を使用）',
      'debug': '**デバッグ出力**\n\nデバッグ情報を出力します。\n開発中のトラブルシューティングに使用します。\n\n```inmu\ndebug x\ndebug "checkpoint reached"\n```\n\n**引数:**\n- 任意の値',
      'trace': '**トレース出力**\n\n実行トレース情報を出力します。\nプログラムの実行フローを追跡するのに使用します。\n\n```inmu\ntrace "entering function"\ntrace x\n```\n\n**引数:**\n- 任意の値',
      'true': '**真偽値: 真**\n\nブール値の真を表します。',
      'false': '**真偽値: 偽**\n\nブール値の偽を表します。'
    };

    // キーワード/組み込み関数の場合
    if (word in hoverInfo) {
      return {
        contents: {
          kind: MarkupKind.Markdown,
          value: hoverInfo[word]
        }
      };
    }

    // ユーザー定義のシンボルの場合
    const symbols = symbolTable.get(word);
    if (symbols && symbols.length > 0) {
      // 現在のドキュメント内のシンボルを優先
      const currentUri = params.textDocument.uri;
      const localSymbol = symbols.find(s => s.uri === currentUri) || symbols[0];
      
      let hoverText = '';
      
      // 種類に応じたラベル
      if (localSymbol.kind === 'variable') {
        hoverText = `**(変数) ${localSymbol.name}**\n\n`;
      } else if (localSymbol.kind === 'function') {
        hoverText = `**(関数) ${localSymbol.name}**\n\n`;
      }
      
      // JSDocコメントがあれば追加
      if (localSymbol.documentation) {
        hoverText += localSymbol.documentation;
      } else {
        hoverText += `定義位置: 行 ${localSymbol.line + 1}`;
      }
      
      return {
        contents: {
          kind: MarkupKind.Markdown,
          value: hoverText
        }
      };
    }

    return null;
  }
);

// 定義ジャンプ
connection.onDefinition(
  (params: DefinitionParams): Location[] => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
      return [];
    }

    const text = document.getText();
    const offset = document.offsetAt(params.position);
    
    // カーソル位置のワードを取得
    const beforeText = text.substring(0, offset);
    const afterText = text.substring(offset);
    const wordMatch = /(\w+)$/.exec(beforeText);
    const wordAfter = /^(\w*)/.exec(afterText);
    
    if (!wordMatch) {
      return [];
    }

    const word = wordMatch[1] + (wordAfter ? wordAfter[1] : '');
    
    // シンボルテーブルから検索
    const symbols = symbolTable.get(word);
    if (!symbols || symbols.length === 0) {
      return [];
    }

    // 定義の位置を返す
    return symbols.map(symbol => ({
      uri: symbol.uri,
      range: {
        start: { line: symbol.line, character: symbol.character },
        end: { line: symbol.line, character: symbol.character + symbol.name.length }
      }
    }));
  }
);

// 参照検索
connection.onReferences(
  (params: ReferenceParams): Location[] => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
      return [];
    }

    const text = document.getText();
    const offset = document.offsetAt(params.position);
    
    // カーソル位置のワードを取得
    const beforeText = text.substring(0, offset);
    const afterText = text.substring(offset);
    const wordMatch = /(\w+)$/.exec(beforeText);
    const wordAfter = /^(\w*)/.exec(afterText);
    
    if (!wordMatch) {
      return [];
    }

    const word = wordMatch[1] + (wordAfter ? wordAfter[1] : '');
    
    // 全ドキュメントで参照を検索
    const references: Location[] = [];
    documents.all().forEach(doc => {
      const docText = doc.getText();
      const lines = docText.split(/\r?\n/);
      
      lines.forEach((line, lineNum) => {
        const regex = new RegExp(`\\b${word}\\b`, 'g');
        let match;
        while ((match = regex.exec(line)) !== null) {
          references.push({
            uri: doc.uri,
            range: {
              start: { line: lineNum, character: match.index },
              end: { line: lineNum, character: match.index + word.length }
            }
          });
        }
      });
    });

    return references;
  }
);

// ドキュメントシンボル
connection.onDocumentSymbol(
  (params: DocumentSymbolParams): SymbolInformation[] => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
      return [];
    }

    const symbols: SymbolInformation[] = [];
    
    // このドキュメントのシンボルを収集
    for (const [name, symbolList] of symbolTable.entries()) {
      symbolList
        .filter(s => s.uri === params.textDocument.uri)
        .forEach(symbol => {
          symbols.push({
            name: symbol.name,
            kind: symbol.kind === 'function' ? SymbolKind.Function : SymbolKind.Variable,
            location: {
              uri: symbol.uri,
              range: {
                start: { line: symbol.line, character: symbol.character },
                end: { line: symbol.line, character: symbol.character + symbol.name.length }
              }
            }
          });
        });
    }

    return symbols;
  }
);

// ドキュメントフォーマッティング
connection.onDocumentFormatting(
  (params: DocumentFormattingParams): TextEdit[] => {
    const document = documents.get(params.textDocument.uri);
    if (!document) {
      return [];
    }

    const text = document.getText();
    const lines = text.split(/\r?\n/);
    const edits: TextEdit[] = [];
    let indentLevel = 0;
    const indentSize = params.options.tabSize || 4;
    const useSpaces = params.options.insertSpaces !== false;
    const indentChar = useSpaces ? ' '.repeat(indentSize) : '\t';

    const formattedLines: string[] = [];

    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      
      // 閉じ括弧の前にインデントを減らす
      if (line.startsWith('}')) {
        indentLevel = Math.max(0, indentLevel - 1);
      }

      // インデントを適用
      const indent = indentChar.repeat(indentLevel);
      formattedLines.push(indent + line);

      // 開き括弧の後にインデントを増やす
      if (line.endsWith('{')) {
        indentLevel++;
      }
    }

    // 全体を置換
    const fullRange: Range = {
      start: { line: 0, character: 0 },
      end: { line: lines.length - 1, character: lines[lines.length - 1].length }
    };

    edits.push({
      range: fullRange,
      newText: formattedLines.join('\n')
    });

    return edits;
  }
);

// ドキュメントのリスニングを開始
documents.listen(connection);

// Connectionのリスニングを開始
connection.listen();
