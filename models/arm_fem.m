function R = arm_fem(X, T, m_tip, n_el)
%ARM_FEM Скінченно-елементна модель променя (балкові елементи Ейлера-Бернуллі,
%   кубічні поліноми Ерміта, 2 ступені вільності у вузлі: w, theta).
%   Узгоджена матриця мас + зосереджена маса на кінці.
%   Використовується для верифікації аналітичної моделі і дослідження збіжності.

OD = X.arm_OD; ID = OD - 2*X.arm_t; L = X.L_arm; E = X.E_arm;
I  = pi/64*(OD^4 - ID^4); A = pi/4*(OD^2 - ID^2); c = OD/2;
mu = X.rho_cf * A;            % кг/м
l  = L / n_el;
nd = 2*(n_el + 1);
K  = zeros(nd); M = zeros(nd);

Ke = E*I/l^3 * [ 12    6*l   -12    6*l;
                 6*l   4*l^2 -6*l   2*l^2;
                -12   -6*l    12   -6*l;
                 6*l   2*l^2 -6*l   4*l^2];
Me = mu*l/420 * [156    22*l    54    -13*l;
                 22*l   4*l^2   13*l  -3*l^2;
                 54     13*l    156   -22*l;
                -13*l  -3*l^2  -22*l   4*l^2];
for e = 1:n_el
    idx = 2*e-1 : 2*e+2;
    K(idx, idx) = K(idx, idx) + Ke;
    M(idx, idx) = M(idx, idx) + Me;
end
M(nd-1, nd-1) = M(nd-1, nd-1) + m_tip;     % маса мотора на кінці

free = 3:nd;                               % защемлення у вузлі 1
F = zeros(nd, 1); F(nd-1) = T;
u = zeros(nd, 1);
u(free) = K(free, free) \ F(free);

R.delta = u(nd-1);
R.theta = u(nd);
% Кривина в корені з функцій форми першого елемента -> напруження
w2 = u(3); t2 = u(4);
kappa0 = 6/l^2*w2 - 2/l*t2;
R.sigma_root = E*c*abs(kappa0);
lam = eig(K(free, free), M(free, free));
lam = sort(real(lam));
R.f_n = sqrt(lam(1)) / (2*pi);
R.n_el = n_el;
end
