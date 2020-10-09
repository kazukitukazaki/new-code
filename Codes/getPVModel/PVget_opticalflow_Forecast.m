function result_opticalflow=PVget_opticalflow_Forecast(input,~,~)
    Forecastdata = input;
    [time_steps, ~]= size(Forecastdata);
    result_opticalflow=Forecastdata(1:time_steps,1);
end