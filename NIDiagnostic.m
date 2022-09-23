classdef NIDiagnostic

    methods(Static) 
        function w_fieldnames = w_fieldnames()
    
            w_fieldnames = {'dscTm', 'rc1PwrM', 'rc2PwrM', 'rc3PwrM', 'hsPwrM', ...
                            'rc1PwrD', 'rc2PwrD', 'rc31PwrD', 'hsPwrD', ...
                            'rc1PwrDIm', 'rc2PwrDIm', 'rc31PwrDIm', 'hsPwrDIm', ...
                            'rc1PwrPtcS', 'rc2PwrPtcS', 'rc31PwrPtcS', 'hsPwrPtcS', ...
                            'pdCur', 'status'};
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

            start_jul_day = NIDateTime.getJulianDateFromCalendarDate(year, month, 1, 12);
            end_jul_day = NIDateTime.getJulianDateFromCalendarDate(year, month, eomday(year, month), 12);

            receiver_apid82_data = NIL1A.readReceiverAppID82(start_jul_day, end_jul_day);

            if isempty(receiver_apid82_data)
                fprintf('No data for %d-%d found in the database for APID 82 (Receiver Data)\r ', year, month);
                return;
            end

            % need to read the photodiode current data too
            l1a_pd_data = NIL1A.readL1APhotodiode(start_jul_day, end_jul_day);

            % convert into writeable format
            NIDaignostic.convertToInstrumentData(receiver_apid82_data, l1a_pd_data, wdata);

            % create HDF file
            hdf_file_name = sprintf('nist_diagnostic_data_%d%d.h5', year, month);
            hdf_file_path = fullfile(options.output_dir, hdf_file_name);
            hdf_file = H5F.create(hdf_file_path, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');

            NIDiagnostic.writeInstrumentData(hdf_file, wdata);

            H5F.close(hdf_file);

        end

        function writeInstrumentData(hdf_file, wdata)

            arguments
                hdf_file (1,1) double {mustBeInteger, mustBePositive}
                wdata (1,1) struct
            end

            number_of_fields = length(NIDiagnostic.w_fieldnames);
            
            % create the required datatypes
            sizes_of_fields = zeros(1, number_of_fields);
            double_type = H5T.copy('H5T_NATIVE_DOUBLE');
            for i = 1:number_of_fields - 1  % status is a string
                sizes_of_fields(i) = H5T.get_size(double_type);
            end
            string_type = H5T.copy('H5T_C_S1');
            H5T.set_size(string_type, 16);  % 16 bits for the status string
            sizes_of_fields(number_of_fields) = H5T.get_size(string_type);

            % compute the offsets of the fields, the first field starts at 0
            offsets_of_fields = zeros(1, number_of_fields);
            for i = 2:number_of_fields
                offsets_of_fields(i) = offsets_of_fields(i-1) + sizes_of_fields(i-1);
            end

            % create the compound datatype for memory
            memtype = H5T.create('H5T_COMPOUND', offsets_of_fields(number_of_fields) + sizes_of_fields(number_of_fields));
            for i = 1:number_of_fields - 1
                H5T.insert(memtype, NIDiagnostic.w_fieldnames{i}, offsets_of_fields(i), double_type);
            end
            H5T.insert(memtype, NIDiagnostic.w_fieldnames{number_of_fields}, offsets_of_fields(number_of_fields), string_type);

            % create the compound datatype for the file
            filetype = H5T.create('H5T_COMPOUND', offsets_of_fields(number_of_fields) + sizes_of_fields(number_of_fields));
            for i = 1:number_of_fields - 1
                H5T.insert(filetype, NIDiagnostic.w_fieldnames{i}, offsets_of_fields(i), double_type);
            end
            H5T.insert(filetype, NIDiagnostic.w_fieldnames{number_of_fields}, offsets_of_fields(number_of_fields), string_type);

            % create the data space
            dataspace = H5S.create_simple(1, length(wdata), []);

            % create the dataset and write
            dset = H5D.create(filename, '/INSTRUMENT_DATA', filetype, dataspace, 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5D.write(dset, memtype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', wdata);

            % close and release resources
            H5D.close(dset);
            H5T.close(memtype);
            H5T.close(filetype);
            H5S.close(dataspace);

        end

        function convertToInstrumentData(receiver_apid82_data, l1a_pd_data, wdata, downsample)

            arguments
                receiver_apid82_data (1,1) struct
                l1a_pd_data (1,1) struct
                wdata (1,1) struct
                downsample (1,1) double {mustBeInteger, mustBePositive} = 10
            end

            fprintf('Converting data to instrument data...\n');

            number_of_fields = length(NIDiagnostic.w_fieldnames);
            
            fprintf('Downsampling by a factor of %d\n', downsample);
            fprintf('Total number of records: %d\n', length(receiver_apid82_data));
            fprintf('Total number of records after downsampling: %d\n', length(receiver_apid82_data)/downsample);

            values = {};
            for i = 1:number_of_fields
                values{i} = zeros(length(receiver_apid82_data)/downsample, 1);
            end
            args = [NIDiagnostic.w_fieldnames; values]
            wdata = struct(args{:});

            fprintf('Averaging modulated receiver power data...\n');
            averaged_rc1_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc1_adc, average_window, step);
            averaged_rc2_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc2_adc, average_window, step);
            averaged_rc3_adc = running_ave(receiver_apid82_data.time, receiver_apid82_data.rc3_adc, average_window, step);
            averaged_hs_dac = running_ave(receiver_apid82_data.time, receiver_apid82_data.hs_adc, average_window, step);

            fprintf('Demodulating receiver power data...\n');
            demod_rc1_adc = demod(receiver_apid82_data.rc1_adc, receiver_apid82_data.rc1_shutter);
            demod_rc2_adc = demod(receiver_apid82_data.rc2_adc, receiver_apid82_data.rc2_shutter);
            demod_rc3_adc = demod(receiver_apid82_data.rc3_adc, receiver_apid82_data.rc3_shutter);
            demod_hs_dac = demod(receiver_apid82_data.hs_adc, receiver_apid82_data.rc2_shutter);

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
                wdata.status(i) = '0000';
            end
        end
    end
end