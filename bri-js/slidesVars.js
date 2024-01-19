




//= === Function_outlines Vars ===//

const sidebar = document.querySelector(".side-bar");
const slideTitleDiv = document.querySelector('.slide-title');
const slideContentDiv = document.querySelector('.slide-content');

// for map change and data table change
let checkboxContainer;

let allButResources;
/*= == Slides === */
const storySlide = {
  title: '<h1> Abstract </h1>',
  slide: 'storySlide',
  content: '<p><b>Motivations and Acknowledgements:</b><p>Air pollution is a big problem in India – researchers say it kills more than 1 million in the country every year. On average its cities exceed World Health Organization (WHO) guidelines for the amount of particulate pollution (PM2.5) in the atmosphere by 500%, according to the IQAir report. Taking inspiration from the "Los Angeles Heat Vulnerability Index" story map, I hope to highlight the areas within India that are most vulnerable to PM 2.5 pollution. My general process:<ol><li>gathered organization satellite imagery and open source data relating to State/Union Territory and District boundaries and PM 2.5 concentration in India,</li><li>calculated and mapped the average PM 2.5 concentration for each District in the country from 2010 to 2019</li></ol></p><p><b>Methods:</b><p>In order to calculate a District&apos;s average PM 2.5 concentration, I used granular PM 2.5 raster data provided by the University of Michigan. More specifically, I converted each pixel (1kmx1km) contained in the PM 2.5 raster file into a point. I then overlayed these points over a map of India&apos;s Districts, designated each point to a District, and averaged the PM 2.5 concentration value for all the points found in each District.</p><p><b>Conclusions and Usability:</b><p>With the average PM 2.5 concentrations that I calculated for each District in India, I produced this India PM 2.5 Pollution interactive map - illustrating the areas of the country that are most polluted with PM 2.5 to help people cope with and mitigate the effects of pollution. With this map, I hope to educate individuals within India about their relative vulnerability to pollution. Additionally, we encourage that the government of India use our map to inform residents of this issue and to aid in the allocation of pollution-mitigating resources and strategies.</p><p><em>This website was created by University of Pennsylvania MUSA (Master of Urban Spatial Analytics) graduate, Aidan Cole. Please contact aidancol@usc.edu for more information.</em></p></p>'
};

// <input type="checkbox" id="Resources"><h4>Resources</h4>
const filterslide = {
  title: '<h2 class="h2 g4-text-burgundy fw-bold g4-header-underline"> EXPOSURES </h2>',
  slide: 'filterSlide',
  content: `<div class="checkies">
  <h5><input type="checkbox" id="PMTFV" class="largerCheck"> <span style="font-weight:bold;">&nbspFine Particulate Matter (PM<sub>2.5</sub>)</span></h5>
  <h5><input type="checkbox" id="OZONE" class="largerCheck"> <span style="font-weight:bold;">&nbspOzone (O<sub>3</sub>)</span></h5>
  <h5><input type="checkbox" id="NOTWO" class="largerCheck" disabled> <span style="font-weight:bold;">&nbspNitrogen Dioxide (NO<sub>2</sub>)</span></h5>
  <h5><input type="checkbox" id="LIGHT" class="largerCheck" disabled> <span style="font-weight:bold;">&nbspNighttime Light</span></h5>
  <h5><input type="checkbox" id="SOURCE" class="largerCheck" disabled> <span style="font-weight:bold;">&nbspFine Particulate Matter (PM<sub>2.5</sub>) &nbsp&nbsp&nbsp&nbsp&nbsp&nbspSource Fraction</span></h5>
  <h5><input type="checkbox" id="GREEN" class="largerCheck" disabled> <span style="font-weight:bold;">&nbspGreen Space</span></h5>
  <h5><input type="checkbox" id="BLUES" class="largerCheck" disabled> <span style="font-weight:bold;">&nbspBlue Space</span></h5>
  <br style="line-height:5px;">
  <p>Source Fraction, Green Space and Blue Space coming soon!</p>
 </div>`,
};

const slides = [storySlide, filterslide];

const motive = {
  title: 'Summary Statistics',
  slide: 'motive',
  content: `<p>Here, we want to put an interactive data table that presents summary statistics depending on the layer shown and the user's selected district.</p>`
};

// const motivationText = [motive]
