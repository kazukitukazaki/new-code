% ---------------------------------------------------------------------------
% Load prediction: Foecasting algorithm 
% 2019/01/15 Updated Daisuke Kodaira 
% daisuke.kodaira03@gmail.com
%
% 2019/10/15 Modified  GyeongGak Kim
% kakkyoung2@gmail.com

% function flag = demandForecast(shortTermPastData, ForecastData, ResultData)
%     flag =1 ; if operation is completed successfully
%     flag = -1; if operation fails.
%     This function depends on demandModel.mat. If these files are not found return -1.
%     The output of the function is "ResultData.csv"
% ----------------------------------------------------------------------------

function flag = PVget_getPVModel(shortTermPastData, ForecastData, ResultData)
    f=waitbar(0,'PVget getPVModel Start','Name','PVget getPVModel');   
    tic;    
    %% parameters
    ci_percentage = 0.05; % 0.05 = 95% it must be between 0 and 1
    %% Load data
    if strcmp(shortTermPastData, 'NULL') == 0 || strcmp(ForecastData, 'NULL') == 0 || strcmp(ResultData, 'NULL') == 0
        short_past_load = csvread(shortTermPastData,1,0);
        predictors = csvread(ForecastData,1,0);
        Resultfile = ResultData;
    else
        flag = -1;
        return
    end       
    %% Load .mat files from given path of "shortTermPastData"
    filepath = fileparts(shortTermPastData);
    buildingIndex = short_past_load(1,1);    
    %% Error recognition: Check if mat files exist
    name1 = [filepath, '\', 'PV_Model_', num2str(buildingIndex), '.mat'];
    name2 = [filepath, '\', 'PV_err_distribution_', num2str(buildingIndex), '.mat'];
    name3 = [filepath, '\', 'PV_pso_coeff_', num2str(buildingIndex), '.mat'];
    if exist(name1) == 0 || exist(name2) == 0 || exist(name3)== 0
        flag = -1;
        return
    end        
    %% Load mat files
    s1 = 'PV_pso_coeff_';
    s2 = 'PV_err_distribution_';
    s3 = num2str(buildingIndex); 
    name(1).string = strcat(s1,s3);
    name(2).string = strcat(s2,s3);
    varX(1).value = 'coeff';
    varX(2).value = 'err_distribution';
    extention='.mat';
    for i = 1:size(varX,2)
        matname = fullfile(filepath, [name(i).string extention]);
        load(matname);
    end    
    %% Prediction for test data   
    waitbar(.1,f,'PVget kmeans Forecast');
    predicted_PV(1).data = PVget_kmeans_Forecast(predictors, short_past_load, filepath);
    
    waitbar(.25,f,'PVget ANN Forecast');
    predicted_PV(2).data = PVget_ANN_Forecast(predictors, short_past_load, filepath);
    
    waitbar(.40,f,' PVget LSTM Forecast');
    predicted_PV(3).data = PVget_LSTM_Forecast(predictors,short_past_load, filepath);   
    %% Get Deterministic prediction result   
    waitbar(.55,f,'waiting');    
    for hour = 1:24
        for i = 1:size(coeff(1).data,1) % the number of prediction methods(k-means, ANN and LSTM)
            if i == 1
                yDetermPred(1+(hour-1)*4:hour*4,:) = coeff(hour).data(i).*predicted_PV(i).data(1+(hour-1)*4:hour*4);
            else
                yDetermPred(1+(hour-1)*4:hour*4,:) = yDetermPred(1+(hour-1)*4:hour*4,:) + coeff(hour).data(i).*predicted_PV(i).data(1+(hour-1)*4:hour*4);  
            end
        end 
    end    
    
    %% Generate Result file    
    % Headers for output file
    hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour', 'Quarter', 'DemandMean', 'CIMin', 'CIMax', 'CILevel', 'pmfStartIndx', 'pmfStep', ...
                      'DemandpmfData1', 'DemandpmfData2', 'DemandpmfData3', 'DemandpmfData4', 'DemandpmfData5', 'DemandpmfData6' ...
                      'DemandpmfData7', 'DemandpmfData8', 'DemandpmfData9', 'DemandpmfData10'};
    fid = fopen(Resultfile,'wt');
    fprintf(fid,'%s,',hedder{:});
    fprintf(fid,'\n');
    %% Make distribution of ensemble forecasting
    for i = 1:size(yDetermPred,1)
        prob_prediction(:,i) = yDetermPred(i) + err_distribution(predictors(i,5)+1, predictors(i,6)+1).data;
        prob_prediction(:,i) = max(prob_prediction(:,i), 0);    % all elements must be bigger than zero
        % %         for debugging --------------------------------------------------------------------------
        %                 h = histogram(prob_prediction(:,i), 'Normalization','probability');
        %                 h.NumBins = 10;
        % %         for debugging -------------------------------------------------------------------------------------
        [demandpmfData(i,:), edges(i,:)] = histcounts(prob_prediction(:,i), 10, 'Normalization', 'probability');
        pmfStart(i,:) = edges(i,1);
        pmfStart(i,:) = max(pmfStart(i,:), 0);
        pmfStep(i,:) =  abs(edges(i,1) - edges(i,2));
    end   
    % When the validation date is for only one day
    if size(prob_prediction, 1) == 1    
        prob_prediction = [prob_prediction; prob_prediction];
    end  
    % Get mean value of Probabilistic load prediction
    y_mean = mean(prob_prediction)';   
    % Get Confidence Interval
    [L_boundary, U_boundary] = PVget_ci(prob_prediction, ci_percentage); 
    % Make matrix to be written in "ResultData.csv"
    result = [predictors(:,1:6) y_mean L_boundary U_boundary 100*(1-ci_percentage)*ones(size(yDetermPred,1),1) pmfStart pmfStep demandpmfData];
    fprintf(fid,['%d,', '%4d,', '%02d,', '%02d,', '%02d,', '%d,', '%f,', '%f,', '%f,', '%02d,', '%f,', '%f,', repmat('%f,',1,10) '\n'], result');
    fclose(fid);
    % for debugging --------------------------------------------------------
    %% Display graph  
    waitbar(.70,f,'Display graph'); 
    % make x timestep
    timestep=csvread(ForecastData,1,4,[1,4,96,5]);
    xtime=timestep(:,1)+0.25*timestep(:,2);
    max_xtime=max(xtime);
    for i=1:size(xtime,1)
        if xtime(i) < xtime(1)
           xtime(i)=xtime(i)+24;
        end
    end
    observed = csvread('target_test.csv');
    boundaries =  [L_boundary, U_boundary];   
    % display graph
    PVget_graph_desc(xtime, yDetermPred, observed, boundaries, 'Combined for forecast data', ci_percentage,max_xtime); % Combined
    PVget_graph_desc(xtime, predicted_PV(1).data, observed, [], 'k-means for forecast data', ci_percentage,max_xtime); % k-means
    PVget_graph_desc(xtime, predicted_PV(2).data, observed, [], 'ANN for forecast data', ci_percentage,max_xtime); % ANN
    PVget_graph_desc(xtime, predicted_PV(3).data, observed, [], 'LSTM for forecast data', ci_percentage,max_xtime); % LSTM
    % Cover Rate of PI
    count = 0;
    for i = 1:(size(observed,1))
        if (L_boundary(i)<=observed(i)) && (observed(i)<=U_boundary(i))
            count = count+1;
        end
    end
    a=0;b=0;c=0;d=0;
    PICoverRate = 100*count/size(observed,1);
    % for calculate MAPE  (Mean Absolute Percentage Error)
    maxreal=max(observed);
    for i=1:size(yDetermPred,1)
        if observed(i)~=0 && observed(i)>maxreal*0.05
            if yDetermPred(i) ~=0
                MAE(i,1) = (abs(yDetermPred(i) - observed(i))./observed(i)); % combined
                a=a+1;
            end
            if predicted_PV(1).data(i)~=0
                MAE(i,2) = (abs(predicted_PV(1).data(i) - observed(i))./observed(i));
                b=b+1;
            end
            if predicted_PV(2).data(i)~=0
                MAE(i,3) = (abs(predicted_PV(2).data(i) - observed(i))./observed(i));
                c=c+1;
            end
            if predicted_PV(3).data(i)~=0
                MAE(i,4) = (abs(predicted_PV(3).data(i) - observed(i))./observed(i));
                d=d+1;
            end
        end
    end
    MAPE(1)=sum(MAE(:,1))/a *100;
    MAPE(2)=sum(MAE(:,2))/b *100;
    MAPE(3)=sum(MAE(:,3))/c *100;
    MAPE(4)=sum(MAE(:,4))/d *100;
    % for calculate RMSE(Root Mean Square Error)
    data_num=size(yDetermPred,1);
    for i=1:data_num %SE=Square Error
        SE(i,1)= (yDetermPred(i) - observed(i))^2;
        SE(i,2)= (predicted_PV(1).data(i)-observed(i))^2;
        SE(i,3)= (predicted_PV(2).data(i)-observed(i))^2;
        SE(i,4)= (predicted_PV(3).data(i)-observed(i))^2;
    end
    RMSE(1)=sqrt(sum(SE(:,1))/96);
    RMSE(2)=sqrt(sum(SE(:,2))/96);
    RMSE(3)=sqrt(sum(SE(:,3))/96);
    RMSE(4)=sqrt(sum(SE(:,4))/96); 
    disp(['PI cover rate is ',num2str(PICoverRate), '[%]/', num2str(100*(1-ci_percentage)), '[%]'])
    disp(['MAPE of combine model: ', num2str(MAPE(1)),'[%]','    RMSE of combine model: ', num2str(RMSE(1))])
    disp(['MAPE of kmeans: ', num2str(MAPE(2)),'[%]','            RMSE of kmeans: ', num2str(RMSE(2))])
    disp(['MAPE of ANN: ', num2str(MAPE(3)),'[%]','              RMSE of ANN: ', num2str(RMSE(3))])
    disp(['MAPE of LSTM: ', num2str(MAPE(4)),'[%]','             RMSE of LSTM: ', num2str(RMSE(4))])  
   % for debugging ---------------------------------------------------------------------  
    flag = 1;
    toc; 
    waitbar(1,f,'finish');
    close(f)
end
