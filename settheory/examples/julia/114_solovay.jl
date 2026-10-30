# 第 114 章：Solovay 内模型与 HOD(Ω)——群作用、轨道稳定子、
# 参数化定义交换、配对整合与 DC 链的有限对拍（与 Python 独立同账）。
println("==== 114")

# ── 一、Z/8 窗口与生成元 ──
rot(x) = (x + 2) % 8
U = collect(0:7)

# ── 二、三个群作用的轨道-稳定子账本 ──
# 群 A：加法循环群 C8，元素 k 作用 x ↦ (x + 2k) mod 8（核=偶子群）。
actA(k, x) = (x + 2k) % 8
orbA(x) = sort(unique([actA(k, x) for k in U]))
stabA(x) = [k for k in U if actA(k, x) == x]

okA = all(length(orbA(x)) * length(stabA(x)) == 8 for x in U)
println("[群A C8: x↦x+2k] 轨道=4 点（奇偶类）、稳定子=2 元、拉格朗日 4*2=8 全员: $(okA)")

# 群 B：偶移位子群 H={0,2,4,6}，k 作用 x ↦ (x + k) mod 8。
H = collect(0:2:6)
actB(k, x) = (x + k) % 8
orbB(x) = sort(unique([actB(k, x) for k in H]))
stabB(x) = [k for k in H if actB(k, x) == x]
okB = all(length(orbB(x)) * length(stabB(x)) == 4 for x in U)
println("[群B 偶子群] 轨道=奇偶两类（4 点）、稳定子平凡、拉格朗日 4*1=4 全员: $(okB)")

# 群 C：翻转对 {id, x↦7-x}——不变性的反例与代表。
flip(x) = 7 - x
orbC(x) = sort(unique([x, flip(x)]))
evens = [x for x in U if x % 2 == 0]
flip_preserves = all(x % 2 == (flip(x)) % 2 for x in U)
println("[群C 翻转对] 偶集在翻转下不变: $(flip_preserves)（反例：0↔7、2↔5 奇偶互换——不变破缺的见证）")

# 轨道代表（可定义代表：每条轨道取最小元——canonical representative）。
repsA = sort(unique([minimum(orbA(x)) for x in U]))
println("[代表] 群A 轨道代表（各轨道最小元）: $(repsA)——「可定义代表」的有限影子")

# ── 三、参数化谓词与群作用交换（OD 的影子——件 A） ──
odef(k, x) = mod(x - k, 8) in (0, 3, 5)
exch_ok = all(odef((k + j) % 8, (x + j) % 8) == odef(k, x)
              for k in U, x in U, j in U)
println("[定义交换] odef((k+j)%8, (x+j)%8) == odef(k,x) 对 8^3=512 组全真: $(exch_ok)")

# 偶集在生成元 rot 下不变（不变对象——件 B）。
invar_ok = all((x % 2 == 0) == (rot(x) % 2 == 0) for x in U)
println("[不变对象] 偶集对 rot 不变: $(invar_ok)")

# 轨道封闭：orbB 的成员再移一位仍在轨道内（件 B2）。
closed_ok = all(rot(y) in orbB(x) for x in U for y in orbB(x))
println("[轨道封闭] 生成元再移一位仍在轨道内: $(closed_ok)")

# ── 四、窗口配对整合（引理 3.22(1) 机制） ──
gpair(m, k) = m + 8k
vals = [gpair(m, k) for m in U, k in U]
inj_ok = length(unique(vec(vals))) == 64
decode_ok = all(gpair(m, k) % 8 == m && gpair(m, k) ÷ 8 == k for m in U, k in U)
println("[配对整合] gpair m+8k 在 0..7 窗口 64 值两两不同: $(inj_ok)；解码往返: $(decode_ok)")

# ── 五、DC 链（引理 3.22(2) 机制核） ──
dchain(next, a, d) = begin
    out = Vector{Int}()
    cur = a
    for _ in 1:d
        push!(out, cur)
        cur = next(cur)
    end
    out
end
R(x, y) = y == rot(x)
ch = dchain(rot, 0, 8)
adj_ok = all(R(ch[i], ch[i+1]) for i in 1:7)
println("[DC 链] next=rot 的 8 步链: $(ch)（0→2→4→6→0 循环）；相邻对满足 R: $(adj_ok)")

# ── 六、HOD 燃料递归（闭包遗传——件 C） ──
parts(x) = x == 0 ? Int[] : [x ÷ 2]
inHOD(d, p, x) = d == 0 ? true : odef(p, x) && all(y -> inHOD(d - 1, p, y), parts(x))
countHOD(d, p) = count(x -> inHOD(d, p, x), 0:15)
println("[HOD 燃料] p=0 的星形 {0,3,5} 下 0..15 各层成员数: d=1→$(countHOD(1,0)) d=2→$(countHOD(2,0)) d=3→$(countHOD(3,0)) d=4→$(countHOD(4,0))")
# 遗传性：x∈HOD(d+1) ⟹ parts(x) ⊆ HOD(d)。
herit_ok = all(!inHOD(d + 1, 0, x) || all(y -> inHOD(d, 0, y), parts(x))
              for d in 1:4 for x in 0:15)
println("[闭包遗传] HOD(d+1) 成员的组件全落 HOD(d): $(herit_ok)")

println("群作用三账+代表；定义交换/不变/封闭；配对整合；DC 链；HOD 燃料账")
println("END ====")
