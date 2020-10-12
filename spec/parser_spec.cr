require "../src/parser"

describe SDX::Parser::Parser do
  it "parses comments" do
    SDX::Parser::Lexer.lex("# comment").should eq [] of SDX::Parser::Token
    SDX::Parser::Lexer.lex("#").should eq [] of SDX::Parser::Token
    SDX::Parser::Lexer.lex("#> comment <#").should eq [] of SDX::Parser::Token
    SDX::Parser::Lexer.lex("#>\ncomment\n<#").should eq [] of SDX::Parser::Token
    SDX::Parser::Lexer.lex("#><#").should eq [] of SDX::Parser::Token
  end

  it "parses numbers" do
    SDX::Parser::Parser.parse_int(SDX::Parser::Lexer.lex("5").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_int(SDX::Parser::Lexer.lex("-5").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_num(SDX::Parser::Lexer.lex("5.0").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_num(SDX::Parser::Lexer.lex("-5.0").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses strings" do
    SDX::Parser::Parser.parse_str(SDX::Parser::Lexer.lex("\"\"").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_str(SDX::Parser::Lexer.lex("\"abc\"").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses booleans and nil" do
    SDX::Parser::Parser.parse_nil(SDX::Parser::Lexer.lex("nil").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_bool(SDX::Parser::Lexer.lex("true").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_bool(SDX::Parser::Lexer.lex("false").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses names" do
    SDX::Parser::Parser.parse_name(SDX::Parser::Lexer.lex("my_name").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_name(SDX::Parser::Lexer.lex("my_name001").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_name(SDX::Parser::Lexer.lex("__my_name").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_access(SDX::Parser::Lexer.lex("a.b").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_access(SDX::Parser::Lexer.lex("a.b.c.d.e").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses lists" do
    SDX::Parser::Parser.parse_list(SDX::Parser::Lexer.lex("[]").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_list(SDX::Parser::Lexer.lex("[1]").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_list(SDX::Parser::Lexer.lex("[1, 2, 3]").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses blocks" do
    SDX::Parser::Parser.parse_block(SDX::Parser::Lexer.lex("{ 1 }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_block(SDX::Parser::Lexer.lex("{ _ * 5 }").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses operators" do
    SDX::Parser::Parser.parse_op(SDX::Parser::Lexer.lex("5 + 5").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_op(SDX::Parser::Lexer.lex("5 + 5 * 5").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_op(SDX::Parser::Lexer.lex("(5 + 5) * 5").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses indexing" do
    SDX::Parser::Parser.parse_index(SDX::Parser::Lexer.lex("a[0]").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_index(SDX::Parser::Lexer.lex("a[1 + 1]").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses calls and new" do
    SDX::Parser::Parser.parse_call(SDX::Parser::Lexer.lex("func()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_call(SDX::Parser::Lexer.lex("func(1)").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_call(SDX::Parser::Lexer.lex("func(1, 2)").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_new(SDX::Parser::Lexer.lex("new Obj()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_new(SDX::Parser::Lexer.lex("new Obj(1)").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_new(SDX::Parser::Lexer.lex("new Obj(1, 2)").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses if, while, and for" do
    SDX::Parser::Parser.parse_if(SDX::Parser::Lexer.lex("if a == b f()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_if(SDX::Parser::Lexer.lex("if a == b f() else g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_if(SDX::Parser::Lexer.lex("if a == b { f() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_if(SDX::Parser::Lexer.lex("if a == b { f() } else { g() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_while(SDX::Parser::Lexer.lex("while a == b f()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_while(SDX::Parser::Lexer.lex("while a == b { f() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_for(SDX::Parser::Lexer.lex("for x f()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_for(SDX::Parser::Lexer.lex("for x { f() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_for(SDX::Parser::Lexer.lex("for i in x f()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_for(SDX::Parser::Lexer.lex("for i in x { f() }").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses fn and object" do
    SDX::Parser::Parser.parse_fn(SDX::Parser::Lexer.lex("fn f() g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_fn(SDX::Parser::Lexer.lex("fn f() { g() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_fn(SDX::Parser::Lexer.lex("fn f(x) g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_fn(SDX::Parser::Lexer.lex("fn f(x) { g() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_fn(SDX::Parser::Lexer.lex("fn f(x, y) g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_fn(SDX::Parser::Lexer.lex("fn f(x, y) { g() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object X g()").as(Array(SDX::Parser::Token)))
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object X { g() }").as(Array(SDX::Parser::Token)))
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object f() g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object f() { g() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object f(x) g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object f(x) { g() }").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object f(x, y) g()").as(Array(SDX::Parser::Token))).should be_truthy
    SDX::Parser::Parser.parse_object(SDX::Parser::Lexer.lex("object f(x, y) { g() }").as(Array(SDX::Parser::Token))).should be_truthy
  end

  it "parses require" do
    SDX::Parser::Parser.parse_require(SDX::Parser::Lexer.lex("require \"file\"").as(Array(SDX::Parser::Token)))
  end
end
