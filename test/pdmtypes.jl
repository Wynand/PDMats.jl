# test pd matrix types
using LinearAlgebra, PDMats, SparseArrays, SuiteSparse
using Test

for T in [Float64, Float32]
    #test that all external constructors are accessible
    m = Matrix{T}(I, 2, 2)
    @test PDMat(m, cholesky(m)).mat == PDMat(Symmetric(m)).mat == PDMat(m).mat == PDMat(cholesky(m)).mat
    d = ones(T,2)
    @test PDiagMat(d,d).inv_diag == PDiagMat(d).inv_diag
    x = one(T)
    @test ScalMat(2,x,x).inv_value == ScalMat(2,x).inv_value
    s = SparseMatrixCSC{T}(I, 2, 2)
    @test PDSparseMat(s, cholesky(s)).mat == PDSparseMat(s).mat == PDSparseMat(cholesky(s)).mat

    #test the functionality
    M = convert(Array{T,2}, [4. -2. -1.; -2. 5. -1.; -1. -1. 6.])
    V = convert(Array{T,1}, [1.5, 2.5, 2.0])
    X = convert(T,2.0)

    test_pdmat(PDMat(M), M,                        cmat_eq=true, verbose=1) #tests of PDMat
    cholL = Cholesky(Matrix(transpose(cholesky(M).factors)), 'L', 0)
    test_pdmat(PDMat(cholL), M,                    cmat_eq=true, verbose=1) #tests of PDMat
    test_pdmat(PDiagMat(V), Matrix(Diagonal(V)),   cmat_eq=true, verbose=1) #tests of PDiagMat
    test_pdmat(ScalMat(3,x), x*Matrix{T}(I, 3, 3), cmat_eq=true, verbose=1) #tests of ScalMat
    test_pdmat(PDSparseMat(sparse(M)), M,          cmat_eq=true, verbose=1, t_eig=false)
end

m = Matrix{Float32}(I, 2, 2)
@test convert(PDMat{Float64}, PDMat(m)).mat == PDMat(convert(Array{Float64}, m)).mat
@test convert(AbstractArray{Float64}, PDMat(m)).mat == PDMat(convert(Array{Float64}, m)).mat
m = ones(Float32,2)
@test convert(PDiagMat{Float64}, PDiagMat(m)).diag == PDiagMat(convert(Array{Float64}, m)).diag
@test convert(AbstractArray{Float64}, PDiagMat(m)).diag == PDiagMat(convert(Array{Float64}, m)).diag
x = one(Float32); d = 4
@test convert(ScalMat{Float64}, ScalMat(d, x)).value == ScalMat(d, convert(Float64, x)).value
@test convert(AbstractArray{Float64}, ScalMat(d, x)).value == ScalMat(d, convert(Float64, x)).value
s = SparseMatrixCSC{Float32}(I, 2, 2)
@test convert(PDSparseMat{Float64}, PDSparseMat(s)).mat == PDSparseMat(convert(SparseMatrixCSC{Float64}, s)).mat

Z = zeros(0, 0)
test_pdmat(PDMat(Z), Z; t_eig=false)
test_pdmat(PDiagMat(diag(Z)), Z; t_eig=false)

# no-op conversion with correct eltype (#101)
X = PDMat((Y->Y'Y)(randn(Float32, 4, 4)))
@test convert(AbstractArray{Float32}, X) === X
@test convert(AbstractArray{Float64}, X) !== X

# type stability of whiten! and unwhiten!
a = PDMat([1 0.5; 0.5 1])
@inferred whiten!(ones(2), a, ones(2))
@inferred unwhiten!(ones(2), a, ones(2))
@inferred whiten(a, ones(2))
@inferred unwhiten(a, ones(2))

# convert Matrix type to the same Cholesky type (#117)
@test PDMat([1 0; 0 1]) == [1.0 0.0; 0.0 1.0]
