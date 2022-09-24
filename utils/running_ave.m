function average = running_ave(time, data, window, step, options)
% averaged = running_ave(time, data, window, step, options)
%
% This function calculates the running average of a data set.  The window
% and step size, and data rate (sampling time) are all in seconds.
%
% INPUTS:
%   time:       time vector
%   data:       data vector
%   window:     window size in seconds
%   step:       step size in seconds
%   options:
%       .data_rate:     sample rate of the input data in seconds, default = 1
%       .first_index:   specify the first index to use in averaging, default = 1
%       .last_index:    specify the last index to use in averaging, default
%           = [] (using the last value)
%       .method:        'mean' or 'median', default = 'mean'
%       .percentage:    minimum percentage of data points in the window to calculate the average, default = 70
%       .output_time:   'center' or 'averaged', default = 'center'
%       .plot:          true to plot the averaged results on top of the input data, default = false
%
% OUTPUTS:
%   average:    struct with the following fields:
%       .time:      time vector
%       .data:      averaged data vector
%       .std:       standard deviation of the data in the window if the method is 'mean'
%       .n:         number of data points in the window
%   
%
% EXAMPLE:
%   averaged = running_ave(time, data, 86400, 3600, data_rate=10, method='mean', percentage=90, output_time='center', plot=true);

arguments
    time (:,1) double
    data (:,1) double
    window (1,1) double
    step (1,1) double
    options.data_rate (1,1) double = 1
    options.first_index (1,1) double {mustBePositive, mustBeInteger} = 1
    options.last_index (1,1) double {mustBePositive, mustBeInteger} = []
    options.method (1,1) string = "mean"
    options.percentage (1,1) double {mustBeGreaterThanOrEqual(options.percentage, 0) ...
        mustBeLessThanOrEqual(options.percentage, 100)} = 70
    options.output_time (1,1) string {mustBeMember(options.output_time, {'center', 'averaged'})} = "center"
    options.plot (1,1) logical = false
end

if isempty(options.last_index)
    last_time_stamp = time(end);
else
    last_time_stamp = time(options.last_index);
end
first_time_stamp = time(options.first_index);
if first_time_stamp > last_time_stamp
    error('The specify first time stamp is greater than the last time stamp');
end
% determine the number of averages
num_averages = floor((last_time_stamp - first_time_stamp) /(step / options.data_rate)) + 1;
if num_averages < 1
    error('The step size is too large for the data');
end
fprintf('Number of averages: %d\n', num_averages);

% determine the number of data points in the window
window_size = window / options.data_rate;

% initialize the averaged vectors
average.time = first_time_stamp + (0:(num_averages-1)) * step + window/2;
average.data = nan(num_averages, 1);
average.std = nan(num_averages, 1);
average.n = zeros(num_averages, 1);

% calculate the averages

% use binary search to find the indexes of the first window
start_index = binary_search_right(time, average.time(1) - window/2, warn=false);
end_index = binary_search_right(time, average.time(1) + window/2, warn=false) - 1; % -1 because it is MATLAB

% determine the number of data points in the window
average.n(1) = sum(~isnan(data(start_index:end_index)));
    
% determine the percentage of data points in the window
percentage = average.n(1) / window_size * 100;

% calculate the average if the percentage is above the threshold
if percentage >= options.percentage
    if options.method == "mean"
        average.data(1) = mean(data(start_index:end_index), 'omitnan');
        average.std(1) = std(data(start_index:end_index), 'omitnan');
    elseif options.method == "median"
        average.data(1) = median(data(start_index:end_index), 'omitnan');
    end
    if options.output_time == "averaged"
        average.time(1) = mean(time(start_index:end_index));
    end
end

for i = 2:num_averages

    % find the indexes of the window, since the average.time increases by
    % step, the indexes of the window will increase by step/data_rate if
    % there is no missing data. If there is missing data, the time stamp of
    % the window will be larger than the time stamp of the data, this signals
    % that the naive search is not working. In this case, we use binary search
    % to find the indexes of the window. 

    naive_start_index = start_index + round(step / options.data_rate);
    naive_end_index = end_index + round(step / options.data_rate);
    if time(naive_start_index) - options.data_rate/2 > average.time(i) - window/2 || time(naive_end_index) - options.data_rate/2 > average.time(i) + window/2
        % binary search
        start_index = binary_search_right(time, average.time(i) - window/2, warn=false);
        end_index = binary_search_right(time, average.time(i) + window/2, warn=false) - 1; % -1 because it is MATLAB
        if start_index == -1 || start_index == end_index
            continue
        end
    else
        % naive search
        start_index = naive_start_index;
        end_index = naive_end_index;
        start_index = min(start_index, length(time));
        end_index = min(end_index, length(time));
    end
    
    % determine the number of data points in the window
    average.n(i) = sum(~isnan(data(start_index:end_index)));
    
    % determine the percentage of data points in the window
    percentage = average.n(i) / window_size * 100;
    
    % calculate the average if the percentage is above the threshold
    if percentage >= options.percentage
        if options.method == "mean"
            average.data(i) = mean(data(start_index:end_index), 'omitnan');
            average.std(i) = std(data(start_index:end_index), 'omitnan');
        elseif options.method == "median"
            average.data(i) = median(data(start_index:end_index), 'omitnan');
        end
        if options.output_time == "averaged"
            average.time(i) = mean(time(start_index:end_index));
        end
    end
end

if options.plot
    figure;
    plot(time, data, 'k');
    hold on;
    plot(average.time, average.data, 'r.', MarkerSize=8);
    stylize_figure(gcf, 8, 6, ax_override_line_color=false, ax_override_marker_size=false);
end
