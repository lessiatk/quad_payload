function T = equilibrium(B, W, cg)
%EQUILIBRIUM Розподіл тяги між роторами у висінні (статична рівновага).
%
%   Система 4 лінійних рівнянь (сили та моменти):
%     sum T_i                   = W            (вертикальна сила)
%     sum y_i T_i               = W*y_cg       (крен)
%     sum x_i T_i               = W*x_cg       (тангаж)
%     sum s_i*k_q*T_i           = 0            (рискання, s_i = +-1)
%   k_q = Q/T = C_P*D/(2*pi*C_T).
A = [ones(1,4);
     B.pos(:,2)';
     B.pos(:,1)';
     (B.spin .* B.kq)'];
b = [W; W*cg(2); W*cg(1); 0];
T = A \ b;
end
