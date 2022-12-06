function [jul_day1, jul_day2] = verify_input_dates(jd1, jd2, cd1, cd2)
%VERIFY_INPUT_DATES Summary of this function goes here
%   Detailed explanation goes here
    if (isempty(jd1) == 0 || isempty(jd2) == 0) && (isempty(cd1) == 0 || isempty(cd2) == 0)
        error('Input Julian days (jd1, jd2) and calendar days (cd1, cd2) are mutually exclusive.');
    end
    if isempty(jd1) == 1 && isempty(cd1) == 1
        error('At least one of the input dates: starting Julian day (jd1) or starting calendar day (cd1) is required.');
    end
    if isempty(jd1) == 0
        if isempty(jd2) == 1
            jd2 = jd1;
        elseif jd2 < jd1
            error('Input Julian day jd2 must be greater than or equal to jd1.');
        end
        jul_day1 = jd1;
        jul_day2 = jd2;
    elseif isempty(cd1) == 0 
        if isempty(cd2) == 1
            cd2 = cd1;
        elseif cd2 < cd1
            error('Input calendar day cd2 must be greater than or equal to cd1.');
        end
        year1 = floor(cd1/10000);
        month1 = floor(rem(cd1, 10000)/100);
        day1 = cd1 - year1*10000 - month1*100;
        jul_day1 = NIDateTime.getJulianDateFromCalendarDate(year1, month1, day1-1, 12, 0, 0);
        year2 = floor(cd2/10000);
        month2 = floor(rem(cd2, 10000)/100);
        day2 = cd2 - year2*10000 - month2*100;
        jul_day2 = NIDateTime.getJulianDateFromCalendarDate(year2, month2, day2-1, 12, 0, 0);
    end
end

