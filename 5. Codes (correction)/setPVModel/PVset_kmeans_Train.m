function PVset_kmeans_Train(LongTermpastData, path)
start_kmeans_Train = tic;
% PV prediction: Model development algorithm made by Seung Hyeon  
% 2019/06/25 Updated by gyeong gak (kakkyoung2@gmail.com)
% The code has been modified to match the PV forecast
% 2019/10/15 updated by gyeong gak (kakkyoung2@gmail.com)
% Add Data standardization & Forecast sunlight & chage predictor 
%% Load data
Past_Load_dataData = LongTermpastData; % PastData load
[m_new_format_PastData, ~]= size(Past_Load_dataData);
%% Standardization
% The k-means clusters data using Euclidean distance. so We have to equalize the distance between the data.
% Data such as time, irradiation, etc. have high variance. so i standardize
mean_value = mean(Past_Load_dataData(:,7:12));
sig_value = std(Past_Load_dataData(:,7:12));
dataTrainStandardized = (Past_Load_dataData(:,7:12) - mean_value) ./ sig_value;
dataTrainStandardized = horzcat(Past_Load_dataData(:,1:6),dataTrainStandardized,Past_Load_dataData(:,13)); 
%% Correlation coefficient
predata=dataTrainStandardized;
predata( ~any(predata(:,13),2), : ) = []; 
R=corrcoef(predata(:,1:13));
k=1;m=1;
for i=1:size(R,1)
    if abs(R(end-1,i))>0.25 && i< size(R,2)-1
    predictor_sun(k)=i;
    k=k+1;
    end
    if abs(R(end,i))>0.25 && i<size(R,2)
    predictor_ger(m)=i;
    m=m+1;
    end
end
%% Kmeans clustering for forecast sunlight data
past_feature_sunlight = horzcat(dataTrainStandardized(:,[3 5]), dataTrainStandardized(:,predictor_sun)); % combine 1~5 columns & 9,10 columns
past_load_sunlight = dataTrainStandardized(:,12);
% Set K for sunlight. 20 is experimentally chosen by gyeong gak. 
% originally this value is 50
k_sunlight = 30;
[idx_sunlight,c_sunlight] = kmeans(past_load_sunlight,k_sunlight); % Set index ans class value using k-means
nb_sunlight = fitcnb(past_feature_sunlight, idx_sunlight,'Distribution','kernel'); % Bayesian Classification 
%% If there is no 1 day past data, Make clone data
if m_new_format_PastData < 96
    dataTrainStandardized(1:96,[1,3,4]) = dataTrainStandardized(1,[1,3,4]); % building ID
    dataTrainStandardized(1:96,5) = transpose([0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 10 10 10 10 ...
        11 11 11 11 12 12 12 12 13 13 13 13 14 14 14 14 15 15 15 15 16 16 16 16 17 17 17 17 18 18 18 18 ...
        19 19 19 19 20 20 20 20 21 21 21 21 22 22 22 22 23 23 23 23 0]);
    dataTrainStandardized(1:96,6) = transpose([1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 ...
        1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0]);
    dataTrainStandardized(1:96,7:12) = dataTrainStandardized(1,7:12);
    dataTrainStandardized(1:96,13) = mean(dataTrainStandardized(1:m_new_format_PastData,13)); % demand
end
%% Patterning data
% 1:Building index , 2:Date, 3:Day of Week,  4:Holiday,  5:Temparature,
%  6:Cloud, 7:Rain 8:SolarIrradiance,  9~104:Generation
Patterned_PastData = PVset_Format_Change(dataTrainStandardized);
%% Train model
Feature =horzcat(2,predictor_ger-4);
[days, ~] = size(Patterned_PastData);
eva_k_pv = evalclusters(Patterned_PastData(:,9:104),'kmeans','Gap','Klist',[7:12],'ReferenceDistribution','uniform','SearchMethod','firstMaxSE');
k_pv = eva_k_pv.OptimalK;
if days <= 30
    [idx_PastData,c_PastData_pv] = kmeans(Patterned_PastData(:,9:104),k_pv); % Set index ans class value using k-means
    train_feature = Patterned_PastData(:,Feature);                       % feature
    train_label = idx_PastData(:,1);                                     % class index
    nb_pv = fitcnb(train_feature,train_label,'Distribution','kernel');       % Bayesian Classification
else
        %% validation for selecting otimal k
     for i_loop = 1:3
            %% Divide data train, valid
            % 100% : total
        raw_100_PastData = Patterned_PastData;
        [m_raw_100_PastData, ~] = size(raw_100_PastData);
        m_raw_70_PastData = m_raw_100_PastData-96+30;                                       % gyeong gak change value
            % 70% : train, 30% : validate 
        raw_70_PastData = raw_100_PastData(1:m_raw_70_PastData,:);
        raw_30_PastData = raw_100_PastData(m_raw_70_PastData+1:end,:);
            %% validation for selecting otimal k
        eva = evalclusters(raw_70_PastData(:,9:104),'kmeans','Gap','Klist',[5:15],'B',90,'ReferenceDistribution','uniform','SearchMethod','firstMaxSE');
        k=eva.OptimalK;
            %% k-means past train data
        [idx_PastData,c_PastData] = kmeans(raw_70_PastData(:,9:104),k);
        idx_PastData_pv_array{k} = idx_PastData;
        c_PastData_pv_array{k} = c_PastData;
        train_feature = raw_70_PastData(1:end,Feature);                                    % set feature
        train_label = idx_PastData(1:end,1);                                               % class index
        nb_pv_array{k} = fitcnb(train_feature,train_label,'Distribution','kernel');        % Bayesian Classification
            %% vaild (to make err data)
        [m_raw_ForecastData, ~] = size(raw_30_PastData);
        result_idx = zeros(m_raw_ForecastData,1);                            % set 0 matrix for reduce run time
        result_cluster = zeros(m_raw_ForecastData,96);                       % set 0 matrix for reduce run time
        for i = 1:m_raw_ForecastData
             test_input(i,:) = raw_30_PastData(i,Feature);                    % feature
             result_idx(i,1) = nb_pv_array{k}.predict(test_input(i,:));       % Find generation's idex using Bayesian
             result_cluster(i,:) = c_PastData(result_idx(i,:),:);             % Find generation using generation's idex
        end
         %% Calculate err data for selet optimal K
        result_cluster_array{k} = result_cluster;
        result_err_data_array{k} =  raw_30_PastData(:,9:104) - result_cluster_array{k}; % real - forecast
        abs_err_rate_k{k} = abs(result_err_data_array{k});
        total_err(k)=sum(mean(abs_err_rate_k{k}));
        Optimal_k=find(total_err==min(total_err(k)));                  % Find optimal k which has lowest error
        %%  Train again (using optimal k model)
        nb_pv_loop{i_loop} =nb_pv_array{Optimal_k};
        c_PastData_pv_loop{i_loop} = c_PastData_pv_array{1,Optimal_k};
        idx_PastData_loop{i_loop}=idx_PastData_pv_array{Optimal_k};
    end
end
%% Save .mat file
clearvars input;
building_num = num2str(LongTermpastData(2,1));
save_name = '\PV_Model_';
save_name = strcat(path,save_name,building_num,'.mat');
if (days) < 31
    save(save_name,'nb_pv','c_PastData_pv','idx_PastData','Feature','nb_sunlight',...
        'c_sunlight','idx_sunlight','sig_value','mean_value','predictor_sun');
else
    save(save_name,'nb_pv_loop','c_PastData_pv_loop','idx_PastData_loop','Feature','nb_sunlight',...
        'c_sunlight','idx_sunlight','sig_value','mean_value','predictor_sun');
end
end_kmeans_Train = toc(start_kmeans_Train)
end