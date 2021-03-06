#univariate nadaraya-watson estimate

function lp0(xdata::RealVector, ydata::RealVector; xeval::RealVector=xdata, kernel::Function=gaussiankernel, h::Real=bwlp0(xdata,ydata,kernel))

    n=length(xdata)
    length(ydata) == n || error("length(ydata) != length(xdata)")
    w=ones(n)
    pre = zeros(length(xeval))
    for i in 1:length(xeval)
        kernel(xeval[i], xdata, h, w, n)
        pre[i] = wsum(w, ydata)/sum(w)
    end
    pre
end
lp0(xdata::RealVector, ydata::RealVector, xeval::Real; kernel::Function = gaussiankernel, h::Real = bwlp0(xdata,ydata,kernel)) = lp0(xdata, ydata, xeval = [xeval;], kernel=kernel, h = h)

function wsumsqdiff(w::RealVector, xdata::RealVector, xeval::Real, n::Int)
    res = 0.0
    for i in 1:n
        @inbounds res += w[i]*(xdata[i]-xeval).^2
    end
    res
end
function wsumyxdiff(w::RealVector, xdata::RealVector, xeval::Real, ydata::RealVector, n::Int)
    res = 0.0
    for i in 1:n
        @inbounds res += w[i]*ydata[i]*(xeval-xdata[i])
    end
    res
end

##univariate local linear
function lp1(xdata::RealVector, ydata::RealVector; xeval::RealVector=xdata, kernel::Function=gaussiankernel, h::Real=bwlp1(xdata, ydata, kernel))
    n=length(xdata)
    length(ydata) == n || error("length of ydata not the same with xdata")
    w = ones(n)
    pre = zeros(length(xeval))
    for i in 1:length(xeval)
        kernel(xeval[i], xdata, h, w, n)
        s0 = sum(w)
        s1 = s0*xeval[i] - wsum(w, xdata)
        s2 = wsumsqdiff(w, xdata, xeval[i], n)
        sy0 = wsum(w, ydata)
        sy1 = wsumyxdiff(w, xdata, xeval[i], ydata, n)
        pre[i] = (s2 * sy0 - s1 * sy1) /(s2 * s0 - s1 * s1)
    end
    pre
end
lp1(xdata::RealVector, ydata::RealVector, xeval::Real; kernel::Function = gaussiankernel, h::Real = bwlp1(xdata,ydata,kernel)) = lp1(xdata, ydata, xeval=[xeval;], kernel=kernel, h=h)



function boundit(xdata::RealVector, xeval::RealVector, kernel::Function, lb::Real, ub::Real)
    if (lb == -Inf) & (ub == Inf)
        return (xdata, xeval)
    elseif (lb > -Inf) & (ub < Inf)
        all(lb .<= xeval .<= ub) & all(lb .<= xdata .<= ub) || error("Your data are not in [lb,ub]")
        xeval = (xeval .- lb)./(ub - lb)
        xdata = (xdata .- lb)./(ub - lb)
        if kernel != betakernel
            warn("Kernel is set to betakernel")
        end
    elseif (lb > -Inf) & (ub == Inf)
        all(xeval .>= lb) & all(xdata .>= lb) || error("lb should be less than your data")
        xeval = xeval .- lb
        xdata = xdata .- lb
        if kernel != gammakernel
            warn("Kernel is set to gammakernel")
        end
    elseif (lb == -Inf) & (ub < Inf)
        all(xeval .<= ub) & all(xdata .<= ub) || error("ub should be greater than your data")
        xeval = ub .- xeval
        xdata = ub .- xdata
        if kernel != gammakernel
             warn("Kernel is set to gamma kernel")
        end
    end
    (xdata, xeval)
end

function npr(xdata::RealVector, ydata::RealVector; xeval::RealVector=xdata,
        reg::Function=lp1, lb::Real=-Inf, ub::Real=Inf, kernel::Function=gaussiankernel, h::Real=-Inf)

    xdata, xeval = boundit(xdata, xeval, kernel, lb, ub)
    if h <= 0
        h = bwreg(xdata, ydata, reg, kernel)
    end
    reg(xdata, ydata, xeval=xeval, kernel=kernel, h=h)
end


# #multi-variate nadaraya-watson
# function LP0(xeval::Vector{Float64}, xdata::Matrix{Float64}, ydata::Vector{Float64}, kernel::Function=GaussianKernel, h::Vector{Float64}=BandwidthLSCVReg(xdata,ydata,LP0,kernel))

#   (n,p)=size(xdata)
#   if length(xeval) != p || length(h) !=p
#     error("xeval, xdata and h should have same dimension!")
#   end

#   tmp=zeros(n)
#   for i in 1:n
#     tmp[i]=prod([GaussianKernel(xeval[j], xdata[i,j],h[j])::Float64 for j in 1:p])
#   end

#   s0 = sum(tmp)
#   sy0 = sum(tmp .* ydata)
#   sy0 / s0
# end

# #
# function LP0(xeval::Matrix{Float64}, xdata::Matrix{Float64},
#   ydata::Vector{Float64}, kernel::Function=GaussianKernel, h::Vector{Float64}=BandwidthLSCVReg(xdata,ydata,LP0,kernel))

#   (m,p)=size(xeval)
#   den=zeros(m)
#   xi=zeros(p)
#   for i=1:m
#     for k in 1:p
#       xi[k] = xeval[i,k]
#     end
#     den[i] = LP0(xi, xdata, ydata, kernel, h)::Float64
#   end
#   den
# end
