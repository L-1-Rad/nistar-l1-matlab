classdef NIDiagnostic

    methods(Static) 
        function w_fieldnames = w_fieldnames()
    
            w_fieldnames.instru = {'dscTm', 'rc1PwrM', 'rc2PwrM', 'rc3PwrM', 'hsPwrM', ...
                            'rc1PwrD', 'rc2PwrD', 'rc3PwrD', 'hsPwrD', ...
                            'rc1PwrDIm', 'rc2PwrDIm', 'rc3PwrDIm', 'hsPwrDIm', ...
                            'rc1PwrPtcS', 'rc2PwrPtcS', 'rc3PwrPtcS', 'hsPwrPtcS', ...
                            'pdCur', 'status'};

            w_fieldnames.ephem = {'dscTm', 'nistView', 'dscPos', 'dscVel', ...
                            'dscAttRow1', 'dscAttRow2', 'dscAttRow3', ...
                            'dscLat', 'dscLon', 'solPos', 'lunPos', ...
                            'lunLat', 'lunLon'};
        end
    end

    methods(Static)
        function generateDiagnosticProduct(year, month, options)

            arguments
                year (1,1) double {mustBeInteger, mustBePositive}
                month (1,1) double {mustBeInteger, mustBePositive}
                options.input_dir (1,1) string = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
                options.output_dir (1,1) string = strcat(NIConstants.dir.root, NIConstants.dir.hdf)
            end

            start_jul_day = NIDateTime.getJulianDateFromCalendarDate(year, month, 0, 12);
            end_jul_day = NIDateTime.getJulianDateFromCalendarDate(year, month, eomday(year, month), 12);

            % read apid82 data
            receiver_apid82_data = NIL1A.readReceiverAppID82(start_jul_day, end_jul_day);

            if isempty(receiver_apid82_data)
                fprintf('No data for %d-%d found in the database for APID 82 (Receiver Data)\r ', year, month);
                return;
            end

            % need to read the photodiode current data too
            l1a_pd_data = NIL1A.readL1APhotodiode(start_jul_day, end_jul_day);

            % convert into writeable format
            w_instru_data = NIDiagnostic.convertToInstrumentData(receiver_apid82_data, l1a_pd_data);

            % create HDF file
            hdf_file_name = sprintf('nist_diagnostic_data_%d%02d.h5', year, month);
            hdf_file_path = fullfile(options.output_dir, hdf_file_name);
            hdf_file = H5F.create(hdf_file_path, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');

            % write apid82 data to HDF file
            NIDiagnostic.writeInstrumentData(hdf_file, w_instru_data);

            fprintf('Wrote instrument data to %s\n', hdf_file_path);

            % read ephemeris data
            nv_data = NIL1A.readNISTARView(start_jul_day, end_jul_day);
            dscovr_ephemeris_data = NIL1A.readEphemeris(start_jul_day, end_jul_day);
            lunar_ephemeris_data = NIL1A.readEphemeris(start_jul_day, end_jul_day, 'lunar');
            solar_ephemeris_data = NIL1A.readEphemeris(start_jul_day, end_jul_day, 'solar');
            attitude_data = NIL1A.readRotationMatrix(start_jul_day, end_jul_day);
            earth_subsatellite_data = NIL1A.readSubsatellitePoint(start_jul_day, end_jul_day);
            lunar_subsatellite_data = NIL1A.readSubsatellitePoint(start_jul_day, end_jul_day, 'lunar');

            % convert into writeable format
            w_ephemeris_data = NIDiagnostic.convertToEphemerisData(nv_data, dscovr_ephemeris_data, ...
                lunar_ephemeris_data, solar_ephemeris_data, attitude_data, earth_subsatellite_data, ...
                lunar_subsatellite_data);


            % update the status code in instrument data
            % w_instru_data = NIDiagnostic.updateInstrumentDataStatus(w_instru_data, w_ephemeris_data);

            % write ephemeris data to HDF file
            NIDiagnostic.writeEphemerisData(hdf_file, w_ephemeris_data);

            fprintf('Wrote ephemeris data to %s\n', hdf_file_path);

            H5F.close(hdf_file);

        end

        function writeInstrumentData(hdf_file, wdata)

            number_of_fields = length(NIDiagnostic.w_fieldnames.instru);
            
            % create the required datatypes
            sizes_of_fields = zeros(1, number_of_fields);
            double_type = H5T.copy('H5T_NATIVE_DOUBLE');
            for i = 1:number_of_fields
                sizes_of_fields(i) = H5T.get_size(double_type);
            end

            % compute the offsets of the fields, the first field starts at 0
            offsets_of_fields = zeros(1, number_of_fields);
            for i = 2:number_of_fields
                offsets_of_fields(i) = offsets_of_fields(i-1) + sizes_of_fields(i-1);
            end

            % create the compound datatype for memory
            memtype = H5T.create('H5T_COMPOUND', offsets_of_fields(number_of_fields) + sizes_of_fields(number_of_fields));
            for i = 1:number_of_fields
                H5T.insert(memtype, NIDiagnostic.w_fieldnames.instru{i}, offsets_of_fields(i), double_type);
            end

            % create the compound datatype for the file
            filetype = H5T.create('H5T_COMPOUND', offsets_of_fields(number_of_fields) + sizes_of_fields(number_of_fields));
            for i = 1:number_of_fields
                H5T.insert(filetype, NIDiagnostic.w_fieldnames.instru{i}, offsets_of_fields(i), double_type);
            end

            % create the data space
            dataspace = H5S.create_simple(1, length(wdata.dscTm), []);

            % create the dataset and write
            dset = H5D.create(hdf_file, 'INSTRUMENT_DATA', filetype, dataspace, 'H5P_DEFAULT');
            H5D.write(dset, memtype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', wdata);

            % close and release resources
            H5D.close(dset);
            H5T.close(memtype);
            H5T.close(filetype);
            H5S.close(dataspace);

        end

        function wdata = convertToInstrumentData(receiver_apid82_data, l1a_pd_data, downsample)

            arguments
                receiver_apid82_data struct
                l1a_pd_data struct
                downsample (1,1) {mustBePositive, mustBeInteger} = 10
            end

            fprintf('Converting data to instrument data...\n');

            number_of_fields = length(NIDiagnostic.w_fieldnames.instru);
            
            fprintf('Downsampling by a factor of %d\n', downsample);
            fprintf('Total number of records: %d\n', length(receiver_apid82_data.time));
            downsample_count = floor(length(receiver_apid82_data.time)/downsample);
            fprintf('Total number of records after downsampling: %d\n', downsample_count);

            values = cell(1, number_of_fields);
            for i = 1:number_of_fields
                values{i} = zeros(downsample_count, 1);
            end
            args = [NIDiagnostic.w_fieldnames.instru; values];
            wdata = struct(args{:});

            fprintf('Averaging modulated receiver power data...\n');
            average_window = NIConstants.receivers.shutter_period;
            step = 1;
            tic
            averaged_rc1_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc1_adc, average_window, step);
            averaged_rc2_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc2_adc, average_window, step);
            averaged_rc3_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc3_adc, average_window, step);
            averaged_hs_dac = running_ave(receiver_apid82_data.time, receiver_apid82_data.hs_dac, average_window, step);
            toc
            fprintf('Demodulating receiver power data...\n');
            demod_rc1_adc = demod(receiver_apid82_data.rc1_adc, receiver_apid82_data.rc1_shutter);
            demod_rc2_adc = demod(receiver_apid82_data.rc2_adc, receiver_apid82_data.rc2_shutter);
            demod_rc3_adc = demod(receiver_apid82_data.rc3_adc, receiver_apid82_data.rc3_shutter);
            demod_hs_dac = demod(receiver_apid82_data.hs_dac, receiver_apid82_data.rc2_shutter);

            for i = 1:length(wdata.dscTm)
                wdata.dscTm(i) = receiver_apid82_data.time(i*downsample);
                wdata.rc1PwrM(i) = averaged_rc1_adc.data(i*downsample);
                wdata.rc2PwrM(i) = averaged_rc2_adc.data(i*downsample);
                wdata.rc3PwrM(i) = averaged_rc3_adc.data(i*downsample);
                wdata.hsPwrM(i) = averaged_hs_dac.data(i*downsample);
                wdata.rc1PwrD(i) = demod_rc1_adc.re(i*downsample);
                wdata.rc2PwrD(i) = demod_rc2_adc.re(i*downsample);
                wdata.rc3PwrD(i) = demod_rc3_adc.re(i*downsample);
                wdata.hsPwrD(i) = demod_hs_dac.re(i*downsample);
                wdata.rc1PwrDIm(i) = demod_rc1_adc.im(i*downsample);
                wdata.rc2PwrDIm(i) = demod_rc2_adc.im(i*downsample);
                wdata.rc3PwrDIm(i) = demod_rc3_adc.im(i*downsample);
                wdata.hsPwrDIm(i) = demod_hs_dac.im(i*downsample);
                wdata.rc1PwrPtcS(i) = receiver_apid82_data.rc1_ptc(i*downsample);
                wdata.rc2PwrPtcS(i) = receiver_apid82_data.rc2_ptc(i*downsample);
                wdata.rc3PwrPtcS(i) = receiver_apid82_data.rc3_ptc(i*downsample);
                wdata.hsPwrPtcS(i) = receiver_apid82_data.hs_ptc(i*downsample);
                wdata.pdCur(i) = l1a_pd_data.curr(i*downsample);
                wdata.status(i) = 0;
            end
        end

        function writeEphemerisData(hdf_file, wdata)

            number_of_fields = length(NIDiagnostic.w_fieldnames.ephem);

            % create the required datatypes
            sizes_of_fields = zeros(1, number_of_fields);
            double_type = H5T.copy('H5T_NATIVE_DOUBLE');
                % create array type
            array_type = H5T.array_create(double_type, fliplr(3));
            for i = 1:number_of_fields
                if (i >= 3 && i <= 7) || (i >= 10 && i <= 11)
                    sizes_of_fields(i) = H5T.get_size(array_type);
                else
                    sizes_of_fields(i) = H5T.get_size(double_type);
                end
            end

            % compute the offsets of the fields, the first field is at offset 0
            offsets_of_fields = zeros(1, number_of_fields);
            for i = 2:number_of_fields
                offsets_of_fields(i) = offsets_of_fields(i-1) + sizes_of_fields(i-1);
            end

            % create the compound datatype for memory
            memtype = H5T.create('H5T_COMPOUND', offsets_of_fields(end) + sizes_of_fields(end));
            for i = 1:number_of_fields
                if (i >= 3 && i <= 7) || (i >= 10 && i <= 11)
                    H5T.insert(memtype, NIDiagnostic.w_fieldnames.ephem{i}, offsets_of_fields(i), array_type);
                else
                    H5T.insert(memtype, NIDiagnostic.w_fieldnames.ephem{i}, offsets_of_fields(i), double_type);
                end
            end

            % create the compound datatype for the file
            filetype = H5T.create('H5T_COMPOUND', offsets_of_fields(end) + sizes_of_fields(end));
            for i = 1:number_of_fields
                if (i >= 3 && i <= 7) || (i >= 10 && i <= 11)
                    H5T.insert(filetype, NIDiagnostic.w_fieldnames.ephem{i}, offsets_of_fields(i), array_type);
                else
                    H5T.insert(filetype, NIDiagnostic.w_fieldnames.ephem{i}, offsets_of_fields(i), double_type);
                end
            end

            % create the data space for the dataset
            dataspace = H5S.create_simple(1, length(wdata.dscTm), []);

            % create the dataset and write
            dataset = H5D.create(hdf_file, 'EPHEMERIS_DATA', filetype, dataspace, 'H5P_DEFAULT');
            H5D.write(dataset, memtype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', wdata);

            % close and release resources
            H5D.close(dataset);
            H5S.close(dataspace);
            H5T.close(filetype);
            H5T.close(memtype);
            H5T.close(array_type);
        end

        function wdata = convertToEphemerisData(nv_data, dscovr_ephemeris_data, ...
            lunar_ephemeris_data, solar_ephemeris_data, attitude_data, earth_subsatellite_data, ...
            lunar_subsatellite_data)

            % ephemeris data use 60 seconds cadence (1440 records per day) from DSCOVR ephemeris

            number_of_fields = length(NIDiagnostic.w_fieldnames.ephem);
            total_records = length(dscovr_ephemeris_data.time);

            values = cell(1, number_of_fields);
            args = [NIDiagnostic.w_fieldnames.ephem; values];
            wdata = struct(args{:});

            for i = 1:total_records
                wdata.dscTm(i) = dscovr_ephemeris_data.time(i);
                % for NISTAR view, attitude only
                idx = binary_search(nv_data.time, wdata.dscTm(i), tol=120, warn=false);
                if idx == -1
                    warning('No corresponding attitude data found for time %f', wdata.dscTm(i));
                    continue;
                end
                wdata.nistView(i) = nv_data.view(idx);
                wdata.dscPos(i, :) = dscovr_ephemeris_data.pos(:, i);
                wdata.dscVel(i, :) = dscovr_ephemeris_data.vel(:, i);
                wdata.dscAttRow1(i, :) = attitude_data.row1(:, idx);
                wdata.dscAttRow2(i, :) = attitude_data.row2(:, idx);
                wdata.dscAttRow3(i, :) = attitude_data.row3(:, idx);
                try
                    wdata.dscLat(i) = earth_subsatellite_data.lat(i);
                    wdata.dscLon(i) = earth_subsatellite_data.lon(i);
                    wdata.lunLat(i) = lunar_subsatellite_data.lat(i);
                    wdata.lunLon(i) = lunar_subsatellite_data.lon(i);
                catch ME
                    warning(['Earth/Moon Subsatellite Point data does not have the same length: ...' ...
                        'Earth: %d, Moon: %d\n'], length(earth_subsatellite_data.time), length(lunar_subsatellite_data.time));
                    fprintf(ME.message);
                    continue;
                end
                try
                    wdata.solPos(i, :) = solar_ephemeris_data.pos(:, i);
                    wdata.lunPos(i, :) = lunar_ephemeris_data.pos(:, i);
                catch ME
                    fprintf(ME.message);
                    continue;
                end              
            end
        end

%         function w_instru_data = updateInstrumentDataStatus(w_instru_data, w_ephemeris_data)
% 
%         end
    end
end