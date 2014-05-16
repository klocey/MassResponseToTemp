## useful functions and example data from NMNHfrom meeting w/ Dan 3/21/14 -------
# NMNH website: http://collections.nmnh.si.edu/search/mammals/

## read in csv with example data from misc California rodents--------------------
dat = read.csv('./ExampleDataNMNH.csv')

## str function retrieves types of information in each column of dataset
str(dat)

## dim function shows number of rows and columns in dataset
dim(dat)

## names function shows column headers
names(dat)

## use $ to subset Measurements column from dataset
## as.character function turns all data entries into strings
dat$Measurements = as.character(dat$Measurements)


?sub
?substr
?grep

## using grep to show which columns contain mass information by searching for 
## data with format [number]g
tst = grep('[0-9]g', dat$Measurements)

## reads out information from the first five columns that contain mass info
dat$Measurements[tst][1:5]




###### looking at species 1 (Peromyscus maniculatus) from NMNH -------------------

## read in csv with data
species1 = read.csv('./PeromyscusmanDataNMNH.csv')

## subset measurements column, determine how many rows contain mass information
species1$Measurements = as.character(species1$Measurements)
species1_mass = grep('[0-9]g', species1$Measurements)
length(species1_mass)

## determine how many rows contain latitude information
species1_lat = which(species1$Centroid.Latitude > 0)
length(species1_lat)

## make county column values into strings, determine how many rows contain county information
species1$District.County = as.character(species1$District.County)
species1_county = which(species1$District.County > 0)
length(species1_county)

## determine how many specimens have lat and county information (using and operator)
species1_latcoun = which(species1$Centroid.Latitude > 0 & species1$District.County > 0)
## specimens with latitude info have county info

## determine how many species have mass and county information
species1_masscoun = grepl('[0-9]g', species1$Measurements) & species1$District.County > 0
length(which(species1_masscoun == TRUE))
species1_masscoun = which(species1_masscoun == TRUE)
## specimens with mass info have county info

## mapping species 1 to determine spatial spread
# read in libary for maps
library(maps)

# map to show all locations of specimens w/ latitude and longitude
map('usa')
points(species1$Centroid.Longitude, species1$Centroid.Latitude, col='red', pch=19)
# alternative way to do this
# points(Centroid.Latitude ~ Centroid.Longitude, data=species1, col='red', pch=19)

lm(y ~ x, data) ## formula style

## create county database that is in correct format for map 
counties = map('county', fill=T, plot=F)
# put state and county columns together, separate by comma
sp_counties = paste(species1$Province.State, species1$District.County, sep=',')
# lowercase all
sp_counties = tolower(sp_counties)
# remove "county" at end
sp_counties = sub(' county', '', sp_counties)
# determine how many counties from NMNH list are in maps county list
sum(sp_counties %in% counties$names)
# use ! to show how many counties from NMNH list are NOT in maps county list
sp_counties[!(sp_counties %in% counties$names)]

## if a county in our county database occurs in the species database make it red
col = ifelse(counties$names %in% sp_counties, 'red', NA)
map('county', fill=T, col=col)

## export to pdf
dir.create('./figs/')
pdf('./figs/species1_county_pres_abs_map.pdf')
map('county', fill=T, col=col)
# why?
dev.off()

# failed attempt to map specimen locations based on latitude and longitude
#map(LatLonSpecies1[1], LatLonSpecies1[2], col = 'red')


## add collection date to county fill map 
#library(mapplots)
# something similar to add.pie, see http://uchicagoconsulting.wordpress.com/2011/04/18/how-to-draw-good-looking-maps-in-r/




######## if species has sufficient data, start here to get temp v. mass plot ----------
# read in csv with data
species1 = read.csv('./PeromyscusmanDataNMNH.csv')


## convert county info to latitude/longitude, only run last line ---------------
# improve accuracy by including state name with geocode function
# improve accuracy even more by using state & county to get FIPS and then get coordinates
library(ggmap)
# Google limits use of geocode to 2,500 queries per day--could be a problem later on, see
# markdown file about this
latlon = geocode(paste(species1$Country, species1$Province.State, species1$District.County), output = 'latlon')
write.table(latlon, "LatLonSpecies1.csv", sep = ",")
LatLonSpecies1 = read.csv("./LatLonSpecies1.csv")

# check coordinates to make sure they're all in the USA
library(maps)
map('world')
points(LatLonSpecies1, col = 'red')
map('usa')
points(LatLonSpecies1, col = 'red')

# read in county-coordinate table from US Census website http://www.census.gov/geo/maps-data/data/gazetteer2013.html
county_to_coord = read.table("2013_Gaz_counties_national.txt", sep = "\t")

## summary matrix of relevant info (lat/long, date, mass) ---------------------
# need to strip everything but mass value from species1 'Measurements' column
# Dan recommended splitting up the Measurements column by its separator and then searching
# for the mass info

# code that didn't work
#splitmeas = strsplit(species1$Measurements, ';')
#mass = substr(splitmeas,grep('[0-9]g',splitmeas),grep('[0-9]g',splitmeas))


# example of a for loop
# for (current_row in species1$Measurements){print(current_row)}

# loop to remove everything from Measurements column except mass
# str_match example: http://stackoverflow.com/questions/952275/regex-group-capture-in-r
library(stringr)
masses = vector()
for (current_row in species1$Measurements){
  mass_match = str_match(current_row, "Specimen Weight: ([0-9.]*)g")
  mass = as.numeric(mass_match[2])
  masses = append(masses, mass)
}

# loop to remove total length value from Measurements column
lengths = vector()
for (current_row in species1$Measurements){
  length_match = str_match(current_row, "Total Length: ([0-9.]*)mm")
  length = as.numeric(length_match[2])
  lengths = append(lengths, length)
}

# find specimens that have length but not mass
size_values = cbind(masses, lengths)
length_nomass = is.na(size_values[,1]) & !is.na(size_values[,2])

# loop attempt #1
calc_mass = vector()
for (current_row in size_values)
  if(is.na(size_values[,1]) & !is.na(size_values[,2])) {} 

# loop attempt #2
calc_mass = vector()
for (i in 1:nrow(size_values))
  if(is.na(size_values[i,1]) & !is.na(size_values[i,2])) {
    calc_mass = size_values[i,2] * 0.14
  } else {
    calc_mass = size_values[i,1] * 100
  }

# loop attempt #3 (closest one)
calc_mass = vector()
for (i in 1:nrow(size_values))
  if(is.na(size_values[i,1]) & !is.na(size_values[i,2])) {
    calc_mass = print(1)
  } else {
    calc_mass = size_values * 100
  }

# loop attempt #4
if(is.na(size_values[1,1]) & !is.na(size_values[1,2])) {
  calc_mass = size_values[1,2] * 0.14
} else {
  print(2)
}

# test of loop b/c current dataset doesn't fulfill length but no mass
test_sizes = matrix(c(10,NA,10,NA,10,10), nrow = 3)
test_sizes

test_mass = vector()
for (i in 1:nrow(test_sizes))
  if(is.na(test_sizes[i,1]) & !is.na(test_sizes[i,2])) {
    test_mass = print(1)
  } else {
    test_mass = test_sizes * 100
  }


# remove everything but year from Date.Collected column
species1$Date.Collected = as.character(species1$Date.Collected)
year = substr(species1$Date.Collected, nchar(species1$Date.Collected)-3, nchar(species1$Date.Collected))

# convert year to stackID (time format used in temperature dataset)
year = as.numeric(year)
stackID = year * 12 - 22793

# final summary with year, stackID, lat/lon, mass
PrelimSummaryTable = cbind(year, stackID, LatLonSpecies1, species1[32])
FinalSummaryTable = cbind(stackID, LatLonSpecies1, masses)
# remove specimens that lack mass
FinalSummaryTable = na.omit(FinalSummaryTable)
# remove specimens with collection date after 2010 because temp data not available
FinalSummaryTable = subset(FinalSummaryTable, FinalSummaryTable$stackID < 1327)

## getting temperature data ----------------------------------------------------
# use University of Delaware temperature dataset

# must install netCDF library on machine to use ncdf
library(raster)

# examples of raster function for July 1900 and July 1901
#temp_stack_1 = raster('air.mon.mean.v301.nc', band=7)
#temp_stack_2 = raster('air.mon.mean.v301.nc', band=19)

# loop to make rasterstack out of July temperatures for all 111 years
# temp_stack = raster('air.mon.mean.v301.nc', band=1)
# for (i in seq(7, 1332, 12)){
#   temp_stack = stack(temp_stack, raster('air.mon.mean.v301.nc', band=i))
# }


# # can't make the following loop because need loop counter to be in numbers
# # loop to make rasterstack out of specimen years (i.e., stackID) using July temps
# stackID = as.vector(stackID)
# select_tempstack = raster('air.mon.mean.v301.nc', band=1)
# for (i in stackID[1:length(stackID)]){
#   select_tempstack = stack(select_tempstack, raster('air.mon.mean.v301.nc', band=i))
# }
# 
# select_tempstack = raster('air.mon.mean.v301.nc', band=1)
# for (current_specimen in SummaryTable$stackID){
#   current_raster = raster('air.mon.mean.v301.nc', band=current_specimen)
#   select_tempstack = stack(select_tempstack, current_raster)
#   #select_tempstack = stack(select_tempstack, raster('air.mon.mean.v301.nc', band=current_specimen))
# }


## need to convert 32767 (missing value) to NA? 

## use temperature data to determine temperatures for lat/lon/date of specimens -----
# code from Dan 4/8/14
library(raster)

# use extract function to get temperature for lat and lon in SummaryTable
# original from Dan: extract(bioStack, cbind(datTemp$Longitude,datTemp$Latitude))
# need to index raster because it's a stack?
# don't have same number of rasterstack and coordinates?
# sapply example: http://stackoverflow.com/questions/14682606/extract-value-from-raster-stack-from-spatialpolygondataframe

# determining temperature for single specimen
#temp = raster('air.mon.mean.v301.nc', band=FinalSummaryTable$stackID[1])
#single_specimen_temp = extract(temp, matrix(coordinates[1, ], ncol=2))


# use loop to determine temperature for all specimens
extracted_temps = NULL
for (i in 1:nrow(FinalSummaryTable)){
  temp = raster('air.mon.mean.v301.nc', band=FinalSummaryTable$stackID[i])
  coordinate = cbind(FinalSummaryTable$lon[i] + 360, FinalSummaryTable$lat[i])
  single_specimen_temp = extract(temp, coordinate)
  extracted_temps = append(extracted_temps, single_specimen_temp)
}


## plot temperature-mass relationship -----------------------------------------
# create matrix with temps and corresponding masses
plot_table = cbind(extracted_temps, FinalSummaryTable$masses)

# plot this
plot(plot_table, xlab = "Temperature (*C)", ylab = "Body Mass (g)")

# plot linear regression of temp and mass
linreg = lm(plot_table[,2] ~ plot_table[,1])
summary(linreg)
abline(linreg)

## NCDF leftovers --------------------------------------------------------------
# raster is easier and more useful than ncdf package

# use ncdf package to read University of Delaware netCDF file in
# can use to convert to ASCII but not recommended because file will be very large
# library(ncdf)
# # TemperatureFile is metadata for netCDF file
# TemperatureFile = open.ncdf('air.mon.mean.v301.nc')
# #ncdump -h air.mon.mean.v301.nc
# print.ncdf(TemperatureFile)
# var1 = get.var.ncdf(TemperatureFile, "lat")
# var2 = get.var.ncdf(TemperatureFile, "lon")
# var3 = get.var.ncdf(TemperatureFile, "time")
# plot(var1,var2[1:360])
# need to unpack data? http://www.esrl.noaa.gov/psd/data/gridded/faq.html#2