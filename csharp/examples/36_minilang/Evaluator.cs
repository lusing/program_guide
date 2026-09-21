// 求值器：遍历 AST 算出结果（解释器的"执行"阶段）
namespace MiniLang;

public sealed class Evaluator
{
    private readonly Dictionary<string, double> _vars = new();

    public IReadOnlyDictionary<string, double> Variables => _vars;

    /// <summary>执行一条语句，返回"本行结果"（裸表达式有值，赋值返回新值）。</summary>
    public double Execute(Stmt stmt)
    {
        switch (stmt)
        {
            case LetStmt(var name, var value):
                if (_vars.ContainsKey(name))
                    throw new MiniLangException(0, $"变量 {name} 已存在（let 只能声明一次，重新赋值直接写 {name} = …）");
                return _vars[name] = Eval(value);

            case AssignStmt(var name, var value):
                if (!_vars.ContainsKey(name))
                    throw new MiniLangException(0, $"变量 {name} 未定义（先 let {name} = …）");
                return _vars[name] = Eval(value);

            case ExprStmt(var expr):
                return Eval(expr);

            default:
                throw new MiniLangException(0, $"未知语句 {stmt?.GetType().Name}");
        }
    }

    private double Eval(Expr expr) => expr switch
    {
        NumberExpr n => n.Value,

        VarExpr v => _vars.TryGetValue(v.Name, out var val)
            ? val
            : throw new MiniLangException(v.Pos, $"变量 {v.Name} 未定义"),

        UnaryExpr("-", var operand) => -Eval(operand),
        UnaryExpr u => throw new MiniLangException(0, $"不支持的一元运算 {u.Op}"),

        BinaryExpr(var op, var l, var r) => op switch
        {
            "+"  => Eval(l) + Eval(r),
            "-"  => Eval(l) - Eval(r),
            "*"  => Eval(l) * Eval(r),
            "/"  => Divide(Eval(l), Eval(r)),
            "%"  => Modulo(Eval(l), Eval(r)),
            "==" => BoolNum(Eval(l) == Eval(r)),
            "!=" => BoolNum(Eval(l) != Eval(r)),
            "<"  => BoolNum(Eval(l) <  Eval(r)),
            "<=" => BoolNum(Eval(l) <= Eval(r)),
            ">"  => BoolNum(Eval(l) >  Eval(r)),
            ">=" => BoolNum(Eval(l) >= Eval(r)),
            _    => throw new MiniLangException(0, $"不支持的运算符 {op}"),
        },

        _ => throw new MiniLangException(0, "无法求值的表达式"),
    };

    // 用 1/0 表示布尔（MiniLang 没有独立布尔类型——讲解取舍见第 36 章）
    private static double BoolNum(bool b) => b ? 1 : 0;

    // double 除零本会是 ∞ 而非异常——语言内置如此，MiniLang 明确报错更符合直觉
    private static double Divide(double a, double b)
        => b == 0 ? throw new MiniLangException(0, "除数为零") : a / b;

    private static double Modulo(double a, double b)
        => b == 0 ? throw new MiniLangException(0, "取模的除数为零") : a % b;
}
