function S = max_payload(X, cfg)
%MAX_PAYLOAD Граничне корисне навантаження.
%
%   Постановка:  m_p* = sup { m_p >= 0 : g_j(X, m_p) <= 0, j = 1..J }
%
%   Метод: (1) сканування сітки m_p з кроком cfg.dm (знаходить усі зміни
%   знаку, у т.ч. для немонотонних обмежень - резонанс); (2) уточнення
%   межі бісекцією до cfg.tol. Окремо для кожного обмеження j
%   знаходиться його власна межа m_j = sup{m : g_j(m) <= 0}.
%   Активне обмеження - те, що дає мінімальну m_j.

B  = precompute(X);
C  = constraint_list();
J  = numel(C);
mg = 0:cfg.dm:cfg.m_hi;
K  = numel(mg);
G  = zeros(J, K);
for k = 1:K
    R = eval_payload(B, X, mg(k));
    G(:, k) = R.g;
end
gmax = max(G, [], 1);
feas = gmax <= 0;

S.X = X; S.B = B; S.grid = mg; S.G = G; S.names = {C.id}; S.labels = {C.label};
S.m_min = NaN; S.m_max = NaN;

if ~any(feas)
    S.status = 'infeasible';
else
    kl = find(feas, 1, 'last');
    if kl == K
        S.status = 'unbounded_in_grid';
        S.m_max = mg(K);
    else
        S.status = 'ok';
        f = @(m) max(eval_g(B, X, m));
        S.m_max = bisect(f, mg(kl), mg(kl+1), cfg.tol);
    end
    % нижня межа суцільної допустимої області, що містить m_max
    kf = kl;
    while kf > 1 && feas(kf-1), kf = kf - 1; end
    if kf == 1
        S.m_min = 0;
    else
        f = @(m) max(eval_g(B, X, m));
        S.m_min = bisect(f, mg(kf), mg(kf-1), cfg.tol);   % a - допустима точка
    end
end

% --- Межі за окремими обмеженнями ---
S.lim = inf(J, 1);
for j = 1:J
    ok = G(j, :) <= 0;
    if ~any(ok)
        S.lim(j) = -Inf;                 % порушене при будь-якому m_p
    elseif ok(end)
        S.lim(j) = Inf;                  % не обмежує в діапазоні сітки
    else
        kj = find(ok, 1, 'last');
        fj = @(m) pick(eval_g(B, X, m), j);
        S.lim(j) = bisect(fj, mg(kj), mg(kj+1), cfg.tol);
    end
end
[~, S.active] = min(S.lim);
if strcmp(S.status, 'infeasible') || ~isfinite(S.m_max)
    S.R = eval_payload(B, X, 0);
else
    S.R = eval_payload(B, X, S.m_max);
end
end

function g = eval_g(B, X, m)
R = eval_payload(B, X, m);
g = R.g;
end

function v = pick(g, j)
v = g(j);
end
