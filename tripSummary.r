## tripSummary   #####################################################################################################################

## MAIN UPDATE: tidyverse, simple features


## STEFFEN OPPEL, 2011

## this script provides a simple summary for the foraging trips of central place foraging animals
## direction can be provided from individual nests if desired (nests=TRUE), default is for colony (mean lat and long across all nests if specified)
## output is a table that provides trip length, distance, and direction for each trip


## Trips must be a SpatialPointsDataFrame generated by the tripSplit function
## Colony must be a DataFrame with Latitudes and Longitudes
#### IF nests=TRUE, Colony must be a DataFrame with ID (the same ID as in Trips), Latitudes and Longitudes
### modified 27 December 2016 to make function more robust to different data frame structure
### updated 9 January 2017 to allow non-numeric trip ID


require(geosphere)
require(tidyverse)
require(lubridate)
                                         
tripSummary <- function(Trips, Colony=Colony, nests=FALSE)
  {

  if(!"Latitude" %in% names(Colony)) stop("Colony missing Latitude field")
  if(!"Longitude" %in% names(Colony)) stop("Colony missing Longitude field")



### SUMMARISE MAX DIST FROM COLONY AND TRIP TRAVELLING TIME FOR EACH TRIP
  
  
  trip_distances <- data.frame(trip=unique(Trips@data$trip_id), max_dist=0, duration=0, total_dist=0) %>%
    filter(trip!=-1) %>%   ### this removes the non-trip locations
    mutate(ID=Trips@data$ID[match(trip, Trips@data$trip_id)])


for (i in unique(trip_distances$trip)){			### removed as.numeric as this only works with numeric ID
x<-Trips@data[Trips@data$trip_id==i,]
maxdist<-cbind(x$Longitude[x$ColDist==max(x$ColDist)],x$Latitude[x$ColDist==max(x$ColDist)])	
if(dim(maxdist)[1]>1){maxdist<-maxdist[1,]}
trip_distances[trip_distances$trip==i,2]<-max(Trips@data$ColDist[Trips@data$trip_id==i])/1000
trip_distances[trip_distances$trip==i,3]<-(max(Trips@data$TrackTime[Trips@data$trip_id==i])-min(Trips@data$TrackTime[Trips@data$trip_id==i]))/3600


## Calculate distances from one point to the next and total trip distance
x$Dist[1]<-x$ColDist[1]/1000				### distance to first point is assumed a straight line from the nest/colony
for (p in 2:dim(x)[1]){
p1<-c(x$Longitude[p-1],x$Latitude[p-1])
p2<-c(x$Longitude[p],x$Latitude[p])
#x$Dist[p]<-pointDistance(p1,p2, lonlat=T, allpairs=FALSE)/1000			### no longer works in geosphere
x$Dist[p]<-distMeeus(p1,p2)/1000						### great circle distance according to Meeus, converted to km

}
trip_distances[trip_distances$trip==i,4]<-sum(x$Dist)+(x$ColDist[p]/1000)				## total trip distance is the sum of all steps plus the dist from the nest of the last location


trip_distances$departure[trip_distances$trip==i]<-format(min(x$DateTime),format="%Y-%m-%d %H:%M:%S") 	## departure time of trip
trip_distances$return[trip_distances$trip==i]<-format(max(x$DateTime),format="%Y-%m-%d %H:%M:%S")		## return time of trip
trip_distances$n_locs[trip_distances$trip==i]<-dim(x)[1]		## number of locations per trip


if(nests == TRUE) {
origin<- Colony[match(unique(x$ID), Colony$ID),]}

origin<-data.frame(mean(Colony$Longitude), mean(Colony$Latitude)) # CHANGED BY MARIA 8DEC14: was "mean(origin$Latitude)"
trip_distances$bearing[trip_distances$trip==i]<-bearing(origin,maxdist)			## great circle route bearing of trip
trip_distances$bearingRhumb[trip_distances$trip==i]<-bearingRhumb(origin,maxdist) 	## constant compass bearing of trip

}

trip_distances<-trip_distances[,c(5,1,6,7,3,2,4,8,9,10)]
return(trip_distances)
}