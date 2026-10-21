function VS = variant_study(P, cfg)
%VARIANT_STUDY Граничне навантаження для кількох варіантів компонування (гірші умови).
V = variants();
C = constraint_list();
VS = struct('name', {}, 'm_max', {}, 'active', {}, 'Izz', {}, 'cg_z', {}, 't_min', {});
for k = 1:numel(V)
    Q = P;
    Q.z_bat.nom = V(k).z_bat;
    Q.z_payload.nom = -V(k).z_pay;                 % z_payload у моделі - вниз
    Q.e_cg.hi = V(k).e_cg;
    S = max_payload(get_point(Q, 'design'), cfg);
    VS(k).name = V(k).name; VS(k).m_max = S.m_max; VS(k).active = C(S.active).label;
    VS(k).Izz = S.R.I(3, 3); VS(k).cg_z = S.R.cg(3); VS(k).t_min = S.R.t_flight_min;
end
end
