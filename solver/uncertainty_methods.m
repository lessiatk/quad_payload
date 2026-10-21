function UM = uncertainty_methods(P, S, MC, SE, cfg)
%UNCERTAINTY_METHODS Альтернативні методи оцінювання невизначеності m_p* (гірші умови).
%
%   1. Інтервальний аналіз - гарантований діапазон [lo, hi] без розподілів: кожен параметр ставиться
%      на «поганий» (або «добрий») край за знаком торнадо; монотонність перевіряється випадковими вершинами.
%   2. FOSM  - розклад у ряд Тейлора: sigma^2 = sum (dm/dx_i)^2 sigma_i^2 (градієнти скінченними різницями).
%   3. FORM  - найімовірніша точка досягнення m_target (ітерації HL-RF у нормальному просторі).
%   4. QMC   - квазі-Монте-Карло на послідовності Хaлтона (детермінований).
%   5. Аналітичне домінуюче обмеження: m_p* = 4 T_max / (k_TW g r) - m_порожня, дешево -> багато вибірок.
%   Усі методи працюють над тими самими параметрами kind='unc' з трикутними розподілами.
Xd = S.X;
nm = unc_names(P); n = numel(nm);
lo = zeros(n, 1); hi = lo; nom = lo;
for j = 1:n
    p = P.(nm{j}); lo(j) = p.lo; hi(j) = p.hi; nom(j) = p.nom;
end
mt = cfg.m_target;
cf = cfg; cf.dm = cfg.dm_mc; cf.tol = 1e-3;          % градієнти: груба сітка, точна бісекція
UM.names = nm; UM.m_target = mt; UM.m_det = S.m_max;

% ---------- 1. Інтервальний аналіз ----------
% Резонансне обмеження немонотонне: при песимістичному E_arm власна частота може збігтися з 2P обертів
% висіння, і допустимої області немає. Тому рахуємо двічі: з усіма обмеженнями і без резонансу
% (res_margin = 0 вимикає g8) - тоді резонанс лишається окремою перевіркою за виміряною f_n.
UM.int     = interval_run(Xd, nm, lo, hi, SE, cf, 60, false);
UM.int_nor = interval_run(Xd, nm, lo, hi, SE, cf, 60, true);

% ---------- 2. FOSM ----------
mu = (lo + hi + nom) / 3;
vr = (lo.^2 + hi.^2 + nom.^2 - lo.*hi - lo.*nom - hi.*nom) / 18;   % дисперсія трикутного закону
xm = Xd;
for j = 1:n, xm.(nm{j}) = mu(j); end
F.mu = mpay(xm, cf);
F.grad = zeros(n, 1);
for j = 1:n
    h = 0.05 * (hi(j) - lo(j));
    a = max(mu(j) - h, lo(j)); b = min(mu(j) + h, hi(j));
    Xa = xm; Xa.(nm{j}) = a; Xb = xm; Xb.(nm{j}) = b;
    F.grad(j) = (mpay(Xb, cf) - mpay(Xa, cf)) / (b - a);
end
c = F.grad.^2 .* vr;
F.sigma = sqrt(sum(c));
F.share = c / max(sum(c), eps);
F.q5 = F.mu - 1.645*F.sigma; F.q95 = F.mu + 1.645*F.sigma;
if F.sigma > 0, F.P = 1 - Phi((mt - F.mu)/F.sigma); else, F.P = double(F.mu >= mt); end
F.evals = 1 + 2*n;
UM.fosm = F;

% ---------- 3. FORM ----------
act = find(F.share > 0.005)';                        % випадкові лише суттєві параметри, решта - медіана
if isempty(act), act = find(F.share == max(F.share), 1); end
na = numel(act);
Gf = @(u) mpay(x_of_u(Xd, nm, lo, nom, hi, act, u), cf) - mt;
u = zeros(na, 1); ev = 0; conv = false; Gs = NaN;
G0 = Gf(u); ev = ev + 1;
for it = 1:10
    G = Gf(u); ev = ev + 1;
    g = zeros(na, 1);
    for k = 1:na
        e = zeros(na, 1); e(k) = 0.25;
        g(k) = (Gf(clip(u + e)) - Gf(clip(u - e))) / 0.5; ev = ev + 2;
    end
    ng = norm(g);
    if ng < 1e-9, break; end
    un = clip(((g'*u - G) / ng^2) * g);
    Gs = G;
    if norm(un - u) < 0.05 || abs(G) < 0.02, u = un; conv = true; break; end
    u = un;
end
Gs = Gf(u); ev = ev + 1;
R.act = act; R.u = u; R.beta = norm(u); R.G0 = G0; R.Gstar = Gs;
R.reachable = abs(Gs) < 0.05;                        % межу G = 0 знайдено в межах діапазонів параметрів
R.converged = conv && R.reachable;
if ~R.reachable
    R.P = 0;                                         % ціль недосяжна навіть на краях діапазонів
elseif G0 < 0
    R.P = Phi(-R.beta);
else
    R.P = Phi(R.beta);
end
Xs = x_of_u(Xd, nm, lo, nom, hi, act, u);
R.x = zeros(na, 1); R.x0 = zeros(na, 1);
for k = 1:na
    R.x(k) = Xs.(nm{act(k)});
    R.x0(k) = tri_inv(0.5, lo(act(k)), nom(act(k)), hi(act(k)));
end
R.FM = Xs.CT^1.5 / (Xs.CP*sqrt(pi/2));
R.evals = ev;
UM.form = R;

% ---------- 4. Квазі-Монте-Карло (Халтон) ----------
cq = cfg; cq.dm = cfg.dm_mc; cq.tol = cfg.tol_mc;
nq = cfg.N_qmc; pr = primes(400);
skip = 20;
Q.m = nan(nq, 1);
for i = 1:nq
    X = Xd;
    for j = 1:n
        uu = mod(radical_inverse(skip + i, pr(j)) + mod(j*0.6180339887, 1), 1);
        X.(nm{j}) = tri_inv(uu, lo(j), nom(j), hi(j));
    end
    if X.CT^1.5/(X.CP*sqrt(pi/2)) > X.FM_max, continue; end
    Q.m(i) = mpay(X, cq);
end
ok = isfinite(Q.m);
Q.q = pctile(Q.m(ok), [5 50 95]);
Q.P = mean(Q.m(ok) >= mt);
Q.mean = mean(Q.m(ok)); Q.std = std(Q.m(ok));
Q.N = nq; Q.n_ok = sum(ok);
Q.ns = [32 64 128 nq];                               % збіжність P5: QMC проти звичайного MC на тих самих n
Q.p5_qmc = zeros(size(Q.ns)); Q.p5_mc = zeros(size(Q.ns));
mq = Q.m(ok); mm = MC.m_max(MC.ok);
for k = 1:numel(Q.ns)
    Q.p5_qmc(k) = pctile(mq(1:min(Q.ns(k), numel(mq))), 5);
    Q.p5_mc(k)  = pctile(mm(1:min(Q.ns(k), numel(mm))), 5);
end
Q.p5_ref = MC.q(1);
Q.evals = nq;
UM.qmc = Q;

% ---------- 5. Аналітичне домінуюче обмеження ----------
r = S.R.T_hi / (S.R.m_total * S.B.g / 4);            % T_max_ротора / середня тяга (перерозподіл через зміщення ЦМ)
A.r = r;
A.m_det = mtw(Xd, r);
ns = 5000;
Xs = sample_params(P, ns);
mA = nan(ns, 1);
for i = 1:ns
    if Xs(i).CT^1.5/(Xs(i).CP*sqrt(pi/2)) > Xs(i).FM_max, continue; end
    mA(i) = mtw(Xs(i), r);
end
okA = isfinite(mA);
A.q = pctile(mA(okA), [5 50 95]);
A.P = mean(mA(okA) >= mt);
A.N = ns;
A.tw_share = MC.active_counts(1) / max(sum(MC.ok), 1);   % частка MC-реалізацій, де визначає запас тяги
UM.ana = A;
end

% ======================= допоміжні =======================
function I = interval_run(Xd, nm, lo, hi, SE, cf, nv, no_res)
% Гарантований діапазон: край за знаком торнадо (2 розрахунки) + перевірка nv випадковими вершинами.
n = numel(nm);
if no_res, Xd.res_margin = 0; end
xw = Xd; xb = Xd;
for j = 1:n                                          % SE.tor_names має той самий порядок, що unc_names
    if SE.lo(j) <= SE.hi(j)
        xw.(nm{j}) = lo(j); xb.(nm{j}) = hi(j);
    else
        xw.(nm{j}) = hi(j); xb.(nm{j}) = lo(j);
    end
end
I.lo_sign = mpay(xw, cf); I.hi = mpay(xb, cf);
mv = zeros(nv, 1);
bits = rand(nv, n) > 0.5;
for i = 1:nv
    X = Xd;
    for j = 1:n
        if bits(i, j), X.(nm{j}) = hi(j); else, X.(nm{j}) = lo(j); end
    end
    mv(i) = mpay(X, cf);
end
I.v_min = min(mv); I.v_max = max(mv);
I.lo = min(I.lo_sign, I.v_min);                      % найменше знайдене значення (не доведений глобальний мінімум)
I.monotone = I.v_min >= I.lo_sign - 0.02 && I.v_max <= I.hi + 0.02;
I.FM_w = xw.CT^1.5 / (xw.CP*sqrt(pi/2));
I.FM_b = xb.CT^1.5 / (xb.CP*sqrt(pi/2));
I.xw = zeros(n, 1); I.xb = zeros(n, 1);
for j = 1:n, I.xw(j) = xw.(nm{j}); I.xb(j) = xb.(nm{j}); end
I.evals = 2 + nv;
end

function m = mpay(X, cf)
S2 = max_payload(X, cf);
m = S2.m_max;
if ~isfinite(m), m = 0; end
end

function m = mtw(X, r)
B = precompute(X);
m = 4 * B.T_max / (X.k_TW * B.g * r) - B.m_empty;
end

function X = x_of_u(Xd, nm, lo, nom, hi, act, u)
X = Xd;
for j = 1:numel(nm)
    X.(nm{j}) = tri_inv(0.5, lo(j), nom(j), hi(j));
end
for k = 1:numel(act)
    j = act(k);
    X.(nm{j}) = tri_inv(Phi(u(k)), lo(j), nom(j), hi(j));
end
end

function u = clip(u)
u = max(min(u, 4), -4);
end

function p = Phi(x)
p = 0.5 * erfc(-x / sqrt(2));
end

function v = radical_inverse(i, b)
v = 0; f = 1 / b;
while i > 0
    v = v + f * mod(i, b);
    i = floor(i / b); f = f / b;
end
end
