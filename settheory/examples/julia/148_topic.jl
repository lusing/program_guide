println("==== 148")

# 六行只是阅读索引，不是六个无限定理的机器证明。
strength = [:inaccessible, :measurable, :supercompact,
            :woodin, :woodin_limit, :measurable_above]
forcing = [:small, :prikry, :proper, :ideal, :tower, :iteration]
regularity = [:borel, :analytic, :sigma12, :universally_baire,
              :projective, :ad_l_r]
@assert length(strength) == length(forcing) == length(regularity) == 6
@assert collect(1:6) == [i for i in 1:6 if strength[i] isa Symbol &&
                         forcing[i] isa Symbol && regularity[i] isa Symbol]

# 直接扫描最终教程目录，避免只检查程序内部写死的章表。
docs = normpath(joinpath(@__DIR__, "..", "..", "docs"))
function chapter_number(file)
    m = match(r"^(\d{2,3})-.*\.md$", file)
    return m === nothing ? nothing : parse(Int, m.captures[1])
end
chapters = sort([chapter_number(f) for f in readdir(docs)
                 if chapter_number(f) !== nothing])
@assert chapters == collect(0:148)
@assert length(chapters) == length(unique(chapters)) == 149

# 第十三篇（郝兆宽·杨跃路线）并入：123-147，共 25 章。
hao_chapters = filter(n -> n >= 123 && n != 148, chapters)
@assert hao_chapters == collect(123:147)
@assert length(hao_chapters) == 25

# 前十二篇 869 单元；郝/杨跃篇新增
# lean 16 + isabelle 8 + coq 6 + julia 15 + python 24 + prolog 10 = 79。
hao_units = Dict(:lean => 16, :isabelle => 8, :coq => 6, :agda => 0,
                 :julia => 15, :python => 24, :prolog => 10)
@assert sum(values(hao_units)) == 79
baseline_units = 869
final_units = baseline_units + sum(values(hao_units))
@assert final_units == 948
println("docs: 149 chapters, continuous 00-148; hao=25")
println("axes: 6 aligned rows; units: 869+79=948")
println("END ====")
