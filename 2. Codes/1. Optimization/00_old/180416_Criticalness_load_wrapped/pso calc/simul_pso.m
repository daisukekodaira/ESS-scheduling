% -------------------------------------------------------------------------------------------------------
%   Date: 2017/04/27
%   Project: Load leveling project 
%   Edited by: Daisuke Kodaira 
%   Input: Classified histgram load data which is obtaned by Baye's theorim(?)
%   Output: ESS operation schedule which minimizes the global criticalness
% -------------------------------------------------------------------------------------------------------

clear; close all;
tic;

%% Include modules for PSO
addpath(genpath('./pso_base'));
addpath('./custom_code');
addpath('../');
savepath;
global_var_declare; % Declare the global variables
simul_1_data_config; % Load parameters
%% Calculate ESS schedule
% PSO calculation
% "run_pso" returns optimum solutions which are given as pso_out
[raw_train_load] = load_calc(g_load_train, zeros(g_num_ESS,24));
[g_pred_min, g_pred_max] = Confd_range_af(raw_train_load, g_percent);
g_label = load_wrap(g_pred_max);

run_pso;
pso_out(size(pso_out,1)) = []; % optimized ESS schedules
pso_out_1(1,:) = pso_out(1:g_L_class);
pso_out_1(2,:) = pso_out(g_L_class+1:end);


%% Arrange the data for graph
% ESS schedule
for i = 1:g_s_period
    if g_label(1,i) == 1
        out_reshape(i,:) = pso_out_1(:,1)'; 
    elseif g_label(1,i) == 2
        out_reshape(i,:) = pso_out_1(:,2)';                 
    elseif g_label(1,i) == 3
        out_reshape(i,:) = pso_out_1(:,3)';                                 
    end
end

out_reshape = out_reshape';

% Power flow on feeder including ESS operations
[adj_train_load] = load_calc(g_load_train, out_reshape);
[valid_flow] = load_calc(g_load_test, out_reshape);

% Combied ESS schedule
for i = 1:g_num_ESS
    ESS_opt(:,i) = transpose(repelem(out_reshape(i,:),g_coef));
end

% Raw power flow without ESS operations
[raw_test_load] = distribute_sub_load(g_load_test); % ?????

%% Graph description
% ---------------------------------------------------------------------------------------
% Figure1: Result of optimized load
% 1. Test load (deterministic): to be predicted. 
% 2. Predicted load (probabilistic): Prediction is provided as PDF whose mean value is described
% 3. Optimized load (deterministic): The result for the predicted load(PDFs)
% 4. Line capacity
% 5. SOC variance
% 6. Adjusted Criticalness (training + ess_opt)
% 7. Original Criticalness (criticalness of predicted load (=training data))
% 8. Adjusted Predicted load
% 9. 
% ---------------------------------------------------------------------------------------

% 0. Select which position is needed to be shown as graph?
pos_graph = [1 0 0 0 0]; % [1 1 0] = [ture ture false].....Position 1 and 2 will be shown as graph
name = {'Substation', 'ESS#1 left', 'ESS#1 right', 'ESS#2 left', 'ESS#2 right'};

% for position = 1:g_num_ESS+3
for position = 1:g_num_ESS+3
    if pos_graph(position) == 1
        % 1. Predicted load: mean load of each time step (Take mean value of each PDF) (1*720 matrix)
        if size(g_load_train,2) == 1
            y(1).data = transpose(raw_train_load(position).data);   % load_pred in case that test is only one day
        else
            y(1).data = max(max(transpose(raw_train_load(position).data)));   % load_pred
        end
        y(1).name = 'Predicted Load (max)';   % mean of plobablistic predictions
        y(1).color = 'm';
        y(1).yaxis = 'left';
        y(1).linestyle = '-';
        y(1).descrp = [0 0]; % [1 0] = [ture false]

        % 2. Optimized load (test load data + ESS operation)
        y(2).data = transpose(valid_flow(position).data); %load_opt
        y(2).name = 'Adjusted Actual Load';
        y(2).color = 'g';
        y(2).yaxis = 'left';
        y(2).linestyle = '-';
        y(2).descrp = [0 0];

        % 3. Test load (test load data)
        y(3).data = transpose(raw_test_load(position).data);
        y(3).name = 'Actual Load';
        y(3).color = 'm';
        y(3).yaxis = 'left';
        y(3).linestyle = '-';
        y(3).descrp = [0 0];

        % 4. Line capacity
        y(4).data = g_line_capacity*ones(1,g_steps);
        y(4).name = 'Line capacity';
        y(4).color = 'r';
        y(4).yaxis = 'left';
        y(4).linestyle = '-';
        y(4).graphno = 0; % both 1 and 2
        y(4).descrp = [0 0];

        % 5. SOC
        SOC = g_initial_SOC;
        for i = 1:g_steps
                SOC(i+1,:) = SOC(i,:) + ESS_opt(i,:)/g_coef;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        SOC(1,:) = []; % erase the initial status for the graph description
        for num = 1:g_num_ESS
            y(end+1).data = transpose(100*SOC(:,num)./g_ESS_capacity(num));
            y(end).name = (['SOC ESS#',num2str(num)]);
            y(end).color = [0 0 0+0.5*(num-1)];
            y(end).yaxis = 'right';
            y(end).linestyle = '-';
            y(end).descrp = [1 1];
        end

        % 6. Original range  (training data)_before
        [orig_mn_be, orig_mx_be] = Confd_range_be(raw_train_load);
        y(end+1).data = repelem(orig_mx_be(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Predicted range';
        y(end).color = 'm';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [0 0];
        y(end+1).data = repelem(orig_mn_be(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Predicted range';
        y(end).color = 'm';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [0 0];

        % 7. Original range  (training data)_after
        [orig_mn_af, orig_mx_af] = Confd_range_af(raw_train_load,g_percent);
        y(end+1).data = repelem(orig_mx_af(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Predicted range';
        y(end).color = 'r';
        y(end).yaxis = 'left';
        y(end).linestyle = '-.';
        y(end).descrp = [1 0];
        y(end+1).data = repelem(orig_mn_af(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Predicted range';
        y(end).color = 'r';
        y(end).yaxis = 'left';
        y(end).linestyle = '-.';
        y(end).descrp = [1 0];

        % 8. Adjusted range (training data + ess operation)_before
        [adj_mn, adj_mx] = Confd_range_be(adj_train_load);   % mx has 5*24, mn has 5*24    
        y(end+1).data = repelem(adj_mx(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Adjusted predicted range';
        y(end).color = 'g';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [0 0]; 
        y(end+1).data = repelem(adj_mn(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Adjusted predicted range';
        y(end).color = 'g';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [0 0]; 

        % 9. Adjusted range (training data + ess operation)_after
        [adj_mn, adj_mx] = Confd_range_af(adj_train_load,g_percent);   % mx has 5*24, mn has 5*24    
        y(end+1).data = repelem(adj_mx(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Adjusted predicted range';
        y(end).color = 'b';
        y(end).yaxis = 'left';
        y(end).linestyle = '-.';
        y(end).descrp = [1 1]; 
        y(end+1).data = repelem(adj_mn(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Adjusted predicted range';
        y(end).color = 'b';
        y(end).yaxis = 'left';
        y(end).linestyle = '-.';
        y(end).descrp = [1 1]; 

        %------------------------------------------------------------------------------------------
        graph_desc(y, raw_train_load(position).data, adj_train_load(position).data, name(position));

        % Calculate peak
        [pred_peak, peak_hour(1)] = max(orig_mx_be(1,:));
        [adjusted_peak, peak_hour(2)] = max(adj_mx(1,:));  % peak among whole days
        % Table
        LastName = {char(strcat('Predicted load (', name(position), ')')); char(strcat('Adjusted load (', name(position), ')'))};
        Peak_at_Substation = [pred_peak peak_hour(1); adjusted_peak peak_hour(2)];
        table(Peak_at_Substation,'RowNames',LastName)

        clear y;
    end
end

% ---------------------------------------------------------------------------------------
% Figure2: Histgram of prediction in 24 hours 
% 1. Predicted load 
% -----------------------------------------------------------------------------------
% histogram_desc(g_flag_hist,raw_train_load(1).data, 'raw_train'); % disply the histogram or not. True = 1, False =0
% histogram_desc(g_flag_hist,adj_train_load(1).data, 'adj_train'); % disply the histogram or not. True = 1, False =0

% ---------------------------------------------------------------------------------------
% Figure3: Confidence interval 
% -----------------------------------------------------------------------------------
if g_flag_hist ~= 0
    CI_name_raw=strcat('PDF_raw_',num2str(g_percent),'%');
    CI_name_adj=strcat('PDF_adj_',num2str(g_percent),'%');
    histo_name_raw=strcat('histogram_raw_',num2str(g_percent),'%');
    histo_name_adj=strcat('histogram_adj_',num2str(g_percent),'%');
    CI_desc(raw_train_load(1).data, CI_name_raw, histo_name_raw, g_percent)
    CI_desc(adj_train_load(1).data, CI_name_adj, histo_name_adj, g_percent)
end
 
%% File Output
SOC = g_initial_SOC;
for i = 1:g_num_ESS
    ESS_schedule(:,i) = transpose(repelem(out_reshape(i,:),4));
    for j = 1:24*4
        SOC(j+1,i) = SOC(j,i) + ESS_schedule(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
    end
    ESS_SOC(:,i) = transpose(100*SOC(:,i)./g_ESS_capacity(i));
end

filename_w1 = 'ESS_schedule.xlsx';
xlswrite(filename_w1, ESS_schedule,1,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w1, ESS_SOC,1,'F5');        % Sheet1: Write T-node(1) original energy[wh] power consumption

filename_w2 = 'Adjusted training load.xlsx';
xlswrite(filename_w2,g_load_train,1,'B2');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w2,transpose(1:g_steps),1,'A2');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w2,adj_train_load(1).data,2,'B2');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w2,transpose(1:g_steps),2,'A2');        % Sheet1: Write T-node(1) original energy[wh] power consumption

beep;
toc;

