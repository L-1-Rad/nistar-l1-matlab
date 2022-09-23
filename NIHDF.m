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

        function printInfoByDateRange(start_date, end_date, processing_level, directory, options)
            arguments
                start_date string % date in format YYYYMMDD
                end_date string % date in format YYYYMMDD
                processing_level string {mustBeMember(processing_level, {'1a', '1b'})}
                directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.save_logs = false
                options.save_csv = false
            end

            if options.save_logs
                log_filename = strcat('hdf_info_', processing_level, '_', start_date, '_', end_date, '.log');
                diary(log_filename)
            end

            if options.save_csv
                fp = fopen(strcat('hdf_info_', processing_level, '_', start_date, '_', end_date, '.csv'), 'w');
                fprintf(fp, '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n', ...
                        'File', 'Demod', 'Band A Total', 'Band A Interp1', 'Band A Interp2', ...
                        'Band B Total', 'Band B Interp1', 'Band B Interp2', 'Band B Interp3', 'Band B Lunar', ...
                        'Band C Total', 'Band C Interp1', 'Band C Interp2', 'Missing');
            end

            date_range = datenum(end_date, 'yyyymmdd') - datenum(start_date, 'yyyymmdd') + 1;
            filelist = NIHDF.getHDFFilenamesByDateRange(start_date, end_date, processing_level, directory);
            if processing_level == '1a'
                total_count = struct('apid82', 0, 'rad', 0, 'missing', 0);
                for i = 1:length(filelist)
                    count = NIHDF.printInfoForSingleFile(filelist(i).with_path);
                    total_count.apid82 = total_count.apid82 + count.apid82;
                    total_count.rad = total_count.rad + count.rad;
                    if options.save_csv
                        fprintf(fp, '%d,%d,%d\n', count.apid82, count.rad, count.missing);
                    end
                end
                total_count.missing = date_range * 86400 - total_count.rad;
                fprintf('\nTotal count: %d APID82, %d RAD, %d MISSING\n', total_count.apid82, total_count.rad, total_count.missing);
                if options.save_csv
                    fprintf(fp, '%d,%d,%d\n', total_count.apid82, total_count.rad, total_count.missing);
                end
            else
                total_count = struct('demod', 0, 'irradiance', struct('a', struct('total', 0, 'interp1', 0, 'interp2', 0), ...
                        'b', struct('total', 0, 'interp1', 0, 'interp2', 0, 'interp3', 0, 'lunar_corr', 0), ...
                        'c', struct('total', 0, 'interp1', 0, 'interp2', 0)), 'missing', 0);
                for i = 1:length(filelist)
                    count = NIHDF.printInfoForSingleFile(filelist(i).with_path);
                    total_count.demod = total_count.demod + count.demod;
                    total_count.irradiance = NIHDF.addIrradianceCounts(total_count.irradiance, count.irradiance);
                    total_count.missing = total_count.missing + count.missing;
                    if options.save_csv
                        NIHDF.writeCountsToCSVLine(fp, filelist(i).no_path, count);
                    end
                end
                NIHDF.printIrradianceCounts(total_count, date_range);
                if options.save_csv
                    NIHDF.writeCountsToCSVLine(fp, 'Total', total_count);
                end
            end
            if options.save_logs
                diary off
            end
            if options.save_csv
                fclose(fp);
            end
        end

        function count = printInfoForSingleFile(filename)
            arguments
                filename string {mustBeFile}
            end

            idx = strfind(filename, 'nist_');
            processing_str_idx = idx(end) + length('nist_');
            processing_str = extractBetween(filename, processing_str_idx, processing_str_idx+1);
            mustBeMember(processing_str, {'1a', '1b'});
            try
                info = h5info(filename);
            catch ME
                warning('Failed to read HDF file %s. Error message: %s', filename, ME.message);
                return
            end

            fprintf('Filename: %s: \n', filename);
            fprintf('  File size: %.2f MB\n', dir(filename).bytes / 1024^2);
            fprintf('  Number of groups: %d\n', length(info.Groups));

            if processing_str{1} == '1a'
                count = struct('apid82', 0, 'rad', 0, 'missing', 0);
                count.apid82 = NIHDF.analyzeHeatSinkData(filename);
                count.rad = NIHDF.analyzeL1ARadiometerData(filename);
                count.missing = 86400 - count.rad;
                if count.rad > 0
                    fprintf('   Number of linear interpolated L1A radiometer data: %d\n', count.rad - count.apid82);
                end
                count_of_non_nominal_fw = NIHDF.analyzeFilterWheelPositionData(filename);
                if count_of_non_nominal_fw == 0
                    fprintf('   All filter wheel positions are nominal.\n');
                end
            else
                count = struct('demod', 0, 'irradiance', struct(), 'missing', 0);
                count.demod = NIHDF.analyzeDemodulatorData(filename);
                count.irradiance = NIHDF.analyzeEarthIrradianceData(filename);
                count.missing = 86400 - count.demod;
                NIHDF.printIrradianceCounts(count, 1);
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

        function res = analyzeDemodulatorData(filename)
            arguments
                filename string {mustBeFile}
            end
            res = 0;
            try
                l1bDemod = h5read(filename, NIConstants.hdfDataSet.l1bDemod);
                res = length(l1bDemod.DSCOVREpochTime);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1B demodulator dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '  Error while reading L1B demodulator dataset: %s', ME.message);
                end
            end
            
            fprintf('   Number of L1B demodulator records: %d, percentage of missing records: %.2f\n', res, 100 * (86400 - res) / 86400);
        end

        function count = analyzeEarthIrradianceData(filename)
            arguments
                filename string {mustBeFile} 
            end
            count = struct('a', struct('total', 0, 'interp1', 0, 'interp2', 0), ...
                        'b', struct('total', 0, 'interp1', 0, 'interp2', 0, 'interp3', 0, 'lunar_corr', 0), ...
                        'c', struct('total', 0, 'interp1', 0, 'interp2', 0));
            try
                l1bEarthIrrA = h5read(filename, NIConstants.hdfDataSet.l1bEarthRadA);
                count.a.total = length(l1bEarthIrrA.DSCOVREpochTime);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1B earth irradiance band A dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '  Error while reading L1B earth irradiance band A dataset: %s', ME.message);
                end
            end
            try
                l1bEarthIrrB = h5read(filename, NIConstants.hdfDataSet.l1bEarthRadB);
                count.b.total = length(l1bEarthIrrB.DSCOVREpochTime);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1B earth irradiance band B dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '  Error while reading L1B earth irradiance band B dataset: %s', ME.message);
                end
            end
            try
                l1bEarthIrrC = h5read(filename, NIConstants.hdfDataSet.l1bEarthRadC);
                count.c.total = length(l1bEarthIrrC.DSCOVREpochTime);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1B earth irradiance band C dataset found in %s.\n', filename);
                else
                    warning(ME.identifier, '  Error while reading L1B earth irradiance band C dataset: %s', ME.message);
                end
            end
            if count.a.total > 0
                count.a.interp1 = sum(l1bEarthIrrA.IsInterpolatedData == 1);
                count.a.interp2 = sum(l1bEarthIrrA.IsInterpolatedData == 2);
            end
            if count.b.total > 0
                count.b.interp1 = sum(l1bEarthIrrB.IsInterpolatedData == 1);
                count.b.interp2 = sum(l1bEarthIrrB.IsInterpolatedData == 2);
                count.b.interp3 = sum(l1bEarthIrrB.IsInterpolatedData == 3);
                count.b.lunar_corr = sum(l1bEarthIrrB.LunarCorrection ~= 0);
            end
            if count.c.total > 0
                count.c.interp1 = sum(l1bEarthIrrC.IsInterpolatedData == 1);
                count.c.interp2 = sum(l1bEarthIrrC.IsInterpolatedData == 2);
            end
        end

        function counts = addIrradianceCounts(counts, count)
            counts.a.total = counts.a.total + count.a.total;
            counts.a.interp1 = counts.a.interp1 + count.a.interp1;
            counts.a.interp2 = counts.a.interp2 + count.a.interp2;
            counts.b.total = counts.b.total + count.b.total;
            counts.b.interp1 = counts.b.interp1 + count.b.interp1;
            counts.b.interp2 = counts.b.interp2 + count.b.interp2;
            counts.b.interp3 = counts.b.interp3 + count.b.interp3;
            counts.b.lunar_corr = counts.b.lunar_corr + count.b.lunar_corr;
            counts.c.total = counts.c.total + count.c.total;
            counts.c.interp1 = counts.c.interp1 + count.c.interp1;
            counts.c.interp2 = counts.c.interp2 + count.c.interp2;
        end

        function printIrradianceCounts(counts, days)
            total_seconds = days * 86400;
            fprintf('\nTotal count: %d DEMOD (%.2f %% of full time period) \n', counts.demod, 100 * counts.demod/total_seconds);
            fprintf('   Number of L1B earth irradiance band A records: %d (%.2f %%)\n', counts.irradiance.a.total, 100 * counts.irradiance.a.total / total_seconds);
            fprintf('   -   Including linear interpolation records: %d\n', counts.irradiance.a.interp1);
            fprintf('   -   Including neighbor-duplicated records: %d\n', counts.irradiance.a.interp2);
            fprintf('   Number of non-nominal (non-Earth view, calibrations, spacecraft manuevers, etc.) records: %d, (%.2f %%)\n', counts.demod - counts.irradiance.a.total, 100 * (counts.demod - counts.irradiance.a.total) / total_seconds);
            fprintf('   Number of L1B earth irradiance band B records: %d (%.2f %%)\n', counts.irradiance.b.total, 100 * counts.irradiance.b.total / total_seconds);
            fprintf('   -   Including linear interpolation records: %d\n', counts.irradiance.b.interp1);
            fprintf('   -   Including neighbor-duplicated records: %d\n', counts.irradiance.b.interp2);
            fprintf('   -   Including photodiode-polyfit interpolation records: %d\n', counts.irradiance.b.interp3);
            fprintf('   -   Including lunar intrusion corrected records: %d\n', counts.irradiance.b.lunar_corr);
            fprintf('   Number of non-nominal (non-Earth view, calibrations, spacecraft manuevers, etc.) records: %d, (%.2f %%)\n', counts.demod - counts.irradiance.b.total, 100 * (counts.demod - counts.irradiance.b.total) / total_seconds);
            fprintf('   Number of L1B earth irradiance band C records: %d (%.2f %%)\n', counts.irradiance.c.total, 100 * counts.irradiance.c.total / total_seconds);
            fprintf('   -   Including linear interpolation records: %d\n', counts.irradiance.c.interp1);
            fprintf('   -   Including neighbor-duplicated records: %d\n', counts.irradiance.c.interp2);
            fprintf('   Number of non-nominal (non-Earth view, calibrations, spacecraft manuevers, etc.) records: %d, (%.2f %%)\n', counts.demod - counts.irradiance.c.total, 100 * (counts.demod - counts.irradiance.c.total) / total_seconds);
        end

        function writeCountsToCSVLine(fp, first_col_str, count)
            fprintf(fp, '%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', first_col_str, count.demod, ...
                            count.irradiance.a.total, count.irradiance.a.interp1, count.irradiance.a.interp2, ...
                            count.irradiance.b.total, count.irradiance.b.interp1, count.irradiance.b.interp2, count.irradiance.b.interp3, count.irradiance.b.lunar_corr, ...
                            count.irradiance.c.total, count.irradiance.c.interp1, count.irradiance.c.interp2, ...
                            count.missing);
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