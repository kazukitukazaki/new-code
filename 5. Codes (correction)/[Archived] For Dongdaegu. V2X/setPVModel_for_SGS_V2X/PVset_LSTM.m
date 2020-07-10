function target = PVset_LSTM(flag,input,shortTermPastData,path)
%% LOAD DATA
traindays=7;
if flag==1
%% devide data (train,vaild)
predata = input(end-96*traindays+1:end,:);
mu = mean(predata);
sig = std(predata); %sig= 표준편차
dataTrainStandardized = (predata - mu) ./ sig;
predictorscol=[5 7 9:11];
predictors=dataTrainStandardized(:,predictorscol);
targetdata=dataTrainStandardized(:,12);

XTrain=transpose(predictors);
YTrain= transpose(targetdata);
%% train lstm
numFeatures = 5;
numResponses = 1;
numHiddenUnits = 200;

layers = [ ...
    sequenceInputLayer(numFeatures)
    lstmLayer(numHiddenUnits)
    fullyConnectedLayer(numResponses)
    regressionLayer];

options = trainingOptions('adam', ...
    'MaxEpochs',250, ...
    'GradientThreshold',1.2, ...
    'InitialLearnRate',0.005, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',125, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);
net = trainNetwork(XTrain,YTrain,layers,options);

    %% save result mat file
    clearvars input;
    clearvars shortTermPastData dataTrainStandardized 
    building_num = num2str(predata(2,1));
    save_name = '\PV_LSTM_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name);
else
    %% load .mat file
    Forecastdata = input;
    building_num = num2str(Forecastdata(2,1));
    load_name = '\PV_LSTM_';
    load_name = strcat(path,load_name,building_num,'.mat');
    load(load_name,'-mat');
    %% forecast
    predictors =(Forecastdata(:,predictorscol)- mu(predictorscol)) ./ sig(predictorscol);
    XTest=transpose(predictors);
    net = predictAndUpdateState(net,XTrain);
    [net,YPred(:,1:96)] = predictAndUpdateState(net,XTrain(:,end-96+1:end));
    numTimeStepsTest = size(XTest,2);
    for i = 1:numTimeStepsTest
        [net,YPred(:,i+96)] = predictAndUpdateState(net,XTest(:,i),'ExecutionEnvironment','auto');
    end
    YPred = sig(12).*YPred(96+1:end) + mu(12);
    target=transpose(YPred);
end

