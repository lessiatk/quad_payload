function X = get_point(P, mode)
%GET_POINT Повертає структуру скалярних значень параметрів.
%   mode = 'nominal' - усі параметри = nom (нормальні умови)
%   mode = 'design'  - епістемічні = nom, експлуатаційні = гірший випадок
if nargin < 2, mode = 'design'; end
f = fieldnames(P);
X = struct();
for k = 1:numel(f)
    p = P.(f{k});
    v = p.nom;
    if strcmp(mode, 'design')
        if strcmp(p.kind, 'env_lo'), v = p.lo; end
        if strcmp(p.kind, 'env_hi'), v = p.hi; end
    end
    X.(f{k}) = v;
end
end
