println("==== 123")

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
@assert chapters == collect(0:123)
@assert length(chapters) == length(unique(chapters)) == 124

expected_new = vcat(collect(79:83), collect(93:122))
actual_new = filter(n -> n in Set(expected_new), chapters)
@assert actual_new == expected_new
@assert length(actual_new) == 35

baseline_units = 624
channels = 7
final_units = baseline_units + length(actual_new) * channels
@assert final_units == 869
@assert final_units == length(chapters) * channels + 1
println("docs: 124 chapters, continuous 00-123; new=35")
println("axes: 6 aligned rows; units: 624+35*7=869")
println("END ====")
