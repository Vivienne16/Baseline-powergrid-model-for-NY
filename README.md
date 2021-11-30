# Baseline-powergrid-model-for-NY




<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgements">Acknowledgements</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

As the urgency to address climate change intensifies, the integration of distributed and intermittent renewable resources in power grids will continue to accelerate. To ensure the reliability and efficacy of the transformed system, researchers and other stakeholders require a validated representation of the essential characteristics of the power grid that is accurate for a specific region under study. For example, the Climate Leadership and Community Protection Act (CLCPA) in New York sets ambitious targets for transformation of the energy system, opening many interesting research and analysis questions. To provide a platform for these analyses, this paper presents an overview of the current NYS power grid and develops an open-source1 baseline model using only publicly available data. The proposed model is validated with real data for power flow and Locational Marginal Prices (LMPs) to demonstrate the feasibility, functionality and consistency of the model with hourly data of 2019 as an example. The model is easily adjustable and customizable for various analyses of future configurations and scenarios that require spatial-temporal information of the NYS power grid with data access to all the available historical data, and serves as a practical system for general methods and algorithms testing.

### Built With
The code is written with Matlab and depends on the installation of Matpower. Please go to the following websties and follow the structions to install Matlab and Matpower.
* [Matlab](https://www.mathworks.com/products/matlab.html)
* [MATPOWER](https://matpower.org/)



<!-- USAGE EXAMPLES -->
## Usage
1. git clone https://github.com/AndersonEnergyLab-Cornell/NYgrid
2. Add the full folder and the subfolders to your Matlab Path
3. Modify the main.m file to run a specific case


### Main.m
Specify a year, and download and format the data in that year. Downlaoded data are stored in the "Prep" directory. Formatted data are stored in the "Data" directory. For example, to run for Jan 1st 2019 1:00 am, modify the test year, month, day and hour.

      testyear = 2019;
      testmonth = 1;
      testday = 1;
      testhour = 1;
      
Data sources include:
1. NYISO: 
   - hourly fuel mix
   - hourly interface flow
   - hourly real time price
2. RGGI: 
   - hourly generation for thermal generators larger than 25 MW
3. NRC: 
   - Daily nuclear capacity factor
4. EIA: 
   - Monthly hydro generation data for Niagara and St. Lawrence
        
The main function first update the operation condition for load and generators from the histroical data and store the modified mpc struct in `mpcreduced`
Then it automatically calls the Optimal Power Flow and Power Flow test and store the result in `resultOPF` and `resultPF`, respectively. 
        
        


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Vivienne Liu - ml2589@cornell.edu

Project Link: [https://github.com/AndersonEnergyLab-Cornell/NYgrid](https://github.com/AndersonEnergyLab-Cornell/NYgrid)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [E4ST-Network Reduction Toolbox](https://e4st.com/network-reduction-toolbox/)





