function FT = motor_full_throttle(X)
%MOTOR_FULL_THROTTLE Робоча точка мотора+пропелера на повному газі.
%
%   Нелінійне рівняння рівноваги моментів (розв'язується fzero):
%     Kt*(I(w) - I0) = Q_prop(w)
%     I(w) = (V_oc - Ke*w) / (Rm + N*R_pack/eta_esc)    (просідання шини
%            від струму всіх N моторів через спільний опір батареї)
%     Q_prop(w) = C_P*rho*n^2*D^5/(2*pi),  n = w/(2*pi)
%   Kt = Ke = 1/Kv [В*с/рад].
%   V_cell_oc - напруга без навантаження в кінці місії; просідання враховано лише
%   через R_pack (і R_esc), щоб не рахувати його двічі.
%   Нагрів обмотки на повному газі не враховано (короткочасний режим).

Ke   = 1 / (X.Kv * 2*pi/60);
Voc  = X.n_cells * X.V_cell_oc;
Rtot = X.Rm + X.R_esc + X.n_rot * X.R_pack / X.eta_esc;
D    = X.D_prop;

f = @(w) Ke*((Voc - Ke*w)/Rtot - X.I0) - X.CP*X.rho*(w/(2*pi))^2*D^5/(2*pi);
w_hi = Voc / Ke;                      % холостий хід без втрат
opts = optimset('TolX', 1e-9, 'Display', 'off');
w = fzero(f, [1e-6, w_hi], opts);

n = w / (2*pi);
FT.w     = w;
FT.n     = n;                          % об/с
FT.rpm   = n * 60;
FT.T     = X.CT * X.rho * n^2 * D^4;   % Н
FT.Q     = X.CP * X.rho * n^2 * D^5 / (2*pi);   % Н*м
FT.I_m   = (Voc - Ke*w) / Rtot;        % А (на мотор)
FT.I_bat = X.n_rot * FT.I_m / X.eta_esc;
FT.V_term= Voc - X.R_pack * FT.I_bat;
FT.residual = f(w);
end
