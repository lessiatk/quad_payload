function th = motor_thermal(X, T)
%MOTOR_THERMAL Усталена температура обмотки при тривалій тязі T [Н].
%
%   Нелінійна задача (опір міді залежить від температури):
%     Tw = T_amb + R_th * P_loss(Tw)
%     Rm(Tw) = Rm25 * (1 + alpha_cu*(Tw - 25))
%   Розв'язок - fzero. Якщо кореня немає -> тепловий розгін (runaway).

h = @(Tw) X.T_amb + X.R_th * loss_at(X, T, Tw) - Tw;
th.runaway = false;
Ta = X.T_amb; Tb = X.T_amb + 2000;
if h(Tb) > 0
    th.runaway = true;
    th.Tw = Inf;
    th.op = rotor_operating_point(X, T, X.Rm);
    return;
end
opts = optimset('TolX', 1e-6, 'Display', 'off');
th.Tw = fzero(h, [Ta, Tb], opts);
th.Rm_hot = X.Rm * (1 + X.alpha_cu*(th.Tw - 25));
th.op = rotor_operating_point(X, T, th.Rm_hot);
end

function P = loss_at(X, T, Tw)
Rm = X.Rm * (1 + X.alpha_cu*(Tw - 25));
op = rotor_operating_point(X, T, Rm);
P  = op.P_loss;
end
