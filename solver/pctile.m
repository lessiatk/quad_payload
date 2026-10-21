function q = pctile(x, p)
%PCTILE Процентилі без Statistics Toolbox (лінійна інтерполяція).
x = sort(x(isfinite(x)));
n = numel(x);
q = nan(size(p));
if n == 0, return; end
for k = 1:numel(p)
    h = (n - 1) * p(k)/100 + 1;
    lo = floor(h); hi = ceil(h);
    q(k) = x(lo) + (h - lo) * (x(hi) - x(lo));
end
end
