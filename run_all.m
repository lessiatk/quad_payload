%RUN_ALL Розрахунок обох конфігурацій і порівняльна таблиця results/summary.md.
root = fileparts(mfilename('fullpath'));
presets = {'light', 'heavy'};
rows = '';
for k = 1:numel(presets)
    main(presets{k});
    R = load(fullfile(root, 'results', presets{k}, 'results.mat'));
    C = constraint_list();
    rows = [rows sprintf('| %s | %.2f | %.2f | %.2f / %.2f / %.2f | %.0f %% | %.2f | %s |\n', presets{k}, ...
        R.SN.m_max, R.S.m_max, R.MC.q(1), R.MC.q(2), R.MC.q(3), 100*R.MC.P_target, R.S.B.m_empty, ...
        C(R.S.active).label)]; %#ok<AGROW>
end
fid = fopen(fullfile(root, 'results', 'summary.md'), 'w', 'n', 'UTF-8');
fprintf(fid, ['# Порівняння конфігурацій\n\n| Конфігурація | m_p* норм., кг | m_p* гірші, кг | MC P5/P50/P95, кг | ' ...
    'P(>= %g кг) | Порожня маса, кг | Активне обмеження |\n|---|---|---|---|---|---|---|\n%s'], config().m_target, rows);
fclose(fid);
fprintf('Порівняння: %s\n', fullfile(root, 'results', 'summary.md'));
