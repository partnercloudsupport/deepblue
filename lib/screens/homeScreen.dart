import 'dart:async';
import 'dart:convert';
import 'package:deepblue/screens/mapScreen.dart';
import 'package:deepblue/screens/locatingScreen.dart';
import 'package:flutter/material.dart';
import 'package:deepblue/models/CardItemModel.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:deepblue/screens/registerLocationScreen.dart';
import 'package:geolocator/geolocator.dart' as gps;
import 'package:flutter_svg/flutter_svg.dart';





class HomeScreen extends StatefulWidget {
  var positionMap = new Map<String,double>();
  
  HomeScreen(this.positionMap);

  @override
  _HomeScreenState createState() => new _HomeScreenState(positionMap);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin{


  var cardIndex = 0;
  ScrollController scrollController;
  var currentColor = Colors.blue[900];
  var cardsList = [/*CardItemModel("Waschbär", Icons.local_car_wash,300, 0.83),
                   CardItemModel("Aral", Icons.local_gas_station,500, 0.24),
                   CardItemModel("Waschbox", Icons.local_car_wash,600, 0.24),
                   CardItemModel("Waschbox", Icons.local_car_wash,700, 0.24),
                   CardItemModel("Waschbox", Icons.local_car_wash,700, 0.24),
                   CardItemModel("Total", Icons.local_gas_station,3000, 0.32)*/];
                  
  var cardColors = [];
  

  AnimationController animationController;
  ColorTween colorTween;
  CurvedAnimation curvedAnimation;
  Future httpReturn;
  int nearLocationsCount = 0;

  bool washboxesLoaded=false;

  bool currentWidget = true;
  Image image1;
  String nearestLocationsJson;
  bool httpRequestExecuted = false;

  var positionMap = new Map<String,double>();
  _HomeScreenState(this.positionMap);

  Timer _reloadTimer;

  String temp ="-";
  String assetName = 'assets/images/Cloud.svg';
  String welcomeText = "-";
  String welcomeTextHeadline = "-";


  @override
  void initState() {
    super.initState();

    scrollController = new ScrollController();    
    setupWeatherContext(positionMap);
    
  }

  @override
  void dispose() {
    super.dispose();
    _reloadTimer.cancel();
  }

  Future setupWeatherContext(var location) async {
    if(httpRequestWeather(location) != "null"){
      var jsonWeather = await httpRequestWeather(location);
      var weather = json.decode(jsonWeather);
      print("jsonWeather $weather");

  
      switch (weather["currently"]["icon"]){

        case "cloudy": 
          assetName = 'assets/images/Cloud.svg';
          welcomeTextHeadline = "Gute Nachrichten";
          welcomeText = "Aktuell sind nur ein paar Wolken am Himmel - gutes Timing um dein Auto zu waschen! Dazu haben wir $nearLocationsCount Waschboxen in deiner Nähe gefunden.";
        
         break;
        
        case "clear-day": 
          assetName = 'assets/images/Sun.svg';
          welcomeTextHeadline = "Perfekt!";
          welcomeText ="Schnapp dir dein Auto - es ist perfektes Wetter um es zu waschen! Dazu haben wir $nearLocationsCount Waschboxen in deiner Nähe gefunden.";
         
         break;

        case "clear-night": 
          assetName = 'assets/images/Moon.svg';
          welcomeTextHeadline = "Perfekt!";
          welcomeText ="Wenn es dir nicht zu spät ist, ist das die perfekte Nacht um dein Auto zu waschen! Dazu haben wir $nearLocationsCount Waschboxen in deiner Nähe gefunden.";
         
         break;

        case "rain": 
          assetName = 'assets/images/Cloud-Rain.svg';
          welcomeTextHeadline = "Lieber abwarten!";
          welcomeText ="Aktuell sieht es am Himmel sehr nach Regen aus, warte lieber noch etwas ab! Warte lieber noch bis das Wetter wieder besser wird.";

         break;

        case "snow": 
          assetName = 'assets/images/Cloud-Snow.svg';
          welcomeTextHeadline = "Das wird kalt!";
          welcomeText ="Aktuell sieht es nach Schnee aus, das ist kein gutes Wetter um dein Auto zu waschen. Warte lieber noch bis das Wetter wieder besser wird.";
         
         break;

        case "wind": 
          assetName = 'assets/images/Wind.svg';
          welcomeTextHeadline = "Achtung Windig!";
          welcomeText ="Aktuell ist es etwas windig draußen, aber das ist für dich natürlich kein Grund dein Auto nicht zu waschen! Dazu haben wir $nearLocationsCount Waschboxen in deiner Nähe gefunden.";
          
         
         break;
        
        case "partly-cloudy-day": 
          assetName = 'assets/images/Cloud.svg';
          welcomeTextHeadline = "Gute Nachrichten";
          welcomeText ="Schnapp dir dein Auto - es sind nur wenige Wolken am Himmel! Dazu haben wir $nearLocationsCount Waschboxen in deiner Nähe gefunden.";
         
         break;
        
        case "partly-cloudy-night": 
          assetName = 'assets/images/Cloud-Moon.svg';
          welcomeTextHeadline = "Gute Nachrichten";
          welcomeText ="Schnapp dir dein Auto - es sind nur wenige Wolken am Himmel! Dazu haben wir $nearLocationsCount Waschboxen in deiner Nähe gefunden.";
         
         break;

      }

      if(weather["currently"]["temperature"] < 6){
        welcomeTextHeadline= "Das wird kalt!";
        welcomeText = "Aktuell ist es draußen ziemlich kalt, kein gutes Wetter um dein Auto zu waschen. Warte lieber noch bis das Wetter wieder besser wird.";
      }

      if(nearLocationsCount < 1){
        welcomeTextHeadline= "Sorry!";
        welcomeText = "Leider haben wir keine Waschboxen in deiner Nähe gefunden. Wechsel in die Karte um alle Waschboxen zu sehen oder neue hinzuzufügen";
      }
        


      setState(() {
              temp = weather["currently"]["temperature"].toStringAsFixed(0);
            });

    }
  }

  Future<String> httpRequestWeather(var location)async {
    var darkSkyUrl="https://api.darksky.net/forecast/97ada79b0fdc34e056d1cdd1f41c6ddf/"
                   "${location['latitude']},${location['longitude']}"
                   "?units=auto";

    final res = await http.read(darkSkyUrl);
    return res;
  }

  void httpRequestLocations(var location)async {
    print("httploc ${location}");

    var url = "http://www.nell.science/deepblue/index.php";

    http.post(url, body: {"getWashboxesHomescreen":"true","key": "0", "latitude": location['latitude'].toString(), "longitude": location['longitude'].toString(), "limit":"5"})
        .then((response) {
      print("Response status: ${response.statusCode}");   
      print("Response body: ${response.body}");

      if (this.mounted){
        if(response.body != "null"){

          var nearestLocation;
          var nearestLocationsJson = "";
          var distanceIndicator;
          var biggestDistance;

          nearestLocationsJson = response.body.toString();
          nearestLocation=json.decode(nearestLocationsJson);
          nearLocationsCount=json.decode(nearestLocationsJson).length;
          biggestDistance=nearestLocation[nearLocationsCount-1]["distanceValue"];

          print("biggestDistance$biggestDistance");

          setState((){
                  for(int i=0;i<nearestLocation.length;i++){
                    distanceIndicator=(nearestLocation[i]["distanceValue"]/biggestDistance);
                    cardsList.add(CardItemModel(nearestLocation[i]["name"], Icons.local_car_wash, nearestLocation[i]["distanceText"], distanceIndicator));
                  }
                  washboxesLoaded=true;
              });
        }else{
          print("reload 3000ms");
          _reloadTimer = new Timer(const Duration(milliseconds: 3000), () {
            httpRequestLocations(location);
          });  
        }
       
      }

    });
    
  }

 



  @override
  Widget build(BuildContext context) {
    //print("location${widget._currentLocation}");
    if(!httpRequestExecuted){
      httpRequestLocations(positionMap);
      httpRequestExecuted=true;
    }

    

    
    
    return new Scaffold(
      backgroundColor: currentColor,
      appBar: new AppBar(
        title: new Text("DeepBlue", style: TextStyle(fontSize: 16.0),),
        backgroundColor: currentColor,
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.map),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => mapScreen(positionMap)),
            );
          },
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: new IconButton(
              icon: new Icon(Icons.refresh),
              onPressed: () {
                
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LocatingScreen()),
                );
              },
            )
          ),
        ],
        elevation: 0.0,
      ),


      body: new Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(48.0, 32.0, 48.0, 32.0),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[

                          Container(
                            width: 60.0,
                            height: 60.0,
                            child: SvgPicture.asset(
                                      assetName,
                                      color: Colors.white,
                                    ),
                          ),


                          Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget> [
                                Text(temp, style: TextStyle(fontSize: 38.0, color: Colors.white, fontWeight: FontWeight.w400),),
                                Text(" °C", style: TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.w400,)),
                              ]
                            ),
                          ),

                          

                        ]
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0,16.0,0.0,12.0),
                      child: Text(welcomeTextHeadline, style: TextStyle(fontSize: 28.0, color: Colors.white, fontWeight: FontWeight.w400),),
                    ),
                    Text(welcomeText, style: TextStyle(color: Colors.white),),
                    Text("", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

            Offstage(
              offstage: washboxesLoaded,
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    child: new CircularProgressIndicator(backgroundColor: Colors.white,valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),),
                    height: 68.0,
                    width: 68.0
                  ),                    
                ],
              ),
            ),

            /*
            new ConstrainedBox(
            constraints: new BoxConstraints(
              minWidth: double.infinity,
              maxWidth: double.infinity,
              minHeight: 300.0,
              maxHeight: 500.0,
            ),
            */
            Expanded(
              child:  Offstage(
                offstage: (!washboxesLoaded),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child:
                        ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: cardsList.length,
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, position) {
                          return GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                child: Container(
                                  width: 250.0,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Icon(cardsList[position].icon, color: Colors.blue[900],),
                                            Icon(Icons.more_vert, color: Colors.grey,),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                              child: Text("${cardsList[position].distance}", style: TextStyle(color: Colors.grey),),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                              child: Text("${cardsList[position].cardTitle}", style: TextStyle(fontSize: 28.0),),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: LinearProgressIndicator(value: cardsList[position].taskCompletion,),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                              ),
                            ),
                            onHorizontalDragEnd: (details) {
                              
                              
                              animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
                              curvedAnimation = CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn);
                              animationController.addListener(() {
                                setState(() {
                                  //currentColor = colorTween.evaluate(curvedAnimation);
                                });
                              });

                              
                              if(details.velocity.pixelsPerSecond.dx > 0) {
                                if(cardIndex>0) {
                                  cardIndex--;
                                }
                              }else {
                                if(cardIndex<(cardsList.length-1)) {
                                  cardIndex++;
                                }
                              }
                              setState(() {
                                scrollController.animateTo((cardIndex)*256.0, duration: Duration(milliseconds: 200), curve: Curves.fastOutSlowIn);
                              });

                              //colorTween.animate(curvedAnimation);
                              
                              animationController.forward( );

                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
              ),
            ),

          ],
        ),
      ),
      //drawer: Drawer(),
    );

    
  }
}

 
