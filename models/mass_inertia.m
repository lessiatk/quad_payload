function MI = mass_inertia(X, B, m_p)
%MASS_INERTIA Маса, центр мас і тензор інерції апарата з вантажем.
%   Модель - сукупність точкових мас, стрижнів і паралелепіпедів.
%   Осі: x - вперед, y - вправо, z - вгору; початок - центр рами.
%   Вантаж зміщено на e_cg уздовж діагоналі до ротора 1 (найгірший випадок
%   для X-схеми: навантажується один ротор).

items = {};
% тіло: центральні пластини, авіоніка, проводка - паралелепіпед 0.25x0.25x0.08
items{end+1} = mk_box(X.m_frame + X.m_avionics + X.m_wiring, [0 0 0], [0.25 0.25 0.08]);
% батарея зверху
items{end+1} = mk_box(X.m_bat, [0 0 X.z_bat], [0.20 0.10 0.12]);
% мотори+пропелери+половина ESC на кінцях, промені як стрижні
for i = 1:4
    p = B.pos(i, :);
    items{end+1} = mk_point(B.m_tip, [p 0.03]);
    u = p / norm(p);
    r_mid = (X.R_center + X.L_arm/2);
    items{end+1} = mk_rod(B.arm.m_arm + 0.5*X.m_esc, [u*r_mid 0], u, X.L_arm);
end
% вантаж
e = X.e_cg / sqrt(2);
items{end+1} = mk_point(m_p, [e e -X.z_payload]);

m = 0; s = [0 0 0];
for k = 1:numel(items)
    m = m + items{k}.m;
    s = s + items{k}.m * items{k}.r;
end
cg = s / max(m, eps);
Itot = zeros(3);
for k = 1:numel(items)
    d = items{k}.r - cg;
    Itot = Itot + items{k}.I + items{k}.m * (dot(d,d)*eye(3) - d'*d);
end
MI.m = m; MI.cg = cg; MI.I = Itot;
MI.Ixx = Itot(1,1); MI.Iyy = Itot(2,2); MI.Izz = Itot(3,3);
end

function it = mk_point(m, r)
it.m = m; it.r = r; it.I = zeros(3);
end

function it = mk_box(m, r, dims)
a = dims(1); b = dims(2); c = dims(3);
it.m = m; it.r = r;
it.I = m/12 * diag([b^2+c^2, a^2+c^2, a^2+b^2]);
end

function it = mk_rod(m, r, u, L)
% тонкий стрижень уздовж одиничного вектора u (в площині xy)
u3 = [u 0];
it.m = m; it.r = r;
it.I = m*L^2/12 * (eye(3) - u3'*u3);
end
