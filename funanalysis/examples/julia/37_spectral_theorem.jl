using LinearAlgebra, Random
println("==== 37 spectral-theorem (Julia) ====")
Random.seed!(3737)
H = randn(8, 8); H = (H + H') / 2
vals, vecs = eigen(H)
println("eigenvalues: $(round.(vals, digits=4))")
println("all real: $(all(isreal, vals))")
@assert all(isreal, vals)
# 谱分解：H = Σ λₙ Pₙ
H_recon = vecs * Diagonal(vals) * vecs'
err = norm(H - H_recon) / norm(H)
println("reconstruction error: $(round(err, digits=10))")
@assert err < 1e-12
println("==== 37 spectral-theorem END ====")
