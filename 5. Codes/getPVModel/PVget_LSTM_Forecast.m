function result = PVget_LSTM_Forecast(input,shorttermdata,path)
% PV prediction: LSTM Model Forecast algorithm
% 2019/10/15 Updated gyeong gak (kakkyoung2@gmail.com)
%% load .mat file
Forecastdata = input;
building_num = num2str(Forecastdata(2,1));
load_name = '\PV_LSTM_';
load_name = strcat(path,load_name,building_num,'.mat');
load(load_name,'-mat');

Forecastdata(:,5)=Forecastdata(:,5)+Forecastdata(:,6)*0.25;
%% forecast solar
data1=Forecastdata(:,predictorscol1);
predictors =(data1 - meandata(predictorscol1))./sigdata(predictorscol1);
XTest1=transpose(predictors);
solar_net = predictAndUpdateState(solar_net,XTrain1);
[solar_net,YPred_solar(:,1:96)] = predictAndUpdateState(solar_net,XTrain1(:,end-96+1:end));
numTimeStepsTest = size(XTest1,2);
for i = 1:numTimeStepsTest
    [solar_net,YPred_solar(:,i+96)] = predictAndUpdateState(solar_net,XTest1(:,i),'ExecutionEnvironment','auto');
end
Forecastdata(:,12)=YPred_solar(96+1:end)';
%% forecast pv
data2=Forecastdata(:,predictorscol2);
predictors =(data2 - meandata(predictorscol2))./sigdata(predictorscol2);
XTest2=transpose(predictors);
pv_net = predictAndUpdateState(pv_net,XTrain2);
[pv_net,YPred(:,1:96)] = predictAndUpdateState(pv_net,XTrain2(:,end-96+1:end));
numTimeStepsTest = size(XTest2,2);
for i = 1:numTimeStepsTest
    [pv_net,YPred(:,i+96)] = predictAndUpdateState(pv_net,XTest2(:,i),'ExecutionEnvironment','auto');
end
YPred = sigdata(13).*YPred(96+1:end) + meandata(13);
result_LSTM=transpose(YPred);
for i=1:size(result_LSTM,1)
    if result_LSTM(i)<0
        result_LSTM(i)=0;
    end
end
result = result_LSTM;