function MC = monte_carlo(P, cfg)
%MONTE_CARLO Поширення невизначеності вихідних даних на m_p*.
%   Вибірки з фізично неправдоподібним FM > FM_max відкидаються
%   (суперечність між незалежно заданими C_T і C_P) - їх частка
%   передається в модуль достовірності.
N  = cfg.N_mc;
Xs = sample_params(P, N);
nm = unc_names(P);
C  = constraint_list();

m_max  = nan(N, 1); active = zeros(N, 1);
T_max  = nan(N, 1); FM = nan(N, 1); t_ref = nan(N, 1);
rejected = false(N, 1);
Xmat = zeros(N, numel(nm));
cfg_fast = cfg; cfg_fast.dm = cfg.dm_mc; cfg_fast.tol = cfg.tol_mc;

for i = 1:N
    X = Xs(i);
    for k = 1:numel(nm), Xmat(i, k) = X.(nm{k}); end
    FM(i) = X.CT^1.5 / (X.CP*sqrt(pi/2));
    if FM(i) > X.FM_max
        rejected(i) = true;
        continue;
    end
    S = max_payload(X, cfg_fast);
    m_max(i) = S.m_max;
    if strcmp(S.status, 'infeasible'), m_max(i) = 0; end
    active(i) = S.active;
    T_max(i) = S.B.T_max;
    R = eval_payload(S.B, X, cfg.m_target);
    t_ref(i) = R.t_flight_min;
    if mod(i, max(1, round(N/10))) == 0
        fprintf('  MC: %d / %d\n', i, N);
    end
end

ok = ~rejected;
MC.N = N; MC.names = nm; MC.X = Xmat;
MC.m_max = m_max; MC.active = active; MC.T_max = T_max; MC.FM = FM;
MC.t_ref = t_ref; MC.rejected = rejected; MC.ok = ok;
MC.frac_rejected = mean(rejected);
MC.p = [5 50 95];
MC.q = pctile(m_max(ok), MC.p);
MC.mean = mean(m_max(ok));
MC.std  = std(m_max(ok));
MC.P_target = mean(m_max(ok) >= cfg.m_target);
MC.active_counts = zeros(numel(C), 1);
for j = 1:numel(C)
    MC.active_counts(j) = sum(active(ok) == j);
end
% Рангова кореляція Спірмена параметр -> m_max (без toolbox)
MC.spearman = zeros(numel(nm), 1);
ry = ranks(m_max(ok));
for k = 1:numel(nm)
    rx = ranks(Xmat(ok, k));
    cc = corrcoef(rx, ry);
    MC.spearman(k) = cc(1, 2);
end
end

function r = ranks(x)
[~, i] = sort(x);
r = zeros(size(x));
r(i) = 1:numel(x);
end
