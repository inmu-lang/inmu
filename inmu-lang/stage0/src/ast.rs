#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
  Number(i64),
  String(String),
  Variable(String),
  Binary { left: Box<Expr>, op: BinaryOp, right: Box<Expr> },
}

#[derive(Debug, Clone, PartialEq)]
pub enum BinaryOp {
  Add,
  Sub,
  Mul,
  Div,
  Equal,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Stmt {
  Print(Expr),
  Let {
    name: String,
    value: Expr,
  },
  If {
    condition: Expr,
    then_body: Vec<Stmt>,
    else_body: Option<Vec<Stmt>>,
  },
  Assert {
    actual: Expr,
    expected: Expr,
  },
  AssertNe {
    actual: Expr,
    expected: Expr,
  },
}

pub type Program = Vec<Stmt>;
