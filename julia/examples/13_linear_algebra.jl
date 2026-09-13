using LinearAlgebra

A = [1.0 2.0; 3.0 4.0]
B = [2.0 0.0; 1.0 2.0]

C = A * B
println("C=", C)
println("det(A)=", det(A))
println("A'=", A')

