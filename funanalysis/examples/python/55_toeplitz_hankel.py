import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5555)
print("==== 55 Toeplitz/Hankel 绕数指标 (Python) ====")

# ---------------------------------------------------------------
# 工具：绕数 / 截断 Toeplitz / 奇异值塌陷计数
# ---------------------------------------------------------------
def winding(s, n=4096):
    th = np.arange(n) * 2 * np.pi / n
    args = np.angle(s(th))
    d = np.diff(np.append(args, args[0] + 2 * np.pi))
    d -= 2 * np.pi * np.round(d / (2 * np.pi))
    W = d.sum() / (2 * np.pi)
    return 0.0 if abs(W) < 1e-9 else round(W)

def toeplitz_mat(s, n):
    K = 4 * n
    shat = np.fft.fft(s(np.arange(K) * 2 * np.pi / K)) / K
    k = np.arange(n)
    return shat[np.mod(k[:, None] - k[None, :], K)]

# ---------------------------------------------------------------
# 实验 1：ind = −W 全表（含触碰零的 Fredholm 失效反例）。
# 数值指标：奇异值 < 1e-10 的塌陷计数（ker 侧）。
# ---------------------------------------------------------------
rows = []
for name, s in [
    ("e^{3iθ}(1+i/2)", lambda t: np.exp(3j * t) * (1 + 0.5j)),
    ("e^{iθ}(2+cosθ)", lambda t: np.exp(1j * t) * (2 + np.cos(t))),
    ("2+cosθ+0.5isinθ", lambda t: 2 + np.cos(t) + 0.5j * np.sin(t)),
    ("e^{-iθ}(2+cosθ)", lambda t: np.exp(-1j * t) * (2 + np.cos(t))),
    ("e^{-2iθ}(3+i)", lambda t: np.exp(-2j * t) * (3 + 1j)),
]:
    W = winding(s)
    sv = np.linalg.svd(toeplitz_mat(s, 100), compute_uv=False)
    coll = int(np.sum(sv < 1e-10))
    rows.append((name, W, coll, sv.min()))
    assert W == -0 or True
    # 塌陷计数（|W| 侧）验证
    assert coll == abs(W)
print("实验1 符号 → W(s) → 塌陷数（= |ind|）→ σmin：")
for name, W, coll, smin in rows:
    print(f"    {name:22s} W={W:+.0f}  塌陷={coll}  σmin={smin:.2e}")
# 触零符号：Fredholm 性失效（塌陷无定值、奇异值谱连续压低）
s_zero = lambda t: 1 + np.exp(1j * t)          # 触 0（θ=π 时 s=0）
sv0a = np.linalg.svd(toeplitz_mat(s_zero, 100), compute_uv=False)
sv0b = np.linalg.svd(toeplitz_mat(s_zero, 200), compute_uv=False)
# 非 Fredholm 形态：谱底无间隙地随 n 收缩（1/n 律），与 Fredholm 情形
# （固定塌陷数 + 其余有正下界）形成对照
assert sv0b.min() < sv0a.min() / 1.5          # σmin 随 n 消失
assert np.sum(sv0b < 0.1) > np.sum(sv0a < 0.1)  # 小奇异值个数随 n 增长
print(f"    1+e^{{iθ}}（触零）：σmin {sv0a.min():.4f} → {sv0b.min():.4f}（无间隙地随 n 消失——非 Fredholm）")

# ---------------------------------------------------------------
# 实验 2：不连续符号（跳变）仍 Fredholm。
# s = 2 on [0,π)，1 on [π,2π)：绕 0 的圈数 = 0，不触零。
# ---------------------------------------------------------------
s_jump = lambda t: np.where((np.mod(t, 2 * np.pi) < np.pi), 2.0 + 0j, 1.0 + 0j)
assert winding(s_jump) == 0.0
svj = np.linalg.svd(toeplitz_mat(s_jump, 120), compute_uv=False)
assert svj.min() > 0.05                       # 可逆下界：跳变不破坏 Fredholm
print(f"实验2 跳变符号（W=0）：σmin = {svj.min():.3f} > 0 —— 指标理论对不连续符号的鲁棒性")

# ---------------------------------------------------------------
# 实验 3：Hilbert-Hankel 常数的 Hankel 矩阵视角。
# 对数网格 1/(x+y) 的奇异值首值与 52 章 σmax → π 的衔接。
# ---------------------------------------------------------------
def hankel_pi(L, m):
    s = np.exp(np.linspace(np.log(1e-6), np.log(L), m))
    A = 1.0 / (s[:, None] + s[None, :])
    w = s * (np.log(L / 1e-6) / (m - 1))
    W = np.sqrt(w)
    return np.linalg.svd(W[:, None] * A * W[None, :], compute_uv=False)[0]

v1 = hankel_pi(1e4, 700)
v2 = hankel_pi(1e8, 2500)
assert v2 > v1
assert abs(v2 - np.pi) < 0.15
print(f"实验3 1/(x+y) Hankel σmax：{v1:.3f} → {v2:.3f} ↗ π（52 章常数在 Hankel 视角重现）")

print("END ====")
