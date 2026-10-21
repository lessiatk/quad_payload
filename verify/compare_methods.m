function CM = compare_methods(X, S, cfg)
%COMPARE_METHODS Порівняння незалежних методів розрахунку.
%   1) Промінь: аналітика (Ейлер-Бернуллі + Релей) vs МСЕ (64 елементи).
%   2) Потужність висіння: модель C_P vs теорія імпульсу з FM = 0.70.
%   3) Граничне навантаження: сітка+бісекція vs fzero для кожного
%      монотонного обмеження.
B = S.B;

% 1. Промінь
F = arm_fem(X, B.FT.T, B.m_tip, 64);
CM.arm.names = {'Прогин кінця, мм', 'Напруження в корені, МПа', 'Власна частота, Гц'};
CM.arm.analytic = [B.arm_op.delta*1e3, B.arm_op.sigma/1e6, B.arm_op.f_n];
CM.arm.fem      = [F.delta*1e3, F.sigma_root/1e6, F.f_n];
CM.arm.rel = abs(CM.arm.analytic - CM.arm.fem) ./ abs(CM.arm.fem);

% 2. Потужність висіння (сумарна механічна, без вантажу і з m_ref)
FM_ref = 0.70;
mm = linspace(B.m_empty, B.m_empty + cfg.m_hi, 25);
CM.pow.m = mm; CM.pow.P_cp = zeros(size(mm)); CM.pow.P_mt = zeros(size(mm));
for k = 1:numel(mm)
    T = mm(k)*B.g/4;
    op = rotor_operating_point(X, T);
    CM.pow.P_cp(k) = 4*op.P_shaft;
    CM.pow.P_mt(k) = 4 * T^1.5 / sqrt(2*X.rho*B.A_disk) / FM_ref;
end
CM.pow.FM_ref = FM_ref; CM.pow.FM_model = B.FM;
CM.pow.rel = abs(CM.pow.P_cp - CM.pow.P_mt) ./ CM.pow.P_mt;

% 3. Граничне навантаження: fzero vs бісекція
J = numel(S.lim);
CM.lim.bisect = S.lim; CM.lim.fzero = nan(J, 1);
opts = optimset('TolX', 1e-8, 'Display', 'off');
for j = 1:J
    g0 = S.G(j, 1); g1 = S.G(j, end);
    if g0 <= 0 && g1 > 0 && is_monotone(S.G(j, :))
        fj = @(m) gj(B, X, m, j);
        CM.lim.fzero(j) = fzero(fj, [0, cfg.m_hi], opts);
    end
end
d = abs(CM.lim.bisect - CM.lim.fzero);
CM.lim.max_diff = max(d(isfinite(d)));
if isempty(CM.lim.max_diff), CM.lim.max_diff = NaN; end
end

function v = gj(B, X, m, j)
R = eval_payload(B, X, m);
v = R.g(j);
end

function tf = is_monotone(g)
dg = diff(g);
tf = all(dg >= -1e-12) || all(dg <= 1e-12);
end
