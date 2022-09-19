classdef NIHDF

    methods (Static)
        function filename = getHDFFilenameByDate(date, processing_level, directory)
            arguments
                date string % date in format YYYYMMDD
                processing_level string {mustBeMember(processing_level, {'1a', '1b'})}
                directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
            end
            
            filename.no_path = [];
            filename.with_path = [];
            f = sprintf(strcat('nist_', processing_level, '_%s_*.h5'), date);
            s = dir(fullfile(directory, f));
            try
                length(s.name);
            catch
                warning('Can''t find / found multiple files of the HDF product for the given date (%s) in the directory %s.', date, directory);
                return
            end
            filename.no_path = s.name;
            filename.with_path = fullfile(directory, s.name);
        end

        function filelist = getHDFFilenamesByDateRange(start_date, end_date, processing_level, directory)
            arguments
                start_date string % date in format YYYYMMDD
                end_date string % date in format YYYYMMDD
                processing_level string {mustBeMember(processing_level, {'1a', '1b'})}
                directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
            end
            
            filelist = [];
            for i = datenum(start_date, 'yyyymmdd'):datenum(end_date, 'yyyymmdd')
                filename = NIHDF.getHDFFilenameByDate(datestr(i, 'yyyymmdd'), processing_level, directory);
                if ~isempty(filename.no_path)
                    filelist = [filelist; filename];
                end
            end
        end
    end

    methods (Static)
        function printInfoForSingleFile(filename)
            arguments
                filename string {mustBeFile}
            end
            
            info = h5info(filename);
            fprintf('Filename: %s: \n', filename);
            fprintf('  File size: %.2f MB\n', dir(filename).bytes / 1024^2);
            fprintf('  Number of groups: %d\n', length(info.Groups));

            count_of_apid82 = NIHDF.analyzeHeatSinkData(filename);
            count_of_l1arad = NIHDF.analyzeL1ARadiometerData(filename);
            if count_of_l1arad > 0
                fprintf('   Number of linear interpolated L1A radiometer data: %d\n', count_of_l1arad - count_of_apid82);
            end
            count_of_non_nominal_fw = NIHDF.analyzeFilterWheelPositionData(filename);
            if count_of_non_nominal_fw == 0
                fprintf('   All filter wheel positions are nominal.\n');
            end
        end

        function res = analyzeHeatSinkData(filename)
            arguments
                filename string {mustBeFile}
            end
            res = 0;
            try
                l1aHS = h5read(filename, NIConstants.hdfDataSet.l1aScience);
                res = length(l1aHS.H052TIME);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1A science dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '  Error while reading L1A science dataset: %s', ME.message);
                end
            end
            fprintf('   Number of AppID82 records: %d, percentage of missing records: %.2f\n', res, 100 * (86400 - res) / 86400);
        end

        function res = analyzeFilterWheelPositionData(filename)
            arguments
                filename string {mustBeFile}
            end
            try
                l1aFW = h5read(filename, NIConstants.hdfDataSet.l1aScience);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1A science dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '    Error while reading L1A science dataset: %s', ME.message);
                end
                res = -1;
                return
            end
            res = NIHDF.findAnomalousValuesInTimeSeries(l1aFW.H052TIME, l1aFW.NIPREFWPOSNUM, 3, false);
        end

        function res = analyzeL1ARadiometerData(filename)
            arguments
                filename string {mustBeFile}
            end
            res = 0;
            try
                l1aRad = h5read(filename, NIConstants.hdfDataSet.l1aRad);
                res = length(l1aRad.DSCOVREpochTime);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1A radiometer dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '  Error while reading L1A radiometer dataset: %s', ME.message);
                end
            end
            
            fprintf('   Number of L1A radiometer records: %d, percentage of missing records: %.2f\n', res, 100 * (86400 - res) / 86400);
        end
        function res = findAnomalousValuesInTimeSeries(time, data, value, equal_or_nonequal)
            arguments
                time double
                data double
                value double
                equal_or_nonequal logical = true
            end
            
            % find anomalous values in time series
            % time: time series
            % data: data series
            % value: value to be searched for
            % equal_or_nonequal: define anomalous as 'equal' or 'nonequal' to the value, default is true (equal)
            % return: indices of anomalous values
            res = 0;
            if equal_or_nonequal
                indices = find(data == value);
            else
                indices = find(data ~= value);
            end
            if ~isempty(indices)
                fprintf('   Found %d anomalous values of %f in the time series.\n', length(indices), value);
                % find the number of consecutive anomalous value segments
                diff_indices = diff(indices);
                diff_indices = [diff_indices; 1];
                indices_of_segments = find(diff_indices > 1);
                res = length(indices_of_segments);
                fprintf('   Found %d consecutive anomalous value segments.\n', res);
                % print the start and end time of each segment
                for i = 1:res
                    if i == 1
                        start_index = 1;
                    else
                        start_index = indices_of_segments(i - 1) + 1;
                    end
                    end_index = indices_of_segments(i);
                    fprintf('    Segment %d: start time: %s, end time: %s\n', i, ...
                        datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(time(indices(start_index))), 'yyyy-mm-dd HH:MM:SS'), ...
                        datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(time(indices(end_index))), 'yyyy-mm-dd HH:MM:SS'));
                end
            end
        end
    end
end