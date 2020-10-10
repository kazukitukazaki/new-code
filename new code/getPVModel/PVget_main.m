clear all
clc
close all
warning('off','all');
y_pred = PVget_getPVModel([pwd,'\','shortTermPastData.csv'],...
                        [pwd,'\','ForecastData.csv'],...
                        [pwd,'\','ResultData.csv'])