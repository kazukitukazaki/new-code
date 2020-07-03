% -----------------------------------------------------------------
% This function is only for debugging
% -------------------------------------------------------------------

function PVget_graph_desc(x, y_pred, y_true, boundaries, name, ci_percentage,max_xtime)     
    %% CHANGE hour and value
    %     if you want see  0 to 23 graph 
    t=0;   
    for i=1:size(x,1)
           t=t+1;
           if x(i) == max_xtime 
               set_point=t;           
           end
    end
    x1=zeros(size(x)); % chage x of form (0~23 hour)
    x1(end-set_point+1:end,1)=x(1:set_point);
    x1(1:end-set_point,1)=x(set_point+1:end); 
    y_pred1=zeros(size(y_pred));% chage y_pred of form (0~23 hour)
    y_pred1(end-set_point+1:end,1)=y_pred(1:set_point);
    y_pred1(1:end-set_point,1)=y_pred(set_point+1:end);
    y_true1=zeros(size(y_true));
    y_true1(end-set_point+1:end,1)=y_true(1:set_point);
    y_true1(1:end-set_point,1)=y_true(set_point+1:end);% chage y_true of form (0~23 hour)
    
    %% Graph description for prediction result 
    f = figure;
    hold on;
    plot(x, y_pred,'g');
    if isempty(y_true) == 0
        plot(x, y_true,'r');
    else
        plot(zeros(x,1));
    end
    if isempty(boundaries) == 0
        boundaries1=zeros(size(boundaries));
        boundaries1(end-set_point+1:end)=boundaries(1:set_point);
        boundaries1(1:end-set_point)=boundaries(set_point+1:end);% chage boundaries of form (0~23 hour)
        plot(x,boundaries(:,1),'b--');
        plot(x,boundaries(:,2),'b--');
    end
    CI = 100*(1-ci_percentage);
    xlabel('Time [h]');
    ylabel('Generation [MW]');
    title(name);
    legend('predicted Load', 'True', [num2str(CI) '% Prediction Interval']);


end