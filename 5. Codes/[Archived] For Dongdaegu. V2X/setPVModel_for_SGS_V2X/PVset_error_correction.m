function target =PVset_error_correction(ForecastData_ANN,result_ForecastData_ANN_mean,shortTermPastData)
% if the time is not sunrise~sunset, enter 0 value
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
        target=zeros(m_forecast,1);
        for i=1:m_forecast
            if rise_row < set_row
                if i >= rise_row && i <= set_row 
                    target(i,1)=result_ForecastData_ANN_mean(i,1);
                end
            elseif rise_row > set_row
                if i >= rise_row || i <= set_row
                    target(i,1)=result_ForecastData_ANN_mean(i,1);
                end
            end
        end
    end
end

