function BC = bench_check(P, preset)
%BENCH_CHECK Порівняння моделі мотор+пропелер із заводською стендовою таблицею (12S, 1 мотор, ρ стенду = 1.2).
%   Колонки таблиці: тяга [г], оберти [об/хв], потужність з батареї [Вт] при 40/50/70/100 % газу.
%   Порівнюється потужність, а не струм: на стенді струм - батарейний (залежить від скважності),
%   у моделі - струм обмотки. Точка 100 % використана для калібрування R_esc,
%   решта - незалежна перевірка C_T, C_P, I0.
if strcmp(preset, 'heavy')    % V605 KV210 + V22x7.4, 46.60 В на 100 %
    tab = [2898 3444 345; 4385 4226 618; 7383 5487 1334; 12761 7036 3183];
    V = 46.60; I_full = 68.3;
else                          % U8 Lite KV150 + P22x6.6, 48 В
    tab = [1702 2925 158; 2376 3431 250; 3967 4427 518; 7243 5924 1272];
    V = 48; I_full = 26.5;
end
X = get_point(P, 'nominal');
X.rho = 1.2; X.n_cells = 12; X.V_cell_load = V/12; X.R_pack = 0; X.n_rot = 1;
BC.rows = zeros(size(tab, 1), 7);
for k = 1:size(tab, 1)
    op = rotor_operating_point(X, tab(k, 1)*1e-3*9.80665);
    Pm = op.P_elec / X.eta_esc;
    BC.rows(k, :) = [tab(k, :), 60*op.n, Pm, 100*(60*op.n/tab(k, 2) - 1), 100*(Pm/tab(k, 3) - 1)];
end
FT = motor_full_throttle(X);
BC.full = [FT.T/9.80665*1e3, FT.rpm, FT.I_m];       % модель на повному газі: тяга [г], об/хв, А
BC.bench_full = [tab(end, 1:2), I_full];
end
