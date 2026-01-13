use crate::ast::*;
use crate::token::Token;

pub struct Parser {
  tokens: Vec<Token>,
  pos: usize,
}

impl Parser {
  pub fn new(tokens: Vec<Token>) -> Self {
    Parser { tokens, pos: 0 }
  }

  fn current(&self) -> &Token {
    if self.pos < self.tokens.len() { &self.tokens[self.pos] } else { &Token::Eof }
  }

  fn advance(&mut self) {
    if self.pos < self.tokens.len() {
      self.pos += 1;
    }
  }

  fn skip_newlines(&mut self) {
    while matches!(self.current(), Token::Newline) {
      self.advance();
    }
  }

  fn expect(&mut self, expected: Token) -> Result<(), String> {
    if self.current() == &expected {
      self.advance();
      Ok(())
    } else {
      Err(format!("Expected {:?}, got {:?}", expected, self.current()))
    }
  }

  pub fn parse(&mut self) -> Result<Program, String> {
    let mut stmts = Vec::new();

    self.skip_newlines();

    while !matches!(self.current(), Token::Eof) {
      stmts.push(self.parse_stmt()?);
      self.skip_newlines();
    }

    Ok(stmts)
  }

  fn parse_stmt(&mut self) -> Result<Stmt, String> {
    match self.current() {
      Token::Print => self.parse_print(),
      Token::Let => self.parse_let(),
      Token::If => self.parse_if(),
      Token::Assert => self.parse_assert(),
      Token::AssertNe => self.parse_assert_ne(),
      _ => Err(format!("Unexpected token: {:?}", self.current())),
    }
  }

  fn parse_print(&mut self) -> Result<Stmt, String> {
    self.expect(Token::Print)?;
    let expr = self.parse_expr()?;
    self.skip_newlines();
    Ok(Stmt::Print(expr))
  }

  fn parse_let(&mut self) -> Result<Stmt, String> {
    self.expect(Token::Let)?;

    let name = match self.current() {
      Token::Identifier(s) => {
        let name = s.clone();
        self.advance();
        name
      }
      _ => return Err(format!("Expected identifier, got {:?}", self.current())),
    };

    self.expect(Token::Equal)?;
    let value = self.parse_expr()?;
    self.skip_newlines();

    Ok(Stmt::Let { name, value })
  }

  fn parse_if(&mut self) -> Result<Stmt, String> {
    self.expect(Token::If)?;
    let condition = self.parse_expr()?;
    self.skip_newlines();

    let mut then_body = Vec::new();
    while !matches!(self.current(), Token::Else | Token::Endif | Token::Eof) {
      then_body.push(self.parse_stmt()?);
      self.skip_newlines();
    }

    let else_body = if matches!(self.current(), Token::Else) {
      self.advance();
      self.skip_newlines();

      let mut else_stmts = Vec::new();
      while !matches!(self.current(), Token::Endif | Token::Eof) {
        else_stmts.push(self.parse_stmt()?);
        self.skip_newlines();
      }
      Some(else_stmts)
    } else {
      None
    };

    self.expect(Token::Endif)?;
    self.skip_newlines();

    Ok(Stmt::If {
      condition,
      then_body,
      else_body,
    })
  }

  fn parse_assert(&mut self) -> Result<Stmt, String> {
    self.expect(Token::Assert)?;
    self.expect(Token::LParen)?;

    let actual = self.parse_expr()?;
    self.expect(Token::Comma)?;
    let expected = self.parse_expr()?;

    self.expect(Token::RParen)?;
    self.skip_newlines();

    Ok(Stmt::Assert { actual, expected })
  }

  fn parse_assert_ne(&mut self) -> Result<Stmt, String> {
    self.expect(Token::AssertNe)?;
    self.expect(Token::LParen)?;

    let actual = self.parse_expr()?;
    self.expect(Token::Comma)?;
    let expected = self.parse_expr()?;

    self.expect(Token::RParen)?;
    self.skip_newlines();

    Ok(Stmt::AssertNe { actual, expected })
  }

  fn parse_expr(&mut self) -> Result<Expr, String> {
    self.parse_equality()
  }

  fn parse_equality(&mut self) -> Result<Expr, String> {
    let mut left = self.parse_additive()?;

    while matches!(self.current(), Token::EqualEqual) {
      self.advance();
      let right = self.parse_additive()?;
      left = Expr::Binary {
        left: Box::new(left),
        op: BinaryOp::Equal,
        right: Box::new(right),
      };
    }

    Ok(left)
  }

  fn parse_additive(&mut self) -> Result<Expr, String> {
    let mut left = self.parse_multiplicative()?;

    while matches!(self.current(), Token::Plus | Token::Minus) {
      let op = match self.current() {
        Token::Plus => BinaryOp::Add,
        Token::Minus => BinaryOp::Sub,
        _ => unreachable!(),
      };
      self.advance();
      let right = self.parse_multiplicative()?;
      left = Expr::Binary {
        left: Box::new(left),
        op,
        right: Box::new(right),
      };
    }

    Ok(left)
  }

  fn parse_multiplicative(&mut self) -> Result<Expr, String> {
    let mut left = self.parse_primary()?;

    while matches!(self.current(), Token::Star | Token::Slash) {
      let op = match self.current() {
        Token::Star => BinaryOp::Mul,
        Token::Slash => BinaryOp::Div,
        _ => unreachable!(),
      };
      self.advance();
      let right = self.parse_primary()?;
      left = Expr::Binary {
        left: Box::new(left),
        op,
        right: Box::new(right),
      };
    }

    Ok(left)
  }

  fn parse_primary(&mut self) -> Result<Expr, String> {
    match self.current() {
      Token::Number(n) => {
        let num = *n;
        self.advance();
        Ok(Expr::Number(num))
      }
      Token::String(s) => {
        let str = s.clone();
        self.advance();
        Ok(Expr::String(str))
      }
      Token::Identifier(id) => {
        let name = id.clone();
        self.advance();
        Ok(Expr::Variable(name))
      }
      Token::Minus => {
        self.advance();
        let expr = self.parse_primary()?;
        match expr {
          Expr::Number(n) => Ok(Expr::Number(-n)),
          _ => Ok(Expr::Binary {
            left: Box::new(Expr::Number(0)),
            op: BinaryOp::Sub,
            right: Box::new(expr),
          }),
        }
      }
      Token::LParen => {
        self.advance();
        let expr = self.parse_expr()?;
        self.expect(Token::RParen)?;
        Ok(expr)
      }
      _ => Err(format!("Unexpected token in expression: {:?}", self.current())),
    }
  }
}
