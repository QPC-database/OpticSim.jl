# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

abstract type Lattice{T<:Real} end
abstract type InfiniteLattice{T<:Real} <: Lattice{T} end
abstract type FiniteLattice{T<:Real,L<:InfiniteLattice{T}} <: Lattice{T} end

"""returns a Tuple = (2D coordinates of emitter in the lattice,emitter)"""
emitter(a::L, i::Int, j::Int) where {L<:InfiniteLattice} = (a.origin + i * a.e1 + j * a.e2, a.emitter)

emitterpitch_e₁(a::L) where {L<:Lattice} = norm(a.e₁)
emitterpitch_e₂(a::L) where {L<:Lattice} = norm(a.e₂)

struct SizedLattice{T<:Real,L<:InfiniteLattice{T}} <: FiniteLattice{T,L}
    lattice::L
    e₁::Int
    e₂::Int

    function SizedLattice(lattice::L, e₁::Int, e₂::Int) where {T<:Real,L<:InfiniteLattice{T}}
        @assert e₁ >= T(0)
        @assert e₂ >= T(0)
        return new{T,L}(lattice, e₁, e₂)
    end
end

emitterpitchx(a::SizedLattice) = emitterpitchx(norm(a.lattice.e₁))
emitterpitchy(a::SizedLattice) = emitterpitchy(norm(a.lattice.e₂))

function emitter(a::FiniteLattice{T,L}, i::Int, j::Int) where {T<:Real,L<:InfiniteLattice{T}}
    @assert T(0) <= i <= a.e₁emitters
    @assert T(0) <= j <= a.e₂emitters
    return emitter(a.lattice, i, j) #because L is of type InfiteLattice and not FiniteLattice this call will not cause infinite recursion.
end

struct PrimitiveLattice{S<:AbstractSpectrum,P<:AbstractAngularPowerDistribution,T<:Real} <: InfiniteLattice{T}
    origin::SVector{2,T}
    e₁::SVector{2,T}
    e2::SVector{2,T}
    emitter::PlanarEmitter{S,P,T}

    PrimitiveLattice(e₁::SVector{2,T}, e₂::SVector{2,T}, emitter::PlanarEmitter{S,P,T}; origin = SVector{2,T}(T(0), T(0))) where {S<:AbstractSpectrum,P<:AbstractAngularPowerDistribution,T<:Real} = new{S,P,T}(e₁, e₂, emitter, origin)
end

hexagonalemitterlattice(pitch::T, emitter::PlanarEmitter{S,P,T}; origin = SVector{2,T}(T(0), T(0))) where {S<:AbstractSpectrum,P<:AbstractAngularPowerDistribution,T<:Real} = PrimitiveLattice{S,P,T}(origin, SVector{2,T}(emitterpitch, T(0)), SVector{2,T}(emitterpitch / T(2), emitterpitch * sqrt(T(3)) / T(2)), emitter)

squareemitterlattice(emitterpitch::T, emitter::PlanarEmitter{S,P,T}) where {S<:AbstractSpectrum,P<:AbstractAngularPowerDistribution,T<:Real} = PrimitiveLattice{S,P,T}(SVector{2,T}(emitterpitch, T(0)), SVector{2,T}(T(0), emitterpitch), emitter)

#This needs work. We probably want some kind of hierarchical lattice with superemitter and subemitter functions.
struct RGBPixelLattice{R<:AbstractSpectrum,G<:AbstractSpectrum,B<:AbstractSpectrum,P<:AbstractAngularPowerDistribution,T<:Real} <: InfiniteLattice{T}
    red::PrimitiveLattice{R,P,T}
    green::PrimitiveLattice{G,P,T}
    blue::PrimitiveLattice{B,P,T}

    function RGBPixelLattice(::Type{R}, ::Type{G}, ::Type{B}, ::Type{P}, subemitterwidth::T, rgbemitterpitch::T) where {R<:AbstractSpectrum,G<:AbstractSpectrum,B<:AbstractSpectrum,P<:AbstractAngularPowerDistribution,T<:Real}
        @assert 3 * subemitterwidth <= rgbemitterpitch

        subemitterpitch = rgbemitterpitch / T(3.0)
        e₁ = SVector{2,T}(rgbemitterpitch, T(0))
        e2 = SVector{2,T}(T(0), rgbemitterpitch)

        return new{R,G,B,P,T}(PrimitiveLattice(e1, e2, PlanarEmitter{R,P,T}(subemitterwidth, rgbemitterpitch)), PrimitiveLattice(e1, e2, PlanarEmitter{G,P,T}(subemitterwidth, rgbemitterpitch), origin = SVector{2,T}(subemitterpitch, T(0.0))), PrimitiveLattice(e1, e2, PlanarEmitter{B,P,T}(subemitterwidth, rgbemitterpitch), origin = SVector{2,T}(2 * subemitterpitch, T(0.0))))
    end
end
