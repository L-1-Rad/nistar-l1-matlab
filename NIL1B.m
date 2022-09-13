classdef NIL1B

    methods(Static)
        function l1bDemod = readL1BDemodPower(jul_day1, jul_day2, options)
            %readL1BDemodPower Read NIST L1B demodulated radiometer data
            %   l1bDemod = readL1BDemodPower(jul_day1, jul_day2, options)
            %   Inputs:
            %       jul_day1: first Julian day
            %       jul_day2: last Julian day (inclusive)
            %       options: 
            %           directory: directory of the HDF files, default is
            %               NIConstants.dir.root/NIConstants.dir.hdf
            %           plotFlag: plot the data or not, default is false
            %   Outputs:
            %       l1bDemod: a structure containing the following fields
            %           time: DSCOVR epoch time
            %           demod_rc1: demodulated ADC power of receiver 1 real component
            %           demod_rc2: demodulated ADC power of receiver 2 real component
            %           demod_rc3: demodulated ADC power of receiver 3 real component
            %           demod_rc1_im: demodulated ADC power of receiver 1 imaginary component
            %           demod_rc2_im: demodulated ADC power of receiver 2 imaginary component
            %           demod_rc3_im: demodulated ADC power of receiver 3 imaginary component
            %           fw: filter wheel position
            %           rc1_shutter: shutter position of receiver 1
            %           rc2_shutter: shutter position of receiver 2
            %           rc3_shutter: shutter position of receiver 3
            %
            %   Example:
            %       l1bDemod = readL1BDemodPower(2458000, 2458001, plotFlag=true);

            arguments
                jul_day1 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end

            fprintf('\n');
            l1bDemod = struct('time', [], 'demod_rc1', [], 'demod_rc2', [], 'demod_rc3', [], ...
                'demod_rc1_im', [], 'demod_rc2_im', [], 'demod_rc3_im', [], 'fw', [], ...
                'rc1_shutter', [], 'rc2_shutter', [], 'rc3_shutter', []);
            
            valid_file_count = 0;

            for jul_day = jul_day1 : jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1b', options.directory);
                catch ME
                    warning('No L1B HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s\n', ME.message);
                    continue;
                end
                fprintf('Reading L1B HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1bDemod_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1bDemod);
                catch ME
                    warning('No/Unable to read L1B radiometry data found in the HDF file %s\n', filename.no_path);
                    fprintf('%s\n', ME.message);
                    continue;
                end
                l1bDemod.time = [l1bDemod.time; l1bDemod_data.DSCOVREpochTime];
                l1bDemod.demod_rc1 = [l1bDemod.demod_rc1; l1bDemod_data.DemodulatedRadiometerPower1];
                l1bDemod.demod_rc2 = [l1bDemod.demod_rc2; l1bDemod_data.DemodulatedRadiometerPower2];
                l1bDemod.demod_rc3 = [l1bDemod.demod_rc3; l1bDemod_data.DemodulatedRadiometerPower3];
                l1bDemod.demod_rc1_im = [l1bDemod.demod_rc1_im; l1bDemod_data.DemodulatedRadiometerPower1Imaginary];
                l1bDemod.demod_rc2_im = [l1bDemod.demod_rc2_im; l1bDemod_data.DemodulatedRadiometerPower2Imaginary];
                l1bDemod.demod_rc3_im = [l1bDemod.demod_rc3_im; l1bDemod_data.DemodulatedRadiometerPower3Imaginary];
                l1bDemod.fw = [l1bDemod.fw; l1bDemod_data.FilterWheel];
                l1bDemod.shutter_rc1 = [l1bDemod.shutter_rc1; l1bDemod_data.ShutterMotor1];
                l1bDemod.shutter_rc2 = [l1bDemod.shutter_rc2; l1bDemod_data.ShutterMotor2];
                l1bDemod.shutter_rc3 = [l1bDemod.shutter_rc3; l1bDemod_data.ShutterMotor3];
                valid_file_count = valid_file_count + 1;
            end
            if valid_file_count == 0
                error('No valid L1B HDF file is found in the path %s', options.directory);
            end
            fprintf('\nRead %d records from %d valid files.\n', length(l1bDemod.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bDemod.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bDemod.time(end))));

            if options.plotFlag
                figure;
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1bDemod.time);
                subplot(3, 1, 1)
                plot(x_datetime_data, l1bDemod.demod_rc1, '.')
                grid on
                title('RC1 Demodulated Radiometer Power')
                subplot(3, 1, 2)
                plot(x_datetime_data, l1bDemod.demod_rc2, '.')
                grid on
                title('RC2 Demodulated Radiometer Power')
                subplot(3, 1, 3)
                plot(x_datetime_data, l1bDemod.demod_rc3, '.')
                grid on
                title('RC3 Demodulated Radiometer Power')
                stylize_figure(gcf, 6, 8);
            end
        end
    end

    methods(Static)
        function l1bEarthRad = readL1BIrradiance(jul_day1, jul_day2, options)
            %readL1BIrradiance Read L1B Earth signal data from HDF files
            %
            %   l1bEarthRad = readL1BIrradiance(jul_day1, jul_day2, options)
            %
            %   Input:
            %       jul_day1: first Julian day to read
            %       jul_day2: last Julian day to read
            %       options.directory: directory of HDF files
            %       options.plotFlag: plot the data
            %
            %   Output:
            %       l1bEarthRad: structure containing the following fields
            %           time_c: DSCOVR epoch time for receiver 1 (band c) data
            %           time_a: DSCOVR epoch time for receiver 2 (band a) data
            %           time_b: DSCOVR epoch time for receiver 3 (band b) data
            %           irradiance_c: Earth irradiance for receiver 1 (band c) data
            %           irradiance_a: Earth irradiance for receiver 2 (band a) data
            %           irradiance_b: Earth irradiance for receiver 3 (band b) data
            %           radiance_c: Earth radiance for receiver 1 (band c) data
            %           radiance_a: Earth radiance for receiver 2 (band a) data
            %           radiance_b: Earth radiance for receiver 3 (band b) data
            %           radiance_b_corr: Earth radiance for receiver 3 (band b) data corrected for the
            %               effect of the Moon intrusions
            %           radiance_b_corr_unc: the uncertainty of radiance_b_corr
            %           is_interp_b: flag for whether the radiance_b from interpolation
            %
            %   Example:
            %       l1bEarthRad = NIL1B.readL1BIrradiance(2458000, 2458001, plotFlag=true);

            arguments
                jul_day1 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end

            fprintf('\n');
            l1bEarthRad = struct('time_c', [], 'time_a', [], 'time_b', [], 'irradiance_c', [], 'irradiance_a', [], ...
                'irradiance_b', [], 'radiance_c', [], 'radiance_a', [], 'radiance_b', [], 'radiance_b_corr', [], ...
                'radiance_b_corr_unc', [], 'is_interp_b', []);

            valid_file_count = 0;

            for jul_day = jul_day1 : jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd'); 
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1b', options.directory);
                catch
                    warning('No L1B HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    continue;
                end
                fprintf('Reading L1B HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1bEarthRad_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1bEarthRadA);
                    l1bEarthRad.time_a = [l1bEarthRad.time_a; l1bEarthRad_data.DSCOVREpochTime];
                    l1bEarthRad.irradiance_a = [l1bEarthRad.irradiance_a; l1bEarthRad_data.Irradiance];
                    l1bEarthRad.radiance_a = [l1bEarthRad.radiance_a; l1bEarthRad_data.Radiance];
                catch
                    warning('No/Unable to read L1B Band A Earth irradiance data found in the HDF file %s\n', filename.no_path);
                end
                try
                    l1bEarthRad_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1bEarthRadB);
                    l1bEarthRad.time_b = [l1bEarthRad.time_b; l1bEarthRad_data.DSCOVREpochTime];
                    l1bEarthRad.irradiance_b = [l1bEarthRad.irradiance_b; l1bEarthRad_data.Irradiance];
                    l1bEarthRad.radiance_b = [l1bEarthRad.radiance_b; l1bEarthRad_data.Radiance];
                    l1bEarthRad.radiance_b_corr = [l1bEarthRad.radiance_b_corr; l1bEarthRad_data.LunarCorrection];
                    l1bEarthRad.radiance_b_corr_unc = [l1bEarthRad.radiance_b_corr_unc; l1bEarthRad_data.LunarCorrectionUncertainty];
                    l1bEarthRad.is_interp_b = [l1bEarthRad.is_interp_b; l1bEarthRad_data.IsInterpolatedData];
                catch
                    warning('No/Unable to read L1B Band B Earth irradiance data found in the HDF file %s\n', filename.no_path);
                end
                try
                    l1bEarthRad_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1bEarthRadC);
                    l1bEarthRad.time_c = [l1bEarthRad.time_c; l1bEarthRad_data.DSCOVREpochTime];
                    l1bEarthRad.irradiance_c = [l1bEarthRad.irradiance_c; l1bEarthRad_data.Irradiance];
                    l1bEarthRad.radiance_c = [l1bEarthRad.radiance_c; l1bEarthRad_data.Radiance];
                catch
                    warning('No/Unable to read L1B Band C Earth irradiance data found in the HDF file %s\n', filename.no_path);
                end
                if ~isempty(l1bEarthRad.time_a) || ~isempty(l1bEarthRad.time_b) || ~isempty(l1bEarthRad.time_c)
                    valid_file_count = valid_file_count + 1;
                end
            end
            if valid_file_count == 0
                error('No valid L1B HDF file found for the given Julian day range');
            end
            fprintf('\nRead %d band A records, %d band B records, and %d band C records from %d valid files.\n', ...
                length(l1bEarthRad.time_a), length(l1bEarthRad.time_b), length(l1bEarthRad.time_c), valid_file_count);
            fprintf('First band A record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_a(1))));
            fprintf('Last band A record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_a(end))));
            fprintf('First band B record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_b(1))));
            fprintf('Last band B record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_b(end))));
            fprintf('First band C record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_c(1))));
            fprintf('Last band C record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_c(end))));

            if options.plotFlag
                x_datetime_data_a = NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_a);
                x_datetime_data_b = NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_b);
                x_datetime_data_c = NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthRad.time_c);

                figure;
                subplot(3, 1, 1);
                plot(x_datetime_data_a, l1bEarthRad.irradiance_a);
                hold on;
                plot(x_datetime_data_b, l1bEarthRad.irradiance_b);
                plot(x_datetime_data_c, l1bEarthRad.irradiance_c);
                title('Irradiance');
                legend('Band A', 'Band B', 'Band C');
                subplot(3, 1, 2);
                plot(x_datetime_data_a, l1bEarthRad.radiance_a);
                hold on;
                plot(x_datetime_data_b, l1bEarthRad.radiance_b);
                plot(x_datetime_data_c, l1bEarthRad.radiance_c);
                title('Radiance');
                legend('Band A', 'Band B', 'Band C');
                subplot(3, 1, 3);
                plot(x_datetime_data_b, l1bEarthRad.radiance_b_corr);
                hold on;
                plot(x_datetime_data_b, l1bEarthRad.radiance_b_corr_unc);
                title('Shortwave Radiance Correction');
                legend('Lunar Correction', 'Lunar Correction Uncertainty');
                stylize_figure(gcf, 6, 8);
            end
        end
    end

    methods(Static)
        function l1bEarthPD = readL1BEarthPDCurrent(jul_day1, jul_day2, options)
            %   Read L1B Earth PD data for the given Julian day range
            %   Inputs:
            %       jul_day1: start Julian day
            %       jul_day2: end Julian day
            %       options: options for reading L1B data
            %           directory: directory where L1B data is stored
            %           plotFlag: flag to plot L1B data
            %   Outputs:
            %       l1bEarthPD: L1B Earth PD data
            %           time: DSCOVR epoch time
            %           curr: Earth Photodiode current
            %           curr_norm: Earth Photodiode current normalized to Earth distance
            %
            %   Example:
            %       l1bEarthPD = NIL1B.readL1BEarthPDCurrent(2458000, 2458001, plotFlag=true);

            arguments
                jul_day1 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day1, 2457203.5)}
                jul_day2 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(jul_day2, jul_day1)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.plotFlag logical = false
            end
            fprintf('\n');
            l1bEarthPD = struct('time', [], 'curr', [], 'curr_norm', []);
            valid_file_count = 0;

            for jul_day = jul_day1 : jul_day2
                curr_datetime = NIDateTime.getCalendarDateFromJulianDay(jul_day);
                date = datestr(curr_datetime + hours(12), 'YYYYmmdd');                
                try
                    filename = NIHDF.getHDFFilenameByDate(date, '1b', options.directory);
                catch ME
                    warning('No L1B HDF file found for Julian day %d in the path %s', jul_day, options.directory);
                    fprintf('%s\n', ME.message);
                    continue;
                end
                fprintf('Reading L1B HDF file %s (%s to %s)...\n', filename.no_path, datestr(curr_datetime), datestr(curr_datetime + days(1)));
                try
                    l1bEarthPD_data = h5read(filename.with_path, NIConstants.hdfDataSet.l1bEarthPD);
                catch ME
                    warning('No/Unable to read L1B radiometry data found in the HDF file %s\n', filename.no_path);
                    fprintf('%s\n', ME.message);
                    continue;
                end
                l1bEarthPD.time = [l1bEarthPD.time; l1bEarthPD_data.DSCOVREpochTime];
                l1bEarthPD.curr = [l1bEarthPD.curr; l1bEarthPD_data.PhotodiodeCurrent];
                l1bEarthPD.curr_norm = [l1bEarthPD.curr_norm; l1bEarthPD_data.PhotodiodeCurrent1AU];

                valid_file_count = valid_file_count + 1;
            end
            if valid_file_count == 0
                error('No valid L1B HDF file found for the given Julian day range');
            end
            fprintf('\nRead %d records from %d L1B HDF files\n', length(l1bEarthPD.time), valid_file_count);
            fprintf('First record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthPD.time(1))));
            fprintf('Last record: %s\n', datestr(NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthPD.time(end))));
            if options.plotFlag
                x_datetime_data = NIDateTime.getCalendarDateFromDSCOVREpoch(l1bEarthPD.time);
                figure;
                subplot(2, 1, 1);
                plot(x_datetime_data, l1bEarthPD.curr);
                title('Earth Photodiode Current');
                subplot(2, 1, 2);
                plot(x_datetime_data, l1bEarthPD.curr_norm);
                title('Earth Photodiode Current Normalized to 1 AU');
                stylize_figure(gcf, 6, 8);
            end
        end
    end
    
    methods(Static)
        function [bandA, bandB, bandC, bandPD, averaged] = readL1BFiltered(year1, month1, year2, month2, options)
            %readL1BFiltered Read L1B filtered data for the given year and month range
            %   Inputs:
            %       year1: start year
            %       month1: start month
            %       year2: end year (inclusive)
            %       month2: end month (inclusive)
            %       options: options for reading L1B data
            %           directory: directory where L1B data is stored
            %           average: generate averaged data
            %           plotFlag: flag to plot L1B data
            %           version: L1B version, current default value is 4
            %   Outputs:
            %       bandA: L1B Band A data
            %           time: DSCOVR epoch time
            %           radiance: Band A Earth radiance
            %           source: Band A data source encoded as an integer
            %       bandB: L1B Band B data
            %           time: DSCOVR epoch time
            %           radiance: Band B Earth radiance
            %           source: Band B data source encoded as an integer
            %       bandC: L1B Band C data
            %           time: DSCOVR epoch time
            %           radiance: Band C Earth radiance
            %           source: Band C data source encoded as an integer
            %       bandPD: L1B Earth PD data
            %           time: DSCOVR epoch time
            %           curr: Earth Photodiode current
            %           curr_norm: Earth Photodiode current normalized to Earth distance
            %       averaged: averaged L1B data of all channels (including longwave)
            %           time_a: DSCOVR epoch time for Band A
            %           time_b: DSCOVR epoch time for Band B and longwave
            %           time_c: DSCOVR epoch time for Band C
            %           time_pd: DSCOVR epoch time for Earth PD
            %           radiance_a: Band A Earth radiance
            %           radiance_b: Band B Earth radiance
            %           radiance_c: Band C Earth radiance
            %           radiance_lw: longwave Earth radiance
            %           curr: Earth Photodiode current (normalized to 1 AU)
            %
            %   Example:
            %       [bandA, bandB, bandC, bandPD, averaged] = NIL1B.readL1BFiltered(2017, 1, 2017, 2, plotFlag=true);

            arguments
                year1 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(year1, 2015)}
                month1 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(month1, 1), mustBeLessThanOrEqual(month1, 12)}
                year2 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(year2, year1)}
                month2 (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(month2, 1), mustBeLessThanOrEqual(month2, 12)}
                options.directory string {mustBeFolder} = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.average string {mustBeMember(options.average, {'none', 'daily', 'weekly'})} = 'none'
                options.plotFlag logical = false
                options.version (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.version, 1), mustBeLessThanOrEqual(options.version, 4)} = 4
            end
            fprintf('\n');
            bandA = struct('time', [], 'radiance', [], 'source', []);
            bandB = struct('time', [], 'radiance', [], 'source', []);
            bandC = struct('time', [], 'radiance', [], 'source', []);
            bandPD = struct('time', [], 'curr', [], 'source', []);
            averaged = struct('time_a', [], 'time_b', [], 'time_c', [], 'time_pd', [], 'radiance_a', [], 'radiance_b', [], 'radiance_c', [], 'radiance_lw', [], 'curr', []);

            index1 = (year1 - 2017) * 12 + month1 - 1;
            index2 = (year2 - 2017) * 12 + month2 - 1;

            for i = index1:index2
                if i > 29 && i < 38 % DSCOVR extended safe mode
                    continue;
                end
                curr_datetime = datetime(2017, 1, 1) + calmonths(i);
                curr_year = curr_datetime.Year;
                curr_month = curr_datetime.Month;

                filename = sprintf('nist_1b_%d%02d_filtered_%02d.h5', curr_year, curr_month, options.version);
                filename = strcat(options.directory, filename);
                if ~exist(filename, 'file')
                    warning('No L1B filtered data product found for year %d month %d\n', curr_year, curr_month);
                    continue;
                end
                fprintf('Reading L1B filtered data for year %d month %d\n', curr_year, curr_month);
                try
                    bandA_data = h5read(filename, NIConstants.hdfDataSet.l1bFilteredA);
                    bandA.time = [bandA.time; bandA_data.DSCOVREpochTime];
                    bandA.radiance = [bandA.radiance; bandA_data.EarthRadiance];
                    bandA.source = [bandA.source; bandA_data.IsInterpolated];
                catch ME
                    warning('Failed to read L1B filtered Band A data for year %d month %d\n', curr_year, curr_month);
                    fprintf('%s\n', ME.message);
                end
                try
                    bandB_data = h5read(filename, NIConstants.hdfDataSet.l1bFilteredB);
                    bandB.time = [bandB.time; bandB_data.DSCOVREpochTime];
                    bandB.radiance = [bandB.radiance; bandB_data.EarthRadiance];
                    bandB.source = [bandB.source; bandB_data.IsInterpolated];
                catch ME
                    warning('Failed to read L1B filtered Band B data for year %d month %d\n', curr_year, curr_month);
                    fprintf('%s\n', ME.message);
                end
                try
                    bandC_data = h5read(filename, NIConstants.hdfDataSet.l1bFilteredC);
                    bandC.time = [bandC.time; bandC_data.DSCOVREpochTime];
                    bandC.radiance = [bandC.radiance; bandC_data.EarthRadiance];
                    bandC.source = [bandC.source; bandC_data.IsInterpolated];
                catch ME
                    warning('Failed to read L1B filtered Band C data for year %d month %d\n', curr_year, curr_month);
                    fprintf('%s\n', ME.message);
                end
                try
                    bandPD_data = h5read(filename, NIConstants.hdfDataSet.l1bFilteredPD);
                    bandPD.time = [bandPD.time; bandPD_data.DSCOVREpochTime];
                    bandPD.curr = [bandPD.curr; bandPD_data.EarthRadiance];
                    bandPD.source = [bandPD.source; bandC_data.IsInterpolated];
                catch ME
                    warning('Failed to read L1B filtered Earth PD data for year %d month %d\n', curr_year, curr_month);
                    fprintf('%s\n', ME.message);
                end
            end

            if options.average ~= "none"
                if strcmp(options.average, 'daily')
                    average_window = 86400;
                elseif strcmp(options.average, 'weekly')
                    average_window = 86400 * 7;
                else
                    error('Unknown averaging option %s. Available options include: %s, %s', options.average, 'daily', 'weekly');
                end
                fprintf('Averaging the data with a window of %d seconds...\n', average_window);
                step = 86400;
                bandA_average = running_ave(bandA.time, bandA.radiance, average_window, step, data_rate=10);
                bandB_average = running_ave(bandB.time, bandB.radiance, average_window, step, data_rate=10);
                bandC_average = running_ave(bandC.time, bandC.radiance, average_window, step, data_rate=10);
                bandPD_average = running_ave(bandPD.time, bandPD.curr, average_window, step, data_rate=10);
                averaged.time_a = bandA_average.time;
                averaged.time_b = bandB_average.time;
                averaged.time_c = bandC_average.time;
                averaged.time_pd = bandPD_average.time;
                averaged.radiance_a = bandA_average.data;
                averaged.radiance_b = bandB_average.data;
                averaged.radiance_c = bandC_average.data;
                radiance_a_interp = interp1(averaged.time_a, averaged.radiance_a, averaged.time_b, 'linear');
                averaged.radiance_lw = transpose(radiance_a_interp) - averaged.radiance_b / NIConstants.bandB_filter_scale;
                averaged.curr = bandPD_average.data
            end

            if options.plotFlag
                figure;
                subplot(3, 1, 1);
                plot(NIDateTime.getCalendarDateFromDSCOVREpoch(bandA.time), bandA.radiance, 'b.');
                subplot(3, 1, 2);
                plot(NIDateTime.getCalendarDateFromDSCOVREpoch(bandB.time), bandB.radiance, 'r.');
                subplot(3, 1, 3);
                plot(NIDateTime.getCalendarDateFromDSCOVREpoch(bandC.time), bandC.radiance, 'g.');
                stylize_figure(gcf, 6, 8);
                figure;
                plot(NIDateTime.getCalendarDateFromDSCOVREpoch(bandB.time), bandB.radiance);
                hold on;
                scale_factor = mean(bandB.radiance, 'omitnan') / mean(bandPD.curr, 'omitnan');
                plot(NIDateTime.getCalendarDateFromDSCOVREpoch(bandPD.time), bandPD.curr * scale_factor);
                stylize_figure(gcf, 6, 4);
                if options.average ~= "none"
                    figure;
                    hold on
                    plot(NIDateTime.getCalendarDateFromDSCOVREpoch(averaged.time_pd), averaged.curr * scale_factor, 'k');
                    plot(NIDateTime.getCalendarDateFromDSCOVREpoch(averaged.time_b), averaged.radiance_b, 'r');
                    title(sprintf('%s averaged SW vs PD channels', options.average));
                    legend('Scaled Photodiode Current', 'Shortwave');
                    ylabel('$W/m^2/sr$');
                    stylize_figure(gcf, 6, 4, override_line_color=true);
                end
            end
        end
    end
end
                