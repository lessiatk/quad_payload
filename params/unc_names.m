function names = unc_names(P)
%UNC_NAMES Імена параметрів з епістемічною невизначеністю (kind='unc').
f = fieldnames(P);
names = {};
for k = 1:numel(f)
    p = P.(f{k});
    if strcmp(p.kind, 'unc') && p.hi > p.lo
        names{end+1} = f{k}; %#ok<AGROW>
    end
end
end
