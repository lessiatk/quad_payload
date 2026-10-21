function U = units_check()
%UNITS_CHECK Перевірка розмірностей усіх розрахункових формул моделі.
%   Розмірність - вектор показників [M L T I Theta] (кг, м, с, А, К).
%   Для добутку показники складаються, для степеня - множаться.

d.one  = [0 0 0 0 0];
d.kg   = [1 0 0 0 0];
d.m    = [0 1 0 0 0];
d.s    = [0 0 1 0 0];
d.A    = [0 0 0 1 0];
d.K    = [0 0 0 0 1];
d.N    = [1 1 -2 0 0];
d.Nm   = [1 2 -2 0 0];
d.J    = [1 2 -2 0 0];
d.W    = [1 2 -3 0 0];
d.V    = [1 2 -3 -1 0];
d.Ohm  = [1 2 -3 -2 0];
d.Pa   = [1 -1 -2 0 0];
d.rho  = [1 -3 0 0 0];
d.Hz   = [0 0 -1 0 0];     % об/с, рад/с, Гц (рад - безрозмірний)
d.Ke   = [1 2 -2 -1 0];    % В*с/рад
d.Rth  = [-1 -2 3 0 1];    % К/Вт
d.m4   = [0 4 0 0 0];
d.Npm  = [1 0 -2 0 0];     % Н/м
d.mps  = [0 1 -1 0 0];
d.mps2 = [0 1 -2 0 0];
d.Ah   = [0 0 1 1 0];

chk = cell(0, 3);
chk(end+1,:) = {'T = C_T*rho*n^2*D^4',            d.N,  d.one + d.rho + 2*d.Hz + 4*d.m};
chk(end+1,:) = {'Q = C_P*rho*n^2*D^5/(2pi)',      d.Nm, d.one + d.rho + 2*d.Hz + 5*d.m};
chk(end+1,:) = {'P = Q*w',                        d.W,  d.Nm + d.Hz};
chk(end+1,:) = {'P_ideal = T^1.5/sqrt(2*rho*A)',  d.W,  1.5*d.N - 0.5*(d.rho + 2*d.m)};
chk(end+1,:) = {'E_bemf = Ke*w',                  d.V,  d.Ke + d.Hz};
chk(end+1,:) = {'Q_m = Kt*I (Kt = Ke)',           d.Nm, d.Ke + d.A};
chk(end+1,:) = {'I = (V - Ke*w)/R',               d.A,  d.V - d.Ohm};
chk(end+1,:) = {'P_cu = I^2*R',                   d.W,  2*d.A + d.Ohm};
chk(end+1,:) = {'dT = R_th*P_loss',               d.K,  d.Rth + d.W};
chk(end+1,:) = {'E_bat = V*Q_Ah*3600',            d.J,  d.V + d.Ah};
chk(end+1,:) = {'t = E/P',                        d.s,  d.J - d.W};
chk(end+1,:) = {'sigma = M*c/I',                  d.Pa, d.Nm + d.m - d.m4};
chk(end+1,:) = {'delta = T*L^3/(3*E*I)',          d.m,  d.N + 3*d.m - d.Pa - d.m4};
chk(end+1,:) = {'theta = T*L^2/(2*E*I)',          d.one,d.N + 2*d.m - d.Pa - d.m4};
chk(end+1,:) = {'k = 3*E*I/L^3',                  d.Npm,d.Pa + d.m4 - 3*d.m};
chk(end+1,:) = {'f_n = sqrt(k/m)/(2pi)',          d.Hz, 0.5*(d.Npm - d.kg)};
chk(end+1,:) = {'k_q = C_P*D/(2pi*C_T)',          d.m,  d.m};
chk(end+1,:) = {'alpha = 4*k_q*dT/I_zz',          [0 0 -2 0 0], d.m + d.N - (d.kg + 2*d.m)};
chk(end+1,:) = {'n_land = 1 + v^2/(g*s)',         d.one,2*d.mps - d.mps2 - d.m};
chk(end+1,:) = {'FM = C_T^1.5/(C_P*sqrt(pi/2))',  d.one,d.one};

n = size(chk, 1);
U.name = chk(:,1); U.ok = false(n, 1);
for k = 1:n
    U.ok(k) = all(abs(chk{k,2} - chk{k,3}) < 1e-12);
end
U.all_ok = all(U.ok);
end
