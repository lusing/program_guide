// 语法分析：记号流 → 抽象语法树（AST）
// 用「优先级爬升」处理运算符优先级——递归下降的标准技巧
namespace MiniLang;

// ---------- AST：语句与表达式都是数据 ----------
public abstract record Stmt;

public sealed record LetStmt(string Name, Expr Value) : Stmt;          // let x = 表达式
public sealed record AssignStmt(string Name, Expr Value) : Stmt;       // x = 表达式
public sealed record ExprStmt(Expr Value) : Stmt;                      // 裸表达式（求值打印）

public abstract record Expr;

public sealed record NumberExpr(double Value) : Expr;
public sealed record VarExpr(string Name, int Pos) : Expr;
public sealed record UnaryExpr(string Op, Expr Operand) : Expr;        // -x
public sealed record BinaryExpr(string Op, Expr Left, Expr Right) : Expr;

public sealed class Parser
{
    private readonly Lexer _lexer;
    private Token _lookahead;      // 当前记号
    private Token _peek;           // 再往前一个（偷看赋值号用）

    public Parser(string source)
    {
        _lexer = new Lexer(source);
        _lookahead = _lexer.Next();
        _peek = _lexer.Next();
    }

    // 语句 ::= "let" 标识符 "=" 表达式 | 标识符 "=" 表达式 | 表达式
    public Stmt ParseStatement()
    {
        if (_lookahead.Kind == TokenKind.Let)
        {
            Advance();                                  // 吃掉 let
            var name = Expect(TokenKind.Ident, "变量名");
            ExpectOp("=");
            return new LetStmt(name.Text, ParseExpr());
        }

        if (_lookahead.Kind == TokenKind.Ident && IsAssignPeeked())
        {
            var name = _lookahead.Text;
            Advance();                                  // 吃掉变量名
            Advance();                                  // 吃掉 =
            return new AssignStmt(name, ParseExpr());
        }

        return new ExprStmt(ParseExpr());
    }

    // ---------- 优先级爬升：数字越小绑得越松 ----------
    // 比较级(1) < 加减(2) < 乘除模(3) < 一元负号 < 括号/原子
    public Expr ParseExpr(int minPrecedence = 1)
    {
        var left = ParseUnary();

        while (true)
        {
            if (_lookahead.Kind != TokenKind.Op) break;
            var op = _lookahead.Text;
            var prec = Precedence(op);
            if (prec < minPrecedence) break;

            Advance();                                  // 吃掉运算符
            var right = ParseExpr(prec + 1);            // 左结合：下一层优先级 +1
            left = new BinaryExpr(op, left, right);
        }
        return left;
    }

    private Expr ParseUnary()
    {
        if (_lookahead is { Kind: TokenKind.Op, Text: "-" })
        {
            Advance();
            return new UnaryExpr("-", ParseUnary());
        }
        return ParseAtom();
    }

    private Expr ParseAtom()
    {
        switch (_lookahead.Kind)
        {
            case TokenKind.Number:
                var num = _lookahead;
                Advance();
                return new NumberExpr(double.Parse(num.Text));

            case TokenKind.Ident:
                var id = _lookahead;
                Advance();
                return new VarExpr(id.Text, id.Pos);

            case TokenKind.Op when _lookahead.Text == "(":
                Advance();
                var inner = ParseExpr();
                ExpectOp(")");
                return inner;

            default:
                throw new MiniLangException(_lookahead.Pos, $"这里应是数字/变量/左括号，但看到 {_lookahead}");
        }
    }

    // ---------- 工具 ----------
    private static int Precedence(string op) => op switch
    {
        "==" or "!=" or "<" or "<=" or ">" or ">=" => 1,
        "+" or "-"                                  => 2,
        "*" or "/" or "%"                           => 3,
        _ => throw new MiniLangException(-1, $"未知运算符 {op}"),
    };

    private bool IsAssignPeeked()
        => _peek is { Kind: TokenKind.Op, Text: "=" };   // 双缓冲偷看，不吃掉任何记号

    private void Advance()
    {
        _lookahead = _peek;
        _peek = _lexer.Next();
    }

    private Token Expect(TokenKind kind, string what)
    {
        if (_lookahead.Kind != kind)
            throw new MiniLangException(_lookahead.Pos, $"期望{what}，但看到 {_lookahead}");
        var t = _lookahead;
        Advance();
        return t;
    }

    private void ExpectOp(string op)
    {
        if (_lookahead.Kind != TokenKind.Op || _lookahead.Text != op)   // 属性模式只能比常量，变量比较用传统写法
            throw new MiniLangException(_lookahead.Pos, $"期望 '{op}'，但看到 {_lookahead}");
        Advance();
    }
}
