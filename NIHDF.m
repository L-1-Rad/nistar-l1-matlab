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
end