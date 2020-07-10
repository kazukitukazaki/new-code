function y = err_correction_ANN(flag,input,Name,path)
% tic;

% feature
% P1(day), P2(holiday), P3(highest Temp), P4(weather)
feature = 2:10;

if flag == 1
    PastDataExcelFile = input;
   %% PastData
    % PastData load
    new_version_PastData = PastDataExcelFile;
    
    % PastData size
    [m_new_version_PastData, ~]= size(new_version_PastData);

    % if there is no 1 day past data
    if m_new_version_PastData < 96
        
        new_version_PastData(1:96,1) = new_version_PastData(1,1); % building ID
        new_version_PastData(1:96,2) = new_version_PastData(1,2);
        new_version_PastData(1:96,3) = new_version_PastData(1,3);
        new_version_PastData(1:96,4) = new_version_PastData(1,4);
        
        new_version_PastData(1:96,5) = transpose([0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 10 10 10 10 ...
            11 11 11 11 12 12 12 12 13 13 13 13 14 14 14 14 15 15 15 15 16 16 16 16 17 17 17 17 18 18 18 18 ...
            19 19 19 19 20 20 20 20 21 21 21 21 22 22 22 22 23 23 23 23 24]);
        
        new_version_PastData(1:96,6) = transpose([1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 ...
            1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0]);
        
        new_version_PastData(1:96,7) = new_version_PastData(1,7);
        new_version_PastData(1:96,8) = new_version_PastData(1,8);
        new_version_PastData(1:96,9) = new_version_PastData(1,9);
        new_version_PastData(1:96,10) = new_version_PastData(1,10);
        
        new_version_PastData(1:96,11) = mean(new_version_PastData(1:m_new_version_PastData,11)); % err

%         msgbox('Not enough data','PastData')
    end
    

   %% Train model
    % ANN
    % for train
    % make a format
    
    % if there are not enough data -> just copy
    % new format
    
    if m_new_version_PastData <= 192
        new_version_PastData_total(:,:) = new_version_PastData(:,:);
    else
        new_version_PastData_total(:,:) = new_version_PastData(:,:);
    end
    
    % make model
    [m_new_version_total,~] = size(new_version_PastData_total);
    trainDay_total = m_new_version_total;
    x_total = transpose(new_version_PastData_total(1:trainDay_total,feature)); % input(feature)
    t_total = transpose(new_version_PastData_total(1:trainDay_total,11)); % target
    
    % Create and display the network
    net_total = fitnet([20, 20, 20, 20, 5],'trainscg');
    net_total.trainParam.showWindow = false;
%     disp('Training fitnet')
    % Train the network using the data in x and t
    net_total = train(net_total,x_total,t_total);

    % PastData , Train work space data will save like .mat file
    
    clearvars input;

    building_num = num2str(PastDataExcelFile(2,1));

    save_name = '\err_correction_kmeans_bayesian_';
    save_name = strcat(path,save_name,building_num,'.mat');

    save(save_name);
        
else
        
    % file does not exist so use already created .mat
   %% load .mat file
    
   ForecastExcelFile = input;

   building_num = num2str(ForecastExcelFile(2,1));

    load_name = '\PVset_err_correction_kmeans_bayesian_';
    load_name = strcat(path,load_name,building_num,'.mat');
   
    load(load_name,'-mat');

    %% ForecastData
    
    % ForecastData load
    new_version_ForecastData = ForecastExcelFile;

    % ForecastData size
    [m_new_veresion_ForecastData, ~]= size(new_version_ForecastData);


    %% Test
    % ANN
    % for test
    % kW

    % Predict the responses using the trained network
    
    result_NN_1D_day = zeros(m_new_veresion_ForecastData,1);

    x2_total = transpose(new_version_ForecastData(1:m_new_veresion_ForecastData,feature));
    result_NN_1D_day(:,:) = net_total(x2_total);

    %%
    %  3. Create demand result excel file with the given file name

    %% ResultingData File

    % same period at ForecastData
    new_version_ResultingData(:,1:5) = new_version_ForecastData(:,1:5);

    % forecast err

    [m_new_veresion_ForecastData, ~]= size(new_version_ForecastData);
    
    new_version_ResultingData(:,7) = result_NN_1D_day;
     
    % 4. return mean forecast values arrary
    
    y = new_version_ResultingData(1:m_new_veresion_ForecastData,7);
     
%     toc

end

