%% Format change
% 1 colunm demand -> 96 colunm demand
function y = format_change_1(input_data)
    new_format_PastData = input_data;
    % check again the size of new_version_PastData because of copy
    [m_new_format_PastData, ~] = size(new_format_PastData);
    % Demand data
    j = 1;
    old_format_PastData = zeros(round(m_new_format_PastData/96),102);
    for i = 1:1:m_new_format_PastData
        if new_format_PastData(i,5) == 0 & new_format_PastData(i,6) == 0
            old_format_PastData(j,7 + 96) = new_format_PastData(i,12);
        else
            old_format_PastData(j,7 + (new_format_PastData(i,5)*4 + new_format_PastData(i,6))) = new_format_PastData(i,12);
        end
        if i == m_new_format_PastData
        else
            if (new_format_PastData(i,4) - new_format_PastData((i+1),4)) ~= 0
                j = j + 1;
            end
        end
    end
    % Feature data
    j = 1;
    old_format_PastData(1:end,1) = new_format_PastData(1,1);
    for i = 1:1:m_new_format_PastData
        if i == m_new_format_PastData
            old_format_PastData(j,3:7) = new_format_PastData(i,7:11);
            old_format_PastData(j,2) = new_format_PastData(i,2)*10000 + new_format_PastData(i,3)*100 + new_format_PastData(i,4);
        else
            old_format_PastData(j,3:7) = new_format_PastData(i,7:11);
            old_format_PastData(j,2) = new_format_PastData(i,2)*10000 + new_format_PastData(i,3)*100 + new_format_PastData(i,4);
                if (new_format_PastData(i,4) - new_format_PastData((i+1),4)) ~= 0
                    j = j + 1;
                end
        end
    end
    y=old_format_PastData;
 
