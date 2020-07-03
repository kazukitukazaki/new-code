function [result1,result2] =PVset_error_correction_sun(ForecastData,result_ForecastData,shortTermPastData,path)
 % 2019/07/22 Made by Gyeonggak
 % kakkyoung2@gmail.com
  % result 1: find sunset,sunrise time and put 0 value
  % result 2: result1 + error correction 
  % Error Correction: Create error_rate with shortterm data and reflect them in actual predicted values.

  % 2019/10/15 Modified by Gyeonggak
  % Change predictor & Modify error
  %% 1. Find sunset,sunrise time code
  %% find sunrise,sunset time using mean of shorttermPastData
  [m_forecast,~] = size(ForecastData);
  [m_shortterm,n_shortterm]=size(shortTermPastData);
  
  days=floor(m_shortterm/m_forecast);
  sum_shortterm=zeros(m_forecast,n_shortterm);
  for day= 1:days  % sum 1day of shortterm
      sum_shortterm(1:m_forecast,:) =sum_shortterm(1:m_forecast,:) + shortTermPastData((end-m_forecast*(day)+1):(end-m_forecast*(day-1)),:);
  end
  mean_shortterm=sum_shortterm./days;
  mean_shortterm(end+1,:)=mean_shortterm(1,:);
  a=any(mean_shortterm(:,13),2);
  if sum(a)>10
      sunrise_time=[8 0];
      sunset_time=[17 0];
      for i=1:m_forecast
          if mean_shortterm(i,13)==0 && mean_shortterm(i+1,13)~=0 && mean_shortterm(i,5) < 8
              sunrise_time(1,:)=mean_shortterm(i,5:6);
          elseif mean_shortterm(i+1,13)==0 && mean_shortterm(i,13)~=0 && mean_shortterm(i,5) >=17
              sunset_time(1,:)=mean_shortterm(i+1,5:6);
          end
      end
      sunrise_time=floor(sunrise_time);
      sunset_time=floor(sunset_time);
      sunrise_time(2,:)=sunrise_time(1,:);
      sunset_time(2,:)=sunset_time(1,:);
      if sunrise_time(1,2)==3
          sunrise_time(2,2)=sunrise_time(1,2)-1;
      else
          sunrise_time(2,2)=sunrise_time(1,2)+1;
      end
      if sunset_time(1,2)==3
          sunset_time(2,2)=sunset_time(1,2)-1;
      else
          sunset_time(2,2)=sunset_time(1,2)+1;
      end
      %% fine sunrise,sunset time row
      for i=1:m_forecast
          for j=1:2
              if ForecastData(i,5:6)== sunrise_time(j,:)
                  rise_row=i;
              elseif  ForecastData(i,5:6) == sunset_time(j,:)
                  set_row=i;
              end
          end
      end
      %% enter 0 value after sunset_time
      result1=zeros(m_forecast,1);
      for i=1:m_forecast
          if rise_row < set_row
              if i >= rise_row && i <= set_row
                  result1(i,1)=result_ForecastData(i,1);
              end
          elseif rise_row > set_row
              if i >= rise_row || i <= set_row
                  result1(i,1)=result_ForecastData(i,1);
              end
          end
      end
  end
  %% 2. error correction code
  %% load .mat file
  [m_Short,~] = size(shortTermPastData);
  building_num = num2str(shortTermPastData(2,1));
  load_name = '\PV_fitnet_ANN_';
  load_name = strcat(path,load_name,building_num,'.mat');
  load(load_name,'-mat');
  %% Find forecast result Using ANN
  len=[1:96];
  row=[len len len len len len len ];
  for i_loop = 1:3
      net_PV_ANN = net_PV_ANN_loop{i_loop};
      result_PV_ANN_loop = zeros(m_Short,1);
      for i = 1:m_Short
          x2_ANN = transpose(shortTermPastData(i,feature2));
          result_PV_ANN_loop(i,:) = net_PV_ANN(x2_ANN);
      end
      result_PV_ANN{i_loop} = result_PV_ANN_loop;
  end
  result_PV_ANN_premean = result_PV_ANN{1}+result_PV_ANN{2}+result_PV_ANN{3};
  result_ForecastData = result_PV_ANN_premean/3;
  %% Calculate error rate
  for i=1:m_Short
      if rise_row<set_row
          if row(i)< (rise_row) || row(i)>(set_row)
              result_ForecastData(i)=0;
          end
      elseif rise_row>set_row
          if row(i)< (rise_row) && row(i)>(set_row)
              result_ForecastData(i)=0;
          end
      end
  end
  for i=1:m_Short
      err_ShortData(i,1)=shortTermPastData(i,13) - result_ForecastData(i,1);
      if shortTermPastData(i,13)==0
          err_ShortData_rate(i,1)=0;
      else
          err_ShortData_rate(i,1) = err_ShortData(i,1)./shortTermPastData(i,13);
      end
  end
  k=1;
  for i=1:m_Short
      result_err_data(row(i),k)=err_ShortData_rate(i);
      if row(i)==96
          k=k+1;
      end
  end
  result_err_data=result_err_data';
  %% Calculate avg_err_rate_mean
  % delete NaN value
  for i = 1:size(result_err_data,1)
      result_err_data(isnan(result_err_data(:,i)),:) = [];
  end
  m_raw_ShortData_0 = sum(result_err_data == 0);             %count number of 0
 [m_raw_ShortData,~] = size(result_err_data);
  num_vaild_data = m_raw_ShortData - m_raw_ShortData_0; %count number of valid data
  err_ShortData_rate_sum = sum(result_err_data(:,:),1);      %sum of err rate
  n_zero = find(err_ShortData_rate_sum(1,:) == 0);       %find row of 0 at err_ShortData_rate_sum
  [~,M_n_zero] = size(n_zero);
  %put mean value at 0 value
%      for i_n_zero = 1:M_n_zero
%           num_vaild_data(1,n_zero(1,i_n_zero)) = 1;
%      enddgh
avg_err_rate_mean=zeros(m_forecast,1);
for i=1:m_forecast
    if num_vaild_data(i)~=0
        avg_err_rate_mean(i,1) = err_ShortData_rate_sum(1,i) ./ num_vaild_data(i);
    end
end
  %% final result
  result2= result1.*(1+avg_err_rate_mean);
end
