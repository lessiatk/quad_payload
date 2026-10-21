function op = rotor_operating_point(X, T, Rm_eff)
%ROTOR_OPERATING_POINT Робоча точка ротора при заданій тязі T [Н].
%   Використовує статичні коефіцієнти C_T, C_P (висіння без вітру).
if nargin < 3, Rm_eff = X.Rm; end
D  = X.D_prop;
Ke = 1 / (X.Kv * 2*pi/60);
T  = max(T, 0);

n  = sqrt(T / (X.CT * X.rho * D^4));        % об/с
w  = 2*pi*n;
Q  = X.CP * X.rho * n^2 * D^5 / (2*pi);     % Н*м
I  = Q / Ke + X.I0;                         % А
Vm = Ke*w + I*Rm_eff;                       % В (ефективна напруга на моторі)

op.n = n; op.rpm = 60*n; op.w = w; op.T = T; op.Q = Q;
op.I = I; op.Vm = Vm;
op.P_shaft = Q*w;
op.P_elec  = Vm*I;
op.P_loss  = I^2*Rm_eff + X.I0*Vm;          % мідь + (залізо+тертя) ~ I0*V
end
