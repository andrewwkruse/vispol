function Aout = Alocal(Ain, params)
params = cell2mat(params);
phi = params(1);
rate = params(2);
Ashift = (Ain - phi) ./ (pi/2);
Ashift(Ashift > 1) = Ashift(Ashift > 1) - 2;
Ashift(Ashift < -1) = Ashift(Ashift < -1) + 2;
scale = ((2 * 1 / (exp(-rate) + 1) -1));
Aout = pi/2 .* (2 ./ (exp(-rate .* Ashift) + 1) - 1) ./ scale + phi;
Aout(Aout > pi/2) = Aout(Aout > pi/2) - pi;
Aout(Aout < -pi/2) = Aout(Aout < -pi/2) + pi;
end
