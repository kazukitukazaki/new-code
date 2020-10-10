function result_opticalflow=PVset_opticalflow_Forecast(input,~,~)
    Forecastdata = input;
    [time_steps, ~]= size(Forecastdata);
    result_opticalflow=Forecastdata(1:time_steps,12);
end