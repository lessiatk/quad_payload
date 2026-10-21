function figs = make_plots(outdir, P, S, SN, MC, SE, CM, CV, cfg)
%MAKE_PLOTS Графіки результатів (PNG у outdir). Повертає імена файлів.
C = constraint_list();
figs = struct('file', {}, 'caption', {});

% 1. Обмеження як функції навантаження
h = newfig();
plot(S.grid, S.G', 'LineWidth', 1.4); hold on; grid on;
plot([S.grid(1) S.grid(end)], [0 0], 'k-', 'LineWidth', 2);
if isfinite(S.m_max)
    plot([S.m_max S.m_max], [-1 1], 'r--', 'LineWidth', 1.5);
end
ylim([-1 1]); xlabel('Корисне навантаження m_p, кг'); ylabel('g_j = попит/ресурс - 1');
title(sprintf('Обмеження (гірші умови); m_p^* = %.2f кг', S.m_max));
legend({C.label}, 'Location', 'eastoutside');
figs(end+1) = save_fig(h, outdir, 'fig1_constraints.png', ...
    'Нормовані обмеження g_j(m_p). Допустимо при g <= 0; червона лінія - m_p^*.');

% 2. Межі за окремими обмеженнями
h = newfig();
lim = S.lim; fin = isfinite(lim);
lab = {C.label};
barh(lim(fin)); set(gca, 'YTick', 1:sum(fin), 'YTickLabel', lab(fin)); grid on;
xlabel('Гранична m_p за обмеженням, кг');
title('Незалежні обмежувальні фактори (нескінченні межі не показано)');
figs(end+1) = save_fig(h, outdir, 'fig2_limits.png', ...
    'Межа m_p для кожного обмеження окремо. Найменша - активна.');

% 3. Розподіл m_p* (Monte Carlo)
h = newfig();
mm = MC.m_max(MC.ok);
hist(mm, 30); hold on; grid on;
yl = ylim;
cols = {'b--', 'k-', 'b--'};
for k = 1:3
    plot([MC.q(k) MC.q(k)], yl, cols{k}, 'LineWidth', 1.5);
end
plot([cfg.m_target cfg.m_target], yl, 'r-', 'LineWidth', 2);
xlabel('m_p^*, кг'); ylabel('Кількість реалізацій');
title(sprintf('Monte Carlo, N = %d: P5 = %.2f, P50 = %.2f, P95 = %.2f кг; P(>= %g кг) = %.0f%%', ...
    sum(MC.ok), MC.q(1), MC.q(2), MC.q(3), cfg.m_target, 100*MC.P_target));
figs(end+1) = save_fig(h, outdir, 'fig3_mc_hist.png', ...
    'Розподіл граничного навантаження при невизначеності вихідних даних (гірші умови).');

% 4. Торнадо
h = newfig();
o = SE.order(1:min(12, numel(SE.order)));
base = S.m_max;
hold on; grid on;
for k = 1:numel(o)
    j = o(k); y = numel(o) - k + 1;
    plot([SE.lo(j) SE.hi(j)], [y y], 'b-', 'LineWidth', 8);
    plot(SE.lo(j), y, 'ko', SE.hi(j), y, 'k^');
end
plot([base base], [0 numel(o)+1], 'r--');
set(gca, 'YTick', 1:numel(o), 'YTickLabel', fliplr(SE.tor_names(o)));
xlabel('m_p^*, кг (o - нижня межа параметра, ^ - верхня)');
title('Діаграма-торнадо: вплив діапазону кожного параметра');
figs(end+1) = save_fig(h, outdir, 'fig4_tornado.png', ...
    'Зміна m_p^* при проходженні параметром свого діапазону (інші - на design point).');

% 5. Матриця еластичностей
h = newfig();
[~, oo] = sort(abs(SE.E(1, :)), 'descend');
oo = oo(1:min(20, numel(oo)));
imagesc(SE.E(:, oo)); colorbar; caxis([-2 2]);
set(gca, 'XTick', 1:numel(oo), 'XTickLabel', SE.names(oo), 'YTick', 1:numel(SE.out_labels), ...
    'YTickLabel', SE.out_labels);
try, set(gca, 'XTickLabelRotation', 60); catch, end
title('Еластичності виходів за параметрами, %/%');
figs(end+1) = save_fig(h, outdir, 'fig5_elasticity.png', ...
    'Відносна чутливість основних результатів (20 найвпливовіших параметрів).');

% 6. Збіжність
h = newfig();
subplot(1, 3, 1);
semilogy(CV.n_el(1:end-1), max(CV.f_err(1:end-1), 1e-16), 'o-'); grid on;
xlabel('Кількість елементів МСЕ'); ylabel('Відн. похибка f_n'); title('МСЕ: власна частота');
subplot(1, 3, 2);
semilogx(CV.tol, CV.m, 's-'); grid on;
xlabel('Допуск бісекції, кг'); ylabel('m_p^*, кг'); title('Бісекція');
subplot(1, 3, 3);
nn = (10:numel(mm))';
run5 = zeros(size(nn)); run50 = zeros(size(nn));
for k = 1:numel(nn)
    q = pctile(mm(1:nn(k)), [5 50]); run5(k) = q(1); run50(k) = q(2);
end
plot(nn, run5, nn, run50); grid on; legend('P5', 'P50', 'Location', 'best');
xlabel('Кількість реалізацій'); ylabel('m_p^*, кг'); title('Monte Carlo');
figs(end+1) = save_fig(h, outdir, 'fig6_convergence.png', ...
    'Збіжність чисельних результатів: МСЕ, бісекція, Monte Carlo.');

% 7. Потужність і тривалість
h = newfig();
subplot(1, 2, 1);
plot(CM.pow.m, CM.pow.P_cp/1e3, 'b-', CM.pow.m, CM.pow.P_mt/1e3, 'r--', 'LineWidth', 1.4); grid on;
xlabel('Злітна маса, кг'); ylabel('Механічна потужність висіння, кВт');
legend('Модель C_P', sprintf('Теорія імпульсу, FM=%.2f', CM.pow.FM_ref), 'Location', 'northwest');
title('Порівняння методів');
subplot(1, 2, 2);
t = zeros(size(S.grid)); tn = t;
for k = 1:numel(S.grid)
    R = eval_payload(S.B, S.X, S.grid(k)); t(k) = R.t_flight_min;
    R = eval_payload(SN.B, SN.X, S.grid(k)); tn(k) = R.t_flight_min;
end
plot(S.grid, t, 'b-', S.grid, tn, 'g-', [S.grid(1) S.grid(end)], [1 1]*S.X.t_min, 'k--', 'LineWidth', 1.4);
grid on; xlabel('m_p, кг'); ylabel('Тривалість польоту, хв');
legend('Гірші умови', 'Нормальні умови', 'Вимога', 'Location', 'northeast');
title('Енергетичне обмеження');
figs(end+1) = save_fig(h, outdir, 'fig7_power_endurance.png', ...
    'Потужність висіння двома методами та тривалість польоту від навантаження.');

% 8. Активні обмеження в MC
h = newfig();
bar(MC.active_counts / max(sum(MC.ok), 1) * 100); grid on;
set(gca, 'XTick', 1:numel(C), 'XTickLabel', {C.id});
try, set(gca, 'XTickLabelRotation', 45); catch, end
ylabel('% реалізацій'); title('Яке обмеження визначає m_p^* (Monte Carlo)');
figs(end+1) = save_fig(h, outdir, 'fig8_active.png', ...
    'Частота, з якою кожне обмеження є визначальним.');
end

function h = newfig()
h = figure('Visible', 'off', 'Position', [100 100 1100 520]);
% Octave при print ігнорує Position невидимого вікна - розмір задаємо через Paper*
set(h, 'PaperUnits', 'inches', 'PaperSize', [10 4.73], 'PaperPosition', [0 0 10 4.73]);
end

function f = save_fig(h, outdir, name, caption)
print(h, fullfile(outdir, name), '-dpng', '-r110');
close(h);
f = struct('file', name, 'caption', caption);
end

