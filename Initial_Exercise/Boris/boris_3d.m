% Constants
q = 1.602e-19;              % Charge of proton (C)
m = 1.67262192e-27;         % Mass of proton (kg)
B0 = 31000 * 10 ^-9;
RE = 6371000;

radius = @(r) sqrt(r(1).^2 + r(2).^2 + r(3).^2);

theta = deg2rad(11);  % Tilt angle in radians

% Dipole moment vector (unit vector tilted by theta from z-axis)
m_unit = [sin(theta); 0; cos(theta)];

B_osc_factor = 1 / 3; % factor determining amplitude of oscillations of B-field
B_osc_rate = 0; % rate of oscillation of B-field

% define function to compute magnetic field at a point
Bfunc = @(r, t) (B0 * RE^3 / radius(r)^5) * ...
    (3 * dot(m_unit, r) * r - m_unit * radius(r)^2) * ...
    (1 + B_osc_factor * sin(B_osc_rate * (180 * t) / pi));

% E = [0; 0; 0];
E_osc_rate = 0; % rate of oscillation of E-field
E_factor = 100000000000; % factor determining amplitude of oscillations of E-field
E_osc_factor = 0; % factor determining amplitude of oscillations of E-field
Efunc = @(r, t) r * E_factor * (1 + E_osc_factor * sin(E_osc_rate * (180 * t) / pi)) / radius(r)^3;

% Simulation parameters
timestep = 1e-3;                 % Time step (s)
numsteps = 1000000;            % Number of time steps

% Initial conditions
r = zeros(3, numsteps);     % Position (m)
v = zeros(3, numsteps);     % Velocity (m/s)

v(:,1) = [9500000; 0; 0];       % Initial velocity
r(:,1) = [RE * 8; 0; 0];  % Initial position (8 earth radii)

for n = 1:numsteps-1

    B = Bfunc(r(:,n), n * timestep);
    E = Efunc(r(:,n), n * timestep);    

    t = (q * B / m) * (0.5 * timestep);       % t = (q B dt)/(2m)
    s = 2 * t / (1 + dot(t, t));

    v_minus = v(:,n) + 0.5 .* q ./ m .* timestep * E;
    
    % Rotation
    v_prime = v_minus + cross(v_minus, t);
    v_plus  = v_minus + cross(v_prime, s);

    v_plus = v_plus + 0.5 * (q/m) * E * timestep;
    
    % Advance position using v_plus (same as v at half-step)
    r(:,n+1) = r(:,n) + v_plus * timestep;
    
    % Store updated velocity
    v(:,n+1) = v_plus;
end

% Plotting
figure;
plot3(r(1, :), r(2, :), r(3, :))
hold on
xlabel('x'); ylabel('y'); zlabel('z')
title('Particle Trajectory in Dipole Magnetic Field')

% adding Earth sphere
[xs, ys, zs] = sphere(50);  % higher resolution sphere
surf(RE * xs, RE * ys, RE * zs, ...
    'FaceColor', [0.2 0.5 1], ...     % earth-like blue
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.5);               % semi-transparent

% set view and axis
axis equal
grid on
view(3)
hold off

energies = .5 .* m .* vecnorm(v).^2;
times = linspace(0, timestep * numsteps, numsteps);

figure;
plot(times, energies);
xlabel('time (s)');
ylabel('energy (joules)');
title('Proton Gyromotion energy');
axis equal;
grid on;