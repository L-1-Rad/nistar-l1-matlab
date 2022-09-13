<a name="readme-top"></a>

<br />
<div align="center">

<h3 align="center">MATLAB for NISTAR Level 1 Product</h3>

  <p align="center">
    project_description
    <br />
    <a href="https://github.com/L-1-Rad/nistar-l1-matlab"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/L-1-Rad/nistar-l1-matlab">View Examples</a>
    ·
    <a href="https://github.com/L-1-Rad/nistar-l1-matlab/issues">Report Bug</a>
    ·
    <a href="https://github.com/L-1-Rad/nistar-l1-matlab/issues">Request Feature</a>
  </p>
</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

The MATLAB NISTAR package is a MATLAB library to the [DSCOVR NISTAR Level 1 Product](https://asdc.larc.nasa.gov/project/DSCOVR). It helps the user read NISTAR Level 1 data from HDF5 files stored on the local drive. With the provided functions, the user can access and visualize data quickly without digging into details of the hierarchy data format of the product.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started


### Prerequisites

The package requires MATLAB 2019b or above. 

### Installation 

1. Clone the repo or download the zip file
   ```sh
   git clone https://github.com/L-1-Rad/nistar-l1-matlab.git
   ```
2. Add the folder and subfolders into MATLAB paths (Set Path -> Add with Subfolders)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

The package includes the following functions:

* Level 1A
  | Module          | Direct Method                 | Functionality    |
  | --------------- |:-----------------------------:|:----------------:|
  | `heatsink`      | `NIL1A.readHeatSink`           |Read the heat sink DAC power between two Julian days |
  | `photodiode`    | `NIL1A.readL1APhotodiode` |Read the photodiode current between two Julian days |
  | `radiometer`    | `NIL1A.readL1ARadiometer`   |Read the modulated radiometer power between two Julian days |
  | `science`       | `NIL1A.readShutterPosition`            |Read the shutter position between two Julian days |
  | `science`       | `NIL1A.readFilterWheel`        |Read the filter wheel position between two Julian days |
  | `science`       | `NIL1A.readPTC`                |Read the PTC setpoint between two Julian days |
  | `space_object`  | `NIL1A.readNISTARView`        |Read the space object and geolocation data between two Julian days |

* Level 1B
  | Module        | Direct Method               | Functionality    |
  | ------------- |:---------------------------:|:----------------:|
  | `demod`       | `NIL1B.readL1BDemodPower`      |Read the demodulated receiver ADC power between two Julian days |
  | `filtered`    | `NIL1B.readL1BFiltered`         |Read the monthly filtered Earth radiance between two months |
  | `irradiance`  | `NIL1B.readL1BIrradiance` |Read the Earth irradiance/radiance between two Julian days |
  | `photodiode`  | `NIL1B.readL1BEarthPDCurrent` |Read the Earth irradiance/radiance between two Julian days |


Example:

```
[bandA, bandB, bandC, bandPD, averaged] = NIL1B.readL1BFiltered(2022, 2, 2022, 7, average='weekly', plotFlag=true);
```
![Earth Radiance Band B vs Photodiode Current Example Plot](https://github.com/L-1-Rad/nistar-l1-matlab/blob/main/examples/sw_pd_weekly_01.png?raw=true "Earth Radiance Band B vs Photodiode Current Example Plot")


_For more details of the usage of each method, please refer to the examples in [Documentation](https://)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap

- [ ] More features to be updated

See the [open issues](https://github.com/L-1-Rad/nistar-l1-matlab/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Yinan Yu - yinan.yu@l-1.biz

Project Link: [https://github.com/L-1-Rad/nistar-l1-matlab](https://github.com/L-1-Rad/nistar-l1-matlab)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [NASA DSCOVR](https://epic.gsfc.nasa.gov/)


<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/L-1-Rad/nistar-l1-matlab.svg?style=for-the-badge
