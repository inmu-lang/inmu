# 共通定数定義

このドキュメントは、INMU Stage 0 で使用される共通定数を定義します。

## システムコール番号

### ARM64 (macOS)
```
SYS_EXIT    = 1
SYS_READ    = 3
SYS_WRITE   = 4
SYS_OPEN    = 5
SYS_CLOSE   = 6
```

### x86_64 (macOS)
```
SYS_EXIT    = 0x2000001
SYS_READ    = 0x2000003
SYS_WRITE   = 0x2000004
SYS_OPEN    = 0x2000005
SYS_CLOSE   = 0x2000006
```

## ファイルディスクリプタ
```
STDIN       = 0
STDOUT      = 1
STDERR      = 2
```

## ファイルオープンフラグ
```
O_RDONLY    = 0
```

## バッファサイズ
```
FILE_BUFFER_SIZE    = 4096
MAX_VARIABLES       = 256
MAX_VAR_NAME_LEN    = 32
NUMBER_BUFFER_SIZE  = 32
```

## キーワード
```
KEYWORD_PRINT     = "print"
KEYWORD_LET       = "let"
KEYWORD_IF        = "if"
KEYWORD_ELSE      = "else"
KEYWORD_ENDIF     = "endif"
KEYWORD_ASSERT    = "assert"
KEYWORD_ASSERT_NE = "assert_ne"
```

## ASCII コード
```
CHAR_SPACE      = 32   (0x20)
CHAR_TAB        = 9    (0x09)
CHAR_NEWLINE    = 10   (0x0A)
CHAR_QUOTE      = 34   (0x22, '"')
CHAR_HASH       = 35   (0x23, '#')
CHAR_PLUS       = 43   (0x2B, '+')
CHAR_MINUS      = 45   (0x2D, '-')
CHAR_STAR       = 42   (0x2A, '*')
CHAR_SLASH      = 47   (0x2F, '/')
CHAR_LPAREN     = 40   (0x28, '(')
CHAR_RPAREN     = 41   (0x29, ')')
CHAR_EQUAL      = 61   (0x3D, '=')
CHAR_0          = 48   (0x30)
CHAR_9          = 57   (0x39)
CHAR_a          = 97   (0x61)
CHAR_z          = 122  (0x7A)
CHAR_A          = 65   (0x41)
CHAR_Z          = 90   (0x5A)
CHAR_UNDERSCORE = 95   (0x5F, '_')
```
