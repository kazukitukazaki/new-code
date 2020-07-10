function target = PVset_ANN_Train(LongTermpastData,path)
    %% set featur
    % P1(hour), P2(temp), P3(cloud), 
    sub_feature1 = 5;
    sub_feature2 = 9:10;
    feature = horzcat(sub_feature1,sub_feature2);
    %% PastData
    PastData_ANN = LongTermpastData(1:(end-96*7),:);    % PastData load
    PastData_ANN(~any(PastData_ANN(:,12),2),:) = [];         % if there is 0 value in generation column -> delete
    [m_PastData_ANN, ~] = size(PastData_ANN);
    %% Train model
    for i_loop = 1:1:3
        trainDay_ANN =m_PastData_ANN;
        x_PV_ANN = transpose(PastData_ANN(1:trainDay_ANN,feature)); % input(feature)
        t_PV_ANN = transpose(PastData_ANN(1:trainDay_ANN,12)); % target
        % Create and display the network
        net_ANN = fitnet([20,20,20,20,5],'trainscg');
        net_ANN.trainParam.showWindow = false;
        net_ANN = train(net_ANN,x_PV_ANN,t_PV_ANN); % Train the network using the data in x and t
        net_ANN_loop{i_loop} = net_ANN;             % save result 
    end
    %% save result mat file
    clearvars input;
    clearvars shortTermPastData;
    building_num = num2str(LongTermpastData(2,1));
    save_name = '\PV_fitnet_ANN_';
    save_name = strcat(path,save_name,building_num,'.mat');
    clearvars path;
    save(save_name,'net_ANN_loop','feature');
end
