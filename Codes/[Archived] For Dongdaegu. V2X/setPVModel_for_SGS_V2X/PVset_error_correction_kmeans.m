function y = PVset_error_correction_kmeans(shortTermPastData,path)
% Seung Hyeon made this code first 
% 2019/07/22 Gyeonggak modified it to fit the PV code
% This code uses shortterm data to calculate the average error rate and reflects the error rate to the actual predicted value.
% Feture: P1(dayoftype), P2(holiday), P3(highest Temp), P4(weather), P5(solarirradiation)
feature = [3:7];
%% load .mat file
[m_Short,~] = size(shortTermPastData);
building_num = num2str(shortTermPastData(2,1));
load_name = '\PV_Model_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');
%% Patterning and Standardization
ShortData(:,1:6)=shortTermPastData(:,1:6);
ShortData(:,7:12) = (shortTermPastData(:,7:12)-mean_value)./sig_value;
old_format_ShortData = PVset_Format_Change(ShortData);
raw_ShortData = old_format_ShortData;
[m_raw_ShortData, ~] = size(old_format_ShortData);
%% Finde forecast result Using K-means, Bayesian 
% same method with PVget_Kmeans_Forecast
Result_idx = zeros(m_raw_ShortData,1);
Result_value = zeros(m_raw_ShortData,96);
for i_loop = 1:3
    nb_pv = nb_pv_loop{i_loop};
    c_PastData_pv = c_PastData_pv_loop{i_loop};
    for i_forecast = 1:m_raw_ShortData
        input_kmeans(i_forecast,:) = raw_ShortData(i_forecast,feature); % feature
        Result_idx(i_forecast,1) = nb_pv.predict(input_kmeans(i_forecast,:));
        Result_value(i_forecast,:) = c_PastData_pv(Result_idx(i_forecast,:),:);
    end
    result_cluster{i_loop} = Result_value;
end
result_cluster_sum = result_cluster{1}+result_cluster{2}+result_cluster{3};
result_cluster_mean = result_cluster_sum/3;
%% Return the standardized data and Calculate error rate
result_cluster_mean_ori=result_cluster_mean*sig_value(6)+mean_value(6);
real_demand = old_format_ShortData(:,8:103)*sig_value(6)+mean_value(6);
% Since sig(+mean) of longtum and shorttom are different,
% there is a nonzero value at night. So if the values are less than 0.01, you need to make them zero.
% that value is never big 
for i=1:m_raw_ShortData
    for j=1:size(real_demand,2)
        if result_cluster_mean_ori(i,j)<0.01
            result_cluster_mean_ori(i,j)=0;
        end
        err_ShortData(i,j)=real_demand(i,j) - result_cluster_mean_ori(i,j); 
        if real_demand(i,j)==0
            err_ShortData_rate(i,j)=0;
        else
            err_ShortData_rate(i,j) = err_ShortData(i,j)./real_demand(i,j);
        end
    end
end
% %% bias detect (??, i don't know this code) 
% bias_detection = zeros(1,24);
% if (ShortData(end,5)*4 + ShortData(end,6)) < 24
%     if m_Short < 96*3
%         bias_detection(1,1:(ShortData(end,5)*4 + ShortData(end,6))) = err_ShortData_rate(end,1:(ShortData(end,5)*4 + ShortData(end,6)));
%     else
%         bias_detection(1,(ShortData(end,5)*4 + ShortData(end,6))+1:24) = err_ShortData_rate(end-1,(ShortData(end,5)*4 + ShortData(end,6))+1:24); 
%         bias_detection(1,1:(ShortData(end,5)*4 + ShortData(end,6))) = err_ShortData_rate(end,1:(ShortData(end,5)*4 + ShortData(end,6))); 
%     end
% else
%     bias_detection(1,1:96) = err_ShortData_rate(end,1:end); 
% end
% 
% bias_detection = bias_detection + 0.0001;
% bias_detection_sign = 1;
% for i = 1:96
%     bias_detection_sign = bias_detection_sign * bias_detection(1,i);
% end
% for delete_detection_i = 1:96
%     bias_detection(isnan(bias_detection(1,delete_detection_i)),:) = [];
% end
% if bias_detection_sign > 0
%     bias_err_rate_mean(1,1:96) = sum(bias_detection) / (96 - sum(bias_detection == 0));
% end
%% Calculate avg_err_rate_mean 
% delete NaN value
for delete_i = 1:96
    err_ShortData_rate(isnan(err_ShortData_rate(:,delete_i)),:) = [];
end
m_raw_ShortData_0 = sum(err_ShortData_rate == 0);        %count number of 0
[m_raw_ShortData,~] = size(err_ShortData_rate);
m_raw_ShortData = m_raw_ShortData - m_raw_ShortData_0;   %count number of valid data
err_ShortData_rate_sum = sum(err_ShortData_rate(:,:),1); %sum of err rate
n_zero = find(err_ShortData_rate_sum(1,:) == 0);         %count number of 0 at err_ShortData_rate_sum
[~,M_n_zero] = size(n_zero);
for i_n_zero = 1:M_n_zero                                %put 1 at 0 value because 0/1 =0, 0/0= Make error
    m_raw_ShortData(1,n_zero(1,i_n_zero)) = 1;
end
avg_err_rate_mean = err_ShortData_rate_sum ./ m_raw_ShortData;

%% calculate result
% err compare % i don't know this code
% if bias_detection_sign > 0
%     err_trend_mean = mean(bias_err_rate_mean) - mean(avg_err_rate_mean);
%     if sign(mean(bias_err_rate_mean)) == sign(err_trend_mean)
%         y = bias_err_rate_mean;
%     else
%         y = avg_err_rate_mean;
%     end
% else
%     y = avg_err_rate_mean;
% end
    y = avg_err_rate_mean;
end

