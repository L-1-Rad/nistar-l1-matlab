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
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)} = jul_day1
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
                jul_day2 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)} = jul_day1
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
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)} = jul_day1
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
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)} = jul_day1
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
                plot(x_datetime_data, l1aHS.hs, '.');
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
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)} = jul_day1
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

    methods (Static)
        function receiver_apid82_data = readReceiverAppID82(jul_day1, jul_day2, options)
            %readReceiverAppID82 Read receiver data from /Science_Data/ScienceData in Level 1A product
            %Also including data of the heatsink heater DAC power and PTC.
            %   receiver_apid82_data = NIL1A.readReceiverAppID82(jul_day1, jul_day2, options)
            %   Inputs:
            %    jul_day1: first Julian day
            %    jul_day2: last Julian day (inclusive)
            %    options:
            %       directory: directory of the HDF files, default is
            %           NIConstants.dir.root/NIConstants.dir.hdf
            %       average: option to show averaged data, options include
            %           '4-shutter', 'hourly', '2-hour', default is 'none'
            %       plotFlag: plot the data or not, default is false
            %   Outputs:
            %       receiver_apid82_data: structure containing the receiver data
            %           receiver_apid82_data.time: time in DSCOVR epoch 
            %           receiver_apid82_data.rc1_adc: receiver 1 heater ADC
            %           receiver_apid82_data.rc2_adc: receiver 2 heater ADC
            %           receiver_apid82_data.rc3_adc: receiver 3 heater ADC
            %           receiver_apid82_data.hs_dac: heat sink heater DAC (same as NIL1A.readHeatSink)
            %           receiver_apid82_data.rc1_shutter: receiver 1 shutter
            %           receiver_apid82_data.rc2_shutter: receiver 2 shutter
            %           receiver_apid82_data.rc3_shutter: receiver 3 shutter
            %           receiver_apid82_data.rc1_ptc: receiver 1 PTC
            %           receiver_apid82_data.rc2_ptc: receiver 2 PTC
            %           receiver_apid82_data.rc3_ptc: receiver 3 PTC
            %           receiver_apid82_data.hs_ptc: heat sink PTC
            %           receiver_apid82_data.autocycle: shutter autocycle status (0: off, 1: on)
            %           receiver_apid82_data.rc1_bit: receiver 1 shutter BIT (0: error, 1: normal)
            %           receiver_apid82_data.rc2_bit: receiver 2 shutter BIT (0: error, 1: normal)
            %           receiver_apid82_data.rc3_bit: receiver 3 shutter BIT (0: error, 1: normal)
            %           receiver_apid82_data.fw_pos: filter wheel position (same as NIL1A.readFilterWheel)

            arguments
                jul_day1 (1,1) double
                jul_day2 (1,1) double
                options.directory (1,1) string = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.average (1,1) string = "none"
                options.plotFlag (1,1) logical = false
            end
            fprintf('\n');
            receiver_apid82_data = struct('time', [], 'rc1_adc', [], 'rc2_adc', [], 'rc3_adc', [], ...
                'hs_dac', [], 'rc1_shutter', [], 'rc2_shutter', [], 'rc3_shutter', [], ...
                'rc1_ptc', [], 'rc2_ptc', [], 'rc3_ptc', [], 'hs_ptc', [], ...
                'autocycle', [], 'rc1_bit', [], 'rc2_bit', [], 'rc3_bit', [], 'fw_pos', []);

            valid_file_count = 0;
            for jul_day = jul_day1:jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'yyyymmdd');
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1a', options.directory);
                catch ME
                    warning('Failed to find L1A product for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                fprintf('Reading L1A HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    apid82 = h5read(filename.with_path, NIConstants.hdfDataSet.l1aScience);
                catch ME
                    warning('Failed to read L1A product for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s', ME.message);
                    continue;
                end
                valid_file_count = valid_file_count + 1;
                receiver_apid82_data.time = [receiver_apid82_data.time; apid82.H052TIME];
                receiver_apid82_data.rc1_adc = [receiver_apid82_data.rc1_adc; apid82.NIRC1HADCMFLAVG];
                receiver_apid82_data.rc2_adc = [receiver_apid82_data.rc2_adc; apid82.NIRC2HADCMFLAVG];
                receiver_apid82_data.rc3_adc = [receiver_apid82_data.rc3_adc; apid82.NIRC3HADCMFLAVG];
                receiver_apid82_data.hs_dac = [receiver_apid82_data.hs_dac; apid82.NIHSHDACCMDAVG];
                receiver_apid82_data.rc1_shutter = [receiver_apid82_data.rc1_shutter; apid82.NIRC1PRESHPOSNUM];
                receiver_apid82_data.rc2_shutter = [receiver_apid82_data.rc2_shutter; apid82.NIRC2PRESHPOSNUM];
                receiver_apid82_data.rc3_shutter = [receiver_apid82_data.rc3_shutter; apid82.NIRC3PRESHPOSNUM];
                receiver_apid82_data.rc1_ptc = [receiver_apid82_data.rc1_ptc; apid82.NIRC1PTCMRESAVG];
                receiver_apid82_data.rc2_ptc = [receiver_apid82_data.rc2_ptc; apid82.NIRC2PTCMRESAVG];
                receiver_apid82_data.rc3_ptc = [receiver_apid82_data.rc3_ptc; apid82.NIRC3PTCMRESAVG];
                receiver_apid82_data.hs_ptc = [receiver_apid82_data.hs_ptc; apid82.NIHSPTCMRESAVG];
                receiver_apid82_data.autocycle = [receiver_apid82_data.autocycle; apid82.NIAUTOCYCLE];
                receiver_apid82_data.rc1_bit = [receiver_apid82_data.rc1_bit; apid82.NIRC1SHTRBIT];
                receiver_apid82_data.rc2_bit = [receiver_apid82_data.rc2_bit; apid82.NIRC2SHTRBIT];
                receiver_apid82_data.rc3_bit = [receiver_apid82_data.rc3_bit; apid82.NIRC3SHTRBIT];
                receiver_apid82_data.fw_pos = [receiver_apid82_data.fw_pos; apid82.NIPREFWPOSNUM];
            end
            if valid_file_count == 0
                error('No valid L1A product found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid L1A products.\n', length(receiver_apid82_data.time), valid_file_count);
            fprintf('First record: %s\n', datestr(receiver_apid82_data.time(1)));
            fprintf('Last record: %s\n', datestr(receiver_apid82_data.time(end)));

            if options.average ~= "none"
                if strcmp(options.average, '4-shutter')
                    average_window = 4*NIConstants.receivers.shutter_period;
                elseif strcmp(options.average, 'hourly')
                    average_window = 3600;
                elseif strcmp(options.average, '2-hour')
                    average_window = 2*3600;
                else
                    error('Invalid averaging option: %s', options.average);
                end
                fprintf('Averaging data over %s...\n', options.average);
                step = average_window;
                averaged_rc1_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc1_adc, average_window, step);
                averaged_rc2_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc2_adc, average_window, step);
                averaged_rc3_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc3_adc, average_window, step);
                averaged_hs_dac = running_ave(receiver_apid82_data.time, receiver_apid82_data.hs_dac, average_window, step);
                averaged_rc1_shutter = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc1_shutter, average_window, step);
                averaged_rc2_shutter = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc2_shutter, average_window, step);
                averaged_rc3_shutter = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc3_shutter, average_window, step);
                averaged_rc1_ptc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc1_ptc, average_window, step, method='median');
                averaged_rc2_ptc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc2_ptc, average_window, step, method='median');
                averaged_rc3_ptc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc3_ptc, average_window, step, method='median');
                averaged_hs_ptc = running_ave(receiver_apid82_data.time, receiver_apid82_data.hs_ptc, average_window, step, method='median');
                averaged_autocycle = running_ave(receiver_apid82_data.time, receiver_apid82_data.autocycle, average_window, step, method='median');
                averaged_rc1_bit = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc1_bit, average_window, step, method='median');
                averaged_rc2_bit = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc2_bit, average_window, step, method='median');
                averaged_rc3_bit = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc3_bit, average_window, step, method='median');
                averaged_fw_pos = running_ave(receiver_apid82_data.time, receiver_apid82_data.fw_pos, average_window, step, method='median');
                receiver_apid82_data.time = averaged_rc1_adc.time;
                receiver_apid82_data.rc1_adc = averaged_rc1_adc.data;
                receiver_apid82_data.rc2_adc = averaged_rc2_adc.data;
                receiver_apid82_data.rc3_adc = averaged_rc3_adc.data;
                receiver_apid82_data.hs_dac = averaged_hs_dac.data;
                receiver_apid82_data.rc1_shutter = averaged_rc1_shutter.data;
                receiver_apid82_data.rc2_shutter = averaged_rc2_shutter.data;
                receiver_apid82_data.rc3_shutter = averaged_rc3_shutter.data;
                receiver_apid82_data.rc1_ptc = averaged_rc1_ptc.data;
                receiver_apid82_data.rc2_ptc = averaged_rc2_ptc.data;
                receiver_apid82_data.rc3_ptc = averaged_rc3_ptc.data;
                receiver_apid82_data.hs_ptc = averaged_hs_ptc.data;
                receiver_apid82_data.autocycle = averaged_autocycle.data;
                receiver_apid82_data.rc1_bit = averaged_rc1_bit.data;
                receiver_apid82_data.rc2_bit = averaged_rc2_bit.data;
                receiver_apid82_data.rc3_bit = averaged_rc3_bit.data;
                receiver_apid82_data.fw_pos = averaged_fw_pos.data;
            end

            if options.plotFlag
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(receiver_apid82_data.time);
                figure;
                subplot(2, 2, 1)
                plot(x_datetime_data, receiver_apid82_data.rc1_adc, '.');
                subplot(2, 2, 2)
                plot(x_datetime_data, receiver_apid82_data.rc2_adc, '.');
                subplot(2, 2, 3)
                plot(x_datetime_data, receiver_apid82_data.rc3_adc, '.');
                subplot(2, 2, 4)
                plot(x_datetime_data, receiver_apid82_data.hs_dac, '.');
                stylize_figure(gcf, 6, 4);
                figure;
                subplot(2, 2, 1)
                plot(x_datetime_data, receiver_apid82_data.rc1_ptc, '.');
                subplot(2, 2, 2)
                plot(x_datetime_data, receiver_apid82_data.rc2_ptc, '.');
                subplot(2, 2, 3)
                plot(x_datetime_data, receiver_apid82_data.rc3_ptc, '.');
                subplot(2, 2, 4)
                plot(x_datetime_data, receiver_apid82_data.hs_ptc, '.');
                stylize_figure(gcf, 6, 4);
            end
        end
    end 
end

