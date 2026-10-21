function x = tri_inv(u, a, m, b)
%TRI_INV Обернена функція розподілу трикутного закону (min a, мода m, max b).
c = (m - a) / (b - a);
x = zeros(size(u));
lo = u < c;
x(lo)  = a + sqrt(u(lo) * (b - a) * (m - a));
x(~lo) = b - sqrt((1 - u(~lo)) * (b - a) * (b - m));
end
