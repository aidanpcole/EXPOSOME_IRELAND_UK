# Aidan Cole India PM 2.5 Pollution Project 
# Calculating average PM 2.5 concentration by Indian district/state

# load libraries 
library(tidyverse)
library(tidycensus)
library(tigris)
library(tmap)
library(sf)
library(kableExtra)
library(tigris)
library(ggmap)
library(raster)
library(stargazer)
library(caTools)
library(caret)
library(spdep)
library(mapboxapi)
library(units)
library(rgdal)
library(ggplot2)
library(stringr)
library(gifski)
library(gganimate)
library(lubridate)
library(data.table)


# ---- Load Styling options -----

mapTheme <- function(base_size = 12) {
  theme(
    text = element_text( color = "black"),
    plot.title = element_text(size = 16,colour = "black"),
    plot.subtitle=element_text(face="italic"),
    plot.caption=element_text(hjust=0),
    axis.ticks = element_blank(),
    panel.background = element_blank(),axis.title = element_blank(),
    axis.text = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = "black", fill=NA, size=2),
    strip.text.x = element_text(size = 14))
}

plotTheme <- function(base_size = 12) {
  theme(
    text = element_text( color = "black"),
    plot.title = element_text(size = 16,colour = "black"),
    plot.subtitle = element_text(face="italic"),
    plot.caption = element_text(hjust=0),
    axis.ticks = element_blank(),
    panel.background = element_blank(),
    panel.grid.major = element_line("grey80", size = 0.1),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = "black", fill=NA, size=2),
    strip.background = element_rect(fill = "grey80", color = "white"),
    strip.text = element_text(size=12),
    axis.title = element_text(size=12),
    axis.text = element_text(size=10),
    plot.background = element_blank(),
    legend.background = element_blank(),
    legend.title = element_text(colour = "black", face = "italic"),
    legend.text = element_text(colour = "black", face = "italic"),
    strip.text.x = element_text(size = 14)
  )
}

# Load Quantile break functions

qBr <- function(df,variable,rnd) {
  if (missing(rnd)) {
    as.character(quantile(round(df[[variable]],0),
                          c(.01,.2,.4,.6,.8), na.rm=T))
  } else if (rnd == FALSE | rnd == F) {
    as.character(formatC(quantile(df[[variable]],
                                  c(.01,.2,.4,.6,.8), na.rm=T), digits = 3))
  }
}

q5 <- function(variable) {as.factor(ntile(variable, 5))}

# Load hexadecimal color palette

palette5 <- c("#f0f9e8","#bae4bc","#7bccc4","#43a2ca","#0868ac")



# Pollution Data
# Read in the geojson data and store it in a variable 
pollutiondistricts2010 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2010pollutiondistricts.geojson")  %>%
  mutate(time = "2010-01-01T00:00:00")
pollutiondistricts2011 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2011pollutiondistricts.geojson") %>%
  mutate(time = "2011-01-01T00:00:00")
pollutiondistricts2012 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2012pollutiondistricts.geojson") %>%
  mutate(time = "2012-01-01T00:00:00")
pollutiondistricts2013 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2013pollutiondistricts.geojson") %>%
  mutate(time = "2013-01-01T00:00:00")
pollutiondistricts2014 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2014pollutiondistricts.geojson") %>%
  mutate(time = "2014-01-01T00:00:00")
pollutiondistricts2015 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2015pollutiondistricts.geojson") %>%
  mutate(time = "2015-01-01T00:00:00")
pollutiondistricts2016 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2016pollutiondistricts.geojson") %>%
  mutate(time = "2016-01-01T00:00:00")
pollutiondistricts2017 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2017pollutiondistricts.geojson") %>%
  mutate(time = "2017-01-01T00:00:00")
pollutiondistricts2018 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2018pollutiondistricts.geojson") %>%
  mutate(time = "2018-01-01T00:00:00")
pollutiondistricts2019 <- st_read("/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/ReferenceData/2019pollutiondistricts.geojson") %>%
  mutate(time = "2019-01-01T00:00:00")

states2019 <- st_read("/Users/Aidan/Desktop/Raster-Timelapse/Raster-Timelapse/data/ReferenceData/PM25_2019_States.geojson") %>%
  mutate(State = DHSREGEN,
         "2019 PM 2.5 Score" = grid_code,
         "Total Area (km^2)" = drop_units((st_area(geometry))/1000000)) %>%
  dplyr::select(State,"2019 PM 2.5 Score","Total Area (km^2)", geometry)


CleanStates2019 <- states2019

CleanStates2019$State <- str_replace(CleanStates2019$State, "Jammu & Kashmir", "Jammu and Kashmir")

CleanStates <- CleanStates2019 %>%
  dplyr::select(State,geometry)


districts2019 <- st_read("/Users/Aidan/Desktop/Raster-Timelapse/Raster-Timelapse/data/ReferenceData/PM25_2019_Districts.geojson") %>%
  mutate(District = REGNAME,
         State = OTHREGNA, 
         "2019 PM 2.5 Score" = grid_code,
         "Total Area (km^2)" = drop_units((st_area(geometry))/1000000)) %>%
  dplyr::select(District,State,"2019 PM 2.5 Score","Total Area (km^2)", geometry)

CleanDistricts2019 <- districts2019

CleanDistricts2019$State <- str_replace(CleanDistricts2019$State, "Jammu & Kashmir", "Jammu and Kashmir")
CleanDistricts2019$State <- str_replace(CleanDistricts2019$State, "Delhi", "New Delhi")





CleanDistricts <- CleanDistricts2019 %>%
  dplyr::select(State,District,geometry)



CleanStates2011 <- states2011 %>%
  mutate(State = str_to_title(State)) 

CleanStates2011[CleanStates2011=="Andaman And Nicobar Islands"] <- "Andaman and Nicobar Islands"
CleanStates2011[CleanStates2011=="Dadra And Nagar Haveli"] <- "Dadra and Nagar Haveli"
CleanStates2011[CleanStates2011=="Nct Of Delhi"] <- "Delhi"
CleanStates2011[CleanStates2011=="Jammu And Kashmir"] <- "Jammu and Kashmir"
CleanStates2011[CleanStates2011=="Daman And Diu"] <- "Daman and Diu"

CleanStates2011$State <- str_replace(CleanStates2011$State, " And", " and")
CleanStates2011$State <- str_replace(CleanStates2011$State, "Nct Of Delhi", "Delhi")

UnionTerritories <- list("Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli", "Jammu and Kashmir", "Delhi", "Lakshadweep", "Pondicherry")

StatesandUTs2011 <- CleanStates2011 %>%
  mutate("State/Union Territory" = ifelse(CleanStates2011$State %in% UnionTerritories, "Union Territory", "State"))



df1$state_title_case = str_to_title(df1$State)

PollutionStates2011 <- pollutiondistricts2011 %>%
  group_by(statename)


# load in census data
Census2011 <- read.csv("/Users/Aidan/Desktop/Raster-Timelapse/Raster-Timelapse/data/ReferenceData/india-districts-census-2011.csv") %>%
  mutate("State" = State.name,
         "District" = District.name,
         "District Code" = District.code) %>%
  dplyr::select("District Code", "State","District",Population,Male,Literate,Workers,Households,Rural_Households,Urban_Households,Below_Primary_Education,Primary_Education,Middle_Education,Secondary_Education,Higher_Education,Graduate_Education,Other_Education,Total_Education,Total_Power_Parity) 


# change case of state names
CleanCensus2011 <- Census2011 %>%
  mutate(State = str_to_title(State))

#match state names to boundary names
CleanCensus2011$State <- str_replace(CleanCensus2011$State, " And", " and")
CleanCensus2011$State <- str_replace(CleanCensus2011$State, "Nct Of Delhi", "New Delhi")
CleanCensus2011$State <- str_replace(CleanCensus2011$State, "Orissa", "Odisha")
CleanCensus2011$State <- str_replace(CleanCensus2011$State, "Pondicherry", "Puducherry")
CleanCensus2011$State <- str_replace(CleanCensus2011$State, "Himachal Pradesh", "Himanchal Pradesh")

#make telangana out of Andhra Pradesh districts
CleanCensus2011$State[CleanCensus2011$District == "Adilabad"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Nizamabad"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Karimnagar"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Medak"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Hyderabad"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Rangareddy"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Mahbubnagar"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Nalgonda"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Warangal"] <- "Telangana"
CleanCensus2011$State[CleanCensus2011$District == "Khammam"] <- "Telangana"

#take out parentheses
CleanDistricts$District <- gsub("[()]", "", CleanDistricts$District)
CleanCensus2011$District <- gsub("[()]", "", CleanCensus2011$District)
CleanDistricts2019$District <- gsub("[()]", "", CleanDistricts2019$District)

# match district names
CleanDistricts$District <- str_replace(CleanDistricts$District, "Senapati Excluding 3 Sub-Divisions", "Senapati")
CleanDistricts$District <- str_replace(CleanDistricts$District, "North & Middle Andaman", "North and Middle Andaman")
CleanDistricts$District <- str_replace(CleanDistricts$District, "Korea Koriya", "Koriya")
CleanDistricts$District <- str_replace(CleanDistricts$District, "Dadra & Nagar Haveli", "Dadra and Nagar Haveli")
CleanDistricts2019$District <- str_replace(CleanDistricts2019$District, "Senapati Excluding 3 Sub-Divisions", "Senapati")
CleanDistricts2019$District <- str_replace(CleanDistricts2019$District, "North & Middle Andaman", "North and Middle Andaman")
CleanDistricts2019$District <- str_replace(CleanDistricts2019$District, "Korea Koriya", "Koriya")
CleanDistricts2019$District <- str_replace(CleanDistricts2019$District, "Dadra & Nagar Haveli", "Dadra and Nagar Haveli")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "LehLadakh", "Leh")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Banas Kantha", "Banaskantha")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "PONDICHERRY", "Puducherry")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Lahul AND Spiti", "Lahul and Spiti")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Saraikela-Kharsawan", "Saraikela Kharsawan")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Sabar Kantha", "Sabarkantha")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "North  AND Middle Andaman", "North and Middle Andaman")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Siddharthnagar", "Siddharth Nagar")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Panch Mahals", "Panchmahal")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Papum Pare", "Papumpare")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Kabeerdham", "Kabirdham")
CleanCensus2011$District <- str_replace(CleanCensus2011$District, "Dadra AND Nagar Haveli", "Dadra and Nagar Haveli")


# confirm that district names match
x <- unique(CleanDistricts$District)
y <- unique(CleanCensus2011$District)
results1 = setdiff(x,y)
results2 = setdiff(y,x)


CensusStates2019 <- merge(CleanCensus2011, CleanStates, by = "State") %>%
  group_by(State) %>%
  summarise("Total Population" = sum(Population),
            "Total Males" = sum(Male),
            "Total Literate" = sum(Literate),
            "Total Workers" = sum(Workers),
            "Total Households" = sum(Households),
            "Total Rural Households" = sum(Rural_Households),
            "Total Urban Households" = sum(Urban_Households),
            "Total with Primary Education" = sum(Primary_Education),
            "Total with Middle Education" = sum(Middle_Education),
            "Total with Secondary Education" = sum(Secondary_Education),
            "Total with Higher Education" = sum(Higher_Education),
            "Total with Graduate Education" = sum(Graduate_Education),
            "Total with Other Education" = sum(Other_Education),
            "Total with Education" = (sum(Below_Primary_Education) + sum(Primary_Education) + sum(Middle_Education) + sum(Secondary_Education) + sum(Higher_Education) + sum(Graduate_Education) + sum(Other_Education)),
            "Total Purchasing Power" = sum(Total_Power_Parity)) %>%
  mutate("Percent Male" = round((CensusStates2019$`Total Males`/CensusStates2019$`Total Population`) * 100, 2) ,
         "Percent Literate" = round((CensusStates2019$`Total Literate`/CensusStates2019$`Total Population`) * 100, 2),
         "Percent Working" = round((CensusStates2019$`Total Workers`/CensusStates2019$`Total Population`) * 100, 2),
         "Percent Rural" = round((CensusStates2019$`Total Rural Households`/CensusStates2019$`Total Households`) * 100, 2),
         "Percent Urban" = round((CensusStates2019$`Total Urban Households`/CensusStates2019$`Total Households`) * 100, 2),
         "Percent w/ No Education" = round(((CensusStates2019$`Total Population` - CensusStates2019$`Total with Education`)/CensusStates2019$`Total Population`) * 100, 2),
         "Percent w/ Higher Ed" = round(((CensusStates2019$`Total with Higher Education` + CensusStates2019$`Total with Graduate Education`)/CensusStates2019$`Total with Education`) * 100, 2),
         "Purchasing Power Quintile" = ntile(CensusStates2019$`Total Purchasing Power`,5)) %>%
  dplyr::select("State", "Total Population", "Percent Male", "Percent Literate", "Percent Working", "Percent Rural", "Percent w/ No Education")


CompleteCensusStates2019 <- merge(CensusStates2019, CleanStates2019, by = "State") %>%
  mutate("2019 PM 2.5 Quintile" = ntile(CompleteCensusStates2019$`2019 PM 2.5 Score`,5),
         "45 or Older" = 80375)



#make variable for 45 or older based on data from Hunter
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Andhra Pradesh"] <- 11885501
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Arunachal Pradesh"] <- 203314
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Assam"] <- 5722981
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Bihar"] <- 18086937
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Chandigarh"] <- 209297
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Chhattisgarh"] <- 5120583
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Dadra and Nagar Haveli"] <- 44135
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Daman and Diu"] <- 32645
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Goa"] <- 400376
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Gujarat"] <- 12852702
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Haryana"] <- 5151735
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Himachal Pradesh"] <- 1695684
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Jammu and Kashmir"] <- 2322043
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Jharkhand"] <- 6062187
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Karnataka"] <- 14152588
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Kerala"] <- 10212476
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Lakshadweep"] <- 15047
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Maharashtra"] <- 13988726
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Manipur"] <- 556826
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Meghalaya"] <- 410869
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Mizoram"] <- 197236
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Nagaland"] <- 299730
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "New Delhi"] <- 3255019
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Odisha"] <- 9650010
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Puducherry"] <- 310773
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Punjab"] <- 6664607
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Rajasthan"] <- 12671799
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Sikkim"] <- 112187
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Tamil Nadu"] <- 19027416
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Telangana"] <- 7616993
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Tripura"] <- 774073
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Uttar Pradesh"] <- 35940850
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "Uttarakhand"] <- 2105805
CompleteCensusStates2019$`45 or Older`[CompleteCensusStates2019$State == "West Bengal"] <- 20604631


CompleteCensusStates <- CompleteCensusStates2019 %>%
  mutate("Percent Over 45" = round((CompleteCensusStates2019$`45 or Older`/CompleteCensusStates2019$`Total Population`) * 100, 2), 
         "Total Population" = prettyNum(CensusStates2019$`Total Population`, big.mark = ",", scientific = FALSE)) %>%
  dplyr::select("State", "Total Population", "Percent Male", "Percent Literate", "Percent Working", "Percent Rural", "Percent w/ No Education", "Percent Over 45", "2019 PM 2.5 Quintile", geometry)


JUSTGEO <- CleanStates2019 %>%
  dplyr::select(State,geometry)


CompleteCensusStates2019 <- merge(CensusStates2019, JUSTGEO, by = "State")


st_write(CompleteCensusStates, "/Users/Aidan/Desktop/Raster-Timelapse/Raster-Timelapse/data/DataForMap/censusstates2019.geojson")

# load in 45 pop data
DistrictsAge45Older <- read.csv("/Users/Aidan/Desktop/Raster-Timelapse/Raster-Timelapse/data/ReferenceData/census_district_pop_45+.csv") 

# clean
Clean45Older <- DistrictsAge45Older %>%
  mutate(District = area_name,
         "45 or Older" = pop_45o,
         "District Code" = district_code) %>%
  dplyr::select("District Code", "District", "45 or Older")

# make sure district names are the same
z <- unique(Clean45Older$District)
results3 <- setdiff(x,z)
results4 <- setdiff(z,x)

# take out parentheses
Clean45Older$District <- gsub("[()]", "", Clean45Older$District)

# replace names to match other districts
Clean45Older$District <- str_replace(Clean45Older$District, "LehLadakh", "Leh")
Clean45Older$District <- str_replace(Clean45Older$District, "Saraikela-Kharsawan", "Saraikela Kharsawan")
Clean45Older$District <- str_replace(Clean45Older$District, "Panch Mahals", "Panchmahal")
Clean45Older$District <- str_replace(Clean45Older$District, "Lahul & Spiti", "Lahul and Spiti")
Clean45Older$District <- str_replace(Clean45Older$District, "Kabeerdham", "Kabirdham")
Clean45Older$District <- str_replace(Clean45Older$District, "Dadra & Nagar Haveli", "Dadra and Nagar Haveli")
Clean45Older$District <- str_replace(Clean45Older$District, "Siddharthnagar", "Siddharth Nagar")
Clean45Older$District <- str_replace(Clean45Older$District, "Banas Kantha", "Banaskantha")
Clean45Older$District <- str_replace(Clean45Older$District, "North  & Middle Andaman", "North and Middle Andaman")
Clean45Older$District <- str_replace(Clean45Older$District, "Papum Pare", "Papumpare")
Clean45Older$District <- str_replace(Clean45Older$District, "Sabar Kantha", "Sabarkantha")

# join 45 population data to CleanDistricts
# make state column so can merge dataframes
#DistrictsStates45Older <- data.frame("45 or Older"=Clean45Older$`45 or Older`, District=CleanDistricts[match(Clean45Older$District, CleanDistricts$District), 2], State=CleanDistricts$State)


#AlmostDone45Older <- DistrictsStates45Older %>%
#  mutate("District" = District.District,
#         "45 or Older" = X45.or.Older,
#         geometry = District.geometry,
#         "State" = State) %>%
#  dplyr::select("District", "State", "45 or Older", geometry)


# merge census with pop and boundaries 
CensusDistricts2019 <- merge(CleanCensus2011, Clean45Older, by=c("District Code","District")) %>%
  mutate("Total Population" = Population, 
         "Total Males" = Male,
         "Total Literate" = Literate,
         "Total Workers" = Workers,
         "Total Households" = Households,
         "Total Rural Households" = Rural_Households,
         "Total with Primary Education" = Primary_Education,
         "Total with Middle Education" = Middle_Education,
         "Total with Secondary Education" = Secondary_Education,
         "Total with Higher Education" = Higher_Education,
         "Total with Graduate Education" = Graduate_Education,
         "Total with Other Education" = Other_Education, 
         "Total with Education" = Below_Primary_Education + Primary_Education + Middle_Education + Secondary_Education + Higher_Education + Graduate_Education + Other_Education) %>% 
  mutate("Percent Male" = round((CensusDistricts2019$`Total Males`/CensusDistricts2019$`Total Population`) * 100, 2) ,
         "Percent Literate" = round((CensusDistricts2019$`Total Literate`/CensusDistricts2019$`Total Population`) * 100, 2),
         "Percent Working" = round((CensusDistricts2019$`Total Workers`/CensusDistricts2019$`Total Population`) * 100, 2),
         "Percent Rural" = round((CensusDistricts2019$`Total Rural Households`/CensusDistricts2019$`Total Households`) * 100, 2),
         "Percent w/ No Education" = round(((CensusDistricts2019$`Total Population` - CensusDistricts2019$`Total with Education`)/CensusDistricts2019$`Total Population`) * 100, 2),
         "Percent w/ Higher Ed" = round(((CensusDistricts2019$`Total with Higher Education` + CensusDistricts2019$`Total with Graduate Education`)/CensusDistricts2019$`Total with Education`) * 100, 2),
         "Percent 45 or Older" = round((CensusDistricts2019$`45 or Older`/CensusDistricts2019$`Total Population`) * 100, 2)) %>%
  dplyr::select("District", "State", "Total Population", "Percent Male", "Percent Literate", "Percent Working", "Percent Rural", "Percent w/ No Education", "Percent 45 or Older")


CompleteCensusDistricts2019 <- merge(CensusDistricts2019, CleanDistricts2019, by=c("State","District")) %>%
  mutate("2019 PM 2.5 Quintile" = ntile(CompleteCensusDistricts2019$`2019 PM 2.5 Score`,5),
         "Total Population" = prettyNum(CompleteCensusDistricts2019$`Total Population`, big.mark = ",", scientific = FALSE)) %>%
  dplyr::select("District", "State", "Total Population", "Percent Male", "Percent Literate", "Percent Working", "Percent Rural", "Percent w/ No Education", "Percent 45 or Older", "2019 PM 2.5 Quintile", geometry)


st_write(CompleteCensusDistricts2019, "/Users/Aidan/Desktop/Raster-Timelapse/Raster-Timelapse/data/DataForMap/censusdistricts2019.geojson")





























timepollution2010 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2010timepollution.geojson") %>%
  mutate(time = "2010-01-01T00:00:00")
timepollution2011 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2011timepollution.geojson") %>%
  mutate(time = "2011-01-01T00:00:00")
timepollution2012 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2012timepollution.geojson") %>%
  mutate(time = "2012-01-01T00:00:00")
timepollution2013 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2013timepollution.geojson") %>%
  mutate(time = "2013-01-01T00:00:00")
timepollution2014 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2014timepollution.geojson") %>%
  mutate(time = "2014-01-01T00:00:00")
timepollution2015 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2015timepollution.geojson") %>%
  mutate(time = "2015-01-01T00:00:00")
timepollution2016 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2016timepollution.geojson") %>%
  mutate(time = "2016-01-01T00:00:00")
timepollution2017 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2017timepollution.geojson") %>%
  mutate(time = "2017-01-01T00:00:00")
timepollution2018 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2018timepollution.geojson") %>%
  mutate(time = "2018-01-01T00:00:00")
timepollution2019 <- st_read("/Users/Aidan/Desktop/India Timelapse/data/ReferenceData/2019timepollution.geojson") %>%
  mutate(time = "2019-01-01T00:00:00")

timepollution20102019 <- st_read("/Users/Aidan/Desktop/India-Timelapse/data/DataForMap/simplesimpletimes20102019pm25.geojson")

k <- Complete2010Districts %>%
  filter(District == "Mumbai Suburban")

# WAS 24048, then st_transform('EPSG:23948')
pollutionstates2010 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2010pollutionstates.geojson") 
pollutionstates2011 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2011pollutionstates.geojson")
pollutionstates2012 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2012pollutionstates.geojson")
pollutionstates2013 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2013pollutionstates.geojson")
pollutionstates2014 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2014pollutionstates.geojson")
pollutionstates2015 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2015pollutionstates.geojson")
pollutionstates2016 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2016pollutionstates.geojson") 
pollutionstates2017 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2017pollutionstates.geojson")
pollutionstates2018 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2018pollutionstates.geojson") 
pollutionstates2019 <- st_read("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/ReferenceData/2019pollutionstates.geojson")


p <- poly2nb(st_make_valid(timepollution2010))


# Example visualization to make sure it worked 
ggplot() +
  geom_sf(data=st_union(Times20102019)) +
  geom_sf(data=Times20102019,aes(fill=q5(grid_code))) +
  scale_fill_manual(values=palette5,
                    labels=qBr(Times20102019,"grid_code"),
                    name="PM 2.5 Concentration\n(Quintile Breaks)") +
  labs(title="PM 2.5 Concentration", 
       subtitle="India, 2010", 
       caption="Figure 1") +
  mapTheme()

# Example visualization to make sure it worked 
ggplot() +
  geom_sf(data=st_union(pollutiondistricts2010)) +
  geom_sf(data=pollutiondistricts2010,aes(fill=q5(grid_code))) +
  scale_fill_manual(values=palette5,
                    labels=qBr(pollutiondistricts2010,"grid_code"),
                    name="PM 2.5 Concentration\n(Quintile Breaks)") +
  labs(title="PM 2.5 Concentration", 
       subtitle="India, 2010", 
       caption="Figure 1") +
  mapTheme()


pollutiondistricts2010 <- pollutiondistricts2010 %>%
  mutate("Duplicate" = duplicated(pollutiondistricts2010$distname)) %>%
duplicateddistricts2010 <- pollutiondistricts2010 %>%  
  filter(pollutiondistricts2010$Duplicate == TRUE)
zeropops <- pollutiondistricts2010 %>%
  filter(pollutiondistricts2010$totalpopul==0)

Complete2010Districts <- pollutiondistricts2010 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2010$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2010$grid_code,5),
         "Year" = 2010) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2011Districts <- pollutiondistricts2011 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2011$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2011$grid_code,5),
         "Year" = 2011) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2012Districts <- pollutiondistricts2012 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2012$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2012$grid_code,5),
         "Year" = 2012) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2013Districts <- pollutiondistricts2013 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2013$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2013$grid_code,5),
         "Year" = 2013) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2014Districts <- pollutiondistricts2014 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2014$state_ut),
         "Total Population" = totalpopul,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2014$grid_code,5),
         "Year" = 2014) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2015Districts <- pollutiondistricts2015 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2015$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2015$grid_code,5),
         "Year" = 2015) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2016Districts <- pollutiondistricts2016 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2016$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2016$grid_code,5),
         "Year" = 2016) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2017Districts <- pollutiondistricts2017 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2017$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2017$grid_code,5),
         "Year" = 2017) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2018Districts <- pollutiondistricts2018 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2018$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2018$grid_code,5),
         "Year" = 2018) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2019Districts <- pollutiondistricts2019 %>%
  mutate("State/Union Territory" = statename,
         "District" = distname,
         "Type" = str_to_title(pollutiondistricts2019$state_ut),
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2019$grid_code,5),
         "Year" = 2019) %>%
  dplyr::select(FID,"State/Union Territory","District","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Districts2010 <- Complete2010Districts
Districts2011 <- Complete2011Districts 
Districts2012 <- Complete2012Districts
Districts2013 <- Complete2013Districts 
Districts2014 <- Complete2014Districts 
Districts2015 <- Complete2015Districts 
Districts2016 <- Complete2016Districts 
Districts2017 <- Complete2017Districts
Districts2018 <- Complete2018Districts 
Districts2019 <- Complete2019Districts 


Districts20102011 <- rbind(Districts2010,Districts2011)
Districts20102012 <- rbind(Districts20102011,Districts2012)
Districts20102013 <- rbind(Districts20102012,Districts2013)
Districts20102014 <- rbind(Districts20102013,Districts2014)
Districts20102015 <- rbind(Districts20102014,Districts2015)
Districts20102016 <- rbind(Districts20102015,Districts2016)
Districts20102017 <- rbind(Districts20102016,Districts2017)
Districts20102018 <- rbind(Districts20102017,Districts2018)
Districts20102019 <- rbind(Districts20102018,Districts2019)






write.csv(Districts20102019,"/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/timelapsedistricts.csv")

df_list = list(Districts2010,Districts2011,Districts2012,Districts2013,Districts2014,Districts2015,Districts2016,Districts2017,Districts2018,Districts2019) 
df_list %>% reduce(inner_join, by='FID')

st_write(Complete2010Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2010pm25.geojson")
st_write(Complete2011Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2011pm25.geojson")
st_write(Complete2012Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2012pm25.geojson")
st_write(Complete2013Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2013pm25.geojson")
st_write(Complete2014Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2014pm25.geojson")
st_write(Complete2015Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2015pm25.geojson")
st_write(Complete2016Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2016pm25.geojson")
st_write(Complete2017Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2017pm25.geojson")
st_write(Complete2018Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2018pm25.geojson")
st_write(Complete2019Districts, "/Users/Aidan/Desktop/India PM 2.5 Dashboard/aidanpcole.github.io/data/DataForMap/districts2019pm25.geojson")


Complete2010States <- pollutionstates2010 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2010$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2010$grid_code,5),
         "Year" = 2010) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2011States <- pollutionstates2011 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2011$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2011$grid_code,5),
         "Year" = 2011) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2012States <- pollutionstates2012 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2012$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2012$grid_code,5),
         "Year" = 2012) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2013States <- pollutionstates2013 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2013$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2013$grid_code,5),
         "Year" = 2013) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2014States <- pollutionstates2014 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2014$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2014$grid_code,5),
         "Year" = 2014) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2015States <- pollutionstates2015 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2015$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2015$grid_code,5),
         "Year" = 2015) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2016States <- pollutionstates2016 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2016$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2016$grid_code,5),
         "Year" = 2016) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2017States <- pollutionstates2017 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2017$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2017$grid_code,5),
         "Year" = 2017) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2018States <- pollutionstates2018 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2018$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2018$grid_code,5),
         "Year" = 2018) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2019States <- pollutionstates2019 %>%
  mutate("Name" = Name,
         "Type" = Type,
         "PM 2.5 Score" = round(pollutionstates2019$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutionstates2019$grid_code,5),
         "Year" = 2019) %>%
  dplyr::select("Name","Type","PM 2.5 Score","PM 2.5 Concentration Quantile","Year")

Complete2010Time <- timepollution2010 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2010$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2010$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2011Time <- timepollution2011 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2011$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2011$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2012Time <- timepollution2012 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2012$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2012$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2013Time <- timepollution2013 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2013$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2013$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2014Time <- timepollution2014 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2014$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2014$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2015Time <- timepollution2015 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2015$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2015$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2016Time <- timepollution2016 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2016$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2016$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2017Time <- timepollution2017 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2017$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2017$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2018Time <- timepollution2018 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2018$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2018$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2019Time <- timepollution2019 %>%
  mutate("District" = LAST_DISTRICT,
         "PM 2.5 Score" = round(timepollution2019$grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(timepollution2019$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")




Complete2010Districts <- pollutiondistricts2010 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2010$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2011Districts <- pollutiondistricts2011 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2011$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2012Districts <- pollutiondistricts2012 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2012$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2013Districts <- pollutiondistricts2013 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2013$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2014Districts <- pollutiondistricts2014 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2014$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2015Districts <- pollutiondistricts2015 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2015$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2016Districts <- pollutiondistricts2016 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2016$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2017Districts <- pollutiondistricts2017 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2017$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2018Districts <- pollutiondistricts2018 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2018$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")

Complete2019Districts <- pollutiondistricts2019 %>%
  mutate("District" = distname,
         "PM 2.5 Score" = round(grid_code, digits=2),
         "PM 2.5 Concentration Quantile" = ntile(pollutiondistricts2019$grid_code,5),
         "time" = time) %>%
  dplyr::select("District","PM 2.5 Concentration Quantile","time")



States2010 <- Complete2010States
States2011 <- Complete2011States 
States2012 <- Complete2012States
States2013 <- Complete2013States 
States2014 <- Complete2014States 
States2015 <- Complete2015States 
States2016 <- Complete2016States 
States2017 <- Complete2017States
States2018 <- Complete2018States 
States2019 <- Complete2019States 


Districts2010 <- Complete2010Districts
Districts2011 <- Complete2011Districts
Districts2012 <- Complete2012Districts
Districts2013 <- Complete2013Districts
Districts2014 <- Complete2014Districts
Districts2015 <- Complete2015Districts
Districts2016 <- Complete2016Districts
Districts2017 <- Complete2017Districts
Districts2018 <- Complete2018Districts
Districts2019 <- Complete2019Districts





#might need to delete geometries
States2010 <- Complete2010States
States2011 <- Complete2011States 
States2012 <- Complete2012States
States2013 <- Complete2013States 
States2014 <- Complete2014States 
States2015 <- Complete2015States 
States2016 <- Complete2016States 
States2017 <- Complete2017States
States2018 <- Complete2018States 
States2019 <- Complete2019States 

Times2010 <- Complete2010Time
Times2011 <- Complete2011Time 
Times2012 <- Complete2012Time
Times2013 <- Complete2013Time 
Times2014 <- Complete2014Time 
Times2015 <- Complete2015Time 
Times2016 <- Complete2016Time 
Times2017 <- Complete2017Time
Times2018 <- Complete2018Time 
Times2019 <- Complete2019Time 


States20102011 <- rbind(States2010,States2011)
States20102012 <- rbind(States20102011,States2012)
States20102013 <- rbind(States20102012,States2013)
States20102014 <- rbind(States20102013,States2014)
States20102015 <- rbind(States20102014,States2015)
States20102016 <- rbind(States20102015,States2016)
States20102017 <- rbind(States20102016,States2017)
States20102018 <- rbind(States20102017,States2018)
States20102019 <- rbind(States20102018,States2019)

Times20102011 <- rbind(Times2010,Times2011)
Times20102012 <- rbind(Times20102011,Times2012)
Times20102013 <- rbind(Times20102012,Times2013)
Times20102014 <- rbind(Times20102013,Times2014)
Times20102015 <- rbind(Times20102014,Times2015)
Times20102016 <- rbind(Times20102015,Times2016)
Times20102017 <- rbind(Times20102016,Times2017)
Times20102018 <- rbind(Times20102017,Times2018)
Times20102019 <- rbind(Times20102018,Times2019)

Districts20102011 <- rbind(Districts2010,Districts2011)
Districts20102012 <- rbind(Districts20102011,Districts2012)
Districts20102013 <- rbind(Districts20102012,Districts2013)
Districts20102014 <- rbind(Districts20102013,Districts2014)
Districts20102015 <- rbind(Districts20102014,Districts2015)
Districts20102016 <- rbind(Districts20102015,Districts2016)
Districts20102017 <- rbind(Districts20102016,Districts2017)
Districts20102018 <- rbind(Districts20102017,Districts2018)
Districts20102019 <- rbind(Districts20102018,Districts2019)










s<-timepollution2010 %>%
  filter(LAST_DISTRICT == "Alwar")



# Example visualization to make sure it worked 
basemap<- ggplot() +
  geom_sf(data=st_union(timepollution2010)) +
  geom_sf(data=timepollution2010) 

base_map <- timepollution2010 %>%
  dplyr::select(geometry,censuscode)

pollution <- States20102019

time <-Times20102019

pollution.panel <-
  expand.grid(
    Year = unique(pollution$Year),
    Name = unique(States20102019$Name))

time.panel <-
  expand.grid(
    Time = unique(time$Time),
    censuscode = unique(Times20102019$censuscode)
  )

time.animation.data <- time %>%
  right_join(time.panel) %>% 
  group_by(Time, censuscode) %>%
  dplyr::select(Time,censuscode,'PM 2.5 Concentration Quantile')
  mutate(Quantile = case_when('PM 2.5 Score' < 13.96 ~ "0-13.96",
                                       'PM 2.5 Score' > 13.96 & 'PM 2.5 Score' <= 25.16 ~ "13.97-25.16",
                                       'PM 2.5 Score' > 25.16 & 'PM 2.5 Score' <= 35.17 ~ "25.17-35.17",
                                       'PM 2.5 Score' > 35.17 & 'PM 2.5 Score' <= 49.60 ~ "35.18-49.60",
                                       'PM 2.5 Score' > 49.60 ~ "49.61-114.07")) %>%
  mutate(Quantile = fct_relevel(Quantile,"0-13.96","13.97-25.16","25.17-35.17",
                                         "35.18-49.60","49.61-114.07"))

time_animation <- 
  ggplot() + 
  geom_sf(data = time.animation.data, aes(fill = 'PM 2.5 Concentration Quantile')) +
  scale_fill_manual(values = palette5,
                    labels = qBr(time.animation.data,'PM 2.5 Concentration Quantile'),
                    name="PM 2.5 Pollution Score\n(Quantile Breaks)") +
  labs(title = "PM 2.5 Concentration in India",
       subtitle = "2010-2019: {current_frame}") +
  transition_manual(Time) +
  mapTheme()

ggplot() +
  geom_sf(data=st_union(filteredSocial)) +
  geom_sf(data=filteredSocial,aes(fill=q5(SocVulScore)))+
  scale_fill_manual(values=palette5,
                    labels=qBr(filteredSocial,"SocVulScore"),
                    name="Social Vulnerability Score\n(Quintile Breaks)")+
  labs(title="Social Vulnerability Score", 
       subtitle="Los Angeles, CA", 
       caption="Figure 4") +
  mapTheme()


time.animation.data <- time %>%
  right_join(time.panel) %>%
  group_by(Time,District) %>%
  ungroup() %>%
  st_sf()

time_animation <-
  ggplot() +
  geom_sf(data = time.animation.data, aes(fill = 'PM 2.5 Quantile')) +
  scale_fill_manual(values = palette5,
                    labels=qBr(time.animation.data,"PM 2.5 Score"),
                    name="PM 2.5 Pollution Score\n(Quintile Breaks)") +
  labs(title = "PM 2.5 Pollution Concentration",
       subtitle = "India 2010-2019: {current_frame}") +
  transition_manual(Time) +
  mapTheme()


p <- Times20102019 %>%
  filter(District == "Mahesana")


q <- Times20102019 %>%
  filter(District == "Alwar")


pollution.animation.data <- pollution  %>%
  right_join(pollution.panel) %>% 
  group_by(Year, Name) %>%
  ungroup() %>%
  st_sf() # %>%
#  mutate('PM 2.5 Quantile' = case_when('PM 2.5 Score' < 13.96 ~ "0-13.96",
#                                       'PM 2.5 Score' > 13.96 & 'PM 2.5 Score' <= 25.16 ~ "13.97-25.16",
#                                       'PM 2.5 Score' > 25.16 & 'PM 2.5 Score' <= 35.17 ~ "25.17-35.17",
#                                       'PM 2.5 Score' > 35.17 & 'PM 2.5 Score' <= 49.60 ~ "35.18-49.60",
#                                       'PM 2.5 Score' > 49.60 ~ "49.61-114.07")) %>%
#  mutate('PM 2.5 Quantile' = fct_relevel('PM 2.5 Quantile', "0-13.96","13.97-25.16","25.17-35.17",
#                                         "35.18-49.60","49.61-114.07"))


ggplot() +
  geom_sf(data=st_union(Times2010)) +
  geom_sf(data=Times2010,aes(fill='PM 2.5 Quantile'))+
  scale_fill_manual(values=palette5,
                    labels=qBr(Times2010,"PM 2.5 Quantile"),
                    name="PM 2.5 Score\n(Quintile Breaks)")+
  labs(title="PM 2.5 2010-2019", 
       subtitle="India", 
       caption="Figure 4") +
  mapTheme()



pollution_animation <-
  ggplot() +
  geom_sf(data = pollution.animation.data, aes(fill = q5('PM 2.5 Score'))) +
  scale_fill_manual(values = palette5,
                    labels=qBr(pollution.animation.data,"PM 2.5 Score"),
                    name="PM 2.5 Pollution Score\n(Quintile Breaks)") +
  labs(title = "PM 2.5 Pollution Concentration",
       subtitle = "India 2010-2019: {current_frame}") +
  transition_manual(Year) +
  mapTheme()



p <- Times20102019 %>%
  filter(District == "Kachchh")

st_write(Districts20102019, "/Users/Aidan/Desktop/India-Timelapse/data/DataForMap/timesdistricts20102019pm25.geojson")
animate(pollution_animation, duration=20, renderer = gifski_renderer())

st_write(Times20102019, "/Users/Aidan/Desktop/India-Timelapse/data/DataForMap/times20102019pm25.geojson")
st_write(Complete2010Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2010pm25.geojson")
st_write(Complete2011Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2011pm25.geojson")
st_write(Complete2012Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2012pm25.geojson")
st_write(Complete2013Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2013pm25.geojson")
st_write(Complete2014Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2014pm25.geojson")
st_write(Complete2015Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2015pm25.geojson")
st_write(Complete2016Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2016pm25.geojson")
st_write(Complete2017Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2017pm25.geojson")
st_write(Complete2018Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2018pm25.geojson")
st_write(Complete2019Time, "/Users/Aidan/Desktop/India Timelapse/data/DataForMap/times2019pm25.geojson")



st_write(Complete2010States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2010pm25.geojson")
st_write(Complete2011States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2011pm25.geojson")
st_write(Complete2012States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2012pm25.geojson")
st_write(Complete2013States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2013pm25.geojson")
st_write(Complete2014States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2014pm25.geojson")
st_write(Complete2015States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2015pm25.geojson")
st_write(Complete2016States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2016pm25.geojson")
st_write(Complete2017States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2017pm25.geojson")
st_write(Complete2018States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2018pm25.geojson")
st_write(Complete2019States, "/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/DataForMap/states2019pm25.geojson")
"C:\Users\Aidan\Desktop\India Pollution Project\India-PM-2.5-Pollution-Project\data\StatewiseData\StatewiseTreeCover.csv"

# Tree Cover
TreeCover <- read.csv("/Users/Aidan/Desktop/India Pollution Project/India-PM-2.5-Pollution-Project/data/StatewiseData/StatewiseTreeCover.csv") 

# ADD ROW TO POLLUTIONandHEALTH FOR 137000 Tract 
PollutionandHealth[nrow(PollutionandHealth) + 1,] <- c(6037137000,2354,'Los Angeles',91367,'Woodland Hills',-118.636,34.16657,11.72,18.27,'15-20%',0.055,73.5,10.81494,53.67,0.046,16.37,702.76,72.97,46.34,46.13,0.01,12.18,232.1077,36.11,347.2178,10.85,0.1,2.43,1.05,9.87,0.05,26.37,3,34.11,0,0,31.67,3.9,24.23,38.86,39.49,2.17,2.75,15.38,68.71,5.9,25.1,2.1,16.42,6.9,3.56,4.9,35.13,12.8,24.78,28.99,3.01,18.54)

# Convert lat/long to a sf 
Pollution_sf <- PollutionandHealth %>%
  st_as_sf(coords = c("Longitude","Latitude"), crs=4326)%>%
  st_transform('EPSG:3498')


# filter to only LA 
#filteredPollution = st_filter(Pollution_sf, Homeless_and_Tracts, .pred = st_within)

Pollution_and_Tracts <- merge(Homeless_and_Tracts, st_drop_geometry(Pollution_sf), by.x="Tract", by.y="Census.Tract", all.Homeless_and_Tracts=TRUE) %>%
  dplyr::select(-Total.Population, -ZIP, -California.County, -Nearby.City...to.help.approximate.location.only.,
                -DRAFT.CES.4.0.Percentile.Range, -Ozone, -PM2.5, -Diesel.PM, -Drinking.Water, 
                -Lead, -Lead.Pctl, -Pesticides, -Pesticides.Pctl, -Tox..Release, -Traffic, -Traffic.Pctl, -Cleanup.Sites,
                -Cleanup.Sites.Pctl, -Groundwater.Threats, -Haz..Waste, -Imp..Water.Bodies, -Solid.Waste,
                -Low.Birth.Weight, -Cardiovascular.Disease,
                -TotalUnemployed, -TotalWorkers, -Institutionalized, -Total18To65, -DRAFT.CES.4.0.Score,
                -DRAFT.CES.4.0.Percentile,-Drinking.Water.Pctl,-Tox..Release.Pctl,
                -Groundwater.Threats.Pctl, -Haz..Waste.Pctl, -Imp..Water.Bodies.Pctl, -Solid.Waste.Pctl,
                -Pollution.Burden.Score,-Asthma, -Education, -Linguistic.Isolation, -Poverty, -Pollution.Burden, 
                -Unemployment, -Housing.Burden, -Pop..Char..Score, -Pop..Char., -Pop..Char..Pctl)











































MapToken = "pk.eyJ1IjoiYWlkYW5wY29sZSIsImEiOiJjbDEzcmwwY2oxeGd4M2tydHJvNmtidjMyIn0.DJrO8ZYZuhECivpDEs2pAA"
mb_access_token(MapToken,install=TRUE,overwrite = TRUE)

tm_shape(pollutionstates2010) + 
  tm_polygons()

hennepin_tiles <- get_static_tiles(
  location = pollutionstates2010,
  zoom = 6,
  style_id = "light-v9",
  username = "mapbox"
)

# Social and Environmental Vulnerability Map 
tm_shape(hennepin_tiles) + 
  tm_rgb() + 
  tm_shape(pollutionstates2010) + 
  tm_polygons(col = "grid_code",
              style = "jenks",
              n = 5,
              palette = "Reds",
              title = "Average PM 2.5 Concentration",
              alpha = 0.7) +
  tm_layout(title = "Average PM 2.5 Concentration\nby district in India",
            legend.outside = TRUE,
            fontfamily = "Verdana") + 
  tm_scale_bar(position = c("left", "bottom")) + 
  tm_compass(position = c("right", "top")) + 
  tm_credits("(c) Mapbox, OSM    ", 
             bg.color = "white",
             position = c("RIGHT", "BOTTOM"))

# DATA WRANGLINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG


# Hospitals and Urgent Cares  
# Read in the CSV data and store it in a variable 
HAddress <- read.csv("/Users/Aidan/Desktop/code2/LARPFINAL/los-angeles-county-hospitals-and-medical-centers.csv")

# take (lat,lon) out of ADDRESS column
#HisAddress$ADDRESS<-gsub("^.*\\(","",HisAddress$ADDRESS)
#HisAddress$ADDRESS<-gsub(")", "", HisAddress$ADDRESS)
#HisLatLon <- HisAddress %>%
#  mutate(X = gsub("^(.*?),.*", "\\1", HisAddress$ADDRESS),
#         Y = gsub(".*,","",HisAddress$ADDRESS))

# Convert lat/long to a sf
H_sf <- HAddress %>%
  st_as_sf(coords = c("longitude","latitude"), crs=4326)%>%
  st_transform('EPSG:3498') 

# Example visualization to make sure it worked 
ggplot() + 
  geom_sf(data=st_union(filteredTracts)) +
  geom_sf(data=H_sf, 
          show.legend = "point", size= 2) +
  labs(title="Hospitals and Urgent Care Locations", 
       subtitle="Los Angeles, CA", 
       caption="Figure 2") +
  mapTheme()

# Emergency Preparedness Locations (schools)
# Read in the CSV data and store it in a variable 
ELocations <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Public_Elementary_Schools.geojson") %>%
  st_transform('EPSG:3498') 

MLocations <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Public_Middle_Schools.geojson") %>%
  st_transform('EPSG:3498')

HLocations <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Public_High_Schools.geojson") %>%
  st_transform('EPSG:3498')

CLocations <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Colleges_and_Universities.geojson") %>%
  st_transform('EPSG:3498')

EandM <- rbind(ELocations, MLocations)
HandC <- rbind(HLocations, CLocations)
EmergencyLocations <- rbind(EandM, HandC)


# Convert lat/long to a sf 
Emergency_sf <- EmergencyLocations %>%
  st_as_sf(coords = c("longitude","latitude"), crs=4326)%>%
  st_transform('EPSG:3498')

# Example visualization to make sure it worked 
ggplot() + 
  geom_sf(data=st_union(filteredTracts)) +
  geom_sf(data=Emergency_sf, 
          show.legend = "point", size= 2) +
  labs(title="Emergency Preparedness Sites", 
       subtitle="Los Angeles, CA", 
       caption="Figure 3") +
  mapTheme()


# community cooling centers = libraries
CoolingLocations <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Libraries.geojson") %>%
  st_transform('EPSG:3498')


# Example visualization to make sure it worked 
ggplot() + 
  geom_sf(data=st_union(filteredTracts)) +
  geom_sf(data=CoolingLocations, 
          show.legend = "point", size= 2) +
  labs(title="Community Cooling Centers", 
       subtitle="Los Angeles, CA", 
       caption="Figure 4") +
  mapTheme()



# Homeless Count by Census tract 
HomelessCount <- 
  st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Homeless_Count_Los_Angeles_County_2019.geojson") %>%
  st_transform('EPSG:3498') 

HomelessTracts <- HomelessCount$Tract_N

Homeless_and_Tracts <- filteredTracts %>%
  mutate(HomelessPeople = ifelse(filteredTracts$Tract_N %in% HomelessTracts, HomelessCount$totPeopl_1, 0),
         pctHomeless = ifelse(HomelessPeople > 0 & TotalPop > 0, HomelessPeople/TotalPop,0),
         HomelessDensity = ifelse(filteredTracts$Tract_N %in% HomelessTracts, HomelessCount$t_dens,0))
# combine homeless count with tracts 
#Homeless_and_Tracts <- merge(filteredTracts, st_drop_geometry(HomelessCount), by="Tract_N", all.filteredTracts=TRUE) %>%
#  dplyr::select(-FID, -SPA, -CD, -Detailed_1, -Detailed_N, -SD, -Tract_1, -Year_1, -unincorpor,
#                -SHAPE_Length, -SHAPE_Area, -totUnshe_1, -totShelt_1, -u_dens, -s_dens)


# Pollution and health data 
PollutionandHealth <- read.csv("/Users/Aidan/Desktop/code2/LARPFINAL/CalEnviroScreen_4.0Excel_ADA_D1_2021.csv") %>%
  filter(California.County=='Los Angeles')

# ADD ROW TO POLLUTIONandHEALTH FOR 137000 Tract 
PollutionandHealth[nrow(PollutionandHealth) + 1,] <- c(6037137000,2354,'Los Angeles',91367,'Woodland Hills',-118.636,34.16657,11.72,18.27,'15-20%',0.055,73.5,10.81494,53.67,0.046,16.37,702.76,72.97,46.34,46.13,0.01,12.18,232.1077,36.11,347.2178,10.85,0.1,2.43,1.05,9.87,0.05,26.37,3,34.11,0,0,31.67,3.9,24.23,38.86,39.49,2.17,2.75,15.38,68.71,5.9,25.1,2.1,16.42,6.9,3.56,4.9,35.13,12.8,24.78,28.99,3.01,18.54)

# Convert lat/long to a sf 
Pollution_sf <- PollutionandHealth %>%
  st_as_sf(coords = c("Longitude","Latitude"), crs=4326)%>%
  st_transform('EPSG:3498')


# filter to only LA 
#filteredPollution = st_filter(Pollution_sf, Homeless_and_Tracts, .pred = st_within)

Pollution_and_Tracts <- merge(Homeless_and_Tracts, st_drop_geometry(Pollution_sf), by.x="Tract", by.y="Census.Tract", all.Homeless_and_Tracts=TRUE) %>%
  dplyr::select(-Total.Population, -ZIP, -California.County, -Nearby.City...to.help.approximate.location.only.,
                -DRAFT.CES.4.0.Percentile.Range, -Ozone, -PM2.5, -Diesel.PM, -Drinking.Water, 
                -Lead, -Lead.Pctl, -Pesticides, -Pesticides.Pctl, -Tox..Release, -Traffic, -Traffic.Pctl, -Cleanup.Sites,
                -Cleanup.Sites.Pctl, -Groundwater.Threats, -Haz..Waste, -Imp..Water.Bodies, -Solid.Waste,
                -Low.Birth.Weight, -Cardiovascular.Disease,
                -TotalUnemployed, -TotalWorkers, -Institutionalized, -Total18To65, -DRAFT.CES.4.0.Score,
                -DRAFT.CES.4.0.Percentile,-Drinking.Water.Pctl,-Tox..Release.Pctl,
                -Groundwater.Threats.Pctl, -Haz..Waste.Pctl, -Imp..Water.Bodies.Pctl, -Solid.Waste.Pctl,
                -Pollution.Burden.Score,-Asthma, -Education, -Linguistic.Isolation, -Poverty, -Pollution.Burden, 
                -Unemployment, -Housing.Burden, -Pop..Char..Score, -Pop..Char., -Pop..Char..Pctl)


Pollution_and_Tracts[is.na(Pollution_and_Tracts)] <- 0

SocialTracts <- Pollution_and_Tracts %>%
  mutate(PM2.5.Pctl = as.numeric(Pollution_and_Tracts$PM2.5.Pctl) / 100,
         Pollution.Burden.Pctl = as.numeric(Pollution_and_Tracts$Pollution.Burden.Pctl) / 100,
         Asthma.Pctl = as.numeric(Pollution_and_Tracts$Asthma.Pctl) / 100, 
         Education.Pctl = as.numeric(Pollution_and_Tracts$Education.Pctl) / 100, 
         Linguistic.Isolation.Pctl = as.numeric(Pollution_and_Tracts$Linguistic.Isolation.Pctl) / 100,
         Poverty.Pctl = as.numeric(Pollution_and_Tracts$Poverty.Pctl) / 100, 
         Unemployment.Pctl = as.numeric(Pollution_and_Tracts$Unemployment.Pctl) / 100,
         Housing.Burden.Pctl = as.numeric(Pollution_and_Tracts$Housing.Burden.Pctl) / 100,
         Low.Birth.Weight.Pctl = as.numeric(Pollution_and_Tracts$Low.Birth.Weight.Pctl) / 100, 
         Cardiovascular.Disease.Pctl = as.numeric(Pollution_and_Tracts$Cardiovascular.Disease.Pctl) / 100,
         Ozone.Pctl = as.numeric(Pollution_and_Tracts$Ozone.Pctl) / 100,
         Diesel.PM.Pctl = as.numeric(Pollution_and_Tracts$Diesel.PM.Pctl) / 100) 

SocialTracts <- SocialTracts %>%
  mutate(EducationQuantile = ntile(SocialTracts$Education.Pctl,5),
         PovertyQuantile = ntile(SocialTracts$Poverty.Pctl,5),
         UnemploymentQuantile = ntile(SocialTracts$Unemployment.Pctl,5),
         SingleParentQuantile = ntile(SocialTracts$pctSinglePar,5),
         Under5Quantile = ntile(SocialTracts$pctUnder5,5),
         Over65Quantile = ntile(SocialTracts$pctOver65,5),
         MentalQuantile = ntile(SocialTracts$pctMENTAL,5),
         PhysicalQuantile = ntile(SocialTracts$pctPHY,5),
         NonWhiteQuantile = ntile(SocialTracts$pctNonWhite,5),
         ImmigrantsQuantile = ntile(SocialTracts$pctImmigrants,5),
         PriorImmigrantQuantile = ntile(SocialTracts$pctPriorImmigrants,5),
         LinguisticIsolationQuantile = ntile(SocialTracts$Linguistic.Isolation.Pctl,5),
         AsthmaQuantile = ntile(SocialTracts$Asthma.Pctl,5),
         BirthWeightQuantile = ntile(SocialTracts$Low.Birth.Weight.Pctl,5),
         CardioDiseaseQuantile = ntile(SocialTracts$Cardiovascular.Disease.Pctl,5),
         CarlessQuantile = ntile(SocialTracts$pctCarless,5),
         PublicTransQuantile = ntile(SocialTracts$pctPubTrans,5),
         HomelessQuantile = ntile(SocialTracts$pctHomeless,5),
         InstitQuantile = ntile(SocialTracts$pctInstit,5),
         HBurdenQuantile = ntile(SocialTracts$Housing.Burden.Pctl,5))




SocialVulScore <- SocialTracts %>%
  mutate(SocVulScore = (((SocialTracts$EducationQuantile + SocialTracts$PovertyQuantile + SocialTracts$UnemploymentQuantile) / 3) * 0.2 + ((SocialTracts$SingleParentQuantile + SocialTracts$Under5Quantile + SocialTracts$Over65Quantile + SocialTracts$PhysicalQuantile + SocialTracts$MentalQuantile) / 5) * 0.2 + ((SocialTracts$NonWhiteQuantile + SocialTracts$ImmigrantsQuantile + SocialTracts$PriorImmigrantQuantile + SocialTracts$LinguisticIsolationQuantile) / 4) * 0.2 + ((SocialTracts$AsthmaQuantile + SocialTracts$CardioDiseaseQuantile + SocialTracts$BirthWeightQuantile) / 3) * 0.2 + ((SocialTracts$CarlessQuantile + SocialTracts$HomelessQuantile + SocialTracts$InstitQuantile + SocialTracts$PublicTransQuantile + SocialTracts$HBurdenQuantile) / 5) * 0.2))

SocialVulScore[is.na(SocialVulScore)] <- 0

filteredSocial <- SocialVulScore %>%
  filter(SocialVulScore$Tract_N != 599100 & SocialVulScore$Tract_N != 599000)

ggplot() +
  geom_sf(data=st_union(filteredSocial)) +
  geom_sf(data=filteredSocial,aes(fill=q5(SocVulScore)))+
  scale_fill_manual(values=palette5,
                    labels=qBr(filteredSocial,"SocVulScore"),
                    name="Social Vulnerability Score\n(Quintile Breaks)")+
  labs(title="Social Vulnerability Score", 
       subtitle="Los Angeles, CA", 
       caption="Figure 4") +
  mapTheme()


MapToken = "pk.eyJ1IjoiYWlkYW5wY29sZSIsImEiOiJjbDEzcmwwY2oxeGd4M2tydHJvNmtidjMyIn0.DJrO8ZYZuhECivpDEs2pAA"
mb_access_token(MapToken,install=TRUE,overwrite = TRUE)

tm_shape(filteredSocial) + 
  tm_polygons()

hennepin_tiles <- get_static_tiles(
  location = filteredSocial,
  zoom = 10,
  style_id = "light-v9",
  username = "mapbox"
)

# Social and Environmental Vulnerability Map 
tm_shape(hennepin_tiles) + 
  tm_rgb() + 
  tm_shape(filteredSocial) + 
  tm_polygons(col = "SocVulScore",
              style = "jenks",
              n = 5,
              palette = "Purples",
              title = "Social Vulnerability Index",
              alpha = 0.7) +
  tm_layout(title = "Social Vulnerability Index\nby Census tract",
            legend.outside = TRUE,
            fontfamily = "Verdana") + 
  tm_scale_bar(position = c("left", "bottom")) + 
  tm_compass(position = c("right", "top")) + 
  tm_credits("(c) Mapbox, OSM    ", 
             bg.color = "white",
             position = c("RIGHT", "BOTTOM"))







######## PHYSICAL VULNERABILITY 

# turn SocialVulScore into filteredSocial if you want without catalina islands 
#distance to closest hospital in feet 
nearestHospital <- st_nearest_feature(st_centroid(SocialVulScore),H_sf)
nearestHospitalDist = st_distance(st_centroid(SocialVulScore), H_sf[nearestHospital,], by_element=TRUE)
SocialVulScore$nearestHospitalDist = nearestHospitalDist

#Count of hospitals per census tract 
SocialVulScore <- SocialVulScore %>% 
  mutate(HospitalCounts = lengths(st_intersects(., H_sf)))


#distance to closest emergency preparedness location 
nearestEmergencyPrep <- st_nearest_feature(st_centroid(SocialVulScore),Emergency_sf)
nearestEmergencyPrepDist = st_distance(st_centroid(SocialVulScore), Emergency_sf[nearestEmergencyPrep,], by_element=TRUE)
SocialVulScore$nearestEmergencyPrepDist = nearestEmergencyPrepDist


#Count of emergency preparedness locations per census tracts 
SocialVulScore <- SocialVulScore %>% 
  mutate(EmergencyPrepCounts = lengths(st_intersects(., Emergency_sf)))


#distance to closest community cooling center 
nearestCoolingStation <- st_nearest_feature(st_centroid(SocialVulScore),CoolingLocations)
nearestCoolingDist = st_distance(st_centroid(SocialVulScore), CoolingLocations[nearestCoolingStation,], by_element=TRUE)
SocialVulScore$nearestCoolingDist = nearestCoolingDist


#Count of community cooling locations per census tracts 
SocialVulScore <- SocialVulScore %>% 
  mutate(CoolingStationCounts = lengths(st_intersects(., CoolingLocations)))


# load in public pools dataset 
PoolLocations <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Pools.geojson") %>%
  st_transform('EPSG:3498')

# Convert lat/long to a sf 
Pool_sf <- PoolLocations %>%
  st_as_sf(coords = c("longitude","latitude"), crs=4326)%>%
  st_transform('EPSG:3498')


#distance to closest public pool
nearestPool <- st_nearest_feature(st_centroid(SocialVulScore),Pool_sf)
nearestPoolDist = st_distance(st_centroid(SocialVulScore), Pool_sf[nearestPool,], by_element=TRUE)
SocialVulScore$nearestPoolDist = nearestPoolDist


#Count of public pool per census tracts 
SocialVulScore <- SocialVulScore %>% 
  mutate(PoolCounts = lengths(st_intersects(., Pool_sf)))


#HEAT DATA
historicalTemps <- read.csv("/Users/Aidan/Desktop/code2/LARPFINAL/CHAT-Los Angeles County-historical.csv") %>%
  distinct(census_tract, .keep_all = TRUE) %>%
  dplyr::select(census_tract,avg_event_rh_max_perc,avg_event_rh_min_perc,tmax,tmin,hist_avg_annual_events,hist_avg_duration)


Temps_and_Tracts <- merge(SocialVulScore, historicalTemps, by.x="Tract", by.y="census_tract", all.SocialVulScore=TRUE)

### USE A DIFFERENT PROJECTIONS TIME FRAME SINCE HISTORICAL IS SOMEHOW HIGHER THAN 2011-2030
projectedTemps <- read.csv("/Users/Aidan/Desktop/code2/LARPFINAL/CHAT-Los Angeles County-projected (1).csv") %>%
  na.omit() %>%
  filter(.,projections_time_frame == '2031-2050') 

filteredProjected <- projectedTemps %>%
  mutate(Tract = substring(projectedTemps$geoid_long, nchar(as.character(projectedTemps$geoid_long)) - 9)) %>%
  distinct(Tract, .keep_all = TRUE) 


All_Temps_and_Tracts <- merge(Temps_and_Tracts, filteredProjected, by.x="Tract", by.y="Tract", all.Temps_and_Tracts=TRUE) %>%
  dplyr::select(-geoid_long,-rcp,-projections_ct,-census_county,-census_city,-projections_time_frame,
                -socioeconomic_group,-time_of_year,-model_percentiles)


# polygon green space 
GreenSpace <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Countywide_Parks_and_Open_Space_(Public_-_Hosted).geojson") %>%
  st_transform('EPSG:3498') 

# Angeles National Forest only, for proximity to largest public access open green space in the county 
AngelesForest <- GreenSpace %>%
  filter(OBJECTID == 1676)

#distance to Angeles National Forest
AngelesForestDist = st_distance(st_centroid(All_Temps_and_Tracts), GreenSpace[AngelesForest,], by_element=TRUE)
All_Temps_and_Tracts$AngelesForestDist = AngelesForestDist


# convert polygons to centroid points to see which parks and open spaces belong to which census tracts
GreenCentroids <- GreenSpace %>%
  filter(OBJECTID != 1676) %>%
  st_drop_geometry() %>%
  st_as_sf(coords = c("CENTER_LON","CENTER_LAT"), crs=4326) %>%
  st_transform('EPSG:3498') %>%
  dplyr::select(ZIP,RPT_ACRES,geometry)

#Count of green space centroids per census tract 
All_Temps_and_Tracts <- All_Temps_and_Tracts %>% 
  mutate(ParkCounts = lengths(st_intersects(., GreenCentroids)))

# list of tracts to help join later 
Tracts <- All_Temps_and_Tracts %>%
  dplyr::select(Tract,geometry)

# sum total green acres per tract, those tracts not in dataframe have zero public green space 
tracts_with_green <- st_join(GreenCentroids, Tracts, left = F)

GreenTracts <- tracts_with_green %>%
  group_by(Tract) %>%
  summarise(Acres = sum(RPT_ACRES))

GreenIDs <- GreenTracts %>%
  st_drop_geometry() %>%
  dplyr::select(Tract)

# join acres to tracts 
AcreTracts <- All_Temps_and_Tracts %>%
  mutate(GreenAcres = ifelse(All_Temps_and_Tracts$Tract %in% GreenIDs$Tract, GreenTracts$Acres, 0))


# load in census tract layer to get area for each census tract to later calculate percent green space per census tract 
#TractAreas <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/Census_Tracts_2020.geojson") %>%
#  st_transform('EPSG:3498') %>%
#  st_drop_geometry() %>%
#  dplyr::select(CT20, ShapeSTArea)

#filteredTractAreas <- st_filter(TractAreas, AcreTracts, .pred = st_intersects)

# 0.000022956 * square ft area = acres 
MoreAcreTracts <- AcreTracts %>%
  mutate(TotalAreaSF = st_area(AcreTracts),
         TotalAcres = TotalAreaSF * 0.000022956)

# tracts with percent public green space 
GreenSpaceTracts <- MoreAcreTracts %>%
  drop_units() %>%
  mutate(pctGreenSpace = ifelse(TotalAcres > 0 & TotalAcres > GreenAcres, GreenAcres/TotalAcres, 0)) 


nearestPark <- st_nearest_feature(st_centroid(GreenSpaceTracts),GreenCentroids)
nearestParkDist = st_distance(st_centroid(GreenSpaceTracts), GreenCentroids[nearestPark,], by_element=TRUE)
GreenSpaceTracts$nearestParkDist = nearestParkDist
#drop_units(GreenSpaceTracts)



#CALCULATE CITY AVERAGE HISTORICAL TMAX AND THEN MAKE FEATURE FOR DIFFERENCE BETWEEN EACH TRACT'S VALUES AND THE AVERAGE VALUES
GreenSpaceTracts <- GreenSpaceTracts %>%
  mutate(HisProjTDiff = GreenSpaceTracts$proj_avg_tmax - GreenSpaceTracts$tmax,
         HisProjEventDiff = GreenSpaceTracts$proj_ann_num_events - GreenSpaceTracts$hist_avg_annual_events,
         HisProjDurDiff = GreenSpaceTracts$proj_avg_duration - GreenSpaceTracts$hist_avg_duration,
         HisProjPercDiff = GreenSpaceTracts$proj_avg_rhmax - GreenSpaceTracts$avg_event_rh_max_perc) %>%
  filter(GreenSpaceTracts$Tract_N != 599100 & GreenSpaceTracts$Tract_N != 599000) %>%
  drop_units()


# TREE CANOPY 
tracts_w_tc_id <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/tracts_w_tc_id.geojson") %>%
  st_transform('EPSG:3498') %>%
  st_drop_geometry()

tc_percentages_w_ids <- st_read("/Users/Aidan/Desktop/code2/LARPFINAL/real_tc_percentages_w_id.geojson") %>%
  st_transform('EPSG:3498') %>%
  st_drop_geometry()

tracts_w_tc_percentages <- merge(tracts_w_tc_id, tc_percentages_w_ids, by.x="TC_ID", by.y="TC_ID", all.tracts_w_tc_id=TRUE) 


# group by tract, sum total area, existing tc, possible tc, etc. 
grouped_tc <- tracts_w_tc_percentages %>%
  group_by(CT10) %>%
  summarise(ExistingTC = sum(TC_E_A),
            PossibleTC = sum(TC_P_A),
            TotalArea = sum(TC_Land_A),
            PossibleIP = sum(TC_Pi_A),
            PossibleVG = sum(TC_Pv_A)) %>%   # calculate percentage
  mutate(EpctTC = ExistingTC/TotalArea,
         PpctTC = PossibleTC/TotalArea,
         PpctIP = PossibleIP/TotalArea,
         PpctVG = PossibleVG/TotalArea)

# calculate average tree canopy percentage for whole county,
# and calculate difference between average and each tract's value
# and calculate difference between possible and actual for each tract 
featured_tc <- grouped_tc %>%
  mutate(AvgTCpct = mean(grouped_tc$EpctTC),
         AvgTCpctDiff = EpctTC - AvgTCpct,
         PEpctDiff = PpctTC - EpctTC) %>%
  dplyr::select(CT10, AvgTCpctDiff, PEpctDiff, EpctTC, PpctIP, PpctVG)


TCGreenSpace <- merge(GreenSpaceTracts, featured_tc, by.x="Tract_N", by.y="CT10", all.GreenSpaceTracts=TRUE)


ggplot() +
  geom_sf(data=st_union(TCGreenSpace)) +
  geom_sf(data=TCGreenSpace,aes(fill=EpctTC))+
  labs(title="Percent Tree Canopy Coverage", 
       subtitle="Los Angeles, CA", 
       caption="Figure 1") +
  mapTheme()



### STANDARDIZE FEATURES WITH QUANTILE RANKINGS FOR PHYSVULSCORE
QuantileTracts <- TCGreenSpace %>%
  mutate(HospitalDistQuantile = ntile(TCGreenSpace$nearestHospitalDist,5),
         EmergencyDistQuantile = ntile(TCGreenSpace$nearestEmergencyPrepDist,5),
         CoolingDistQuantile = ntile(TCGreenSpace$nearestCoolingDist,5),
         ParkDistQuantile = ntile(TCGreenSpace$nearestParkDist,5),
         ForestDistQuantile = ntile(TCGreenSpace$AngelesForestDist,5),
         PoolDistQuantile = ntile(TCGreenSpace$nearestPoolDist,5),
         HospitalCountQuantile = ntile(desc(TCGreenSpace$HospitalCounts),5),
         EmergencyCountQuantile = ntile(desc(TCGreenSpace$EmergencyPrepCounts),5),
         CoolingCountQuantile = ntile(desc(TCGreenSpace$CoolingStationCounts),5),
         ParkCountQuantile = ntile(desc(TCGreenSpace$ParkCounts),5),
         PoolCountQuantile = ntile(desc(TCGreenSpace$PoolCounts),5),
         PM2.5Quantile = ntile(TCGreenSpace$PM2.5.Pctl,5),
         DieselPMQuantile = ntile(TCGreenSpace$Diesel.PM.Pctl,5),
         OzoneQuantile = ntile(TCGreenSpace$Ozone.Pctl,5),
         GreenSpaceQuantile = ntile(desc(TCGreenSpace$pctGreenSpace),5),
         HisProjTDiffQuantile = ntile(TCGreenSpace$HisProjTDiff,5),
         HisProjEventDiffQuantile = ntile(TCGreenSpace$HisProjEventDiff,5),
         HisProjDurDiffQuantile = ntile(TCGreenSpace$HisProjDurDiff,5),
         ExistingTCQuantile = ntile(desc(TCGreenSpace$EpctTC),5),
         PdiffETCQuantile = ntile(desc(TCGreenSpace$PEpctDiff),5))


PhysVulScore <- QuantileTracts %>%
  mutate(PhysVulScore = ((HospitalDistQuantile + EmergencyDistQuantile + CoolingDistQuantile + ParkDistQuantile + ForestDistQuantile + PoolDistQuantile) / 6) * 0.20 + ((HospitalCountQuantile + EmergencyCountQuantile + CoolingCountQuantile + ParkCountQuantile + PoolCountQuantile) / 5) * 0.20 + ((PM2.5Quantile + DieselPMQuantile + OzoneQuantile) / 3) * 0.20 + ((GreenSpaceQuantile + ExistingTCQuantile + PdiffETCQuantile) / 3) * 0.20 + ((HisProjTDiffQuantile + HisProjEventDiffQuantile + HisProjDurDiffQuantile) / 3) * 0.20)



ggplot() +
  geom_sf(data=st_union(PhysVulScore)) +
  geom_sf(data=PhysVulScore,aes(fill=q5(PhysVulScore)))+
  scale_fill_manual(values=palette5,
                    labels=qBr(PhysVulScore,"PhysVulScore"),
                    name="Physical Vulnerability Score\n(Quintile Breaks)")+
  labs(title="Physical Vulnerability Score", 
       subtitle="Los Angeles, CA", 
       caption="Figure 4") +
  mapTheme()


MapToken = "pk.eyJ1IjoiYWlkYW5wY29sZSIsImEiOiJjbDEzcmwwY2oxeGd4M2tydHJvNmtidjMyIn0.DJrO8ZYZuhECivpDEs2pAA"
mb_access_token(MapToken,install=TRUE,overwrite = TRUE)

tm_shape(PhysVulScore) + 
  tm_polygons()

hennepin_tiles <- get_static_tiles(
  location = PhysVulScore,
  zoom = 10,
  style_id = "light-v9",
  username = "mapbox"
)

# Social and Environmental Vulnerability Map 
tm_shape(hennepin_tiles) + 
  tm_rgb() + 
  tm_shape(PhysVulScore) + 
  tm_polygons(col = "PhysVulScore",
              style = "jenks",
              n = 5,
              palette = "Purples",
              title = "Physical Vulnerability Index",
              alpha = 0.7) +
  tm_layout(title = "Physical Vulnerability Index\nby Census tract",
            legend.outside = TRUE,
            fontfamily = "Verdana") + 
  tm_scale_bar(position = c("left", "bottom")) + 
  tm_compass(position = c("right", "top")) + 
  tm_credits("(c) Mapbox, OSM    ", 
             bg.color = "white",
             position = c("RIGHT", "BOTTOM"))



TotalVulScore <- PhysVulScore %>%
  mutate(TotalVulScore = (PhysVulScore + SocVulScore)/2,
         TotalVulScoreQuantile = ntile(TotalVulScore,5),
         SocVulScoreQuantile = ntile(SocVulScore,5),
         PhysVulScoreQuantile = ntile(PhysVulScore,5))


ggplot() +
  geom_sf(data=st_union(TotalVulScore)) +
  geom_sf(data=TotalVulScore,aes(fill=q5(TotalVulScore)))+
  scale_fill_manual(values=palette5,
                    labels=qBr(TotalVulScore,"TotalVulScore"),
                    name="Total Vulnerability Score\n(Quintile Breaks)")+
  labs(title="Total Vulnerability Score", 
       subtitle="Los Angeles, CA", 
       caption="Figure 4") +
  mapTheme()


MapToken = "pk.eyJ1IjoiYWlkYW5wY29sZSIsImEiOiJjbDEzcmwwY2oxeGd4M2tydHJvNmtidjMyIn0.DJrO8ZYZuhECivpDEs2pAA"
mb_access_token(MapToken,install=TRUE,overwrite = TRUE)

tm_shape(TotalVulScore) + 
  tm_polygons()

hennepin_tiles <- get_static_tiles(
  location = TotalVulScore,
  zoom = 10,
  style_id = "light-v9",
  username = "mapbox"
)

# Social and Environmental Vulnerability Map 
tm_shape(hennepin_tiles) + 
  tm_rgb() + 
  tm_shape(TotalVulScore) + 
  tm_polygons(col = "TotalVulScore",
              style = "jenks",
              n = 5,
              palette = "Purples",
              title = "Overall Vulnerability Index",
              alpha = 0.7) +
  tm_layout(title = "Overall Extreme Heat Vulnerability Index\nby Census tract",
            legend.outside = TRUE,
            fontfamily = "Verdana") + 
  tm_scale_bar(position = c("left", "bottom")) + 
  tm_compass(position = c("right", "top")) + 
  tm_credits("(c) Mapbox, OSM    ", 
             bg.color = "white",
             position = c("RIGHT", "BOTTOM"))




# EXPORT DATAFRAMES AS GEOJSON LAYERS 
# pools, emergency, cooling, parks, hospitals
#st_write(H_sf, "/Users/Aidan/Desktop/code2/LARPFINAL/hospitals.geojson")
#st_write(Emergency_sf, "/Users/Aidan/Desktop/code2/LARPFINAL/emergencyprep.geojson")
#st_write(CoolingLocations, "/Users/Aidan/Desktop/code2/LARPFINAL/coolingcenters.geojson")
#st_write(Pool_sf, "/Users/Aidan/Desktop/code2/LARPFINAL/publicpools.geojson")
#st_write(GreenCentroids, "/Users/Aidan/Desktop/code2/LARPFINAL/parksandgs.geojson")


#GreenCentroids <- GreenCentroids %>%
#  dplyr::select(OBJECTID,PARK_NAME,ACCESS_TYP,RPT_ACRES,ADDRESS,CITY,ZIP,PHONES,MNG_AGENCY,AGNCY_WEB)

#Emergency_sf <- Emergency_sf %>%
#  dplyr::select(OBJECTID,Name,addrln1,phones,url,zip,link,latitude,longitude)

#H_sf <- H_sf %>%
#  dplyr::select(phones,Name,zip,addrln1,hours,post_id,link,url,cat1,cat2)

#CoolingLocations <- CoolingLocations %>%
#  dplyr::select(OBJECTID,Name,addrln1,hours,phones,url,zip,link,latitude,longitude)

#Pool_sf <- Pool_sf %>%
#  dplyr::select(OBJECTID,Name,addrln1,hours,phones,url,zip,link,latitude,longitude)