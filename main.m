%MAIN Параметрична модель квадрокоптера 22": граничне корисне навантаження.
%
%   Запуск: відкрити папку проєкту в MATLAB (або GNU Octave >= 7) і виконати
%       >> main            % пресет з config.m (cfg.preset)
%       >> main('heavy')   % 'light' | 'heavy' | 'ref'
%       >> run_all         % light + heavy + порівняльна таблиця results/summary.md
%   Результати: results/<пресет>/ (report.html, report.md, графіки PNG).
%   Toolbox-и не потрібні.

function main(preset)
close all;
root = fileparts(mfilename('fullpath'));
addpath(genpath(root));
cfg = config();
if nargin > 0, cfg.preset = preset; end
outdir = fullfile(root, 'results', cfg.preset);
if ~exist(outdir, 'dir'), mkdir(outdir); end
try
    rng(cfg.seed);
catch
    rand('seed', cfg.seed); randn('seed', cfg.seed); %#ok<RAND>
end
t0 = tic;

fprintf('1/8 Вихідні дані\n');
switch cfg.preset
    case 'light', P = real_params();         % U8 Lite KV150
    case 'heavy', P = real_params_heavy();   % MN605-S KV170 + посилені промені
    otherwise,    P = ref_params();          % узагальнена референсна конфігурація
end
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

fprintf('6б Інтервальний аналіз, FOSM, FORM, квазі-MC, аналітика\n');
UM = uncertainty_methods(P, S, MC, SE, cfg);
fprintf('    інтервал: [%.2f ... %.2f] кг (без резонансу [%.2f ... %.2f]); FOSM %.2f +- %.2f; FORM P(>= %g кг) = %.2g\n', ...
    UM.int.lo, UM.int.hi, UM.int_nor.lo, UM.int_nor.hi, UM.fosm.mu, UM.fosm.sigma, cfg.m_target, UM.form.P);

fprintf('7/8 Оцінювання достовірності\n');
CR = credibility_check(P, Xd, S, SN, MC, SE, CM, CV, U, cfg);
fprintf('    критичних: %d, попереджень: %d, достовірний: %d\n', CR.n_crit, CR.n_warn, CR.credible);

fprintf('8/8 Варіанти компонування, стендова перевірка, графіки і звіт\n');
EX.bom = components(cfg.preset);
EX.bench = bench_check(P, cfg.preset);
EX.var = variant_study(P, cfg);
EX.UM = UM;
for k = 1:numel(EX.var)
    fprintf('    %s: m_p* = %.2f кг (%s)\n', EX.var(k).name, EX.var(k).m_max, EX.var(k).active);
end
try
    figs = make_plots(outdir, P, S, SN, MC, SE, CM, CV, cfg, UM);
catch err    % без графічного середовища (headless) звіт будується без рисунків
    warning('Графіки не побудовано: %s', err.message);
    figs = struct('file', {}, 'caption', {});
end
generate_report(outdir, P, S, SN, MC, SE, CM, CV, U, CR, figs, cfg, EX);
save(fullfile(outdir, 'results.mat'), 'P', 'S', 'SN', 'MC', 'SE', 'CM', 'CV', 'U', 'CR', 'cfg', 'EX', '-v7');

fprintf('Готово за %.0f с. Звіт: %s\n', toc(t0), fullfile(outdir, 'report.html'));
