// Define global variables
var map;
var currentPos;
var marker;
var JLmapOptions;
var JLMap;
var JLcenter;
var JLmapTypeId;
var windowContent;
var markerArray;
var infowindow;


//makeMap uses json data for hunt to plot locations and show clues in infowindows
function makeMap(thisHuntData, role, prog){
  windowContent = [];
  markerArray = [];

  // Changed maxShowMarker b/c limiting of array now occurs in back end
  var maxShowMarker = thisHuntData.loc.length;
  // var maxShowMarker;
  // function setMaxShowMarker (){
  //   if (role==="hunter"){
  //     maxShowMarker = prog-1;
  //   }
  //   else maxShowMarker = thisHuntData.loc.length;
  // };
  // setMaxShowMarker();

  //BEGIN OF CODE TO PLOT MAP
  JLcenter = new google.maps.LatLng(thisHuntData.loc[0].lat, thisHuntData.loc[0].long);
  var styles =
[
  {
    "featureType": "water",
    "stylers": [
      { "color": "#08519C" }
    ]
  },{
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [
      { "visibility": "on" },
      { "color": "#6BAED6" }
    ]
  },{
    "featureType": "road.arterial",
    "elementType": "labels",
    "stylers": [
      { "gamma": 1.05 },
      { "color": "#922e36" },
      { "visibility": "on" }
    ]
  },{
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#BDD7E7" }
    ]
  },{
    "featureType": "road",
    "elementType": "labels.text",
    "stylers": [
      { "visibility": "on" },
      { "color": "#181616" },
      { "weight": 0.1 }
    ]
  }
];
  JLmapTypeId = google.maps.MapTypeId.ROADMAP
    JLmapOptions = {
      zoom: 15,
      mapTypeId: JLmapTypeId,
      center: JLcenter
    };
  JLMap = new google.maps.Map(document.getElementById('huntMap'), JLmapOptions);
  JLMap.setOptions({styles: styles});



  //END OF CODE TO PLOT MAP
        var treasure = 'map_treasure.png';
         var star = 'star_red_24.png';
         // var marker;
        var selectedMarker;
    for (var i = 0; i < maxShowMarker; i++){
        var marker = new google.maps.Marker({
          position: new google.maps.LatLng(thisHuntData.loc[i].lat,thisHuntData.loc[i].long),
          map: JLMap,
          icon: treasure
        });
        markerArray[i]=marker;
        marker.myIndex = i;

        //fill in content window with hunt details for huntmaster
          var contentString ='<div> Clue number ' + thisHuntData.loc[i].clues[0].id + '</br> Clue: ' + thisHuntData.loc[i].clues[0].question + ' </br> Answer: ' + thisHuntData.loc[i].clues[0].answer + '</div>';

          windowContent[i] = contentString;

            google.maps.event.addListener(marker, 'click', function() {

                  this.setIcon(star);
                  for (var i=0; i<maxShowMarker; i++){
                    if (this != markerArray[i]) {
                        markerArray[i].setIcon(treasure)
                    }
                  }
              // document.getElementById('clickedLocInfo').innerHTML = windowContent[this.myIndex];
              // };
              if(infowindow) {
                  infowindow.close();
              }
              infowindow = new google.maps.InfoWindow({
              content: windowContent[this.myIndex]
              });
            infowindow.open(JLMap,this);
            });


    }
    google.maps.event.addDomListener(window, "resize", function() {
           // var center = JLMap.getCenter();
             google.maps.event.trigger(JLMap, "resize");
             JLMap.setCenter(JLcenter);
             console.log('resized');
            });
};

//function initialize plots map showing current location, and contains functions markCurrentLocation and codeAddress
function initialize() {
 navigator.geolocation.getCurrentPosition(function(position){
    currentPos = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
  var mapOptions = {
    zoom: 16,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  var styles =
[
  {
    "featureType": "water",
    "stylers": [
      { "color": "#08519C" }
    ]
  },{
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [
      { "visibility": "on" },
      { "color": "#6BAED6" }
    ]
  },{
    "featureType": "road.arterial",
    "elementType": "labels",
    "stylers": [
      { "gamma": 1.05 },
      { "color": "#922e36" },
      { "visibility": "on" }
    ]
  },{
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#BDD7E7" }
    ]
  },{
    "featureType": "road",
    "elementType": "labels.text",
    "stylers": [
      { "visibility": "on" },
      { "color": "#181616" },
      { "weight": 0.1 }
    ]
  }
];
  map = new google.maps.Map(document.getElementById('map-foo'), mapOptions);
  map.setCenter(currentPos);
  map.setOptions({styles: styles});
  });

 google.maps.event.addDomListener(currentLocButton, 'click', markCurrentLocation);
 google.maps.event.addDomListener(searchButton, 'click', codeAddress);
 google.maps.event.addDomListener(window, "resize", function() {
           var center = map.getCenter();
             google.maps.event.trigger(map, "resize");
             map.setCenter(center);
           });
var star = 'star_red_24.png';
//adds marker to current location
  function markCurrentLocation () {
    document.getElementById('address').value='';
    navigator.geolocation.getCurrentPosition(function(position){
      currentPos = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      map.setCenter(currentPos);
      document.getElementById('location_lat').value=currentPos.ob;
      document.getElementById('location_long').value=currentPos.pb;
        marker = new google.maps.Marker({
            position: currentPos,
            map: map,
            draggable: true,
            title: 'This is your current location',
            icon: star
        });
      google.maps.event.addDomListener(marker, 'dragend', markerMoved);
    });

  };

//plots map and marker showing user-entered address
  function codeAddress() {
    var coordinates = document.getElementById('coordinates');
    var geocoder = new google.maps.Geocoder();
    var address = document.getElementById('address').value;
    geocoder.geocode( { 'address': address}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        currentPos = results[0].geometry.location;
        map.setCenter(currentPos);
        marker = new google.maps.Marker({
            map: map,
            position: currentPos,
            draggable: true,
            icon: star
        });
        } else {
          alert('Geocode was not successful for the following reason: ' + status);
      }
      // Enter lat and long into new clue marker form
      document.getElementById('location_lat').value=currentPos.ob;
      document.getElementById('location_long').value=currentPos.pb;
      google.maps.event.addDomListener(marker, 'dragend',markerMoved);
    });
  }
//update co-ordinates for new clue marker if marker moved (before saved to db)
  function markerMoved(){
    document.getElementById('location_lat').value=marker.position.ob;
    document.getElementById('location_long').value=marker.position.pb;
  };

}

// google.maps.event.addDomListener(window, 'load', initialize);

