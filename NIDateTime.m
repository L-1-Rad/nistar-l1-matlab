classdef NIDateTime

    methods (Static)
        function calendar_date = getCalendarDateFromDSCOVREpoch(dscovr_epochtime)
            % NIDateTime.getCalendarDateFromDSCOVREpoch
            %   Convert DSCOVR epoch time to calendar date
            %   Input: DSCOVR epoch time (seconds since 1968-05-24 00:00:00)
            %   Output: calendar date (yyyy-mm-dd HH:MM:SS)
            %   Example: NIDateTime.getCalendarDateFromDSCOVREpoch(0)
            %   Example: NIDateTime.getCalendarDateFromDSCOVREpoch(1.5e9)
            
            arguments
                dscovr_epochtime (1,:) double
            end
            calendar_date = datetime(1968, 5, 24) + seconds(dscovr_epochtime);
        end
    end

    methods (Static)
        function dscovr_epochtime = getDSCOVREpochFromCalendarDate(year, month, day, hour, minute, second)
            % NIDateTime.getDSCOVREpochFromCalendarDate
            %   Convert a calendar date to a DSCOVR epoch time.
            %
            %   Inputs:
            %       year    -   Year
            %       month   -   Month
            %       day     -   Day
            %       hour    -   Hour
            %       minute  -   Minute
            %       second  -   Second
            %
            %   Outputs:
            %       epoch   -   DSCOVR epoch time
            %
            %   Example:
            %       epoch = NIDateTime.getDSCOVREpochFromCalendarDate(2015, 1, 1, 0, 0, 0);
            %
            %   See also NIDateTime.getDSCOVREpochFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromDSCOVREpoch,
            %   NIDateTime.getUnixEpochFromCalendarDate,
            %   NIDateTime.getCalendarDateFromDSCOVREpoch,
            %   NIDateTime.getCalendarDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromCalendarDate,
            %   NIDateTime.getCalendarDateFromUnixEpoch,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            arguments
                year (1,1) double
                month (1,1) double
                day (1,1) double
                hour (1,1) double = 0
                minute (1,1) double = 0
                second (1,1) double = 0
            end
            dscovr_epochtime = seconds(datetime(year, month, day, hour, minute, second) - datetime([1968, 5, 24]));
        end

        function dscovr_epochtime = getDSCOVREpochFromJulianDay(jul_day)
            calendar_datetime = datetime([1858, 11, 17]) + days(jul_day - 2400000.5);
            dscovr_epochtime = NIDateTime.getDSCOVREpochFromCalendarDate(year(calendar_datetime), ...
                month(calendar_datetime), day(calendar_datetime), hour(calendar_datetime), ...
                minute(calendar_datetime), second(calendar_datetime));
        end
    end

    methods(Static)
        function calendar_date = getCalendarDateFromJulianDay(julian_date)
            % NIDateTime.getCalendarDateFromJulianDay
            %   Convert a Julian date to a calendar date.
            %
            %   Inputs:
            %       julian_date -   Julian date
            %
            %   Outputs:
            %       calendar_date   -   MATLAB datetime object
            %
            %   Example:
            %       calendar_date = NIDateTime.getCalendarDateFromJulianDay(2457204.5);
            %
            %   See also NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,

            arguments
                julian_date (1,:) double
            end
            calendar_date = datetime([1858, 11, 17]) + days(julian_date - 2400000.5);
        end
    end

    methods(Static)
        function julian_date = getJulianDateFromCalendarDate(year, month, day, hour, minute, second)
            % NIDateTime.getJulianDateFromCalendarDate
            %   Convert a calendar date to a Julian date.
            %
            %   Inputs:
            %       year    -   Year
            %       month   -   Month
            %       day     -   Day
            %       hour    -   Hour
            %       minute  -   Minute
            %       second  -   Second
            %
            %   Outputs:
            %       julian_date -   Julian date
            %
            %   Example:
            %       julian_date = NIDateTime.getJulianDateFromCalendarDate(datetime(2015, 1, 1));
            %
            %   See also NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,
            %   NIDateTime.getJulianDateFromDSCOVREpoch,
            %   NIDateTime.getDSCOVREpochFromJulianDate,
            %   NIDateTime.getJulianDateFromUnixEpoch,
            %   NIDateTime.getUnixEpochFromJulianDate,
            %   NIDateTime.getJulianDateFromCalendarDate,
            %   NIDateTime.getCalendarDateFromJulianDay,

            arguments
                year (1,1) double
                month (1,1) double
                day (1,1) double
                hour (1,1) double = 0
                minute (1,1) double = 0
                second (1,1) double = 0
            end
            julian_date = days(datetime(year, month, day, hour, minute, second) - datetime([1858, 11, 17])) + 2400000.5;
        end

        function jul_day = getJulianDayFromDSCOVREpoch(dscovr_epoch)
            jul_day = days(datetime([1968, 5, 24]) + seconds(dscovr_epoch) - datetime([1858, 11, 17]) + 2400000.5);
        end

    end

end