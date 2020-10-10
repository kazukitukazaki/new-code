% PV prediction: Model development algorithm 
function flag = PVset_setPVModel(LongTermPastData)
    start_all = tic;    
    %% Get file path
    path = fileparts(LongTermPastData);
    %% parameters
    ValidDays = 30; % it must be above 1 day. 3days might provide the best performance
    n_valid_data = 48*ValidDays; % 24*2*day
    %% Load data
    if strcmp(LongTermPastData,'NULL') == 0    % if the filename is not null
        longPastdata = readmatrix(LongTermPastData);
        longPastdata = longPastdata(1:end,:);
    else  % if the fine name is null
        flag = -1; 
        return
    end
    %% Devide the data into training and validation
    [row,~]=size(longPastdata);
    for PV_ID=1:27
        m=1;
            for n=1:row
                if longPastdata(n,1)==PV_ID
                    longPast(m,:)=longPastdata(n,:);
                    m=m+1;
                end
            end
                valid_data = longPast(end-n_valid_data+1:end, 1:13); 
                train_data = longPast(1:end-n_valid_data, 1:13); 
                valid_predictors = longPast(end-n_valid_data+1:end, 1:end-2);
                valid_data_opticalflow = longPast(end-n_valid_data+1:end, [1:12,14]);
    %% Train each model using past load data
                PVset_kmeans_Train(longPast, path);   
                PVset_ANN_Train(longPast, path);     
                PVset_LSTM_train(longPast, path);
    %% Validate the performance of each model
                g=waitbar(0,'PVset Forecasting(forLoop)','Name','PVset Forecasting(forLoop)');   
                for day = 1:ValidDays 
                    waitbar(day/ValidDays,g,'PVset Forecasting(forLoop)');
                    TimeIndex = size(train_data,1)+1+48*(day-1);  % Indicator of the time instance for validation data in past_load, 
                    short_past_load = longPast(TimeIndex-48*7+1:TimeIndex, 1:13); % size of short_past_load is always "672*11" for one week data set
                    short_past_load_opticalflow = longPast(TimeIndex-48*7+1:TimeIndex, [1:12,14]);
                    valid_predictor = valid_predictors(1+(day-1)*48:day*48, 1:end);  % predictor for 1 day (96 data instances)
                    valid_predictor_opticalflow = valid_data_opticalflow(1+(day-1)*48:day*48, :);
                    y_ValidEstIndv(1).data(:,day) = PVset_kmeans_Forecast(valid_predictor, short_past_load, path);
                    y_ValidEstIndv(2).data(:,day) = PVset_ANN_Forecast(valid_predictor, short_past_load, path);
                    y_ValidEstIndv(3).data(:,day) = PVset_LSTM_Forecast(valid_predictor,short_past_load, path);
                    y_ValidEstIndv(4).data(:,day) = PVset_opticalflow_Forecast(valid_predictor_opticalflow,short_past_load_opticalflow, path);
                end
                close(g)
    %% Optimize the coefficients for the additive model
                coeff = PVset_pso_main_3(y_ValidEstIndv(1:3), valid_data(:,end)); % three method 
                coeff4 = PVset_pso_main_4(y_ValidEstIndv(1:4), valid_data(:,end)); % four method
    %% Integrate individual forecasting algorithms
    % integrate into one ensemble forecasting model with optimal coefficients
                err_distribution_3 = PVset_err_distribution_3(coeff,y_ValidEstIndv(1:3),valid_data,valid_predictors,ValidDays);
                err_distribution_4 = PVset_err_distribution_4(coeff4,y_ValidEstIndv(1:4),valid_data,valid_predictors,ValidDays);
    %% Save .mat files     
                s1 = 'PV_pso_coeff_';
                s2 = 'PV_err_distribution_3_';
                s3 = num2str(longPast(1,1)); % Get building index
                s4 = 'PV_pso_coeff4_';
                s5 = 'PV_err_distribution_4_';
                name(1).string = strcat(s1,s3);
                name(2).string = strcat(s2,s3);
                name(3).string = strcat(s4,s3);
                name(4).string = strcat(s5,s3);
                varX(1).value = 'coeff';
                varX(2).value = 'err_distribution_3';
                varX(3).value = 'coeff4';
                varX(4).value = 'err_distribution_4';
                for i = 1:size(varX,2)
                    matname = fullfile(path,[name(i).string '.mat']);
                    save(matname, varX(i).value);
                end        
                flag = 1;    % Return 1 when the operation properly works
        clearvars longPast;
        clearvars valid_data;
        clearvars train_data;
        clearvars valid_predictors;
    end
    end_all = toc(start_all)
end