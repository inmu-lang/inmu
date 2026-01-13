use crate::ast::*;
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
  Number(i64),
  String(String),
}

impl Value {
  fn as_number(&self) -> Result<i64, String> {
    match self {
      Value::Number(n) => Ok(*n),
      _ => Err(format!("Expected number, got {:?}", self)),
    }
  }
}

pub struct Interpreter {
  variables: HashMap<String, Value>,
}

impl Interpreter {
  pub fn new() -> Self {
    Interpreter { variables: HashMap::new() }
  }

  pub fn execute(&mut self, program: &Program) -> Result<(), String> {
    for stmt in program {
      self.execute_stmt(stmt)?;
    }
    Ok(())
  }

  fn execute_stmt(&mut self, stmt: &Stmt) -> Result<(), String> {
    match stmt {
      Stmt::Print(expr) => {
        let value = self.eval_expr(expr)?;
        match value {
          Value::Number(n) => println!("{}", n),
          Value::String(s) => println!("{}", s),
        }
        Ok(())
      }

      Stmt::Let { name, value } => {
        let val = self.eval_expr(value)?;
        self.variables.insert(name.clone(), val);
        Ok(())
      }

      Stmt::If {
        condition,
        then_body,
        else_body,
      } => {
        let cond_val = self.eval_expr(condition)?;
        let cond_num = cond_val.as_number()?;

        if cond_num != 0 {
          for stmt in then_body {
            self.execute_stmt(stmt)?;
          }
        } else if let Some(else_stmts) = else_body {
          for stmt in else_stmts {
            self.execute_stmt(stmt)?;
          }
        }
        Ok(())
      }

      Stmt::Assert { actual, expected } => {
        let actual_val = self.eval_expr(actual)?;
        let expected_val = self.eval_expr(expected)?;

        if actual_val != expected_val {
          return Err(format!("Assertion failed: expected {:?}, got {:?}", expected_val, actual_val));
        }
        Ok(())
      }

      Stmt::AssertNe { actual, expected } => {
        let actual_val = self.eval_expr(actual)?;
        let expected_val = self.eval_expr(expected)?;

        if actual_val == expected_val {
          return Err(format!("Assertion failed: expected values to be different, but both are {:?}", actual_val));
        }
        Ok(())
      }
    }
  }

  fn eval_expr(&self, expr: &Expr) -> Result<Value, String> {
    match expr {
      Expr::Number(n) => Ok(Value::Number(*n)),

      Expr::String(s) => Ok(Value::String(s.clone())),

      Expr::Variable(name) => self.variables.get(name).cloned().ok_or_else(|| format!("Undefined variable: {}", name)),

      Expr::Binary { left, op, right } => {
        let left_val = self.eval_expr(left)?;
        let right_val = self.eval_expr(right)?;

        match op {
          BinaryOp::Add => {
            let l = left_val.as_number()?;
            let r = right_val.as_number()?;
            Ok(Value::Number(l + r))
          }
          BinaryOp::Sub => {
            let l = left_val.as_number()?;
            let r = right_val.as_number()?;
            Ok(Value::Number(l - r))
          }
          BinaryOp::Mul => {
            let l = left_val.as_number()?;
            let r = right_val.as_number()?;
            Ok(Value::Number(l * r))
          }
          BinaryOp::Div => {
            let l = left_val.as_number()?;
            let r = right_val.as_number()?;
            if r == 0 {
              return Err("Division by zero".to_string());
            }
            Ok(Value::Number(l / r))
          }
          BinaryOp::Equal => {
            let result = if left_val == right_val { 1 } else { 0 };
            Ok(Value::Number(result))
          }
        }
      }
    }
  }
}
