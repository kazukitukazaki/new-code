% Return the boundaries of confidence interval


function [lwBound, upBound] = PVget_ci(prob_prediction, percentage)    
    % When the validation date is for only one day
    if size(prob_prediction, 1) == 1    
        prob_prediction = [prob_prediction; prob_prediction];
    end
    
    % Sort the array
    srtPred = sort(prob_prediction,1);
    size_PI = size(srtPred,1);

    lower = round(size_PI*percentage);
    upper = round(size_PI*(1-percentage));
    if lower < 1 
        lower = 1;
    elseif size_PI < lower
        lower = size_PI;
    end
   
    % boudaries must be more than zero
    srtPred = max(srtPred, 0);
    
    lwBound = srtPred(lower, :)';
    upBound = srtPred(upper, :)';
end    