%% Format change
% 2019/10/15 Modified  GyeongGak Kim
% kakkyoung2@gmail.com

% 1 colunm demand -> 96 colunm demand
% year,month,day -> 2 colunm    predictor(7~12 colunm at data)-> 3~8 
% generation(13 colunm)- >9~104 sequence
function y = PVset_Format_Change(input_data)
    new_format_PastData = input_data;
    % check again the size of new_version_PastData because of copy
    [m_new_format_PastData, ~] = size(new_format_PastData);
    % Demand data
    j = 1;
    old_format_PastData = zeros(round(m_new_format_PastData/96),104);
    for i = 1:1:m_new_format_PastData
        if new_format_PastData(i,5) == 0 && new_format_PastData(i,6) == 0
            old_format_PastData(j,8 + 96) = new_format_PastData(i,13);
        else
            old_format_PastData(j,8 + (new_format_PastData(i,5)*4 + new_format_PastData(i,6))) = new_format_PastData(i,13);
        end
        if i == m_new_format_PastData
        else
            if (new_format_PastData(i,4) - new_format_PastData((i+1),4)) ~= 0
                j = j + 1;
            end
        end
    end
    % Feature data
    j = 1;k=1;
    old_format_PastData(1:end,1) = new_format_PastData(1,1);
    for i = 1:m_new_format_PastData
        old_format_PastData(j,3) = max(new_format_PastData(:,7));
        old_format_PastData(j,4) = mean(new_format_PastData(k:i,8));
        old_format_PastData(j,5) = max(new_format_PastData(:,9));
        old_format_PastData(j,6:8) = mean(new_format_PastData(k:i,10:12));
        mon=(new_format_PastData(i,3) + round(new_format_PastData(i,4)/30));
        if mon >= 12 || mon < 3  %Winter
            old_format_PastData(j,2) = 1;
        elseif mon >= 6 && mon<9 
            old_format_PastData(j,2) = 3;
        else
            old_format_PastData(j,2) = 2;
        end
        if i ~= m_new_format_PastData
            if (new_format_PastData(i,4) - new_format_PastData((i+1),4)) ~= 0
                j = j + 1;
                k=i;
            end
        end
    end
    y=old_format_PastData;
 
