classdef NIConstants
    
    methods(Static)     % configure your filesystem here
        function dir = dir()
            dir.root = 'D:/NISTAR';
            dir.hdf = '/hdf/';
            dir.cal = '/calibration/';
            dir.input = '/input/';
        end
    end

    methods(Static)
        function astro = astro()
            astro.earth_r = 6371;
            astro.moon_r = 1737.1;
            astro.l1 = 1.49e6;
            astro.dscovr0day = 2457203.5;
        end
    end
    
    methods(Static)
        function dac_scale = dac_scale()
            dac_scale.hs = 7.20882543e-10;
        end
    end
    
    methods(Static)
        function ptc_scale = ptc_scale()
            ptc_scale = 0.00118424726;
        end
    end
    
    methods(Static)
        function receivers = receivers()
            receivers.shutter_period = 256.0;
            receivers.aperture1 = 0.498558e-4;
            receivers.aperture2 = 0.499745e-4;
            receivers.aperture3 = 0.500166e-4;
            receivers.aperture4 = 0.500460e-4;
            receivers.sec_aperture1 = 0.89107;
            receivers.sec_aperture2 = 0.90489;
            receivers.sec_aperture3 = 0.90485;
            receivers.sec_aperture4 = 0.90405;
            receivers.aperture_separation = 15.89;
            receivers.response1 = 1.0112;
            receivers.response2 = 1.0069;
            receivers.response3 = 1.0091;
            receivers.min_fov = 0.0169;
            receivers.max_fov = 0.0173;
            receivers.min_for = 0.1170;
            receivers.max_for = 0.1176;
        end
    end
    
    methods(Static)
        function pointingCorrectionMatrix = pointingToEPIC()
            pointingCorrectionMatrix = [0.999997349222362 0.001719289215765 0.001531532840498
                -0.001719287199381 0.999998522021204 -0.000002633151788
                -0.001531535104074 0 0.999998827199425];
        end
    end

    methods(Static)
        function bandB_filter_scale = bandB_filter_scale()
            bandB_filter_scale = 0.869;     % from Langley scene-dependent model
        end
    end

    methods(Static)
        function hdfDataSet = hdfDataSet()
            hdfDataSet.l1aScience = '/Science_Data/ScienceData';
            hdfDataSet.l1aRad = '/Radiometric_Data/RadiometricPower';
            hdfDataSet.l1aPD = '/Radiometric_Data/PhotodiodeCurrent';
            hdfDataSet.l1aNV = '/Geolocation_Data/NISTARView';
            hdfDataSet.l1bDemod = '/Demodulated_Power/DemodulatedRadiometerPower';
            hdfDataSet.l1bEarthRadA = '/Earth_Irradiance/BandA_EarthIrradiance';
            hdfDataSet.l1bEarthRadB = '/Earth_Irradiance/BandB_EarthIrradiance';
            hdfDataSet.l1bEarthRadC = '/Earth_Irradiance/BandC_EarthIrradiance';
            hdfDataSet.l1bEarthPD = '/Earth_Irradiance/EarthPhotodiodeCurrent';
            hdfDataSet.l1bFilteredA = '/Filtered_Earth_Radiance/BandA_EarthRadiance';
            hdfDataSet.l1bFilteredB = '/Filtered_Earth_Radiance/BandB_EarthRadiance';
            hdfDataSet.l1bFilteredC = '/Filtered_Earth_Radiance/BandC_EarthRadiance';
            hdfDataSet.l1bFilteredPD = '/Filtered_Earth_Radiance/PhotodiodeCurrent';
        end
    end

    methods(Static)
        function figureConfig = figureConfig()
            figureConfig.font.axes = 'Helvetica';
            figureConfig.font.label = 'Helvetica';
            figureConfig.font.title = 'Helvetica';
            figureConfig.font.legend = 'Helvetica';
            figureConfig.colorSet.light = {'#FFAB91', '#FFE082', '#C5E1A5', ...
                '#80DEEA', '#B39DDB', '#FFCDD2'};
            figureConfig.colorSet.normal = {'#00BCD4', '#FF8A65', '#8BC34A', ...
                '#FFC107', '#673AB7', '#E91E63', '#1E88E5'};
        end
    end
end