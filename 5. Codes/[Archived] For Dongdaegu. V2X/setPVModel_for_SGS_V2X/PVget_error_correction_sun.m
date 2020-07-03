function [result1,result2] =PVget_error_correction_sun(ForecastData_ANN,result_ForecastData_ANN_mean,shortTermPastData,path)
 % 2019/07/22  made by Gyeonggak  
  % result 1: find sunset,sunrise time and put 0 value
  % result 2: result 1+ error correction 
  % Error Correction: Create error_rate with shortterm data and reflect them in actual predicted values.
  %% 1. Find sunset,sunrise time code
  %% find sunrise,sunset time using mean of shorttermPastData
  [m_forecast,~] = size(ForecastData_ANN);
  [m_shortterm,n_shortterm]=size(shortTermPastData);
  
  days=floor(m_shortterm/m_forecast);
  sum_shortterm=zeros(m_forecast,n_shortterm);
  for day= 1:days  % sum 1day of shortterm
      sum_shortterm(1:m_forecast,:) =sum_shortterm(1:m_forecast,:) + shortTermPastData((end-m_forecast*(day)+1):(end-m_forecast*(day-1)),:);
  end
  mean_shortterm=sum_shortterm./days;
  mean_shortterm(end+1,:)=mean_shortterm(1,:);
  a=any(mean_shortterm(:,12),2);
  if sum(a)>10
      for i=1:m_forecast
          if mean_shortterm(i,12)==0 && mean_shortterm(i+1,12)~=0 && mean_shortterm(i,5) < 8
              sunrise_time=mean_shortterm(i,5:6);
          elseif mean_shortterm(i+1,12)==0 && mean_shortterm(i,12)~=0 && mean_shortterm(i,5) >=17
              sunset_time=mean_shortterm(i+1,5:6);
          end
      end
      %% fine sunrise,sunset time row
      for i=1:m_forecast
          if ForecastData_ANN(i,5:6)== sunrise_time
              rise_row=i;
          elseif  ForecastData_ANN(i,5:6) == sunset_time
              set_row=i;
          end
      end
      %% enter 0 value after sunset_time
      result1=zeros(m_forecast,1);
      for i=1:m_forecast
          if rise_row < set_row
              if i >= rise_row && i <= set_row
                  result1(i,1)=result_ForecastData_ANN_mean(i,1);
              end
          elseif rise_row > set_row
              if i >= rise_row || i <= set_row
                  result1(i,1)=result_ForecastData_ANN_mean(i,1);
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
  feature = [5 9:10];
  for i_loop = 1:3
      net_ANN = net_ANN_loop{i_loop};
      result_ForecastData_ANN_loop = zeros(m_Short,1);
      for i = 1:m_Short
          x2_ANN = transpose(shortTermPastData(i,feature));
          result_ForecastData_ANN_loop(i,:) = net_ANN(x2_ANN);
          row(i)=rem(i,96)+1;
      end
      result_ForecastData_ANN{i_loop} = result_ForecastData_ANN_loop;
  end
  result_ForecastData_ANN_premean = result_ForecastData_ANN{1}+result_ForecastData_ANN{2}+result_ForecastData_ANN{3};
  result_ForecastData_ANN_mean = result_ForecastData_ANN_premean/3;
  %% Calculate error rate
  for i=1:m_Short
      if row(i)< (rise_row) || row(i)>(set_row)
          result_ForecastData_ANN_mean(i)=0;
      end
  end
  for i=1:m_Short
      err_ShortData(i,1)=shortTermPastData(i,12) - result_ForecastData_ANN_mean(i,1);
      if shortTermPastData(i,12)==0
          err_ShortData_rate(i,1)=0;
      else
          err_ShortData_rate(i,1) = err_ShortData(i,1)./shortTermPastData(i,12);
      end
  end
  k=1;
  for i=1:m_Short
      j=rem(i,96);
      if j==0
          j=96;
      end
      result_data(j,k)=err_ShortData_rate(i);
      if j==96
          k=k+1;
      end
  end
  result_data=result_data';
  %% Calculate avg_err_rate_mean
  % delete NaN value
  for i = 1:size(result_data,1)
      result_data(isnan(result_data(:,i)),:) = [];
  end
  m_raw_ShortData_0 = sum(result_data == 0);             %count number of 0
 [m_raw_ShortData,~] = size(result_data);
  m_raw_ShortData = m_raw_ShortData - m_raw_ShortData_0; %count number of valid data
  err_ShortData_rate_sum = sum(result_data(:,:),1);      %sum of err rate
  n_zero = find(err_ShortData_rate_sum(1,:) == 0);       %count number of 0 at err_ShortData_rate_sum
  [~,M_n_zero] = size(n_zero);
  %put mean value at 0 value
  for i_n_zero = 1:M_n_zero
      m_raw_ShortData(1,n_zero(1,i_n_zero)) = 1;
  end
  avg_err_rate_mean = err_ShortData_rate_sum ./ m_raw_ShortData;
  %% final result
  result2= result1./(1-avg_err_rate_mean');
end
