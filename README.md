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
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
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

This project provides a baseline model for the NY power grid. 

### Built With

This section should list any major frameworks that you built your project using. Leave any add-ons/plugins for the acknowledgements section. Here are a few examples.
* [Matlab](https://www.mathworks.com/products/matlab.html)
* [MATPOWER](https://matpower.org/)






<!-- USAGE EXAMPLES -->
## Usage

Run the ModifyMPC.m file to get started. This file shows the initial changes we made to the NPCC140-bus network.
Run the OperationConditionUpdate.m file to update the generaion and load condition and perform the network reduction. You can modify the month, day, hour in the begining for a different operation condition.
Sample code for PF and OPF tests are provided with OPFtestcase.m and PFtestcase.m

All the data needed are in the Data Folder. The final mpc file will be stored in the Result file.





<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Vivienne Liu - ml2589@cornell.edu

Project Link: [https://github.com/your_username/repo_name](https://github.com/your_username/repo_name)



<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements
* [E4ST-Network Reduction Toolbox](https://e4st.com/network-reduction-toolbox/)





