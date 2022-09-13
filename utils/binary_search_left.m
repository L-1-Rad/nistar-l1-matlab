function [idx, diff] = binary_search_left(array, value, options)
% binary_search_left - find the index of the last element less 
% than or equal to value, regardless of the difference between the
% value and the element. The output returned in DIFF is the 
% difference of ARRAY(IDX) - VALUE. If the tolerance OPTIONS.tol is set,
% then IDX is the index of the last element in ARRAY that is less 
% than or equal to VALUE within the tolerance. If no element is within 
% the tolerance, IDX is returned as -1 and DIFF is returned as NaN.
% [idx, diff] = binary_search_left(array, value)
%
% array - a sorted array of numbers
% value - the value to search for
% options - a structure with the following fields:
%   .tol - the tolerance for the difference between the value and the
%          element in the array. If not set, the default is Inf.
%   .warn - if true, a warning is issued if the value is not found, 
%           otherwise no warning is issued. The default is true.
%
% idx - the index of the last element no greater than value
% diff - the difference ARRAY(IDX) - VALUE (non-positive), or NaN if IDX is -1
%
% Example:
%   array = [1 2 3 4 5 6 7 8 9 10];
%   idx = binary_search_left(array, 5.5)
%   idx = 5
%   diff = -0.5
%
%   idx = binary_search_left(array, 5.5, tol=0.2)
%   idx = -1
%   diff = NaN
% 
% See also: binary_search_right, binary_search

        arguments
            array (:,1) double
            value (1,1) double
            options.tol (1,1) double = Inf
            options.warn (1,1) logical = true
        end

        % check if the value is less than the first element
        if value < array(1)
            idx = 0;
            diff = NaN;
            if options.warn
                warning('Value is less than the first element in the array');
                disp('Value: ' + string(value));
                disp('First element in array: ' + string(array(1)));
            end
            return
        end

        low = 1;
        high = length(array);
        while low < high
            mid = floor((low + high) / 2);
            if array(mid) >= value
                high = mid;
            else
                low = mid + 1;
            end
        end
        if array(low) ~= value
            low = low - 1;
        end
        if array(low) <= value && abs(array(low) - value) <= options.tol
            idx = low;
            diff = array(low) - value;
        else
            if options.warn
                warning('Value not found within tolerance: TOL = %g', options.tol);
                disp('Closest value found: ');
                fprintf('ARRAY(%d) = %g\n', low, array(low));
                disp('Difference to the target: ');
                fprintf('ARRAY(%d) - VALUE = %g', low, array(low) - value);
            end
            idx = -1;
            diff = NaN;
        end
    end