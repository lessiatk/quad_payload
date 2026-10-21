function generate_report(outdir, P, S, SN, MC, SE, CM, CV, U, CR, figs, cfg, EX)
%GENERATE_REPORT Автоматичний технічний звіт (report.md + report.html, UTF-8).
fm = fopen(fullfile(outdir, 'report.md'),   'w', 'n', 'UTF-8');
fh = fopen(fullfile(outdir, 'report.html'), 'w', 'n', 'UTF-8');
C  = constraint_list();
X  = S.X;

fprintf(fh, ['<!doctype html><html lang="uk"><head><meta charset="utf-8">' ...
  '<title>Звіт: граничне навантаження</title><style>' ...
  'body{font-family:Arial,sans-serif;max-width:1100px;margin:24px auto;padding:0 16px;color:#222;line-height:1.45}' ...
  'table{border-collapse:collapse;margin:10px 0;font-size:13px}td,th{border:1px solid #bbb;padding:4px 8px;text-align:left}' ...
  'th{background:#eef}img{max-width:100%%;border:1px solid #ddd}.ok{background:#e7f6e7;padding:10px}' ...
  '.bad{background:#fdecea;padding:10px}code{background:#f4f4f4;padding:1px 4px}</style></head><body>\n']);

h1(fm, fh, 'Технічний звіт: граничне корисне навантаження квадрокоптера 22"');
par(fm, fh, sprintf('Згенеровано автоматично: %s. Реалізацій Monte Carlo: %d (прийнято %d).', ...
    datestr(now, 'yyyy-mm-dd HH:MM'), MC.N, sum(MC.ok)));

% ---------- Висновок ----------
h2(fm, fh, '1. Підсумок');
if CR.credible
    v = 'Результат ДОСТОВІРНИЙ за критеріями модуля оцінювання.';
    cls = 'ok';
else
    v = sprintf(['Результат НЕ може вважатися достовірним: %d критичних і %d попереджень. ' ...
        'Значення нижче - розрахункова оцінка / гіпотеза до експериментальної верифікації.'], CR.n_crit, CR.n_warn);
    cls = 'bad';
end
fprintf(fm, '> **%s**\n\n', v);
fprintf(fh, '<p class="%s"><b>%s</b></p>\n', cls, esc(v));
rows = {
  'm_p* у нормальних умовах (номінальні дані)', sprintf('%.2f кг', SN.m_max), C(SN.active).label;
  'm_p* у гірших умовах (design point)',          sprintf('%.2f кг', S.m_max),  C(S.active).label;
  'Monte Carlo, P5 / P50 / P95 (гірші умови)',     sprintf('%.2f / %.2f / %.2f кг', MC.q(1), MC.q(2), MC.q(3)), '-';
  sprintf('Ймовірність m_p* >= %g кг', cfg.m_target), sprintf('%.0f %%', 100*MC.P_target), '-';
  'Гарантований діапазон, усі обмеження (інтервальний аналіз)', sprintf('%.2f ... %.2f кг', EX.UM.int.lo, EX.UM.int.hi), 'без розподілів, лише [lo, hi]';
  'Гарантований діапазон без резонансу променя',   sprintf('%.2f ... %.2f кг', EX.UM.int_nor.lo, EX.UM.int_nor.hi), 'за умови, що f_n променя виміряно';
  'Рекомендоване значення (гарантована нижня межа без резонансу)', sprintf('%.1f кг', floor(10*EX.UM.int_nor.lo)/10), ...
      sprintf('імовірнісна оцінка P5 (MC) = %.1f кг', MC.q(1))};
tab(fm, fh, {'Величина', 'Значення', 'Активне обмеження'}, rows);

% ---------- Компоненти, стенд, варіанти ----------
h2(fm, fh, '1а. Склад апарата (вхідні компоненти і заводські дані)');
tab(fm, fh, {'Роль', 'Виріб', 'Дані виробника', 'Джерело'}, EX.bom);
rows = cell(size(EX.bench.rows, 1), 5);
for k = 1:size(rows, 1)
    r = EX.bench.rows(k, :);
    rows(k, :) = {sprintf('%.0f', r(1)), sprintf('%.0f / %.0f', r(2), r(4)), sprintf('%+.1f %%', r(6)), ...
                  sprintf('%.0f / %.0f', r(3), r(5)), sprintf('%+.1f %%', r(7))};
end
tab(fm, fh, {'Тяга стенду, г', 'Оберти: стенд / модель', 'Похибка обертів', 'Потужність, Вт: стенд / модель', 'Похибка потужності'}, rows);
par(fm, fh, sprintf(['Перевірка моделі на заводській стендовій таблиці (12S, 1 мотор). Повний газ: стенд %.0f г / %.0f об/хв / %.1f А, ' ...
    'модель %.0f г / %.0f об/хв / %.1f А (калібрування R_esc). C_T, C_P виведено з цієї ж таблиці, ρ стенду припущено 1.2 кг/м^3.'], ...
    EX.bench.bench_full(1), EX.bench.bench_full(2), EX.bench.bench_full(3), EX.bench.full(1), EX.bench.full(2), EX.bench.full(3)));
h2(fm, fh, '1б. Варіанти компонування (гірші умови)');
rows = cell(numel(EX.var), 5);
for k = 1:numel(EX.var)
    rows(k, :) = {EX.var(k).name, sprintf('%.2f', EX.var(k).m_max), EX.var(k).active, ...
                  sprintf('%.3f', EX.var(k).Izz), sprintf('%.1f', EX.var(k).t_min)};
end
tab(fm, fh, {'Варіант', 'm_p*, кг', 'Активне обмеження', 'Izz, кг*м^2', 'Політ при m_p*, хв'}, rows);
par(fm, fh, ['Висота вантажу і батареї майже не впливає на статичне висіння: у моделі вона змінює лише інерцію (рискання) ' ...
    'і ЦМ по вертикалі. Головний чинник - зміщення вантажу від осі (перерозподіл тяги). Маятниковість, аеродинаміка ' ...
    'обтікання вантажу і стійкість при нахилі в модель не входять.']);

% ---------- Постановка ----------
h2(fm, fh, '2. Математична постановка');
par(fm, fh, ['m_p* = sup { m_p >= 0 : g_j(x, m_p) <= 0, j = 1..10 }, де x - вектор параметрів, ' ...
    'g_j = попит_j / ресурс_j - 1. Межа шукається скануванням сітки (виявлення всіх змін знаку, ' ...
    'зокрема для немонотонного резонансного обмеження) з уточненням бісекцією; для монотонних ' ...
    'обмежень результат перевіряється fzero. Невизначеність поширюється методом Monte Carlo ' ...
    '(трикутні розподіли), експлуатаційні параметри фіксуються на гіршому випадку.']);

% ---------- Обмеження ----------
h2(fm, fh, '3. Обмежувальні фактори (гірші умови)');
rows = cell(numel(C), 5);
for j = 1:numel(C)
    rows(j, :) = {C(j).label, C(j).group, yesno(C(j).dep), limstr(S.lim(j)), sprintf('%+.3f', S.R.g(j))};
end
tab(fm, fh, {'Обмеження', 'Тип', 'Залежить від m_p', 'Межа m_p, кг', 'g при m_p*'}, rows);
R = S.R; B = S.B;
rows = {
  'Злітна маса', sprintf('%.2f кг', R.m_total);
  'Порожня маса', sprintf('%.2f кг', B.m_empty);
  'Макс. тяга ротора (кінець розряду)', sprintf('%.1f Н (%.2f кгс), %.0f об/хв', B.T_max, B.T_max/B.g, B.FT.rpm);
  'Тяга найбільш навантаженого ротора', sprintf('%.1f Н, T/W = %.2f', R.T_hi, R.TW);
  'Розподіл тяги T1..T4', sprintf('%.1f / %.1f / %.1f / %.1f Н', R.T);
  'Центр мас (x, y, z)', sprintf('%.1f / %.1f / %.1f мм', 1e3*R.cg);
  'Моменти інерції Ixx / Iyy / Izz', sprintf('%.3f / %.3f / %.3f кг*м^2', R.I(1,1), R.I(2,2), R.I(3,3));
  'Потужність з батареї у висінні', sprintf('%.0f Вт (%.1f А)', R.P_bat, R.I_bat);
  'Тривалість польоту', sprintf('%.1f хв', R.t_flight_min);
  'Температура обмотки (тривалий режим)', sprintf('%.0f C', R.Tw);
  'Оберти висіння / власна частота променя', sprintf('%.0f об/хв (%.1f Гц) / %.1f Гц', R.rpm_hover, R.f_1P, R.f_n);
  'Еквівалентне напруження в корені / допустиме', sprintf('%.1f / %.1f МПа', B.arm.sigma_vm/1e6, B.arm.sigma_allow/1e6);
  'Нахил мотора від прогину (при T_max)', sprintf('%.2f град', B.arm_op.theta*180/pi);
  'FM пропелера (з C_T, C_P)', sprintf('%.3f', B.FM)};
tab(fm, fh, {'Величина при m_p*', 'Значення'}, rows);
figure_block(fm, fh, figs, 1); figure_block(fm, fh, figs, 2);

% ---------- Класифікація ----------
h2(fm, fh, '4. Класифікація результатів за рівнем доказовості');
rows = cell(numel(SE.out_labels), 4);
for i = 1:numel(SE.out_labels)
    w = CR.out_weak{i};
    if isempty(w), ws = '-'; else, ws = strjoin(w, ', '); end
    rows(i, :) = {SE.out_labels{i}, sprintf('%.4g', SE.y0(i)), CR.level_labels{CR.out_level(i)}, ws};
end
tab(fm, fh, {'Результат', 'Значення (design point)', 'Рівень', 'Залежить від припущень'}, rows);
par(fm, fh, sprintf(['Рівень визначається автоматично: результат успадковує найнижчий рівень джерела ' ...
    'серед параметрів, до яких він чутливий (|E| > %.2f). Експериментально підтверджених параметрів ' ...
    'зараз: %d. Після вимірювань змініть src = ''measured'' у ref_params.m - класифікація оновиться.'], ...
    cfg.E_dep, CR.n_measured));

% ---------- Невизначеність і чутливість ----------
h2(fm, fh, '5. Невизначеність і чутливість');
figure_block(fm, fh, figs, 3); figure_block(fm, fh, figs, 8);
rows = cell(numel(CR.top), 3);
for k = 1:numel(CR.top)
    rows(k, :) = {CR.top{k}, sprintf('%+.3f', CR.top_E(k)), P.(CR.top{k}).src};
end
tab(fm, fh, {'Параметр', 'Еластичність m_p*', 'Джерело'}, rows);
[~, o] = sort(abs(MC.spearman), 'descend');
o = o(1:min(6, numel(o)));
rows = [MC.names(o)', cellfun(@(v) sprintf('%+.2f', v), num2cell(MC.spearman(o)), 'UniformOutput', false)];
tab(fm, fh, {'Параметр', 'Кореляція Спірмена з m_p* (MC)'}, rows);
figure_block(fm, fh, figs, 4); figure_block(fm, fh, figs, 5);

% ---------- Порівняння методів невизначеності ----------
UM = EX.UM; mt = cfg.m_target;
h2(fm, fh, '5а. Порівняння методів оцінювання невизначеності (гірші умови)');
rows = {
  'Інтервальний аналіз, усі обмеження', sprintf('%.2f', UM.int.lo), sprintf('%.2f', S.m_max), sprintf('%.2f', UM.int.hi), '-', sprintf('%d', UM.int.evals + 1);
  'Інтервальний аналіз, без резонансу', sprintf('%.2f', UM.int_nor.lo), '-', sprintf('%.2f', UM.int_nor.hi), '-', sprintf('%d', UM.int_nor.evals);
  'FOSM (нормальне наближення)', sprintf('%.2f', UM.fosm.q5), sprintf('%.2f', UM.fosm.mu), sprintf('%.2f', UM.fosm.q95), sprintf('%.2g %%', 100*UM.fosm.P), sprintf('%d', UM.fosm.evals);
  sprintf('FORM (beta = %.2f)', UM.form.beta), '-', '-', '-', sprintf('%.2g %%', 100*UM.form.P), sprintf('%d', UM.form.evals);
  sprintf('Квазі-MC, Халтон (N = %d)', UM.qmc.n_ok), sprintf('%.2f', UM.qmc.q(1)), sprintf('%.2f', UM.qmc.q(2)), sprintf('%.2f', UM.qmc.q(3)), sprintf('%.2g %%', 100*UM.qmc.P), sprintf('%d', UM.qmc.evals);
  sprintf('Monte Carlo (N = %d)', sum(MC.ok)), sprintf('%.2f', MC.q(1)), sprintf('%.2f', MC.q(2)), sprintf('%.2f', MC.q(3)), sprintf('%.2g %%', 100*MC.P_target), sprintf('%d', MC.N);
  sprintf('Аналітика T/W (N = %d)', UM.ana.N), sprintf('%.2f', UM.ana.q(1)), sprintf('%.2f', UM.ana.q(2)), sprintf('%.2f', UM.ana.q(3)), sprintf('%.2g %%', 100*UM.ana.P), '5000 (лише precompute)'};
tab(fm, fh, {'Метод', 'Нижня / P5, кг', 'Центр / P50, кг', 'Верхня / P95, кг', sprintf('P(m_p* >= %g кг)', mt), 'Розрахунків моделі'}, rows);
par(fm, fh, sprintf(['Інтервальний аналіз: край кожного параметра береться за знаком торнадо (2 розрахунки), потім ' ...
    'перевіряється %d випадковими вершинами коробки параметрів. Монотонність %s (мінімум серед вершин %.2f кг, максимум %.2f кг). ' ...
    'Резонансне обмеження немонотонне: при песимістичному E_arm власна частота променя збігається з 2P оборотів висіння, ' ...
    'і допустимої області немає, тому «гарантована» межа з усіма обмеженнями так низька. Без резонансу (його знімає ' ...
    'вимірювання f_n модальним тестом) межа монотонна: %s. FM в кутах коробки: найгірший %.2f, найкращий %.2f (> %.2f - фізично сумнівно).'], ...
    60, yn(UM.int.monotone), UM.int.v_min, UM.int.v_max, yn(UM.int_nor.monotone), ...
    UM.int.FM_w, UM.int.FM_b, S.X.FM_max));
[~, o] = sort(abs(SE.hi - SE.lo), 'descend'); o = o(1:min(8, numel(o)));
rows = cell(numel(o), 4);
for k = 1:numel(o)
    j = o(k); p = P.(UM.names{j});
    rows(k, :) = {UM.names{j}, sprintf('%g', UM.int_nor.xw(j)), sprintf('%g', UM.int_nor.xb(j)), sprintf('%g', p.nom)};
end
tab(fm, fh, {'Параметр', 'Поганий край', 'Добрий край', 'Номінал'}, rows);
[~, o] = sort(UM.fosm.share, 'descend'); o = o(1:min(6, numel(o)));
rows = cell(numel(o), 4);
for k = 1:numel(o)
    j = o(k);
    rows(k, :) = {UM.names{j}, sprintf('%+.3g кг/од.', UM.fosm.grad(j)), sprintf('%.1f %%', 100*UM.fosm.share(j)), P.(UM.names{j}).src};
end
tab(fm, fh, {'Параметр (FOSM)', 'dm*/dx', 'Частка дисперсії', 'Джерело'}, rows);
par(fm, fh, sprintf(['FOSM: середнє %.2f кг, sigma = %.2f кг. Розкладання в ряд Тейлора не бачить зламів min() і резонансу, ' ...
    'тому нижній хвіст (P5) менш песимістичний, ніж у MC/QMC.'], UM.fosm.mu, UM.fosm.sigma));
R = UM.form; na = numel(R.act);
rows = cell(na, 4);
for k = 1:na
    j = R.act(k);
    rows(k, :) = {UM.names{j}, sprintf('%g', R.x(k)), sprintf('%g', R.x0(k)), sprintf('%+.2f', R.u(k))};
end
tab(fm, fh, {'Параметр (FORM)', 'Значення в найімовірнішій точці', 'Медіана', 'Зсув, sigma'}, rows);
if R.reachable
    ps = sprintf('Найімовірніша комбінація параметрів, при якій m_p* = %g кг, віддалена від медіани на beta = %.2f sigma; FM у цій точці %.2f.', mt, R.beta, R.FM);
else
    ps = sprintf('Ціль %g кг недосяжна навіть на краях діапазонів параметрів: імовірність практично нульова.', mt);
end
par(fm, fh, ps);
rows = cell(numel(UM.qmc.ns), 3);
for k = 1:numel(UM.qmc.ns)
    rows(k, :) = {sprintf('%d', UM.qmc.ns(k)), sprintf('%.2f', UM.qmc.p5_qmc(k)), sprintf('%.2f', UM.qmc.p5_mc(k))};
end
tab(fm, fh, {'Число точок', 'P5, Халтон', 'P5, звичайний MC'}, rows);
par(fm, fh, sprintf(['Збіжність P5 (еталон - MC на %d точках: %.2f кг). Аналітичне домінуюче обмеження: ' ...
    'm_p* = 4 T_max / (k_TW g r) - m_порожня, r = %.3f (перерозподіл тяги через зміщення ЦМ). За детермінованого вихідного ' ...
    'набору дає %.2f кг проти %.2f кг повної моделі; запас тяги визначає %.0f %% реалізацій MC, решта - інші обмеження ' ...
    '(резонанс), які аналітична формула не бачить.'], sum(MC.ok), UM.qmc.p5_ref, UM.ana.r, UM.ana.m_det, S.m_max, 100*UM.ana.tw_share));
figure_block(fm, fh, figs, 9);

% ---------- Верифікація ----------
h2(fm, fh, '6. Верифікація');
rows = cell(numel(U.name), 2);
for k = 1:numel(U.name), rows(k, :) = {U.name{k}, yesno(U.ok(k))}; end
tab(fm, fh, {'Формула', 'Розмірність коректна'}, rows);
rows = cell(3, 4);
for k = 1:3
    rows(k, :) = {CM.arm.names{k}, sprintf('%.4g', CM.arm.analytic(k)), sprintf('%.4g', CM.arm.fem(k)), ...
                  sprintf('%.2f %%', 100*CM.arm.rel(k))};
end
tab(fm, fh, {'Промінь', 'Аналітика', 'МСЕ (64 ел.)', 'Розбіжність'}, rows);
par(fm, fh, sprintf(['Потужність висіння: модель C_P vs теорія імпульсу (FM = %.2f) - розбіжність до %.1f %%; ' ...
    'FM, що випливає з C_T, C_P: %.3f. Межі обмежень: бісекція vs fzero - макс. різниця %.2g кг.'], ...
    CM.pow.FM_ref, 100*max(CM.pow.rel), CM.pow.FM_model, CM.lim.max_diff));
figure_block(fm, fh, figs, 6); figure_block(fm, fh, figs, 7);

% ---------- Висновки модуля достовірності ----------
h2(fm, fh, '7. Висновки модуля оцінювання достовірності');
F = CR.findings;
rows = cell(numel(F), 3);
for k = 1:numel(F), rows(k, :) = {F(k).sev, F(k).cat, F(k).msg}; end
tab(fm, fh, {'Рівень', 'Категорія', 'Повідомлення'}, rows);

% ---------- Експерименти ----------
h2(fm, fh, '8. Дані, необхідні для експериментальної верифікації');
[~, o] = sort(abs(SE.E(1, :)), 'descend');
rows = cell(0, 4);
for j = o
    nm = SE.names{j}; p = P.(nm);
    if any(strcmp(p.src, {'assumed', 'datasheet'})) && ~strcmp(p.test, '-') && abs(SE.E(1, j)) > cfg.E_dep
        rows(end+1, :) = {nm, p.desc, sprintf('%+.2f', SE.E(1, j)), p.test}; %#ok<AGROW>
    end
end
tab(fm, fh, {'Параметр', 'Опис', 'Еластичність', 'Метод перевірки'}, rows);

% ---------- Вихідні дані ----------
h2(fm, fh, '9. Вихідні дані та припущення');
fn = fieldnames(P);
rows = cell(numel(fn), 6);
for k = 1:numel(fn)
    p = P.(fn{k});
    if p.hi > p.lo, rng_s = sprintf('[%g ... %g]', p.lo, p.hi); else, rng_s = '-'; end
    rows(k, :) = {fn{k}, sprintf('%g', X.(fn{k})), rng_s, p.unit, p.src, p.desc};
end
tab(fm, fh, {'Параметр', 'Design point', 'Діапазон', 'Од.', 'Джерело', 'Опис'}, rows);

% ---------- Умови достовірності ----------
h2(fm, fh, '10. Умови, за яких результат вважається достовірним');
items = {
  sprintf('усі параметри, до яких m_p* чутливий (|E| > %.2f), мають джерело не нижче паспортних даних, а ключові (C_T, C_P, R_th, V_cell_load) - виміряні на стенді;', cfg.E_dep);
  sprintf('відносна ширина інтервалу P5-P95 менша за %.0f %% (зараз %.0f %%);', 100*cfg.width_ok, 100*CR.rel_width);
  'немає критичних суперечностей, розмірності коректні, незалежні методи узгоджуються в межах 5 %;';
  'розрахункова тяга, струм і температура при m_p* підтверджені прив''язним випробуванням з вантажем;';
  'умови експлуатації не виходять за огинаючу (густина повітря, температура, зміщення ЦМ).'};
lst(fm, fh, items);

fprintf(fh, '</body></html>\n');
fclose(fm); fclose(fh);
end

% ======================= допоміжні функції =======================
function h1(fm, fh, t)
fprintf(fm, '# %s\n\n', t);  fprintf(fh, '<h1>%s</h1>\n', esc(t));
end
function h2(fm, fh, t)
fprintf(fm, '\n## %s\n\n', t); fprintf(fh, '<h2>%s</h2>\n', esc(t));
end
function par(fm, fh, t)
fprintf(fm, '%s\n\n', t); fprintf(fh, '<p>%s</p>\n', esc(t));
end
function lst(fm, fh, items)
fprintf(fh, '<ul>\n');
for k = 1:numel(items)
    fprintf(fm, '- %s\n', items{k}); fprintf(fh, '<li>%s</li>\n', esc(items{k}));
end
fprintf(fm, '\n'); fprintf(fh, '</ul>\n');
end
function tab(fm, fh, hdr, rows)
fprintf(fm, '| %s |\n', strjoin(hdr, ' | '));
fprintf(fm, '|%s\n', repmat('---|', 1, numel(hdr)));
fprintf(fh, '<table><tr>');
for k = 1:numel(hdr), fprintf(fh, '<th>%s</th>', esc(hdr{k})); end
fprintf(fh, '</tr>\n');
for i = 1:size(rows, 1)
    cells = rows(i, :);
    fprintf(fm, '| %s |\n', strjoin(strrep(cells, '|', '/'), ' | '));
    fprintf(fh, '<tr>');
    for k = 1:numel(cells), fprintf(fh, '<td>%s</td>', esc(cells{k})); end
    fprintf(fh, '</tr>\n');
end
fprintf(fm, '\n'); fprintf(fh, '</table>\n');
end
function figure_block(fm, fh, figs, k)
if k > numel(figs), return; end
fprintf(fm, '![%s](%s)\n\n*%s*\n\n', figs(k).file, figs(k).file, figs(k).caption);
fprintf(fh, '<figure><img src="%s"><figcaption>%s</figcaption></figure>\n', figs(k).file, esc(figs(k).caption));
end
function s = esc(s)
s = strrep(s, '&', '&amp;'); s = strrep(s, '<', '&lt;'); s = strrep(s, '>', '&gt;');
end
function s = yesno(b)
if b, s = 'так'; else, s = 'ні'; end
end
function s = yn(b)
if b, s = 'виконується'; else, s = 'порушена'; end
end
function s = limstr(v)
if isinf(v) && v > 0
    s = 'не обмежує';
elseif isinf(v)
    s = 'порушене завжди';
else
    s = sprintf('%.2f', v);
end
end
