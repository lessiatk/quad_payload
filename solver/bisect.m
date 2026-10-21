function [x, it] = bisect(f, a, b, tol)
%BISECT Межа між допустимою (f<=0) та недопустимою (f>0) областями.
%   a - точка з f(a) <= 0, b - точка з f(b) > 0 (a може бути > b).
%   Повертає останню допустиму точку з точністю tol.
it = 0;
while abs(b - a) > tol
    c = 0.5*(a + b);
    if f(c) <= 0
        a = c;
    else
        b = c;
    end
    it = it + 1;
    if it > 200, break; end
end
x = a;
end
