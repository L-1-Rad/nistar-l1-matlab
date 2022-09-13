function [idx, diff] = binary_search(array, value, options)
    % BINARY_SEARCH  Binary search for a value in a sorted array.
    %
    %   [IDX, DIFF] = BINARY_SEARCH(ARRAY, VALUE, OPTIONS) returns the 
    %   index IDX of the element in ARRAY closest to VALUE, regardless of 
    %   whether VALUE is smaller or larger than ARRAY(IDX). The output 
    %   returned in DIFF is the difference of ARRAY(IDX) - VALUE. If the 
    %   tolerance OPTIONS.tol is set, then IDX is the index of the first 
    %   element in ARRAY that is closest to VALUE within the tolerance. 
    %   If no element is within the tolerance, IDX is returned as -1 and 
    %   DIFF is returned as NaN.
    %
    %   OPTIONS is a struct with the following fields:
    %   .tol - the tolerance for the difference between the value and the
    %          element in the array. If not set, the default is Inf.
    %   .warn - if true, a warning is issued if the value is not found, 
    %           otherwise no warning is issued. The default is true.
    %
    %   See also: binary_search_left, binary_search_right.


    arguments
        array (:,1) double
        value double
        options.tol (1,1) double = Inf
        options.warn (1,1) logical = true
    end

    idx = binary_search_right(array, value, warn=false);
    if idx == length(array) + 1 % value is larger than all elements
        idx = length(array);
    % check the element to the left of idx
    elseif idx > 1 && abs(array(idx-1) - value) < abs(array(idx) - value)
        idx = idx - 1;
    end
    
    % check if the element is within the tolerance
    if abs(array(idx) - value) > options.tol
        if options.warn
            warning('Value not found within tolerance: TOL = %g', options.tol);
            disp('Closest value found: ');
            fprintf('ARRAY(%d) = %g\n', idx, array(idx));
            disp('Difference to the target: ');
            fprintf('ARRAY(%d) - VALUE = %g\n', idx, array(idx) - value);
        end
        idx = -1;
        diff = NaN;
        return
    else
        diff = array(idx) - value;
    end

    while idx > 1 && array(idx-1) == array(idx) % in case of duplicates
        idx = idx - 1;
    end

