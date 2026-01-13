#[derive(Debug, Clone, PartialEq)]
pub enum Token {
  // Literals
  Number(i64),
  String(String),
  Identifier(String),

  // Keywords
  Print,
  Let,
  If,
  Else,
  Endif,
  Assert,
  AssertNe,

  // Operators
  Plus,
  Minus,
  Star,
  Slash,
  Equal,
  EqualEqual,

  // Delimiters
  LParen,
  RParen,
  Comma,

  // Special
  Newline,
  Eof,
}

pub struct Tokenizer {
  input: Vec<char>,
  pos: usize,
}

impl Tokenizer {
  pub fn new(input: &str) -> Self {
    Tokenizer {
      input: input.chars().collect(),
      pos: 0,
    }
  }

  fn current(&self) -> Option<char> {
    if self.pos < self.input.len() { Some(self.input[self.pos]) } else { None }
  }

  fn peek(&self, offset: usize) -> Option<char> {
    let pos = self.pos + offset;
    if pos < self.input.len() { Some(self.input[pos]) } else { None }
  }

  fn advance(&mut self) -> Option<char> {
    let ch = self.current();
    self.pos += 1;
    ch
  }

  fn skip_whitespace(&mut self) {
    while let Some(ch) = self.current() {
      if ch == ' ' || ch == '\t' || ch == '\r' {
        self.advance();
      } else {
        break;
      }
    }
  }

  fn skip_line_comment(&mut self) {
    // Skip //
    self.advance();
    self.advance();

    while let Some(ch) = self.current() {
      if ch == '\n' {
        break;
      }
      self.advance();
    }
  }

  fn skip_block_comment(&mut self) {
    // Skip /**
    self.advance();
    self.advance();
    self.advance();

    while let Some(ch) = self.current() {
      if ch == '*' && self.peek(1) == Some('/') {
        self.advance();
        self.advance();
        break;
      }
      self.advance();
    }
  }

  fn read_number(&mut self) -> i64 {
    let mut num = String::new();

    while let Some(ch) = self.current() {
      if ch.is_ascii_digit() {
        num.push(ch);
        self.advance();
      } else {
        break;
      }
    }

    num.parse().unwrap_or(0)
  }

  fn read_string(&mut self) -> String {
    // Skip opening quote
    self.advance();

    let mut s = String::new();

    while let Some(ch) = self.current() {
      if ch == '"' {
        self.advance();
        break;
      }
      s.push(ch);
      self.advance();
    }

    s
  }

  fn read_identifier(&mut self) -> String {
    let mut id = String::new();

    while let Some(ch) = self.current() {
      if ch.is_alphanumeric() || ch == '_' {
        id.push(ch);
        self.advance();
      } else {
        break;
      }
    }

    id
  }

  pub fn next_token(&mut self) -> Token {
    self.skip_whitespace();

    match self.current() {
      None => Token::Eof,

      Some('\n') => {
        self.advance();
        Token::Newline
      }

      Some('#') => {
        self.skip_line_comment();
        self.next_token()
      }

      Some('/') if self.peek(1) == Some('/') => {
        self.skip_line_comment();
        self.next_token()
      }

      Some('/') if self.peek(1) == Some('*') && self.peek(2) == Some('*') => {
        self.skip_block_comment();
        self.next_token()
      }

      Some('"') => Token::String(self.read_string()),

      Some(ch) if ch.is_ascii_digit() => Token::Number(self.read_number()),

      Some(ch) if ch.is_alphabetic() || ch == '_' => {
        let id = self.read_identifier();
        match id.as_str() {
          "print" => Token::Print,
          "let" => Token::Let,
          "if" => Token::If,
          "else" => Token::Else,
          "endif" => Token::Endif,
          "assert" => Token::Assert,
          "assert_ne" => Token::AssertNe,
          _ => Token::Identifier(id),
        }
      }

      Some('+') => {
        self.advance();
        Token::Plus
      }

      Some('-') => {
        self.advance();
        Token::Minus
      }

      Some('*') => {
        self.advance();
        Token::Star
      }

      Some('/') => {
        self.advance();
        Token::Slash
      }

      Some('=') if self.peek(1) == Some('=') => {
        self.advance();
        self.advance();
        Token::EqualEqual
      }

      Some('=') => {
        self.advance();
        Token::Equal
      }

      Some('(') => {
        self.advance();
        Token::LParen
      }

      Some(')') => {
        self.advance();
        Token::RParen
      }

      Some(',') => {
        self.advance();
        Token::Comma
      }

      Some(_) => {
        self.advance();
        self.next_token()
      }
    }
  }

  pub fn tokenize(&mut self) -> Vec<Token> {
    let mut tokens = Vec::new();

    loop {
      let token = self.next_token();
      if token == Token::Eof {
        tokens.push(token);
        break;
      }
      tokens.push(token);
    }

    tokens
  }
}
