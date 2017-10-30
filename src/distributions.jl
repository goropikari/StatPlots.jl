
# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha = 0.0001)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1-alpha)
    minval, maxval
end

# this "user recipe" adds a default x vector based on the distribution's μ and σ
@recipe f(dist::Distribution) = (dist, default_range(dist)...)

@recipe function f(distvec::AbstractArray{<:Distribution}, yz...)
    for di in distvec
        @series begin
            seriesargs = isempty(yz) ? default_range(di) : yz
            (di, seriesargs...)
        end
    end
end

# this "type recipe" replaces any instance of a distribution with a function mapping xi to yi
@recipe function f(::Type{T}, dist::T; func = pdf) where T<:Distribution
    xi -> func(dist, xi)
end

#-----------------------------------------------------------------------------
# qqplots

@recipe function f(h::QQPair; qqline = :identity)
    if qqline in (:fit, :quantile, :identity, :R)
        xs = [extrema(h.qx)...]
        if qqline == :identity
            ys = xs
        elseif qqline == :fit
            itc, slp = linreg(h.qx, h.qy)
            ys = slp .* xs .+ itc
        else # if qqline == :quantile || qqline == :R
            quantx, quanty = quantile(h.qx, [0.25, 0.75]), quantile(h.qy, [0.25, 0.75])
            slp = diff(quanty) ./ diff(quantx)
            ys = quanty .+ slp .* (xs .- quantx)
        end

        @series begin
            primary := false
            seriestype := :path
            xs, ys
        end
    end

    seriestype --> :scatter
    legend --> false
    h.qx, h.qy
end

loc(D::Type{T}, x) where T<:Distribution = fit(D, x), x
loc(D, x) = D, x

@userplot QQPlot
@recipe f(h::QQPlot) = qqbuild(loc(h.args[1], h.args[2])...)

@userplot QQNorm
@recipe f(h::QQNorm) = QQPlot((Normal, h.args[1]))
