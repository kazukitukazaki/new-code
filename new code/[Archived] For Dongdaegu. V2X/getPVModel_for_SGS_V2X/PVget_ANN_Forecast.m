function target = PVget_ANN_Forecast(predictors,shortTermPastData,path)    
    %% set featur
    % P1(hour), P2(temp), P3(cloud), P4(solar)
    sub_feature1 = 5;
    sub_feature2 = 9:10;
    feature = horzcat(sub_feature1,sub_feature2);

    % file does not exist so use already created .mat
    %% load .mat file
    building_num = num2str(predictors(2,1));
    load_name = '\PV_fitnet_ANN_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');
    %% ForecastData
    predictors( ~any(predictors,2), : ) = []; 
    [time_steps, ~]= size(predictors);
    %% Test using forecast data
    % use ANN 3 times for reduce ANN's error
    for i_loop = 1:3
        net_ANN = net_ANN_loop{i_loop};
        result_ForecastData_ANN_loop = zeros(time_steps,1);
        for i = 1:time_steps
                x2_ANN = transpose(predictors(i,feature));
                result_ForecastData_ANN_loop(i,:) = net_ANN(x2_ANN);
        end
        result_ForecastData_ANN{i_loop} = result_ForecastData_ANN_loop;
    end
    result_ForecastData_ANN_premean = result_ForecastData_ANN{1}+result_ForecastData_ANN{2}+result_ForecastData_ANN{3};
    result_ForecastData_ANN_mean = result_ForecastData_ANN_premean/3;
    [result1,result2] = PVget_error_correction_sun(predictors,result_ForecastData_ANN_mean,shortTermPastData,path);
    %% ResultingData File
    ResultingData_ANN(:,1:10) = predictors(:,1:10);
    ResultingData_ANN(:,12) = result2;
    target = ResultingData_ANN(1:time_steps,12);
end