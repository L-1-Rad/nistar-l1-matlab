function outData = demod(radiometer, shutter, samples_per_cycle, n_filters)

    arguments
        radiometer (1,:) {mustBeNumeric}
        shutter (1,:) {mustBeNumeric}
        samples_per_cycle (1,1) {mustBeNumeric} = 256
        n_filters (1,1) {mustBeNumeric} = 4
    end

    if length(radiometer) ~= length(shutter)
        error('Lengths of input arrays not equal.');
    end

    outData.input = radiometer;
    outData.ref = shutter;
    N = length(radiometer);
    iw = 1:N;
    ref_signal = cast((shutter-min(shutter))/max(max((max(shutter)-min(shutter)),min(shutter)),1), 'double');
    dtmp = 2*pi/samples_per_cycle;
    outData.re = zeros(N,1);
    outData.im = zeros(N,1);
    bufR = cos(dtmp*(iw - 1));
    bufI = sin(dtmp*(iw - 1));
    PInpDataSetR = radiometer.*bufR;
    PInpDataSetI = radiometer.*bufI;
    PRefDataSetI = cast(ref_signal, 'double').*bufI;
    PRefDataSetR = cast(ref_signal, 'double').*bufR;
    for k = 1:n_filters
        for i = 1:N - samples_per_cycle
            PInpDataSetR(i) = sum(PInpDataSetR(i:i + samples_per_cycle - 1), 'omitnan');
            PInpDataSetI(i) = sum(PInpDataSetI(i:i + samples_per_cycle - 1), 'omitnan');
            PRefDataSetR(i) = sum(PRefDataSetR(i:i + samples_per_cycle - 1), 'omitnan');
            PRefDataSetI(i) = sum(PRefDataSetI(i:i + samples_per_cycle - 1), 'omitnan');
        end
    end
    dtmp = 2/(samples_per_cycle^n_filters);
    itmp = samples_per_cycle*n_filters/2;
    for i = N-samples_per_cycle*n_filters:-1:1
        ctmp1R 	= dtmp*PInpDataSetR(i);
        ctmp1I	= dtmp*PInpDataSetI(i);
        ctmp2R	= dtmp*PRefDataSetR(i);
        ctmp2I	= dtmp*PRefDataSetI(i);
        PInpDataSetR(i+itmp) = ctmp1R;
        PInpDataSetI(i+itmp) = ctmp1I;
        PRefDataSetR(i+itmp) = ctmp2R;
        PRefDataSetI(i+itmp) = ctmp2I;
        dvar = ctmp2R^2 + ctmp2I^2;
        if dvar == 0
            outData.re(i+itmp)  = 0;
            outData.im(i+itmp)  = 0;
        else
            outData.re(i+itmp)  = (ctmp1R*ctmp2R+ctmp1I*ctmp2I)/dvar;
            outData.im(i+itmp)  = (ctmp1I*ctmp2R-ctmp1R*ctmp2I)/dvar;
        end
    end
    outData.mod = sqrt(outData.re.^2 + outData.im.^2);
end
