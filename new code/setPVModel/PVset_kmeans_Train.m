function PVset_kmeans_Train(LongTermpastData, path)
start_kmeans_Train = tic;
%% Load data
Past_Load_dataData = LongTermpastData(:,1:13); % PastData load
%% normalize
% Data such as time, irradiation, etc. have high variance. so i normalize
max_value = max(Past_Load_dataData(:,7:12));
min_value = min(Past_Load_dataData(:,7:12));
dataTrainnormalize = (Past_Load_dataData(:,7:12) - min_value) ./ (max_value - min_value);
dataTrainnormalize = horzcat(Past_Load_dataData(:,1:6),dataTrainnormalize,Past_Load_dataData(:,13)); 
%% Correlation coefficient
predata=dataTrainnormalize;
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
past_feature_sunlight = horzcat(dataTrainnormalize(:,[3 5]), dataTrainnormalize(:,predictor_sun)); % combine 1~5 columns & 9,10 columns
past_load_sunlight = dataTrainnormalize(:,12);
% Set K for sunlight. 20 is experimentally chosen by gyeong gak. 
% originally this value is 50
k_sunlight = 30;
[idx_sunlight,c_sunlight] = kmeans(past_load_sunlight,k_sunlight); % Set index ans class value using k-means
nb_sunlight = fitcnb(past_feature_sunlight, idx_sunlight,'Distribution','kernel'); % Bayesian Classification 
%% Patterning data
% 1:Building index , 2:Date, 3:Day of Week,  4:Holiday,  5:Temparature,
%  6:Cloud, 7:Rain 8:SolarIrradiance,  9~104:Generation
Patterned_PastData = PVset_Format_Change(dataTrainnormalize);
%% Train model
Feature =horzcat(2,predictor_ger-4);
[days, ~] = size(Patterned_PastData);
k_pv = 2;
if days <= 30
    [idx_PastData,c_PastData_pv] = kmeans(Patterned_PastData(:,9:56),k_pv); % Set index ans class value using k-means
    train_feature = Patterned_PastData(:,Feature);                       % feature
    train_label = idx_PastData(:,1);                                     % class index
    nb_pv = fitcnb(train_feature,train_label,'Distribution','kernel');       % Bayesian Classification
else
            %% Divide data train, valid
            % 100% : total
        [m_raw_100_PastData, ~] = size(Patterned_PastData);
        m_raw_70_PastData = m_raw_100_PastData-48+30;                                       % gyeong gak change value
            % 70% : train, 30% : validate 
        raw_70_PastData = Patterned_PastData(1:m_raw_70_PastData,:);
        raw_30_PastData = Patterned_PastData(m_raw_70_PastData+1:end,:);
            %% validation for selecting otimal k
     for i_loop = 1:3
        eva = evalclusters(raw_70_PastData(:,9:56),'kmeans','Gap','Klist',[5:15],'B',90,'ReferenceDistribution','uniform','SearchMethod','firstMaxSE');
        k=eva.OptimalK;
            %% k-means past train data
        [idx_PastData,c_PastData] = kmeans(raw_70_PastData(:,9:56),k);
        idx_PastData_pv_array{k} = idx_PastData;
        c_PastData_pv_array{k} = c_PastData;
        train_feature = raw_70_PastData(1:end,Feature);                                    % set feature
        train_label = idx_PastData(1:end,1);                                               % class index
        nb_pv_array{k} = fitcnb(train_feature,train_label,'Distribution','kernel');        % Bayesian Classification
            %% vaild (to make err data)
        [m_raw_ForecastData, ~] = size(raw_30_PastData);
        for i = 1:m_raw_ForecastData
             test_input(i,:) = raw_30_PastData(i,Feature);                    % feature
             result_idx(i,1) = nb_pv_array{k}.predict(test_input(i,:));       % Find generation's idex using Bayesian
             result_cluster(i,:) = c_PastData(result_idx(i,:),:);             % Find generation using generation's idex
        end
         %% Calculate err data for selet optimal K
        result_cluster_array{k} = result_cluster;
        result_err_data_array{k} =  raw_30_PastData(:,9:56) - result_cluster_array{k}; % real - forecast
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
        'c_sunlight','idx_sunlight','max_value','min_value','predictor_sun');
else
    save(save_name,'nb_pv_loop','c_PastData_pv_loop','idx_PastData_loop','Feature','nb_sunlight',...
        'c_sunlight','idx_sunlight','max_value','min_value','predictor_sun');
end
end_kmeans_Train = toc(start_kmeans_Train)
end