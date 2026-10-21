function CR = credibility_check(P, Xd, S, SN, MC, SE, CM, CV, U, cfg)
%CREDIBILITY_CHECK Автоматичне оцінювання достовірності моделі.
%
%   1. Недостатність даних      - параметри-припущення з високою чутливістю
%   2. Найчутливіші параметри   - ранжування за еластичністю і Спірменом
%   3. Суперечності припущень   - фізична правдоподібність і узгодженість
%   4. Діапазони невизначеності - з Monte Carlo
%   6. Класифікація результатів - підтверджено / розрахунок / гіпотеза
%   (п. 5 - звіт - generate_report.m)

F = struct('sev', {}, 'cat', {}, 'msg', {});
B = S.B;
C = constraint_list();
iM = 1;                                   % рядок m_p_max у матриці еластичностей

% ---------------- 1. Недостатність даних ----------------
fn = fieldnames(P);
for k = 1:numel(fn)
    p = P.(fn{k});
    if any(isnan([p.nom p.lo p.hi])) || isempty(p.src)
        F(end+1) = fnd('КРИТИЧНО', 'Дані', sprintf('Параметр %s не задано (NaN/порожньо).', fn{k})); %#ok<AGROW>
    end
end
CR.gaps = {};
for j = 1:numel(SE.names)
    nmj = SE.names{j};
    e = abs(SE.E(iM, j));
    if strcmp(P.(nmj).src, 'assumed') && e >= cfg.E_warn
        sev = 'УВАГА';
        if e >= cfg.E_crit, sev = 'КРИТИЧНО'; end
        F(end+1) = fnd(sev, 'Дані', sprintf(['Параметр "%s" (%s) - припущення, але еластичність m_p* = %.2f. ' ...
            'Потрібне вимірювання: %s.'], nmj, P.(nmj).desc, SE.E(iM, j), P.(nmj).test)); %#ok<AGROW>
        CR.gaps{end+1} = nmj; %#ok<AGROW>
    end
end

% ---------------- 2. Найчутливіші параметри ----------------
[~, ord] = sort(abs(SE.E(iM, :)), 'descend');
CR.top = SE.names(ord(1:min(cfg.n_top, numel(ord))));
CR.top_E = SE.E(iM, ord(1:min(cfg.n_top, numel(ord))));
F(end+1) = fnd('ІНФО', 'Чутливість', ['Найвпливовіші параметри (еластичність m_p*): ' ...
    strjoin(cellfun(@(a, b) sprintf('%s (%.2f)', a, b), CR.top, num2cell(CR.top_E), ...
    'UniformOutput', false), ', ') '.']);
req_hi = {};
for j = 1:numel(SE.names)
    if strcmp(P.(SE.names{j}).src, 'requirement') && abs(SE.E(iM, j)) >= cfg.E_crit
        req_hi{end+1} = sprintf('%s (%.2f)', SE.names{j}, SE.E(iM, j)); %#ok<AGROW>
    end
end
if ~isempty(req_hi)
    F(end+1) = fnd('УВАГА', 'Критерії', ['Результат сильно залежить від обраних критеріїв допустимості: ' ...
        strjoin(req_hi, ', ') '. Їх значення мають бути погоджені із замовником.']);
end

% ---------------- 3. Суперечності між припущеннями ----------------
if B.FM > Xd.FM_max
    F(end+1) = fnd('КРИТИЧНО', 'Суперечність', sprintf(['FM = %.2f > %.2f: задані C_T і C_P ' ...
        'фізично несумісні (пропелер ефективніший за реалістичну межу).'], B.FM, Xd.FM_max));
end
if MC.frac_rejected > cfg.rej_warn
    F(end+1) = fnd('УВАГА', 'Суперечність', sprintf(['%.0f%% комбінацій C_T, C_P з заданих діапазонів ' ...
        'дають FM > %.2f - діапазони незалежно заданих коефіцієнтів частково несумісні. ' ...
        'Їх слід визначати спільно на стенді.'], 100*MC.frac_rejected, Xd.FM_max));
end
if B.tip_mach > 0.6
    F(end+1) = fnd('УВАГА', 'Суперечність', sprintf(['Число Маха кінця лопаті %.2f > 0.6: ' ...
        'статичні C_T, C_P не придатні (стисливість).'], B.tip_mach));
end
if B.FT.I_m > Xd.I_esc_cont
    F(end+1) = fnd('КРИТИЧНО', 'Суперечність', sprintf(['Струм мотора на повному газі %.1f А > ' ...
        'тривалого струму ESC %.0f А: прийнята T_max недосяжна.'], B.FT.I_m, Xd.I_esc_cont));
end
if B.FT.I_bat > Xd.C_cont * Xd.Q_Ah
    F(end+1) = fnd('УВАГА', 'Суперечність', sprintf(['Струм батареї на повному газі %.0f А > ' ...
        'C_cont*Q = %.0f А: T_max досяжна лише короткочасно.'], B.FT.I_bat, Xd.C_cont*Xd.Q_Ah));
end
if B.E_density > cfg.E_density_max
    F(end+1) = fnd('КРИТИЧНО', 'Суперечність', sprintf(['Питома енергія батареї %.0f Вт*год/кг > %.0f: ' ...
        'нереалістично для LiPo/Li-ion.'], B.E_density, cfg.E_density_max));
end
if abs(B.FT.residual) > 1e-6
    F(end+1) = fnd('КРИТИЧНО', 'Чисельний метод', 'Рівняння повного газу розв''язано неточно.');
end
if any(S.G(4, :) >= 10)
    F(end+1) = fnd('КРИТИЧНО', 'Суперечність', 'Тепловий розгін мотора в досліджуваному діапазоні навантажень.');
end
if S.m_min > 0
    F(end+1) = fnd('УВАГА', 'Суперечність', sprintf(['Допустима область починається з m_p = %.2f кг ' ...
        '(обмеження: %s) - без вантажу апарат порушує критерії.'], S.m_min, ...
        lowest_label(S, C)));
end
switch S.status
    case 'infeasible'
        F(end+1) = fnd('КРИТИЧНО', 'Результат', 'Жодне навантаження не задовольняє всі критерії (навіть 0 кг).');
    case 'unbounded_in_grid'
        F(end+1) = fnd('УВАГА', 'Чисельний метод', 'Межа не досягнута в діапазоні сітки - збільште cfg.m_hi.');
end
if ~U.all_ok
    F(end+1) = fnd('КРИТИЧНО', 'Розмірності', ['Розмірність не сходиться: ' strjoin(U.name(~U.ok)', '; ')]);
end
if max(CM.arm.rel) > cfg.method_tol
    F(end+1) = fnd('УВАГА', 'Методи', sprintf(['Аналітична модель променя відрізняється від МСЕ до %.1f%% ' ...
        '(наближення Релея для частоти).'], 100*max(CM.arm.rel)));
end
if max(CM.pow.rel) > 0.25
    F(end+1) = fnd('УВАГА', 'Методи', sprintf(['Потужність за C_P і за теорією імпульсу (FM=%.2f) ' ...
        'розходяться на %.0f%%.'], CM.pow.FM_ref, 100*max(CM.pow.rel)));
end
if isfinite(CM.lim.max_diff) && CM.lim.max_diff > 10*cfg.tol
    F(end+1) = fnd('УВАГА', 'Методи', sprintf('Бісекція і fzero дають межі, що відрізняються на %.3g кг.', CM.lim.max_diff));
end
% збіжність MC: P5 на першій половині вибірки vs повна вибірка
mm = MC.m_max(MC.ok);
if numel(mm) >= 40
    q_half = pctile(mm(1:floor(end/2)), 5);
    CR.mc_conv = abs(q_half - MC.q(1));
    if CR.mc_conv > cfg.mc_conv_tol
        F(end+1) = fnd('УВАГА', 'Збіжність', sprintf(['P5 m_p* змінюється на %.2f кг між N/2 і N ' ...
            'реалізацій - збільште cfg.N_mc.'], CR.mc_conv));
    end
else
    CR.mc_conv = NaN;
    F(end+1) = fnd('УВАГА', 'Збіжність', 'Замало реалізацій Monte Carlo для оцінки збіжності.');
end
% незалежні від навантаження обмеження - перевірка запасу
for j = find(~[C.dep])
    g = S.G(j, 1);
    if g > 0
        F(end+1) = fnd('КРИТИЧНО', 'Конструкція', sprintf('"%s" порушене незалежно від навантаження (g = %.2f).', C(j).label, g)); %#ok<AGROW>
    else
        F(end+1) = fnd('ІНФО', 'Конструкція', sprintf('"%s" не залежить від m_p; запас %.0f%%.', C(j).label, -100*g)); %#ok<AGROW>
    end
end
F(end+1) = fnd('ІНФО', 'Метод', ['Межі застосовності: статичне висіння без вітру, статичні C_T/C_P, ' ...
    'лінійно-пружна балка, усталений тепловий режим, без втоми та динаміки керування.']);

% ---------------- 4. Діапазони невизначеності ----------------
CR.q = MC.q; CR.p = MC.p;
CR.rel_width = (MC.q(3) - MC.q(1)) / max(MC.q(2), eps);
if CR.rel_width > cfg.width_warn
    F(end+1) = fnd('УВАГА', 'Невизначеність', sprintf(['Відносна ширина інтервалу P5-P95 = %.0f%%: ' ...
        'результат визначений лише за порядком величини.'], 100*CR.rel_width));
end
F(end+1) = fnd('ІНФО', 'Невизначеність', sprintf(['m_p* (гірші умови): P5 = %.2f, P50 = %.2f, P95 = %.2f кг; ' ...
    'P(m_p* >= %.0f кг) = %.0f%%.'], MC.q(1), MC.q(2), MC.q(3), cfg.m_target, 100*MC.P_target));

% ---------------- 6. Класифікація результатів ----------------
rank_of = @(s) src_rank(s);
CR.out_names = SE.out_labels;
CR.out_level = zeros(numel(SE.out_names), 1);
CR.out_weak  = cell(numel(SE.out_names), 1);
for i = 1:numel(SE.out_names)
    lvl = 3; weak = {};
    for j = 1:numel(SE.names)
        if abs(SE.E(i, j)) > cfg.E_dep
            r = rank_of(P.(SE.names{j}).src);
            if r < lvl, lvl = r; end
            if r == 1, weak{end+1} = SE.names{j}; end %#ok<AGROW>
        end
    end
    CR.out_level(i) = lvl;
    CR.out_weak{i} = weak;
end
CR.level_labels = {'Гіпотеза (залежить від неперевірених припущень)', ...
                   'Розрахункова оцінка (паспортні дані)', ...
                   'Підтверджено (виміряно / задано)'};
CR.n_measured = sum(cellfun(@(f) strcmp(P.(f).src, 'measured'), fn));

% Умова достовірності m_p*: усі параметри з |E| > E_dep мають src >= datasheet,
% а ширина P5-P95 < width_ok.
CR.credible = CR.out_level(1) >= 2 && CR.rel_width < cfg.width_ok;

sev_order = {'КРИТИЧНО', 'УВАГА', 'ІНФО'};
r = zeros(numel(F), 1);
for k = 1:numel(F), r(k) = find(strcmp(sev_order, F(k).sev)); end
[~, o] = sort(r);
CR.findings = F(o);
CR.n_crit = sum(r == 1); CR.n_warn = sum(r == 2);
end

function f = fnd(sev, cat, msg)
f = struct('sev', sev, 'cat', cat, 'msg', msg);
end

function r = src_rank(s)
switch s
    case {'measured', 'design', 'requirement', 'constant'}, r = 3;
    case 'datasheet', r = 2;
    otherwise, r = 1;
end
end

function s = lowest_label(S, C)
k = find(S.grid < S.m_min, 1, 'last');
if isempty(k), k = 1; end
[~, j] = max(S.G(:, k));
s = C(j).label;
end
