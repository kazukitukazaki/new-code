% Load prediction: Foecasting algorithm 
% function flag = demandForecast(shortTermPastData, ForecastData, ResultData)
%     flag =1 ; if operation is completed successfully
%     flag = -1; if operation fails.
%     This function depends on demandModel.mat. If these files are not found return -1.
%     The output of the function is "ResultData.csv"
function flag = PVget_getPVModel(ShortTermPastData, forecastData, resultdata)
    tic;    
    %% parameters
    ci_percentage = 0.05; % 0.05 = 95% it must be between 0 and 1
    %% Load data
    if strcmp(ShortTermPastData, 'NULL') == 0 || strcmp(forecastData, 'NULL') == 0 || strcmp(resultdata, 'NULL') == 0
        short_past_load = csvread(ShortTermPastData,1,0);
        predictors = csvread(forecastData,1,0);
        Resultfile = resultdata;
    else
        flag = -1;
        return
    end     
    target = csvread('TargetData.csv',1,0);   
    [row_m,~]=size(short_past_load);
    [row_i,~]=size(predictors);
    [row_k,~]=size(target);
    [row_pre,~]=size(predictors);
    for n=1:row_pre/48
        predictors([48*n-47:48*n],5)=transpose([0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13 14 14 15 15 16 16 17 17 18 18 19 19 20 20 21 21 22 22 23 23]) ;
    end
    for PV_ID=1:27
        m=1;
        i=1;
        k=1;
            for n=1:row_m
                if short_past_load(n,1)==PV_ID
                    shortTermPastData(m,:)=short_past_load(n,:);
                    m=m+1;
                end
            end
            for n=1:row_i
                if predictors(n,1)==PV_ID
                    ForecastData(i,:)=predictors(n,:);
                    i=i+1;
                end
            end   
            for n=1:row_k
                if target(n,1)==PV_ID
                    targetdata(k,:)=target(n,:);
                    k=k+1;
                end
            end 
            observed=targetdata(:,2);
            opticalflow_Forecast=targetdata(:,3);
    %% Load .mat files from given path of "shortTermPastData"
            filepath = fileparts(ShortTermPastData);
            buildingIndex = shortTermPastData(1,1);    
    %% Error recognition: Check if mat files exist
            name1 = [filepath, '\', 'PV_Model_', num2str(buildingIndex), '.mat'];
            name2 = [filepath, '\', 'PV_err_distribution_3_', num2str(buildingIndex), '.mat'];
            name3 = [filepath, '\', 'PV_err_distribution_4_', num2str(buildingIndex), '.mat'];
            name4 = [filepath, '\', 'PV_pso_coeff_', num2str(buildingIndex), '.mat'];
            name5 = [filepath, '\', 'PV_pso_coeff4_', num2str(buildingIndex), '.mat'];
            if exist(name1) == 0 || exist(name2) == 0 || exist(name3)== 0 || exist(name4)== 0 || exist(name5)== 0
                flag = -1;
                return
            end        
    %% Load mat files
            s1 = 'PV_pso_coeff_';
            s2 = 'PV_err_distribution_3_';
            s3 = num2str(buildingIndex); 
            s4 = 'PV_pso_coeff4_';
            s5 = 'PV_err_distribution_4_';
            name(1).string = strcat(s1,s3);
            name(2).string = strcat(s2,s3);
            name(3).string = strcat(s4,s3);
            name(4).string = strcat(s5,s3);
            varX(1).value = 'coeff';
            varX(2).value = 'err_distribution_3';
            varX(3).value = 'coeff4';
            varX(4).value = 'err_distribution_4';
            extention='.mat';
            for i = 1:size(varX,2)
                matname = fullfile(filepath, [name(i).string extention]);
                load(matname);
            end    
    %% Prediction for test data   
            predicted_PV(1).data = PVget_kmeans_Forecast(ForecastData, shortTermPastData, filepath);   
            predicted_PV(2).data = PVget_ANN_Forecast(ForecastData, shortTermPastData, filepath);   
            predicted_PV(3).data = PVget_LSTM_Forecast(ForecastData,shortTermPastData, filepath);   
            predicted_PV(4).data = PVget_opticalflow_Forecast(opticalflow_Forecast,shortTermPastData, filepath); 
     
%% three method
    %% Get Deterministic prediction result   
      % three method
        [~,numCols]=size(coeff(1,:));
            for hour = 1:24              
                    for i = 1:numCols % the number of prediction methods(k-means, ANN and LSTM)
                        if i == 1
                            yDetermPred3(1+(hour-1)*2:hour*2,:) = coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
                        else
                            yDetermPred3(1+(hour-1)*2:hour*2,:) = yDetermPred3(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
                        end
                    end
            end 
      %% Generate Result file    
            % Headers for output file
                    hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour','half-time' ,  'DemandMean', 'CIMin', 'CIMax', 'CILevel', 'pmfStartIndx', 'pmfStep', ...
                              'DemandpmfData1', 'DemandpmfData2', 'DemandpmfData3', 'DemandpmfData4', 'DemandpmfData5', 'DemandpmfData6' ...
                              'DemandpmfData7', 'DemandpmfData8', 'DemandpmfData9', 'DemandpmfData10'};
                    fid = fopen(Resultfile,'wt');
                    fprintf(fid,'%s,',hedder{:});
                    fprintf(fid,'\n'); 
            %% Make distribution of ensemble forecasting (three method)
                    for i = 1:size(yDetermPred3,1)
                        prob_prediction(:,i) = yDetermPred3(i)+ err_distribution_3(predictors(i,5)+1, predictors(i,6)).data;
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
                    [L_boundary_3, U_boundary_3] = PVget_ci(prob_prediction, ci_percentage); 
            % Make matrix to be written in "ResultData.csv"
                    result = [ForecastData(:,1:6) y_mean L_boundary_3 U_boundary_3 100*(1-ci_percentage)*ones(size(yDetermPred3,1),1) pmfStart pmfStep demandpmfData];
                    fprintf(fid,['%d,', '%4d,', '%02d,', '%02d,', '%02d,', '%d,', '%f,', '%f,', '%f,', '%02d,', '%f,', '%f,', repmat('%f,',1,10) '\n'], result');
                    fclose(fid);    
       %% Display graph  
        % make x timestep
                timestep=csvread(forecastData,1,4,[1,4,48,5]);
                xtime=timestep(:,1);
                max_xtime=max(xtime);
                for i=1:size(xtime,1)
                    if xtime(i) < xtime(1)
                    xtime(i)=xtime(i)+24;
                    end
                end  
                boundaries_3 =  [L_boundary_3, U_boundary_3];   
        % display graph
                Number=num2str(PV_ID);
                graphname_Combined_3=strcat('Combined the results of the three predictions ',Number);
                graphname_kmeans=strcat('k-means for forecast data ',Number);
                graphname_ANN=strcat('ANN for forecast data ',Number);
                graphname_LSTM=strcat('LSTM for forecast data ',Number);
                graphname_opticalflow=strcat('opticalflow ',Number);
                PVget_graph_desc(xtime, yDetermPred3, observed, boundaries_3, graphname_Combined_3, ci_percentage,max_xtime); % Combined 
                PVget_graph_desc(xtime, predicted_PV(1).data, observed, [], graphname_kmeans, ci_percentage,max_xtime); % k-means
                PVget_graph_desc(xtime, predicted_PV(2).data, observed, [], graphname_ANN, ci_percentage,max_xtime); % ANN
                PVget_graph_desc(xtime, predicted_PV(3).data, observed, [], graphname_LSTM, ci_percentage,max_xtime); % LSTM
                PVget_graph_desc(xtime, predicted_PV(4).data, observed, [], graphname_opticalflow, ci_percentage,max_xtime);
                
        % Cover Rate of PI (three method)
                count = 0;
                for i = 1:(size(observed,1))
                    if (L_boundary_3(i)<=observed(i)) && (observed(i)<=U_boundary_3(i))
                        count = count+1;
                    end
                end
                PICoverRate_3 = 100*count/size(observed,1); 
                
                
        % for calculate MAPE  (Mean Absolute Percentage Error)
                a=0;b=0;c=0;d=0;e=0;
                maxreal=max(observed);
                for i=1:(size(yDetermPred3,1))
                    if observed(i)~=0 && observed(i)>maxreal*0.05
                        if yDetermPred3(i) ~=0
                            MAE(i,1) = (abs(yDetermPred3(i) - observed(i))./observed(i)); % combined
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
                        if predicted_PV(4).data(i)~=0
                            MAE(i,5) = (abs(predicted_PV(4).data(i) - observed(i))./observed(i));
                            e=e+1;
                        end
                    end
                end
                
                MAPE(1)=sum(MAE(:,1))/a *100;
                MAPE(2)=sum(MAE(:,2))/b *100;
                MAPE(3)=sum(MAE(:,3))/c *100;
                MAPE(4)=sum(MAE(:,4))/d *100;
                MAPE(5)=sum(MAE(:,5))/e *100;
                
                % for calculate RMSE(Root Mean Square Error)
                data_num=size(yDetermPred3,1);
                for i=1:data_num %SE=Square Error
                    SE(i,1)= (yDetermPred3(i) - observed(i))^2;
                    SE(i,2)= (predicted_PV(1).data(i)-observed(i))^2;
                    SE(i,3)= (predicted_PV(2).data(i)-observed(i))^2;
                    SE(i,4)= (predicted_PV(3).data(i)-observed(i))^2;
                    SE(i,5)= (predicted_PV(4).data(i)-observed(i))^2;             
                end
                
                RMSE(1)=sqrt(sum(SE(:,1))/48);
                RMSE(2)=sqrt(sum(SE(:,2))/48);
                RMSE(3)=sqrt(sum(SE(:,3))/48);
                RMSE(4)=sqrt(sum(SE(:,4))/48); 
                RMSE(5)=sqrt(sum(SE(:,5))/48);
                
                disp(['PI cover rate of three method ',num2str(PICoverRate_3), '[%]/', num2str(100*(1-ci_percentage)), '[%]'])
                disp(['MAPE of combined the results of the three predictions ', num2str(MAPE(1)),'[%]','    RMSE of combine model the results of the three predictions', num2str(RMSE(1))])
                disp(['MAPE of kmeans: ', num2str(MAPE(2)),'[%]','            RMSE of kmeans: ', num2str(RMSE(2))])
                disp(['MAPE of ANN: ', num2str(MAPE(3)),'[%]','              RMSE of ANN: ', num2str(RMSE(3))])
                disp(['MAPE of LSTM: ', num2str(MAPE(4)),'[%]','             RMSE of LSTM: ', num2str(RMSE(4))])  
                disp(['MAPE of opticalflow: ', num2str(MAPE(5)),'[%]','             RMSE of opticalflow: ', num2str(RMSE(5))])
%% four method
      %% Get Deterministic prediction result                 
      % four method
            [~,numCols]=size(coeff(1,:));
            for predict_time=11:18
                for hour = 1:24
                    if hour==predict_time                       
                            for i = 1:numCols+1 
                                if i == 1
                                    yDetermPred4(1+(hour-1)*2:hour*2,:) = coeff4(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
                                else
                                    yDetermPred4(1+(hour-1)*2:hour*2,:) = yDetermPred4(1+(hour-1)*2:hour*2,:) + coeff4(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
                                end
                            end
                    else
                        for i = 1:numCols
                            if i == 1
                                yDetermPred4(1+(hour-1)*2:hour*2,:) = coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);
                            else
                                yDetermPred4(1+(hour-1)*2:hour*2,:) = yDetermPred4(1+(hour-1)*2:hour*2,:) + coeff(hour,i).*predicted_PV(i).data(1+(hour-1)*2:hour*2);  
                            end
                        end
                    end
                end                 
            %% Generate Result file    
            % Headers for output file
                    hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour','half-time' ,  'DemandMean', 'CIMin', 'CIMax', 'CILevel', 'pmfStartIndx', 'pmfStep', ...
                              'DemandpmfData1', 'DemandpmfData2', 'DemandpmfData3', 'DemandpmfData4', 'DemandpmfData5', 'DemandpmfData6' ...
                              'DemandpmfData7', 'DemandpmfData8', 'DemandpmfData9', 'DemandpmfData10'};
                    fid = fopen(Resultfile,'wt');
                    fprintf(fid,'%s,',hedder{:});
                    fprintf(fid,'\n'); 
            %% Make distribution of ensemble forecasting (four method)
                    for i = 1:size(yDetermPred4,1)
                        if i==1+(predict_time-1)*2 || i==predict_time*2
                            prob_prediction(:,i) = yDetermPred4(i)+ err_distribution_4(predictors(i,5)+1, predictors(i,6)).data;
                            prob_prediction(:,i) = max(prob_prediction(:,i), 0);    % all elements must be bigger than zero
                    % %         for debugging --------------------------------------------------------------------------
                    %                 h = histogram(prob_prediction(:,i), 'Normalization','probability');
                    %                 h.NumBins = 10;
                    % %         for debugging -------------------------------------------------------------------------------------
                            [demandpmfData(i,:), edges(i,:)] = histcounts(prob_prediction(:,i), 10, 'Normalization', 'probability');
                            pmfStart(i,:) = edges(i,1);
                            pmfStart(i,:) = max(pmfStart(i,:), 0);
                            pmfStep(i,:) =  abs(edges(i,1) - edges(i,2));
                        else
                            prob_prediction(:,i) = yDetermPred4(i)+ err_distribution_3(predictors(i,5)+1, predictors(i,6)).data;
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
                    end   
            % When the validation date is for only one day
                    if size(prob_prediction, 1) == 1    
                        prob_prediction = [prob_prediction; prob_prediction];
                    end  
            % Get mean value of Probabilistic load prediction
                    y_mean = mean(prob_prediction)';   
            % Get Confidence Interval
                    [L_boundary_4, U_boundary_4] = PVget_ci(prob_prediction, ci_percentage); 
            % Make matrix to be written in "ResultData.csv"
                    result = [ForecastData(:,1:6) y_mean L_boundary_4 U_boundary_4 100*(1-ci_percentage)*ones(size(yDetermPred3,1),1) pmfStart pmfStep demandpmfData];
                    fprintf(fid,['%d,', '%4d,', '%02d,', '%02d,', '%02d,', '%d,', '%f,', '%f,', '%f,', '%02d,', '%f,', '%f,', repmat('%f,',1,10) '\n'], result');
                    fclose(fid);                    
        %% Display graph  
        % make x timestep
                timestep=csvread(forecastData,1,4,[1,4,48,5]);
                xtime=timestep(:,1);
                max_xtime=max(xtime);
                for i=1:size(xtime,1)
                    if xtime(i) < xtime(1)
                    xtime(i)=xtime(i)+24;
                    end
                end  
                boundaries_4 =  [L_boundary_4, U_boundary_4];  
        % display graph
                Number=num2str(PV_ID);
                graphname_Combined_4=strcat('Combined the results of the four predictions',Number);
                PVget_graph_desc(xtime, yDetermPred4, observed, boundaries_4, graphname_Combined_4, ci_percentage,max_xtime); % Combined 

        % predict time 
                L_Predict_time=num2str(predict_time-1.5);
                U_Predict_time=num2str(predict_time-1);
                Xtime=(predict_time-2.5:0.5:predict_time)';
                max_xtime=predict_time;
                graphname_predict_time_3=strcat('Combined the results of the three predictions ',Number,'(predict time',L_Predict_time,'~',U_Predict_time,' ) ');
                graphname_predict_time_4=strcat('Combined the results of the four predictions ',Number,'(predict time',L_Predict_time,'~',U_Predict_time,' ) ');
                PVget_graph_desc(Xtime, yDetermPred3((predict_time-2)*2+1:(predict_time+1)*2,1), observed((predict_time-2)*2+1:(predict_time+1)*2,1), boundaries_3((predict_time-2)*2+1:(predict_time+1)*2,:), graphname_predict_time_3, ci_percentage,max_xtime); % Combined 
                PVget_graph_desc(Xtime, yDetermPred4((predict_time-2)*2+1:(predict_time+1)*2,1), observed((predict_time-2)*2+1:(predict_time+1)*2,1), boundaries_4((predict_time-2)*2+1:(predict_time+1)*2,:), graphname_predict_time_4, ci_percentage,max_xtime); % Combined
    
         % Cover Rate of PI (four method)
                count = 0;
                for i = 1:(size(observed,1))
                    if (L_boundary_4(i)<=observed(i)) && (observed(i)<=U_boundary_4(i))
                        count = count+1;
                    end
                end
                PICoverRate_4 = 100*count/size(observed,1);    

        % Cover Rate of PI (predict time 3)
                count = 0;
                for i = 1:size(Xtime,1)
                    if (L_boundary_3((predict_time-1)*2+i)<=observed(predict_time*2)) && (observed((predict_time-1)*2+i)<=U_boundary_3(predict_time*2))
                        count = count+1;
                    end
                end
                PICoverRate_3_predict_time = 100*count/size(Xtime,1); 

        % Cover Rate of PI (predict time 4)
                count = 0;
                for i = 1:size(Xtime,1)
                    if (L_boundary_4((predict_time-1)*2+i)<=observed(predict_time*2)) && (observed((predict_time-1)*2+i)<=U_boundary_4(predict_time*2))
                        count = count+1;
                    end
                end
                PICoverRate_4_predict_time = 100*count/size(Xtime,1); 

        % for calculate MAPE  (Mean Absolute Percentage Error)
                f=0;
                maxreal=max(observed);
                for i=1:size(yDetermPred4,1)
                    if observed(i)~=0 && observed(i)>maxreal*0.05                   
                        if yDetermPred4(i) ~=0
                            MAE(i,6) = (abs(yDetermPred4(i) - observed(i))./observed(i)); % combined
                            f=f+1;
                        end
                    end
                end
                g=0;h=0;
                for i=1:2
                    mae(i,1) = (abs(yDetermPred3((predict_time-1)*2+i) - observed((predict_time-1)*2+i))./observed((predict_time-1)*2+i)); 
                    mae(i,2) = (abs(yDetermPred4((predict_time-1)*2+i) - observed((predict_time-1)*2+i))./observed((predict_time-1)*2+i)); 
                    g=g+1;
                    h=h+1;
                end

                MAPE(6)=sum(MAE(:,6))/f *100;
                MAPE(7)=sum(mae(:,1))/g *100;
                MAPE(8)=sum(mae(:,2))/h *100;
        % for calculate RMSE(Root Mean Square Error)
                data_num=size(yDetermPred4,1);
                for i=1:data_num %SE=Square Error
                    SE(i,6)= (yDetermPred4(i) - observed(i))^2;            
                end

                for i=1:2
                    se(i,1)= (yDetermPred3((predict_time-1)*2+i) - observed((predict_time-1)*2+i))^2;
                    se(i,2)= (yDetermPred4((predict_time-1)*2+i) - observed((predict_time-1)*2+i))^2;
                end

                RMSE(6)=sqrt(sum(SE(:,6))/48);
                RMSE(7)=sqrt(sum(se(:,1))/2);
                RMSE(8)=sqrt(sum(se(:,2))/2);
                
                disp(['predict time',L_Predict_time,'~',U_Predict_time])
                disp(['PI cover rate of four method ',num2str(PICoverRate_4), '[%]/', num2str(100*(1-ci_percentage)), '[%]'])
                disp(['PI cover rate of three method (predict time) ',num2str(PICoverRate_3_predict_time), '[%]/', num2str(100*(1-ci_percentage)), '[%]'])
                disp(['PI cover rate of four method (predict time) ',num2str(PICoverRate_4_predict_time), '[%]/', num2str(100*(1-ci_percentage)), '[%]'])         
                disp(['MAPE of combined the results of the four predictions ', num2str(MAPE(6)),'[%]','    RMSE of combine model the results of the three predictions ', num2str(RMSE(6))])
                disp(['MAPE of combined the results of the three predictions (predict time) ', num2str(MAPE(7)),'[%]','    RMSE of combine model the results of the three predictions (predict time) ', num2str(RMSE(7))])
                disp(['MAPE of combined the results of the four predictions (predict time) ', num2str(MAPE(8)),'[%]','    RMSE of combine model the results of the four predictions (predict time)', num2str(RMSE(8))])
            
                Data=horzcat(PV_ID,predict_time-1,PICoverRate_3,PICoverRate_4,PICoverRate_3_predict_time,PICoverRate_4_predict_time,RMSE(1),RMSE(6),RMSE(2),RMSE(3),RMSE(4),RMSE(5),RMSE(7),RMSE(8));
                if predict_time==11
                    data=Data;
                else
                    data=vertcat(data,Data);
                end
            end
            
            data=array2table(data);
            data.Properties.VariableNames{'data1'} = 'ID';
            data.Properties.VariableNames{'data2'} = 'predict_time';
            data.Properties.VariableNames{'data3'} = 'PICoverRate_3';
            data.Properties.VariableNames{'data4'} = 'PICoverRate_4';
            data.Properties.VariableNames{'data5'} = 'PICoverRate_3_predict_time';
            data.Properties.VariableNames{'data6'} = 'PICoverRate_4_predict_time';
            data.Properties.VariableNames{'data7'} = 'RMSE(combined the results of the three predictions)';
            data.Properties.VariableNames{'data8'} = 'RMSE(combined the results of the four predictions)';
            data.Properties.VariableNames{'data9'} = 'RMSE(kmeans)';
            data.Properties.VariableNames{'data10'} = 'RMSE(ANN)';
            data.Properties.VariableNames{'data11'} = 'RMSE(LSTM)';
            data.Properties.VariableNames{'data12'} = 'RMSE(opticalflow)';
            data.Properties.VariableNames{'data13'} = 'RMSE(combined the three predictions (predict time))';
            data.Properties.VariableNames{'data14'} = 'RMSE(combined the four predictions (predict time))';
            savename=strcat('RMSE&CoverRate_',Number,'.csv');
            writetable(data,savename)
            
            flag = 1;
        clearvars shortTermPastData;
        clearvars ForecastData;
        clearvars observed;
        clearvars targetdata;
        clearvars opticalflow_Forecast;
        clearvars yDetermPred3;
        clearvars yDetermPred4;
        clearvars prob_prediction;
        clearvars data;
    end
    toc; 
end