// 词法分析：字符流 → 记号流
namespace MiniLang;

public enum TokenKind
{
    Number,     // 数字字面量
    Ident,      // 标识符（变量名）
    Let,        // 关键字 let
    Op,         // 运算符/标点（+ - * / % = == != < <= > >= ( )）
    Eof,        // 输入结束
}

public readonly record struct Token(TokenKind Kind, string Text, int Pos)
{
    public override string ToString() => Kind switch
    {
        TokenKind.Number => $"数({Text})",
        TokenKind.Ident  => $"名({Text})",
        TokenKind.Let    => "let",
        TokenKind.Op     => Text,
        _                => "⟨结束⟩",
    };
}

public sealed class Lexer(string source)
{
    private int _pos;

    public Token Next()
    {
        SkipWhitespace();

        if (_pos >= source.Length)
            return new Token(TokenKind.Eof, "", _pos);

        var start = _pos;
        var ch = source[_pos];

        if (char.IsDigit(ch) || ch == '.')
        {
            while (_pos < source.Length && (char.IsDigit(source[_pos]) || source[_pos] == '.'))
                _pos++;
            return new Token(TokenKind.Number, source[start.._pos], start);
        }

        if (char.IsLetter(ch) || ch == '_')
        {
            while (_pos < source.Length && (char.IsLetterOrDigit(source[_pos]) || source[_pos] == '_'))
                _pos++;
            var word = source[start.._pos];
            return word == "let"
                ? new Token(TokenKind.Let, word, start)
                : new Token(TokenKind.Ident, word, start);
        }

        // 双字符运算符优先探测（== != <= >=），单字符兜底
        if (_pos + 1 < source.Length)
        {
            var pair = source.Substring(_pos, 2);
            if (pair is "==" or "!=" or "<=" or ">=")
            {
                _pos += 2;
                return new Token(TokenKind.Op, pair, start);
            }
        }

        if ("+-*/%=<>()".Contains(ch))
        {
            _pos++;
            return new Token(TokenKind.Op, ch.ToString(), start);
        }

        throw new MiniLangException(start, $"无法识别的字符 '{ch}'");
    }

    private void SkipWhitespace()
    {
        while (_pos < source.Length && char.IsWhiteSpace(source[_pos]))
            _pos++;
    }
}

public sealed class MiniLangException(int pos, string message)
    : Exception($"位置 {pos}: {message}");
