clear all
close all

%datafiles = {'case1', 'case2', 'case3', 'case4', 'case5'};
datafiles={'case2'}
time = [1980:2018];
colors = {'p', 'b', 'k', 'o', 'g'};
figure(1)

for i = 1:length(datafiles)
    output = calculateLifetimes(datafiles{i});
    %mean(output.global_e_folds)
    %std(output.global_e_folds)
    subplot(1,2,1)
    plot(time, output.ch4_global_lifetime, colors{i});
    xlabel('Years')
    ylabel('lifetimes')
    title('Eigenvalue Lifetimes')
    hold on;
    subplot(1,2,2);
    plot(time, output.ch4_ss, colors{i});
    xlabel('Years')
    ylabel('lifetimes')
    title('Steady State Lifetime')
    hold on
end
feedback = output.ch4_global_lifetime ./ output.ch4_ss;

legend('Case 1', 'Case 2', 'Case 3', 'Case 4', 'Case 5');
saveas(figure(1), 'ch4_lifetime.pdf', 'pdf')
% The CO plot
figure(2)
for i = 1:length(datafiles)
    output = calculateLifetimes(datafiles{i});
    fprintf('CO lifetimes')
    mean(output.co_global_lifetime)
    std(output.co_global_lifetime)
    subplot(1,2,1)
    plot(time, output.co_global_lifetime, colors{i});
    xlabel('Years')
    ylabel('lifetimes')
    title('Eigenvalue Lifetimes')
    hold on;
    subplot(1,2,2);
    plot(time, output.co_ss, colors{i});
    xlabel('Years')
    ylabel('lifetimes')
    title('Steady State Lifetime')
    hold on
end
legend('Case 1', 'Case 2', 'Case 3', 'Case 4', 'Case 5');
saveas(figure(2), 'co_lifetime.pdf', 'pdf')

figure(3)
for i = 1:length(datafiles)
    output = calculateLifetimes(datafiles{i});
    fprintf('OH lifetimes')
    mean(output.oh_global_lifetime)
    std(output.oh_global_lifetime)
    subplot(1,2,1)
    plot(time, output.oh_global_lifetime, colors{i});
    xlabel('Years')
    ylabel('lifetimes')
    title('Eigenvalue Lifetimes')
    hold on;
    subplot(1,2,2);
    plot(time, output.oh_ss, colors{i});
    xlabel('Years')
    ylabel('lifetimes')
    title('Steady State Lifetime')
    hold on
end
legend('Case 1', 'Case 2', 'Case 3', 'Case 4', 'Case 5');
saveas(figure(3), 'oh_lifetime.pdf' , 'pdf')

function result = calculateLifetimes(filename)

load(filename)

day2sec = 60*60*24; % convert days to seconds
year2sec = 365*day2sec;
n_air = params.n_air; % molec/cm^3 for dry atmosphere
conversion = day2sec * n_air/1d9; % conversion factor rom ppb/day to molec/cm^3 / s;
ppb2con = n_air / 1e9;
ppt2con = n_air / 1e12;


k_ch4 = params.k_12ch4; % ppb/day
k_co =  params.k_co; % ppb/day
k_ch4 = k_ch4 / conversion; % molec/cm^3 / s
k_co = k_co / conversion; % molec/ cm^3 / s

kX_NH = kX_NH(1);
kX_SH = kX_SH(1);
kx_global = 0.5 * (kX_NH + kX_SH); % molec/cm^3 / s



%%% Read in concentrations
nh_ch4 = ppb2con * out.nh_ch4; % molec/cm^3
sh_ch4 = ppb2con * out.sh_ch4; % molec/cm^3
global_ch4  = 0.5* (nh_ch4 + sh_ch4); % molec/ cm^3

nh_co = ppb2con * out.nh_co; % molec/ cm^3
sh_co = ppb2con * out.sh_co; % molec/ cm^3
global_co = 0.5* (nh_co + sh_co); % molec/ cm^3

nh_oh = out.nh_oh; % molec/ cm^3
sh_oh = out.sh_oh; % molec/ cm^3
global_oh = 0.5* (nh_oh + sh_oh); % molec/ cm^3



[time_index, p] = size(out.nh_ch4);
nh_e_folds = zeros(size(out.nh_ch4));
sh_e_folds = zeros(size(out.nh_ch4));
global_e_folds = zeros(size(out.nh_ch4));

for t = 1:time_index
    
    nh_jacobian = zeros(3,3);
    sh_jacobian = zeros(3,3);
    global_jacobian = zeros(3,3);
    
    
    %%% Construct the jacobians according to Prather 1994
    
    nh_jacobian(1,1) = -k_ch4 * nh_oh(t);
    sh_jacobian(1,1) = -k_ch4 * sh_oh(t);
    global_jacobian(1,1) = -k_ch4 * global_oh(t);
    
    %%% the [2,1] element is 0
    
    
    nh_jacobian(3,1) = -k_ch4 * nh_ch4(t);
    sh_jacobian(3,1) = -k_ch4 * sh_ch4(t);
    global_jacobian(3,1) = -k_ch4 * global_ch4(t);
    
    % 2. Now for the CO equation
    nh_jacobian(1,2) = k_ch4 * nh_oh(t);
    sh_jacobian(1,2) = k_ch4 * sh_oh(t);
    global_jacobian(1,2) = k_ch4 * global_oh(t);
    
    nh_jacobian(2,2) = -k_co * nh_oh(t);
    sh_jacobian(2,2) = -k_co * sh_oh(t);
    global_jacobian(2,2) = -k_co * global_oh(t);
    
    nh_jacobian(3,2) = k_ch4 * nh_ch4(t) - k_co * nh_co(t);
    sh_jacobian(3,2) = k_ch4 * sh_ch4(t) - k_co * sh_co(t);
    global_jacobian(3,2) = k_ch4 * global_ch4(t) - k_co * global_co(t);
    
    % 3. The Oh reaactions, d OH / dt
    nh_jacobian(1,3) = -k_ch4 * nh_oh(t);
    sh_jacobian(1,3) = -k_ch4 * sh_oh(t);
    global_jacobian(1,3) = -k_ch4 * global_oh(t);
    
    nh_jacobian(2,3) = -k_co * nh_oh(t);
    sh_jacobian(2,3) = -k_co * sh_oh(t);
    global_jacobian(2,3) = -k_co * global_oh(t);
    
    nh_jacobian(3,3) = -k_ch4 * nh_ch4(t) - k_co * nh_co(t) - kX_NH;
    sh_jacobian(3,3) = -k_ch4 * sh_ch4(t) - k_co * sh_co(t) - kX_SH;
    global_jacobian(3,3) = -k_ch4 * global_ch4(t) - k_co * global_co(t) - kx_global;
    
    nh_jacobian = nh_jacobian';
    sh_jacobian = sh_jacobian';
    global_jacobian = global_jacobian';
    
    
    %%% Take the eigenvalues
    D_nh = eig(nh_jacobian);
    D_sh = eig(sh_jacobian);
    D_global = eig(global_jacobian);
    
    
    
    % CH4 lifetimes
    result.ch4_nh_lifetime(t) = -1/D_nh(2)/year2sec;
    result.ch4_sh_lifetime(t) = -1/D_sh(2)/year2sec;
    result.ch4_global_lifetime(t) = -1/D_global(2)/year2sec;
    result.ch4_ss(t) = -1 ./(global_jacobian(1,1)*year2sec);
    
    % CO lifetimes
    result.co_nh_lifetime(t) = -1/D_nh(3)/day2sec;
    result.co_sh_lifetime(t) = -1/D_sh(3)/day2sec;
    result.co_global_lifetime(t) = -1/D_global(3)/day2sec;
    result.co_ss(t) = -1 ./(global_jacobian(2,2)*day2sec);
    
    % OH lifetimes
    result.oh_nh_lifetime(t) = -1/D_nh(1);
    result.oh_sh_lifetime(t) = -1/D_sh(1);
    result.oh_global_lifetime(t) = -1/D_global(1);
    result.oh_ss(t) = -1 ./global_jacobian(3,3);
    
    
    
    % End of loop
end

end

%%% End of function
