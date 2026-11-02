# 第 32 章 Julia：精确得分账、闭式 MLE 与 Newton 优化。
println("==== 32 mle")

bernoulli_score(x, p) = x / p - (1 - x) / (1 - p)
bernoulli_information(p) = 1 / (p * (1 - p))
p = 1 // 3
score0, score1 = bernoulli_score(0, p), bernoulli_score(1, p)
@assert (1 - p) * score0 + p * score1 == 0
@assert (1 - p) * score0^2 + p * score1^2 == bernoulli_information(p)
@assert (1 - p) / (1 - p)^2 + p / p^2 == bernoulli_information(p)
println("Bernoulli score and information identities: OK")

data = [1, 0, 1, 1, 0, 1, 0, 1, 1, 1]
function bernoulli_loglik(p, observations)
    k, n = sum(observations), length(observations)
    (k == 0 ? 0.0 : k * log(p)) +
        (n - k == 0 ? 0.0 : (n - k) * log(1 - p))
end

function bernoulli_newton(observations; start=0.2, tolerance=1e-12)
    p = start
    history = [p]
    for _ in 1:30
        k, n = sum(observations), length(observations)
        score = k / p - (n - k) / (1 - p)
        curvature = -k / p^2 - (n - k) / (1 - p)^2
        candidate = p - score / curvature
        0 < candidate < 1 || error("unconstrained Newton left (0,1)")
        push!(history, candidate)
        abs(candidate - p) < tolerance && return candidate, history
        p = candidate
    end
    error("Newton did not converge")
end

phat, history = bernoulli_newton(data)
@assert abs(phat - sum(data) / length(data)) < 1e-12
@assert bernoulli_loglik(phat, data) >= bernoulli_loglik(0.2, data)
odds_hat = phat / (1 - phat)
@assert abs(odds_hat / (1 + odds_hat) - phat) < 1e-12
println("Newton history: ", history)

# 正态双参数 MLE 的固定数据精确账。
xs = Rational{Int}[1, 2, 4, 5]
n = length(xs)
mu_hat = sum(xs) / n
q = sum((x - mu_hat)^2 for x in xs)
v_hat = q / n
@assert (mu_hat, q, v_hat) == (3 // 1, 10 // 1, 5 // 2)
@assert sum(x - mu_hat for x in xs) / v_hat == 0
@assert -n / (2 * v_hat) + q / (2 * v_hat^2) == 0

# Poisson MLE 与得分曲率账。
poisson_data = [0, 2, 1, 3, 1, 2]
lambda_hat = sum(poisson_data) // length(poisson_data)
@assert lambda_hat == 3 // 2
@assert sum(poisson_data) / lambda_hat - length(poisson_data) == 0

# 精确二项枚举给出 phat=k/n 的抽样均值和方差。
n, p = 8, 1 // 4
weights = [(k, Rational{Int}(binomial(n, k)) * p^k * (1 - p)^(n - k))
           for k in 0:n]
@assert sum(weight for (_, weight) in weights) == 1
mean_phat = sum((k // n) * weight for (k, weight) in weights)
second_moment = sum((k // n)^2 * weight for (k, weight) in weights)
@assert mean_phat == p
@assert second_moment - mean_phat^2 == p * (1 - p) / n
println("normal, Poisson, reparameterization and exact sampling moments: OK")
println("END ====")
