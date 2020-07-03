function predictedPVGen = PVset_kmeans_Forecast(ForecastData, shortTermPastData, path)
% PV prediction: Forecast algorithm made by Seung Hyeon  
% 2019/06/25 Updated by gyeong gak (kakkyoung2@gmail.com)
% The code has been modified to match the PV forecast
% 2019/10/15 updated by gyeong gak (kakkyoung2@gmail.com)
% Add Data standardization & Forecast sunlight & chage predictor 
%% load .mat file
building_num = num2str(ForecastData(2,1));
load_name = '\PV_Model_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');

%% Standardization
% The k-means clusters data using Euclidean distance. so We have to equalize the distance between the data.
% Data such as time, irradiation, etc. have high variance. so i standardize
dataForecastStandardized = (ForecastData(:,7:11) - mean_value(1:5)) ./ sig_value(1:5);
dataForecastStandardized = horzcat(ForecastData(:,1:6),dataForecastStandardized);

%% Forecast solarlrradiance
% There is no solar irradiance data so i predict solar data using k-means
% Feature values: 1.Year 2.Month 3.Day 4.Temperature 5.Cloud
TempArray = dataForecastStandardized(~any(isnan(dataForecastStandardized),2),:);
predictorArray = horzcat(TempArray(:,[3 5]),TempArray(:,predictor_sun));        % Set feature column
predict_label_nb_sunlight = nb_sunlight.predict(predictorArray);     % Find solar's idex using Bayesian
result_nb_sunlight = c_sunlight(predict_label_nb_sunlight,:);        % Find solar irradiance using solar's idex
dataForecastStandardized = horzcat(dataForecastStandardized,result_nb_sunlight); % Make a new forecast data
ForecastData(:,12)=sig_value(6).*result_nb_sunlight + mean_value(6);       % Return standardized data back to real value.

%% Patterning ForecastData
% In PV forecast, it is much better to use patterned data
% Count day number -> (0~23: 1 day), (8~7: 2 days)
[m_ForecastData, ~]= size(dataForecastStandardized);
j = 1;k=1;
% Patterning data. (if there is two day's data in forecast data, Separate data in two rows)
for i = 1:m_ForecastData
    patterned_Forecastdata(j,1)=dataForecastStandardized(2,1);
    patterned_Forecastdata(j,3)=max(dataForecastStandardized(i,7));
    patterned_Forecastdata(j,4)=mean(dataForecastStandardized(k:i,8));
    patterned_Forecastdata(j,5)=max(dataForecastStandardized(i,9));
    patterned_Forecastdata(j,6:8)=mean(dataForecastStandardized(k:i,10:12));
    mon=(dataForecastStandardized(i,3) + round(dataForecastStandardized(i,4)/30));
    if mon >= 12 || mon < 3  %Winter
        patterned_Forecastdata(j,2) = 1;
    elseif mon >= 6 && mon<9
        patterned_Forecastdata(j,2) = 3;
    else
        patterned_Forecastdata(j,2) = 2;
    end
    if i ~= m_ForecastData && (dataForecastStandardized(i,4) - dataForecastStandardized((i+1),4)) ~= 0
        j = j + 1;
        k=i;
    end
end

%% Use k-means, bayesian for predict
[Forecastday, ~] = size(patterned_Forecastdata);
Result_idx = zeros(Forecastday,1);
Result_value = zeros(Forecastday,96);
%The k-means algorithm repeats three times because the result may vary from execution to execution.
for i_loop = 1:3
    nb_pv = nb_pv_loop{i_loop};
    c_PastData = c_PastData_pv_loop{i_loop};
    for day = 1:Forecastday
        Result_idx(day,1) = nb_pv.predict(patterned_Forecastdata(day,Feature)); % Find generation's idex using Bayesian
        Result_value(day,:) = c_PastData(Result_idx(day,:),:);                  % Find generation using generation's idex
    end
    Result_cluster{i_loop} = Result_value;
end
% Average the results and derive the final result
Result_cluster_mean = Result_cluster{1}+Result_cluster{2}+Result_cluster{3};
Result_cluster_final = Result_cluster_mean/3;

%% Make a prediction result
% Returns to the original data format.
% Generation: 8~103 colume -> 1~96 row
new_version_ResultingData(:,1:12) = ForecastData(:,1:12);
[m_ForecastData, ~]= size(ForecastData);
j = 1;
for i = 1:m_ForecastData
    if ForecastData(i,5) == 0 && ForecastData(i,6) == 0
        new_version_ResultingData(i,13) = Result_cluster_final(j,96);
    else
        new_version_ResultingData(i,13) = Result_cluster_final(j,(ForecastData(i,5)*4 + ForecastData(i,6)));
    end
    if i == k && i~=1
        j = j + 1;
    end
end
y_pv = new_version_ResultingData(1:m_ForecastData,13);
% Return standardized data back to real value.
Result_pv(:,1) =y_pv;
if exist('shortTermPastData','var')
    y_err_rate = PVset_error_correction_kmeans(shortTermPastData,path);
end
Result_pv(:,2)=Result_pv(:,1)./(1-y_err_rate');
for i=1:size(Result_pv,1)
    for j=1:size(Result_pv,2)
        if Result_pv(i,j)<0.01
            Result_pv(i,j)=0;
        end
    end
end
predictedPVGen=Result_pv(:,1);
% predictedPVGen=Result_pv(:,2);
end

