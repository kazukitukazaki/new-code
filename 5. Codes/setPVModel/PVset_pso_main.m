% ----------------------------------------------------------
% y_ture: True load [MW]
% y_predict: predicted load [MW]
%-----------------------------------------------------------

function coeff = PVset_pso_main(y_predict, y_true)

    % Declare the global variables
    PVset_global_var_declare;

    % Initialization
    methods = size(y_predict, 2);
    days = size(y_predict(1).data,2);
    
    % Restructure the predicted data
    for j = 1:methods % the number of prediction methods (k-means and fitnet)
        for hour = 1:24
            yPredict(hour).data(:,j) = reshape(y_predict(j).data(1+(hour-1)*4:hour*4,:), [],1); % this global variable is utilized in 'objective_func'
        end
    end
    
   % Restructure the target data
   for day = 1:days
       initial = 1+(day-1)*96;
       for hour = 1:24    
           yTarget(hour).data(1+(day-1)*4:4*day,1) = reshape(y_true(initial+(hour-1)*4:initial-1+hour*4,:), [],1); 
       end
   end
   
    % Essential paramerters for PSO performance
    particlesize = 200;  % number of particles default = 200
    mvden = 1000;    % Bigger value makes the search area wider default = 1000
    epoch   = 2000;  % max iterations default = 2000
    
    % 
    for hour = 1:24
        g_y_predict = yPredict(hour).data;
        g_y_true = yTarget(hour).data;
        PVset_run_pso;
        coeff(hour).data = pso_out(1:end-1);
    end
end














