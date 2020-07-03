function PVset_LSTM_train(input,path)
% PV prediction: LSTM Model Forecast algorithm
% 2019/10/15 Updated gyeong gak (kakkyoung2@gmail.com)
%% LOAD DATA
traindays=7;
%% devide data (train,vaild)
predata = input(end-96*traindays+1:end,:);
meandata = mean(predata);
sigdata = std(predata); %sig= 표준편차
if sigdata(11)==0 % in case of rain, its valus is usually 0. so it make NAN value
    sigdata(11)=1;
end
dataTrainStandardized = (predata - meandata) ./ sigdata;
dataTrainStandardized(:,5)=dataTrainStandardized(:,5)+dataTrainStandardized(:,6)*0.25;
predata( ~any(predata(:,13),2), : ) = []; 
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
predictors1=dataTrainStandardized(:,predictorscol1);
targetdata1=dataTrainStandardized(:,12);
XTrain1=transpose(predictors1);
YTrain1= transpose(targetdata1);
%lstm
numFeatures = size(predictorscol1,2);
numResponses = 1;
numHiddenUnits1 = 100;
numHiddenUnits2 = 50;
layers = [ ...
    sequenceInputLayer(numFeatures)
    lstmLayer(numHiddenUnits1)
    lstmLayer(numHiddenUnits2)
    fullyConnectedLayer(numResponses)
    regressionLayer];

options = trainingOptions('adam', ...
    'MaxEpochs',250, ...
    'GradientThreshold',1.2, ...
    'InitialLearnRate',0.01, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',125, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);
solar_net = trainNetwork(XTrain1,YTrain1,layers,options);

%% train lstm (generation)
predictorscol2=[5 predictor_ger];
predictors2=dataTrainStandardized(:,predictorscol2);
targetdata2=dataTrainStandardized(:,13);
XTrain2=transpose(predictors2);
YTrain2= transpose(targetdata2);
%lstm
numFeatures = size(predictorscol2,2);
numResponses = 1;
numHiddenUnits1 = 100;
numHiddenUnits2 = 50;
layers = [ ...
    sequenceInputLayer(numFeatures)
    lstmLayer(numHiddenUnits1)
    lstmLayer(numHiddenUnits2)
    fullyConnectedLayer(numResponses)
    regressionLayer];

options = trainingOptions('adam', ...
    'MaxEpochs',250, ...
    'GradientThreshold',1.2, ...
    'InitialLearnRate',0.01, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',125, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);
pv_net = trainNetwork(XTrain2,YTrain2,layers,options);
    %% save result mat file
    clearvars input;
    clearvars shortTermPastData dataTrainStandardized 
    building_num = num2str(predata(2,1));
    save_name = '\PV_LSTM_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name);

end

