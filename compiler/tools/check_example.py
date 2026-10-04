#!/usr/bin/env python
# 对 examples/NN_slug 做对账：
#   无 programs/ → 简单程序：无参运行，stdout(+stderr) 对 expected/output.txt，
#                            退出码对 expected/exit.txt（默认 0）
#   有 programs/ → 对 programs/*.tip 依次 tipa --check，拼接 "== file ==" 头，
#                  对 expected/output.txt；programs/errors/*.tip 对 expected/errors/<stem>.txt，
#                  期望退出码非零；expected/run、expected/soundness、expected/opt 按需对账
import pathlib, subprocess, sys

MSYS_BASH = r"G:\scoop\apps\msys2\current\usr\bin\bash.exe"

def run(cmd, stdin=None):
    p = subprocess.run(cmd, input=stdin, capture_output=True, text=True, encoding="utf-8")
    return p.returncode, p.stdout + p.stderr

def read_inputs(path):
    runs = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            runs.append(line)
    return runs

def main(ex):
    ex = pathlib.Path(ex)
    tipa = ex.parents[1] / "build" / ex.name / "tipa.exe"
    exp = ex / "expected"
    progs = ex / "programs"
    if not progs.is_dir():                       # 简单示例（01-03）
        want_code = int((exp / "exit.txt").read_text().strip()) if (exp / "exit.txt").exists() else 0
        code, out = run([str(tipa)])
        assert code == want_code, f"exit {code} != {want_code}"
        assert out == (exp / "output.txt").read_text(encoding="utf-8"), "stdout mismatch"
        print(f"[check {ex.name} OK]"); return
    # --check 正常样例
    chunks = []
    for f in sorted(progs.glob("*.tip")):
        chunks.append(f"== {f.name} ==")
        code, out = run([str(tipa), "--check", str(f)])
        assert code == 0, f"{f.name}: exit {code}\n{out}"
        chunks.append(out.rstrip("\n"))
    got = "\n".join(c for c in chunks if c) + "\n"
    assert got == (exp / "output.txt").read_text(encoding="utf-8"), "analysis output mismatch"
    # 错误样例
    errfiles = sorted((progs / "errors").glob("*.tip")) if (progs / "errors").is_dir() else []
    for f in errfiles:
        code, out = run([str(tipa), "--check", str(f)])
        assert code != 0, f"{f.name}: 期望报错但退出 0"
        assert out == (exp / "errors" / f"{f.stem}.txt").read_text(encoding="utf-8"), \
               f"{f.name}: 诊断文本不符"
    # --run / --verify-soundness（.inputs 与 .txt 同名成对）
    for sub, flag in (("run", "--run"), ("soundness", "--verify-soundness")):
        d = exp / sub
        if not d.is_dir():
            continue
        for inf in sorted(d.glob("*.inputs")):
            runs = read_inputs(inf)
            code, out = run([str(tipa), flag, str(progs / f"{inf.stem}.tip"), str(inf)])
            assert code == 0, f"{sub}/{inf.stem}: exit {code}\n{out}"
            assert out == (d / f"{inf.stem}.txt").read_text(encoding="utf-8"), \
                   f"{sub}/{inf.stem} 输出不符"
    # opt 对照（*.cmd 配 *.out）
    od = exp / "opt"
    if od.is_dir():
        for cmdfile in sorted(od.glob("*.cmd")):
            cmd = f"cd '{pathlib.Path.cwd().as_posix()}' && {cmdfile.read_text(encoding='utf-8').strip()}"
            p = subprocess.run([MSYS_BASH, "-lc", cmd], capture_output=True, text=True)
            assert p.returncode == 0, p.stderr
            want = (od / f"{cmdfile.stem}.out").read_text(encoding="utf-8")
            assert p.stdout == want, f"opt/{cmdfile.stem} 漂移"
    print(f"[check {ex.name} OK]")

if __name__ == "__main__":
    main(sys.argv[1])
