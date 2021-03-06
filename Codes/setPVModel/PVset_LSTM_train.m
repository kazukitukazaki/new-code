function PVset_LSTM_train(input,path)
start_LSTM_train = tic;
% PV prediction: LSTM Model Forecast algorithm
%% LOAD DATA
traindays=31;
%% devide data (train,vaild)
predata = input(end-48*traindays+1:end,1:13);
meandata = mean(predata);
sigdata = std(predata); 
if sigdata(11)==0 % in case of rain, its valus is usually 0. so it make NAN value
    sigdata(11)=1;
end
dataTrainStandardized = (predata - meandata) ./ sigdata;
R=corrcoef(predata(:,:));
k=1;m=1;
for i=1:size(R,1)
    if abs(R(end-1,i))>0.25 && i< size(R,2)-1
    predictor_sun(k)=i;
    k=k+1;
    end
    if abs(R(end,i))>0.25 && i<size(R,2)
    predictor_ger(m)=i;
    m=m+1;
    end
end
%% train lstm (solar)
predictorscol1=[5 predictor_sun];
XTrain1=(dataTrainStandardized(:,predictorscol1))';
YTrain1=(dataTrainStandardized(:,12))';
%lstm
numFeatures = size(predictorscol1,2);
numResponses = 1;
numHiddenUnits1 = 100;
numHiddenUnits2 = 50;
numHiddenUnits3 = 25;
layers = [ ...
    sequenceInputLayer(numFeatures) 
    reluLayer
    lstmLayer(numHiddenUnits1)   
    reluLayer
    lstmLayer(numHiddenUnits2)    
    reluLayer
    lstmLayer(numHiddenUnits3)    
    reluLayer
    fullyConnectedLayer(numResponses)
    regressionLayer];
options = trainingOptions('adam', ...
    'MaxEpochs',300, ...
    'GradientThreshold',1.2, ...
    'InitialLearnRate',0.01, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',125, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);
solar_net = trainNetwork(XTrain1,YTrain1,layers,options);
%% train lstm (generation)
predictorscol2=[5 predictor_ger];
XTrain2=(dataTrainStandardized(:,predictorscol2))';
YTrain2=(dataTrainStandardized(:,13))';
%lstm
numFeatures = size(predictorscol2,2);
layers = [ ...
    sequenceInputLayer(numFeatures)
    reluLayer
    lstmLayer(numHiddenUnits1)
    reluLayer
    lstmLayer(numHiddenUnits2)
    reluLayer
    lstmLayer(numHiddenUnits3)    
    reluLayer
    fullyConnectedLayer(numResponses)
    regressionLayer];
pv_net = trainNetwork(XTrain2,YTrain2,layers,options);
    %% save result mat file
    clearvars input;
    clearvars shortTermPastData dataTrainnormalize
    building_num = num2str(predata(2,1));
    save_name = '\PV_LSTM_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name);
    end_LSTM_train = toc(start_LSTM_train)
end