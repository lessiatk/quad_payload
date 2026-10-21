function Xs = sample_params(P, N)
%SAMPLE_PARAMS N випадкових реалізацій параметрів (Monte Carlo).
%   Параметри kind='unc' - трикутний розподіл (lo, nom, hi).
%   Експлуатаційні параметри фіксуються на гіршому випадку (design point),
%   тобто MC оцінює епістемічну невизначеність у найгірших умовах.
Xd = get_point(P, 'design');
f  = fieldnames(P);
Xs = repmat(Xd, N, 1);
for k = 1:numel(f)
    p = P.(f{k});
    if strcmp(p.kind, 'unc') && p.hi > p.lo
        u = rand(N, 1);
        v = tri_inv(u, p.lo, p.nom, p.hi);
        for i = 1:N
            Xs(i).(f{k}) = v(i);
        end
    end
end
end

function x = tri_inv(u, a, m, b)
% Обернена функція розподілу трикутного закону.
c = (m - a) / (b - a);
x = zeros(size(u));
lo = u < c;
x(lo)  = a + sqrt(u(lo) * (b - a) * (m - a));
x(~lo) = b - sqrt((1 - u(~lo)) * (b - a) * (b - m));
end
