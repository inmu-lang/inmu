mod ast;
mod interpreter;
mod parser;
mod token;

use interpreter::Interpreter;
use parser::Parser;
use std::env;
use std::fs;
use std::process;
use token::Tokenizer;

fn main() {
  let args: Vec<String> = env::args().collect();

  if args.len() != 2 {
    eprintln!("Usage: {} <filename.inmu>", args[0]);
    process::exit(1);
  }

  let filename = &args[1];

  let source = match fs::read_to_string(filename) {
    Ok(content) => content,
    Err(err) => {
      eprintln!("Error reading file '{}': {}", filename, err);
      process::exit(1);
    }
  };

  // Tokenize
  let mut tokenizer = Tokenizer::new(&source);
  let tokens = tokenizer.tokenize();

  // Parse
  let mut parser = Parser::new(tokens);
  let program = match parser.parse() {
    Ok(prog) => prog,
    Err(err) => {
      eprintln!("Parse error: {}", err);
      process::exit(1);
    }
  };

  // Execute
  let mut interpreter = Interpreter::new();
  if let Err(err) = interpreter.execute(&program) {
    eprintln!("Runtime error: {}", err);
    process::exit(1);
  }
}
