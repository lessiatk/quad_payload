function B = precompute(X)
%PRECOMPUTE Величини, що не залежать від корисного навантаження.
B.g = 9.80665;
% Геометрія X-схеми: x вперед, y вправо.
% Ротор 1 - передній правий (CCW), 2 - задній лівий (CCW),
% 3 - передній лівий (CW), 4 - задній правий (CW).
a = (X.R_center + X.L_arm) / sqrt(2);
B.a    = a;
B.pos  = [ a  a;  -a -a;   a -a;  -a  a];
B.spin = [ 1;  1;  -1;  -1];
B.A_disk = pi * X.D_prop^2 / 4;
B.kq = X.CP * X.D_prop / (2*pi*X.CT);            % м, Q/T
B.FM = X.CT^1.5 / (X.CP * sqrt(pi/2));           % якість (figure of merit)

% Повний газ
B.FT = motor_full_throttle(X);
B.T_max = B.FT.T;
B.tip_mach = pi * X.D_prop * B.FT.n / 343;

% Конструкція
B.m_tip = X.m_motor + X.m_prop + 0.5*X.m_esc;
B.arm     = arm_structure(X, B.FT.T * X.k_dyn, B.FT.Q * X.k_dyn, B.m_tip); % міцність
B.arm_op  = arm_structure(X, B.FT.T, B.FT.Q, B.m_tip);                     % жорсткість
B.m_empty = X.m_frame + X.m_avionics + X.m_wiring + X.m_bat + ...
            X.n_rot * (B.arm.m_arm + X.m_motor + X.m_prop + X.m_esc);

% Енергія батареї
B.E_use = X.n_cells * X.V_cell_nom * X.Q_Ah * 3600 * X.DoD * X.SoH;   % Дж
B.E_density = X.n_cells * X.V_cell_nom * X.Q_Ah / X.m_bat;          % Вт*год/кг
end
