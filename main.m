%MAIN Параметрична модель квадрокоптера 22": граничне корисне навантаження.
%
%   Запуск: відкрити папку проєкту в MATLAB (або GNU Octave >= 7) і виконати
%       >> main
%   Результати: папка results/ (report.html, report.md, графіки PNG).
%   Toolbox-и не потрібні.

clear; close all; clc;
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));
outdir = fullfile(root, 'results');
if ~exist(outdir, 'dir'), mkdir(outdir); end

cfg = config();
try
    rng(cfg.seed);
catch
    rand('seed', cfg.seed); randn('seed', cfg.seed); %#ok<RAND>
end
t0 = tic;

fprintf('1/8 Вихідні дані\n');
P  = ref_params();
Xd = get_point(P, 'design');     % гірші експлуатаційні умови
Xn = get_point(P, 'nominal');    % нормальні умови

fprintf('2/8 Перевірка розмірностей\n');
U = units_check();
fprintf('    усі формули коректні: %d\n', U.all_ok);

fprintf('3/8 Граничне навантаження (детерміновано)\n');
S  = max_payload(Xd, cfg);
SN = max_payload(Xn, cfg);
C  = constraint_list();
fprintf('    нормальні умови: m_p* = %.2f кг (%s)\n', SN.m_max, C(SN.active).label);
fprintf('    гірші умови:     m_p* = %.2f кг (%s)\n', S.m_max,  C(S.active).label);

fprintf('4/8 Порівняння методів і збіжність\n');
CM = compare_methods(Xd, S, cfg);
CV = convergence_study(Xd, cfg);

fprintf('5/8 Аналіз чутливості\n');
SE = sensitivity(P, Xd, cfg, S);

fprintf('6/8 Monte Carlo (N = %d)\n', cfg.N_mc);
MC = monte_carlo(P, cfg);
fprintf('    P5/P50/P95 = %.2f / %.2f / %.2f кг\n', MC.q);

fprintf('7/8 Оцінювання достовірності\n');
CR = credibility_check(P, Xd, S, SN, MC, SE, CM, CV, U, cfg);
fprintf('    критичних: %d, попереджень: %d, достовірний: %d\n', CR.n_crit, CR.n_warn, CR.credible);

fprintf('8/8 Графіки і звіт\n');
figs = make_plots(outdir, P, S, SN, MC, SE, CM, CV, cfg);
generate_report(outdir, P, S, SN, MC, SE, CM, CV, U, CR, figs, cfg);
save(fullfile(outdir, 'results.mat'), 'P', 'S', 'SN', 'MC', 'SE', 'CM', 'CV', 'U', 'CR', 'cfg', '-v7');

fprintf('Готово за %.0f с. Звіт: %s\n', toc(t0), fullfile(outdir, 'report.html'));
