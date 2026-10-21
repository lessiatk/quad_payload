function SE = sensitivity(P, Xd, cfg, S0)
%SENSITIVITY Локальний (еластичності) і глобальний OAT (торнадо) аналіз.
%
%   Еластичність:  E_ij = (dy_i/dx_j) * (x_j / y_i)  (центральні різниці, +-1%)
%   - на скільки % змінюється вихід i при зміні параметра j на 1%.
%   Торнадо: m_p* при x_j = lo і x_j = hi (решта - design point).
%   Виходи: m_p*, T_max, тривалість польоту, температура мотора і
%   потужність при m_ref, напруження і власна частота променя.

% Еластичності рахуються для ВСІХ неперервних параметрів (у т.ч. вимог):
% це показує і вплив даних, і вплив обраних критеріїв допустимості.
f  = fieldnames(P);
nm = {};
for k = 1:numel(f)
    if ~any(strcmp(f{k}, {'n_rot', 'n_cells'})) && Xd.(f{k}) ~= 0
        nm{end+1} = f{k}; %#ok<AGROW>
    end
end
np = numel(nm);
SE.names = nm;
SE.src = cell(1, np);
for j = 1:np, SE.src{j} = P.(nm{j}).src; end
SE.out_names = {'m_p_max', 'T_max', 't_flight', 'T_motor', 'P_hover', 'sigma_arm', 'f_arm'};
SE.out_labels = {'Граничне навантаження', 'Макс. тяга ротора', 'Тривалість польоту', ...
                 'Температура мотора', 'Потужність висіння', 'Напруження променя', ...
                 'Власна частота променя'};
m_ref = S0.m_max;
if ~isfinite(m_ref), m_ref = cfg.m_target; end
SE.m_ref = m_ref;

y0 = outputs(Xd, cfg, m_ref);
SE.y0 = y0;
SE.E = zeros(numel(y0), np);
h = 0.01;
for j = 1:np
    x0 = Xd.(nm{j});
    Xp = Xd; Xp.(nm{j}) = x0*(1 + h);
    Xm = Xd; Xm.(nm{j}) = x0*(1 - h);
    yp = outputs(Xp, cfg, m_ref);
    ym = outputs(Xm, cfg, m_ref);
    SE.E(:, j) = (yp - ym) ./ (2*h*y0);
end

% Торнадо для m_p* - лише параметри з невизначеністю
nu = unc_names(P);
SE.tor_names = nu;
SE.lo = zeros(numel(nu), 1); SE.hi = zeros(numel(nu), 1);
for j = 1:numel(nu)
    p = P.(nu{j});
    Xl = Xd; Xl.(nu{j}) = p.lo;
    Xh = Xd; Xh.(nu{j}) = p.hi;
    Sl = max_payload(Xl, cfg); Sh = max_payload(Xh, cfg);
    SE.lo(j) = clean(Sl.m_max); SE.hi(j) = clean(Sh.m_max);
end
SE.swing = abs(SE.hi - SE.lo);
[~, SE.order] = sort(SE.swing, 'descend');
end

function y = outputs(X, cfg, m_ref)
S = max_payload(X, cfg);
R = eval_payload(S.B, X, m_ref);
y = [clean(S.m_max); S.B.T_max; R.t_flight_min; R.Tw; R.P_bat; ...
     S.B.arm.sigma_vm; S.B.arm_op.f_n];
end

function v = clean(v)
if ~isfinite(v), v = 0; end
end
