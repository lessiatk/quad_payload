function R = eval_payload(B, X, m_p)
%EVAL_PAYLOAD Оцінка всіх обмежень при корисному навантаженні m_p [кг].
%   Повертає R.g (вектор нормованих обмежень, допустимо при g <= 0)
%   та проміжні величини для звіту.
g0 = B.g;
MI = mass_inertia(X, B, m_p);
W  = MI.m * g0;

% --- 1. Рівновага: тяги роторів ---
T  = equilibrium(B, W, MI.cg);
[T_hi, i_hi] = max(T);

% --- 2. Висіння: робочі точки, потужність, енергія ---
P_e = 0; n_mean = 0;
for i = 1:4
    op = rotor_operating_point(X, T(i));
    P_e = P_e + op.P_elec;
    n_mean = n_mean + op.n/4;
end
V_bus  = X.n_cells * X.V_cell_load;
P_bat  = P_e / X.eta_esc + X.P_avionics;
I_bat  = P_bat / V_bus;
t_fl   = B.E_use / P_bat;                         % с

% --- 3. Тривалий режим найбільш навантаженого ротора ---
th = motor_thermal(X, X.k_cont * T_hi);
I_cont_bat = I_bat * X.k_cont^1.5;                % P ~ T^1.5

% --- 4. Резонанс: частоти 1P і 2P (2-лопатевий гвинт) ---
f1 = n_mean; fn = B.arm_op.f_n;
mrg = min(abs(f1 - fn), abs(2*f1 - fn)) / fn;

% --- 5. Керованість по рисканню ---
T_idle = 0.05 * B.T_max;
dT = min(min(B.T_max - T), min(T - T_idle));
alpha_z = max(4 * B.kq * dT, 0) / MI.Izz;

% --- 6. Посадка ---
n_land = 1 + X.v_land^2 / (g0 * X.s_gear);
F_land = n_land * W;

% --- Нормовані обмеження g = попит/ресурс - 1 ---
g = zeros(10, 1);
g(1)  = X.k_TW * T_hi / B.T_max - 1;
g(2)  = X.t_min*60 / t_fl - 1;
g(3)  = th.op.I / X.I_cont - 1;
if th.runaway
    g(4) = 10;
else
    g(4) = (th.Tw - X.T_amb) / (X.T_motor_max - X.T_amb) - 1;
end
g(5)  = I_cont_bat / (X.C_cont * X.Q_Ah) - 1;
g(6)  = B.arm.sigma_vm / B.arm.sigma_allow - 1;
g(7)  = B.arm_op.theta / (X.theta_max_deg*pi/180) - 1;
g(8)  = X.res_margin / max(mrg, 1e-9) - 1;
g(9)  = X.alpha_yaw_min / max(alpha_z, 1e-9) - 1;
g(10) = F_land / X.F_gear_allow - 1;
g = min(g, 10);                                   % обмеження для графіків

R.g = g;
R.m_total = MI.m; R.cg = MI.cg; R.I = MI.I;
R.T = T; R.T_hi = T_hi; R.i_hi = i_hi;
R.TW = B.T_max / T_hi;
R.P_bat = P_bat; R.I_bat = I_bat; R.t_flight_min = t_fl/60;
R.Tw = th.Tw; R.I_motor_cont = th.op.I; R.runaway = th.runaway;
R.f_1P = f1; R.f_n = fn; R.res_margin = mrg;
R.alpha_yaw = alpha_z; R.F_land = F_land;
R.rpm_hover = 60*n_mean;
op_hi = rotor_operating_point(X, T_hi);
R.throttle = op_hi.Vm / (V_bus - X.R_pack*I_bat);
end
