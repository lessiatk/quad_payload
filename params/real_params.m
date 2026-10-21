function P = real_params()
%REAL_PARAMS Конфігурація на реальних компонентах (див. components.m).
%   Береться ref_params, потім перекриваються значення, що мають заводські дані.
%   Усе, чого заводські дані не дають (теплові опори, міцність труби, ...), лишається припущенням.
P = ref_params();

% --- Рама Tarot X4 (TL4X001): база 960 мм -> мотор на радіусі 0.48 м ---
P = ov(P, 'R_center', 0.164, 0.164, 0.164, 'datasheet');            % радіус центральної плити (D 328 мм)
P = ov(P, 'L_arm',    0.316, 0.316, 0.316, 'datasheet');            % 480 - 164 мм
P = ov(P, 'm_frame',  1.15,  1.10,  1.25,  'datasheet');            % 1600 г - 4 x 113 г (промені)
% труба променя: Ш30x2 підібрано так, щоб маса променя ~113 г (виробник не дає перерізу)
P = ov(P, 'arm_OD',   0.030, 0.0285, 0.0315, 'assumed');
P = ov(P, 'arm_t',    0.002, 0.0018, 0.0022, 'assumed');

% --- Мотор T-Motor U8 Lite KV150 (12S) ---
P = ov(P, 'Kv',       150,   145,   155,   'datasheet');
P = ov(P, 'Rm',       0.085, 0.080, 0.090, 'datasheet');
P = ov(P, 'I0',       1.0,   0.8,   1.2,   'datasheet');
P = ov(P, 'I_cont',   18.5,  15,    26.5,  'assumed');             % паспорт: 26.5 А лише 180 с; тривалий не заявлено
P = ov(P, 'm_motor',  0.239, 0.236, 0.242, 'datasheet');

% --- Пропелер T-Motor P22x6.6 CF: C_T, C_P виведено зі стендової таблиці 12S (ρ стенду припущено 1.2) ---
P = ov(P, 'CT',       0.061, 0.058, 0.065, 'datasheet');
P = ov(P, 'CP',       0.0165,0.0155,0.0185,'datasheet');
P = ov(P, 'm_prop',   0.090, 0.086, 0.094, 'datasheet');            % 2 x 45 г

% --- ESC T-Motor Alpha 60A 12S ---
P = ov(P, 'm_esc',    0.073, 0.070, 0.076, 'datasheet');
P = ov(P, 'eta_esc',  0.93,  0.90,  0.95,  'datasheet');           % сумарний ККД привода: підігнано під потужність зі стенда
P = ov(P, 'R_esc',    0.235, 0.15,  0.30,  'assumed');             % калібрування: стенд 48 В, 26.5 А, 5924 об/хв

% --- Батарея Tattu Plus 1.0 16000 мАг 12S (compact) ---
P = ov(P, 'Q_Ah',     16,    15.2,  16,    'datasheet');
P = ov(P, 'm_bat',    4.25,  4.20,  4.30,  'datasheet');
P = ov(P, 'C_cont',   15,    10,    15,    'datasheet');
P = ov(P, 'R_pack',   0.035, 0.025, 0.050, 'assumed');

% --- Авіоніка і проводка: за вказівкою - довільні значення ---
P = ov(P, 'm_avionics', 0.5, 0.4, 0.6, 'assumed');
P = ov(P, 'm_wiring',   0.3, 0.25, 0.4, 'assumed');
end

function P = ov(P, name, nom, lo, hi, src)
p = P.(name);
p.nom = nom; p.lo = lo; p.hi = hi; p.src = src;
P.(name) = p;
end
