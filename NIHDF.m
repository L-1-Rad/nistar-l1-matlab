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
            fprintf('  File size: %s bytes\n', dir(filename).bytes);
            fprintf('  Number of groups: %d\n', length(info.Groups));

            analyzeHeatSinkData(filename);
            analyzeL1ARadiometerData(filename);
        end

        function analyzeHeatSinkData(filename)
            arguments
                filename string {mustBeFile}
            end
            try
                l1aHS = h5read(filename, NIConstants.hdfDataSet.l1aScience);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1A science dataset found in %s.\n', filename);
                else
                    warning('  Error while reading L1A science dataset: %s', ME.message);
                end
            end
            fprintf('Number of records: %d, percentage of missing records: %f\n', length(l1aHS.time), 100 * (86400 - length(l1aHS.time)) / 86400);
        end

        function analyzeL1ARadiometerData(filename)
            arguments
                filename string {mustBeFile}
            end
            try
                l1aRad_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1aRad);
            catch ME
                if ME.identifier == "MATLAB:imagesci:h5read:libraryError"
                    fprintf('  No L1A radiometer dataset found in %s.\n', filename);
                else
                    warning('  Error while reading L1A radiometer dataset: %s', ME.message);
                end
            end
            fprintf('Number of records: %d, percentage of missing records: %f\n', length(l1aRad.time), 100 * (total_seconds - length(l1aRad.time)) / total_seconds);
        end
    end
end