function CV = convergence_study(X, cfg)
%CONVERGENCE_STUDY Збіжність чисельних методів.
%   1) МСЕ променя: прогин, напруження і власна частота при згущенні сітки.
%   2) Бісекція: m_p* при зменшенні допуску.
B = precompute(X);
ne = [1 2 4 8 16 32 64];
CV.n_el = ne;
CV.f = zeros(size(ne)); CV.delta = zeros(size(ne)); CV.sigma = zeros(size(ne));
for k = 1:numel(ne)
    R = arm_fem(X, B.FT.T, B.m_tip, ne(k));
    CV.f(k) = R.f_n; CV.delta(k) = R.delta; CV.sigma(k) = R.sigma_root;
end
CV.f_err = abs(CV.f - CV.f(end)) / CV.f(end);

tols = [1 0.3 0.1 0.03 0.01 0.003 0.001];
CV.tol = tols; CV.m = zeros(size(tols));
c2 = cfg;
for k = 1:numel(tols)
    c2.tol = tols(k);
    S = max_payload(X, c2);
    CV.m(k) = S.m_max;
end
end
