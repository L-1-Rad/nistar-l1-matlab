classdef NIL1A

    methods(Static)
        function l1aRad = readL1ARadiometer(jul_day1, jul_day2, options)
            %readL1ARadiometer Read L1A radiometer shutter-modulated ADC power data
            %   l1aRad = readL1ARadiometer(jul_day1, jul_day2, options)
            %   Inputs:
            %       jul_day1: first Julian day
            %       jul_day2: last Julian day (inclusive)
            %       options: 
            %           directory: directory of the HDF files, default is
            %               NIConstants.dir.root/NIConstants.dir.hdf
            %           plotFlag: plot the data or not, default is false
            %   Outputs:
            %       l1aRad: a structure containing the following fields
            %           time: DSCOVR epoch time
            %           rc1: ADC power of receiver 1
            %           rc2: ADC power of receiver 2
            %           rc3: ADC power of receiver 3
            %           fw: filter wheel position
            %           rc1_shutter: shutter position of receiver 1
            %           rc2_shutter: shutter position of receiver 2
            %           rc3_shutter: shutter position of receiver 3
            %
            %   Example:
            %       l1aRad = readL1ARadiometer(2458000, 2458001, plotFlag=true);

            arguments
                jul_day1 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end

            fprintf('\n');
            l1aRad = struct('time', [], 'rc1', [], 'rc2', [], 'rc3', [], 'fw', [], ...
                'rc1_shutter', [], 'rc2_shutter', [], 'rc3_shutter', []);

            valid_file_count = 0;

            for jul_day = jul_day1 : jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1a', options.directory);
                catch ME
                    warning('No L1A HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                fprintf('Reading L1A HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1aRad_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1aRad);
                catch ME
                    warning('No L1A radiometry data is found in the HDF file %s\n', filename.no_path);
                    fprintf('%s', ME.message);
                    continue;
                end
                l1aRad.time = [l1aRad.time; l1aRad_data.DSCOVREpochTime];
                l1aRad.rc1 = [l1aRad.rc1; l1aRad_data.RadiometerPower1];
                l1aRad.rc2 = [l1aRad.rc2; l1aRad_data.RadiometerPower2];
                l1aRad.rc3 = [l1aRad.rc3; l1aRad_data.RadiometerPower3];
                l1aRad.fw = [l1aRad.fw; l1aRad_data.FilterWheel];
                l1aRad.rc1_shutter = [l1aRad.rc1_shutter; l1aRad_data.ShutterMotor1];
                l1aRad.rc2_shutter = [l1aRad.rc2_shutter; l1aRad_data.ShutterMotor2];
                l1aRad.rc3_shutter = [l1aRad.rc3_shutter; l1aRad_data.ShutterMotor3];
                valid_file_count = valid_file_count + 1;
            end
            if valid_file_count == 0
                error('No valid L1A HDF file is found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid files.\n', length(l1aRad.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aRad.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aRad.time(end))));

            if options.plotFlag
                figure;
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1aRad.time);
                subplot(3, 1, 1)
                plot(x_datetime_data, l1aRad.rc1, '.')
                grid on
                title('RC1 Radiometer Power')
                subplot(3, 1, 2)
                plot(x_datetime_data, l1aRad.rc2, '.')
                grid on
                title('RC2 Radiometer Power')
                subplot(3, 1, 3)
                plot(x_datetime_data, l1aRad.rc3, '.')
                grid on
                title('RC3 Radiometer Power')
                stylize_figure(gcf, 6, 8);
            end
        end
    end

    methods(Static)
        function l1aNV = readNISTARView(jul_day1, jul_day2, options)
            %readNISTARView Read L1A NISTAR view and geolocation data from HDF files
            %   l1aNV = readNISTARView(jul_day1, jul_day2, options)
            %   Inputs:
            %       jul_day1: first Julian day
            %       jul_day2: last Julian day (inclusive)
            %       options: 
            %           directory: directory of the HDF files, default is
            %               NIConstants.dir.root/NIConstants.dir.hdf
            %           plotFlag: plot the data or not, default is false
            %   Outputs:
            %       l1aNV: structure containing the L1A NISTAR view and geolocation data
            %           time: DSCOVR epoch time
            %           view: NISTAR viewing space object encoder:
            %               -1: Spacecraft pointing data is missing
            %               0: Earth is partially visible
            %               1: Only Earth is fully visible (nominal case)
            %               2: Only Moon is partially or fully visible
            %               3: Deep space
            %               4: Earth is fully visible and the Moon is at least partially visible
            %               5: Same as 4 but the Moon intrusion is correctable in the shortwave channel
            %           earthDev: Earth deviation angle, including three fields:
            %               y: y-axis deviation angle on the spacecraft coordinates in radians
            %               z: z-axis deviation angle on the spacecraft coordinates in radians
            %               mag: magnitude of the deviation angle in radians
            %           moonDev: Moon deviation angle, including three fields:
            %               y: y-axis deviation angle on the spacecraft coordinates in radians
            %               z: z-axis deviation angle on the spacecraft coordinates in radians
            %               mag: magnitude of the deviation angle in radians
            %           earthFOV: Earth field of view
            %           earthFOR: Earth field of regard
            %           moonFOV: Moon field of view
            %           moonFOR: Moon field of regard
            %           moonPhase: Moon phase angle as seen from DSCOVR in radians
            %           earthMoonSep: Earth-Moon separation angle as seen from DSCOVR in radians
            %           angleSEV: Angle between the Sun and the Earth-spacecraft line in radians
            %
            %   Example:
            %       l1aNV = NIL1A.readNISTARView(2458000, 2458000, plotFlag=true);

            arguments
                jul_day1 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end
            fprintf('\n');
            l1aNV = struct('time', [], 'view', [], 'earthDev', [], 'moonDev', [], 'earthFOV', [], ...
                'earthFOR', [], 'moonFOV', [], 'moonFOR', [], 'moonPhase', [], 'earthMoonSep', [], 'angleSEV', []);

            valid_file_count = 0;
            for jul_day = jul_day1:jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1a', options.directory);
                catch ME
                    warning('No L1A HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                fprintf('Reading L1A HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1aNV_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1aNV);
                catch ME
                    warning('No/Unable to read L1A NISTAR view data found in the HDF file %s\n', filename.no_path);
                    fprintf('%s', ME.message);
                    continue;
                end
                l1aNV.time = [l1aNV.time; l1aNV_data.DSCOVREpochTime];
                l1aNV.view = [l1aNV.view; l1aNV_data.NISTARView];
                l1aNV.earthDev.y = [l1aNV.earthDev.y; l1aNV_data.EarthDeviationAngle(1, :)'];
                l1aNV.earthDev.z = [l1aNV.earthDev.z; l1aNV_data.EarthDeviationAngle(2, :)'];
                l1aNV.earthDev.mag = [l1aNV.earthDev.mag; l1aNV_data.EarthDeviationAngle(3, :)'];
                l1aNV.moonDev.y = [l1aNV.moonDev.y; l1aNV_data.MoonDeviationAngle(1, :)'];
                l1aNV.moonDev.z = [l1aNV.moonDev.z; l1aNV_data.MoonDeviationAngle(2, :)'];
                l1aNV.moonDev.mag = [l1aNV.moonDev.mag; l1aNV_data.MoonDeviationAngle(3, :)'];
                l1aNV.earthFOV = [l1aNV.earthFOV; l1aNV_data.EarthFOV];
                l1aNV.earthFOR = [l1aNV.earthFOR; l1aNV_data.EarthFOR];
                l1aNV.moonFOV = [l1aNV.moonFOV; l1aNV_data.MoonFOV];
                l1aNV.moonFOR = [l1aNV.moonFOR; l1aNV_data.MoonFOR];
                l1aNV.moonPhase = [l1aNV.moonPhase; l1aNV_data.MoonPhaseAngle];
                l1aNV.earthMoonSep = [l1aNV.earthMoonSep; l1aNV_data.EarthMoonAngle];
                l1aNV.angleSEV = [l1aNV.angleSEV; l1aNV_data.SolarEarthVehicleAngle];
                valid_file_count = valid_file_count + 1;
            end
            if valid_file_count == 0
                error('No valid L1A HDF file is found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid files.\n', length(l1aNV.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aNV.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aNV.time(end))));

            if options.plotFlag
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1aNV.time);
                figure;
				subplot(3, 1, 1)
				plot(x_datetime_data, l1aNV.earthDev.mag, 'b.')
				hold on
				plot(x_datetime_data, l1aNV.earthFOV, 'k--')
				plot(x_datetime_data, l1aNV.earthFOR, 'k--')
                subplot(3, 1, 2)
				plot(x_datetime_data, l1aNV.moonDev.mag, '.', 'Color', '#ABB2B9')
				hold on
				plot(x_datetime_data, l1aNV.moonFOV, 'k--')
				plot(x_datetime_data, l1aNV.moonFOR, 'k--')
				subplot(3, 1, 3)
                plot(x_datetime_data, l1aNV.view, 'r.')
                grid on
                stylize_figure(gcf, 6, 8);
            end
        end
    end

    methods(Static)
        function l1aPD = readL1APhotodiode(jul_day1, jul_day2, options)
            %readL1APhotodiode Read L1A photodiode current data from HDF files
            %   l1aPD = readL1APhotodiode(jul_day1, jul_day2, options)
            %   Inputs:
            %       jul_day1: first Julian day
            %       jul_day2: last Julian day (inclusive)
            %       options: 
            %           directory: directory of the HDF files, default is
            %               NIConstants.dir.root/NIConstants.dir.hdf
            %           plotFlag: plot the data or not, default is false
            %   Outputs:
            %       l1aPD: structure containing the L1A photodiode current data
            %           l1aPD.time: time in DSCOVR epoch
            %           l1aPD.curr: photodiode current
            %           l1aPD.fw: filter wheel position
            %           
            %   Example:
            %       l1aPD = NIReadL1A.readHeatSink(2457204, 2457205, plotFlag=true);

            arguments
                jul_day1 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end
            fprintf('\n');
            l1aPD = struct('time', [], 'curr', [], 'fw', []);

            valid_file_count = 0;
            for jul_day = jul_day1:jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1a', options.directory);
                catch ME
                    warning('No L1A HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                fprintf('Reading L1A HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1aPD_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1aPD);
                catch ME
                    warning('No/Unable to read L1A photodiode data found in the HDF file %s\n', filename.no_path);
                    fprintf('%s', ME.message);
                    continue;
                end
                l1aPD.time = [l1aPD.time; l1aPD_data.DSCOVREpochTime];
                l1aPD.curr = [l1aPD.curr; l1aPD_data.PhotodiodeCurrent];
                l1aPD.fw = [l1aPD.fw; l1aPD_data.FilterWheel];
                valid_file_count = valid_file_count + 1;
            end

            if valid_file_count == 0
                error('No valid L1A HDF file is found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid files.\n', length(l1aPD.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aPD.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aPD.time(end))));
            if options.plotFlag
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1aPD.time);
                figure;
                plot(x_datetime_data, l1aPD.curr, 'b.');
                grid on
                stylize_figure(gcf, 5, 4);
            end
        end
    end

    methods(Static)
        function l1aHS = readHeatSink(jul_day1, jul_day2, options)
            %readHeatSink Read L1A heat sink data from HDF files
            %   l1aHS = NIL1A.readHeatSink(jul_day1, jul_day2, options)
            %   Inputs:
            %       jul_day1: first Julian day
            %       jul_day2: last Julian day (inclusive)
            %       options: 
            %           directory: directory of the HDF files, default is
            %               NIConstants.dir.root/NIConstants.dir.hdf
            %           average: option to show averaged data, options
            %               include '4-shutter', 'hourly', '2-hour', default is 'none'
            %           plotFlag: plot the data or not, default is false
            %   Outputs:
            %       l1aHS: structure containing the L1A heat sink data
            %           l1aHS.time: time in DSCOVR epoch
            %           l1aHS.hs: heat sink ADC power
            %           
            %   Example:
            %       l1aHS = NIL1A.readHeatSink(2457204, 2457205, plotFlag=true);

            arguments
                jul_day1 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.average string {mustBeMember(options.average, {'none', '4-shutter', 'hourly', '2-hour'})} = 'none'
                options.plotFlag logical = false
            end
            fprintf('\n');
            l1aHS = struct('time', [], 'hs', []);

            valid_file_count = 0;
            for jul_day = jul_day1:jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1a', options.directory);
                catch ME
                    warning('No L1A HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                fprintf('Reading L1A HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1aHS_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1aScience);
                catch ME
                    warning('No/Unable to read L1A heat sink data found in the HDF file %s\n', filename.no_path);
                    fprintf('%s', ME.message);
                    continue;
                end
                l1aHS.time = [l1aHS.time; l1aHS_data.H052TIME];
                l1aHS.hs = [l1aHS.hs; l1aHS_data.NIHSHDACCMDAVG];
                valid_file_count = valid_file_count + 1;
            end

            if valid_file_count == 0
                error('No valid L1A HDF file is found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid files.\n', length(l1aHS.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aHS.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aHS.time(end))));
            
            if options.average ~= "none"
                if strcmp(options.average, '4-shutter')
                    average_window = 4*NIConstants.receivers.shutter_period;
                elseif strcmp(options.average, 'hourly')
                    average_window = 3600;
                elseif strcmp(options.average, '2-hour')
                    average_window = 2*3600;
                else
                    error('Unknown averaging option %s. Available options include: %s, %s, %s', options.average, '4-shutter', 'hourly', '2-hour');
                end
                fprintf('Averaging the data with a window of %d seconds...\n', average_window);
                step = average_window;
                averaged_hs = running_ave(l1aHS.time, l1aHS.hs, average_window, step);
                l1aHS.time = averaged_hs.time;
                l1aHS.hs = averaged_hs.data;
            end

            if options.plotFlag
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1aHS.time);
                figure;
                plot(x_datetime_data, l1aHS.hs, 'b.');
                grid on
                stylize_figure(gcf, 5, 4);
            end
        end
    end

    methods(Static)
        function l1aFW = readFilterWheel(jul_day1, jul_day2, options)
            %READFILTERWHEEL Read L1A filter wheel data from HDF files
            %   l1aFW = readFilterWheel(jul_day1, jul_day2, options)
            %
            %   Inputs:
            %       jul_day1: first Julian day
            %       jul_day2: last Julian day (inclusive)
            %       options: 
            %           directory: directory of the HDF files, default is
            %               NIConstants.dir.root/NIConstants.dir.hdf
            %           average: option to show averaged data (using median),
            %               options include '4-shutter', 'hourly', '2-hour', default is 'none'
            %           plotFlag: plot the data or not, default is false
            %   Outputs:
            %       l1aFW: structure containing the L1A filter wheel data
            %           l1aFW.time: time in DSCOVR epoch
            %           l1aFW.fw: filter wheel position
            %           
            %   Example:
            %       l1aFW = NIReadL1A.readFilterWheel(2457204, 2457205, plotFlag=true);

            arguments
                jul_day1 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end
            fprintf('\n');
            l1aFW = struct('time', [], 'fw', []);

            valid_file_count = 0;
            for jul_day = jul_day1:jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1a', options.directory);
                catch ME
                    warning('No L1A HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                fprintf('Reading L1A HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1aFW_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1aScience);
                catch ME
                    warning('No/Unable to read L1A filter wheel data found in the HDF file %s\n', filename.no_path);
                    fprintf('%s', ME.message);
                    continue;
                end
                l1aFW.time = [l1aFW.time; l1aFW_data.H052TIME];
                l1aFW.fw = [l1aFW.fw; l1aFW_data.NIPREFWPOSNUM];
                valid_file_count = valid_file_count + 1;
            end

            if valid_file_count == 0
                error('No valid L1A HDF file is found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid files.\n', length(l1aFW.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aFW.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1aFW.time(end))));
            
            if options.average ~= "none"
                if strcmp(options.average, '4-shutter')
                    average_window = 4*NIConstants.receivers.shutter_period;
                elseif strcmp(options.average, 'hourly')
                    average_window = 3600;
                elseif strcmp(options.average, '2-hour')
                    average_window = 2*3600;
                else
                    error('Unknown averaging option %s. Available options include: %s, %s, %s', options.average, '4-shutter', 'hourly', '2-hour');
                end
                fprintf('Averaging the data with a window of %d seconds...\n', average_window);
                step = average_window;
                averaged_fw = running_ave(l1aFW.time, l1aFW.fw, average_window, step, method='median');
                l1aFW.time = averaged_fw.time;
                l1aFW.fw = averaged_fw.data;
            end
            
            if options.plotFlag
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1aFW.time);
                figure;
                plot(x_datetime_data, l1aFW.fw, 'b.');
                grid on
                stylize_figure(gcf, 5, 4);
            end
        end
    end

end

