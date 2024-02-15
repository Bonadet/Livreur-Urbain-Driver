import 'dart:math';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/pages/login/landingpage.dart';
import 'package:flutter_driver/pages/login/login.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:io';
import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../functions/notifications.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/notification.dart';
import '../chatPage/chat_page.dart';
import '../loadingPage/loading.dart';
import '../navDrawer/nav_drawer.dart';
import '../noInternet/nointernet.dart';
import '../vehicleInformations/docs_onprocess.dart';
import 'digitalsignature.dart';
import 'invoice.dart';
import 'rides.dart';

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  State<Maps> createState() => _MapsState();
}

dynamic _center = const LatLng(41.4219057, -102.0840772);
dynamic center;
bool locationAllowed = false;

List<Marker> myMarkers = [];
Set<Circle> circles = {};
bool polylineGot = false;

dynamic _timer;
String cancelReasonText = '';
bool notifyCompleted = false;
bool logout = false;
bool deleteAccount = false;
bool getStartOtp = false;
dynamic shipLoadImage;
dynamic shipUnloadImage;
bool unloadImage = false;
String driverOtp = '';
bool serviceEnabled = false;
bool show = true;

int filtericon = 0;
dynamic isAvailable;
List vechiletypeslist = [];

class _MapsState extends State<Maps>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List driverData = [];

  bool sosLoaded = false;
  bool cancelRequest = false;
  bool _pickAnimateDone = false;

  late geolocator.LocationPermission permission;
  Location location = Location();
  String state = '';
  dynamic _controller;
  Animation<double>? _animation;
  dynamic animationController;
  String _cancellingError = '';
  double mapPadding = 0.0;
  var iconDropKeys = {};
  String _cancelReason = '';
  bool _locationDenied = false;
  int gettingPerm = 0;
  bool _errorOtp = false;
  String beforeImageUploadError = '';
  String afterImageUploadError = '';
  dynamic loc;
  String _otp1 = '';
  String _otp2 = '';
  String _otp3 = '';
  String _otp4 = '';
  bool showSos = false;
  bool _showWaitingInfo = false;
  bool _isLoading = false;
  bool _reqCancelled = false;
  bool navigated = false;
  dynamic pinLocationIcon;
  dynamic pinLocationIcon2;
  dynamic pinLocationIcon3;
  dynamic userLocationIcon;
  bool makeOnline = false;
  bool contactus = false;
  GlobalKey iconKey = GlobalKey();
  GlobalKey iconDropKey = GlobalKey();
  List gesture = [];
  dynamic start;
  dynamic onrideicon;
  dynamic onridedeliveryicon;
  dynamic offlineicon;
  dynamic offlinedeliveryicon;
  dynamic onlineicon;
  dynamic onlinedeliveryicon;
  dynamic onridebikeicon;
  dynamic offlinebikeicon;
  dynamic onlinebikeicon;
  bool navigationtype = false;

  bool currentpage = true;
  bool _tripOpenMap = false;
  bool _isDarkTheme = false;

  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;
  TextEditingController bidText = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    myMarkers = [];
    show = true;
    navigated = false;
    filtericon = 0;
    polylineGot = false;
    currentpage = true;
    _isDarkTheme = isDarkTheme;
    getadminCurrentMessages();
    getLocs();
    getonlineoffline();
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
    if ((choosenRide.isNotEmpty || driverReq.isNotEmpty) &&
        _pickAnimateDone == false) {
      _pickAnimateDone = true;
      // Future.delayed(const Duration(milliseconds: 100), () {
      _pickAnimateDone = true;
      addMarkers();
      // });
    }
  }

  getonlineoffline() async {
    if (userDetails['role'] == 'driver' &&
        userDetails['owner_id'] != null &&
        userDetails['vehicle_type_id'] == null &&
        userDetails['active'] == true) {
      var val = await driverStatus();
      if (val == 'logout') {
        navigateLogout();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller!.setMapStyle(mapStyle);
        valueNotifierHome.incrementNotifier();
      }

      isBackground = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      isBackground = true;
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
    }
    _controller?.dispose();
    _controller = null;
    animationController?.dispose();

    super.dispose();
  }

  //navigate
  navigate() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const DigitalSignature()));
  }

  navigateLogout() {
    if (ownermodule == '1') {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (route) => false);
      });
    } else {
      ischeckownerordriver = 'driver';
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false);
      });
    }
  }

  reqCancel() {
    _reqCancelled = true;

    Future.delayed(const Duration(seconds: 2), () {
      _reqCancelled = false;
      userReject = false;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  capturePng(GlobalKey iconKeys) async {
    dynamic bitmap;

    try {
      RenderRepaintBoundary boundary =
          iconKeys.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      bitmap = BitmapDescriptor.fromBytes(pngBytes);
      // return pngBytes;
      return bitmap;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  addMarkers() {
    Future.delayed(const Duration(milliseconds: 200), () {
      addPickDropMarker();
    });
  }

  addDropMarker() async {
    if (tripStops.isNotEmpty) {
      for (var i = 0; i < tripStops.length; i++) {
        var testIcon = await capturePng(iconDropKeys[i]);
        // ignore: unnecessary_null_comparison
        if (testIcon != null) {
          myMarkers.add(Marker(
              markerId: MarkerId((i + 3).toString()),
              icon: testIcon,
              position:
                  LatLng(tripStops[i]['latitude'], tripStops[i]['longitude'])));
        }
      }
      setState(() {});
    } else if (choosenRide.isNotEmpty) {
      var testIcon = await capturePng(iconDropKey);
      if (testIcon != null) {
        setState(() {
          myMarkers.add(Marker(
              markerId: const MarkerId('3'),
              icon: testIcon,
              position: LatLng(
                  choosenRide[0]['drop_lat'], choosenRide[0]['drop_lng'])));
        });
      }
    } else {
      var testIcon = await capturePng(iconDropKey);
      if (testIcon != null) {
        setState(() {
          myMarkers.add(Marker(
              markerId: const MarkerId('3'),
              icon: testIcon,
              position: LatLng(driverReq['drop_lat'], driverReq['drop_lng'])));
        });
      }
    }
    // setState((){});
    LatLngBounds bound;
    if (driverReq.isNotEmpty) {
      if (driverReq['pick_lat'] > driverReq['drop_lat'] &&
          driverReq['pick_lng'] > driverReq['drop_lng']) {
        bound = LatLngBounds(
            southwest: LatLng(driverReq['drop_lat'], driverReq['drop_lng']),
            northeast: LatLng(driverReq['pick_lat'], driverReq['pick_lng']));
      } else if (driverReq['pick_lng'] > driverReq['drop_lng']) {
        bound = LatLngBounds(
            southwest: LatLng(driverReq['pick_lat'], driverReq['drop_lng']),
            northeast: LatLng(driverReq['drop_lat'], driverReq['pick_lng']));
      } else if (driverReq['pick_lat'] > driverReq['drop_lat']) {
        bound = LatLngBounds(
            southwest: LatLng(driverReq['drop_lat'], driverReq['pick_lng']),
            northeast: LatLng(driverReq['pick_lat'], driverReq['drop_lng']));
      } else {
        bound = LatLngBounds(
            southwest: LatLng(driverReq['pick_lat'], driverReq['pick_lng']),
            northeast: LatLng(driverReq['drop_lat'], driverReq['drop_lng']));
      }
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bound, 100);
      _controller?.animateCamera(cameraUpdate);
    } else {
      if (choosenRide[0]['pick_lat'] > choosenRide[0]['drop_lat'] &&
          choosenRide[0]['pick_lng'] > choosenRide[0]['drop_lng']) {
        bound = LatLngBounds(
            southwest:
                LatLng(choosenRide[0]['drop_lat'], choosenRide[0]['drop_lng']),
            northeast:
                LatLng(choosenRide[0]['pick_lat'], choosenRide[0]['pick_lng']));
      } else if (choosenRide[0]['pick_lng'] > choosenRide[0]['drop_lng']) {
        bound = LatLngBounds(
            southwest:
                LatLng(choosenRide[0]['pick_lat'], choosenRide[0]['drop_lng']),
            northeast:
                LatLng(choosenRide[0]['drop_lat'], choosenRide[0]['pick_lng']));
      } else if (choosenRide[0]['pick_lat'] > choosenRide[0]['drop_lat']) {
        bound = LatLngBounds(
            southwest:
                LatLng(choosenRide[0]['drop_lat'], choosenRide[0]['pick_lng']),
            northeast:
                LatLng(choosenRide[0]['pick_lat'], choosenRide[0]['drop_lng']));
      } else {
        bound = LatLngBounds(
            southwest:
                LatLng(choosenRide[0]['pick_lat'], choosenRide[0]['pick_lng']),
            northeast:
                LatLng(choosenRide[0]['drop_lat'], choosenRide[0]['drop_lng']));
      }

      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bound, 100);
      _controller?.animateCamera(cameraUpdate);
    }
  }

  addMarker() async {
    polyline.clear();
    if (choosenRide.isNotEmpty || driverReq.isNotEmpty) {
      var testIcon = await capturePng(iconKey);
      if (testIcon != null) {
        setState(() {
          myMarkers.add(Marker(
              markerId: const MarkerId('2'),
              icon: testIcon,
              position: (driverReq.isNotEmpty)
                  ? LatLng(driverReq['pick_lat'], driverReq['pick_lng'])
                  : LatLng(
                      choosenRide[0]['pick_lat'], choosenRide[0]['pick_lng'])));
        });
      }
    }
  }

  addPickDropMarker() async {
    addMarker();
    if (driverReq['drop_address'] != null || choosenRide.isNotEmpty) {
      getPolylines();
      polyline.add(
        Polyline(
            polylineId: const PolylineId('1'),
            color: buttonColor,
            points: (driverReq.isNotEmpty)
                ? [
                    LatLng(double.parse(driverReq['pick_lat'].toString()),
                        double.parse(driverReq['pick_lng'].toString())),
                    LatLng(double.parse(driverReq['pick_lat'].toString()),
                        double.parse(driverReq['pick_lng'].toString()))
                  ]
                : [
                    LatLng(double.parse(choosenRide[0]['pick_lat'].toString()),
                        double.parse(choosenRide[0]['pick_lng'].toString())),
                    LatLng(double.parse(choosenRide[0]['pick_lat'].toString()),
                        double.parse(choosenRide[0]['pick_lng'].toString()))
                  ],
            geodesic: false,
            width: 5),
      );
      addDropMarker();
    }
  }

//getting permission and current location
  getLocs() async {
    unloadImage = false;
    afterImageUploadError = '';
    beforeImageUploadError = '';
    shipLoadImage = null;
    shipUnloadImage = null;
    permission = await geolocator.GeolocatorPlatform.instance.checkPermission();
    serviceEnabled =
        await geolocator.GeolocatorPlatform.instance.isLocationServiceEnabled();

    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;

      if (gettingPerm > 1) {
        locationAllowed = false;
        if (userDetails['active'] == true) {
          var val = await driverStatus();
          if (val == 'logout') {
            navigateLogout();
          }
        }
        state = '3';
      } else {
        state = '2';
      }
      setState(() {
        _isLoading = false;
      });
    } else if (permission == geolocator.LocationPermission.whileInUse ||
        permission == geolocator.LocationPermission.always) {
      if (serviceEnabled == true) {
        final Uint8List markerIcon;
        final Uint8List markerIcon2;
        final Uint8List markerIcon3;
        final Uint8List onrideicon1;
        final Uint8List onridedeliveryicon1;
        final Uint8List offlineicon1;
        final Uint8List offlinedeliveryicon1;
        final Uint8List onlineicon1;
        final Uint8List onlinedeliveryicon1;
        final Uint8List onlinebikeicon1;
        final Uint8List offlinebikeicon1;
        final Uint8List onridebikeicon1;
        // if(userDetails['transport_type'] == 'taxi'){
        markerIcon = await getBytesFromAsset('assets/images/top-taxi.png', 40);
        markerIcon2 = await getBytesFromAsset('assets/images/bike.png', 40);
        markerIcon3 =
            await getBytesFromAsset('assets/images/vehicle-marker.png', 40);
        if (userDetails['role'] == 'owner') {
          onlinebikeicon1 =
              await getBytesFromAsset('assets/images/bike_online.png', 40);
          onridebikeicon1 =
              await getBytesFromAsset('assets/images/bike_onride.png', 40);
          offlinebikeicon1 =
              await getBytesFromAsset('assets/images/bike.png', 40);
          onrideicon1 =
              await getBytesFromAsset('assets/images/onboardicon.png', 40);
          offlineicon1 =
              await getBytesFromAsset('assets/images/offlineicon.png', 40);
          onlineicon1 =
              await getBytesFromAsset('assets/images/onlineicon.png', 40);
          onridedeliveryicon1 = await getBytesFromAsset(
              'assets/images/onboardicon_delivery.png', 40);
          offlinedeliveryicon1 = await getBytesFromAsset(
              'assets/images/offlineicon_delivery.png', 40);
          onlinedeliveryicon1 = await getBytesFromAsset(
              'assets/images/onlineicon_delivery.png', 40);
          onrideicon = BitmapDescriptor.fromBytes(onrideicon1);
          offlineicon = BitmapDescriptor.fromBytes(offlineicon1);
          onlineicon = BitmapDescriptor.fromBytes(onlineicon1);
          onridedeliveryicon = BitmapDescriptor.fromBytes(onridedeliveryicon1);
          offlinedeliveryicon =
              BitmapDescriptor.fromBytes(offlinedeliveryicon1);
          onlinedeliveryicon = BitmapDescriptor.fromBytes(onlinedeliveryicon1);
          onridebikeicon = BitmapDescriptor.fromBytes(onridebikeicon1);
          offlinebikeicon = BitmapDescriptor.fromBytes(offlinebikeicon1);
          onlinebikeicon = BitmapDescriptor.fromBytes(onlinebikeicon1);
        }

        if (center == null) {
          var locs = await geolocator.Geolocator.getLastKnownPosition();
          if (locs != null) {
            center = LatLng(locs.latitude, locs.longitude);
            heading = locs.heading;
          } else {
            loc = await geolocator.Geolocator.getCurrentPosition(
                desiredAccuracy: geolocator.LocationAccuracy.low);
            center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            heading = loc.heading;
          }
          if (driverReq.isEmpty && choosenRide.isEmpty) {
            _controller
                ?.animateCamera(CameraUpdate.newLatLngZoom(center, 14.0));
          }
        }
        if (mounted) {
          setState(() {
            pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
            pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);
            pinLocationIcon3 = BitmapDescriptor.fromBytes(markerIcon3);

            if (myMarkers.isEmpty && userDetails['role'] != 'owner') {
              myMarkers = [
                Marker(
                    markerId: const MarkerId('1'),
                    rotation: heading,
                    position: center,
                    icon: (userDetails['vehicle_type_icon_for'] == 'motor_bike')
                        ? pinLocationIcon2
                        : (userDetails['vehicle_type_icon_for'] == 'taxi')
                            ? pinLocationIcon
                            : pinLocationIcon3,
                    anchor: const Offset(0.5, 0.5))
              ];
            }
          });
        }
      }

      if (makeOnline == true && userDetails['active'] == false) {
        var val = await driverStatus();
        if (val == 'logout') {
          navigateLogout();
        }
      }
      makeOnline = false;
      if (mounted) {
        setState(() {
          locationAllowed = true;
          state = '3';
          _isLoading = false;
        });
      }
      if (choosenRide.isNotEmpty || driverReq.isNotEmpty) {}
    }
  }

  getLocationService() async {
    // await location.requestService();
    await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.low);
    getLocs();
  }

  getLocationPermission() async {
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      if (permission != geolocator.LocationPermission.deniedForever) {
        if (platform == TargetPlatform.android) {
          await perm.Permission.location.request();
          await perm.Permission.locationAlways.request();
        } else {
          await [perm.Permission.location].request();
        }
        if (serviceEnabled == false) {
          // await location.requestService();
          await geolocator.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocator.LocationAccuracy.low);
        }
      }
    } else if (serviceEnabled == false) {
      // await location.requestService();
      await geolocator.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocator.LocationAccuracy.low);
    }
    setState(() {
      _isLoading = true;
    });
    getLocs();
  }

  int _bottom = 0;
  String _permission = '';

  GeoHasher geo = GeoHasher();

  @override
  Widget build(BuildContext context) {
    //get camera permission
    getCameraPermission() async {
      var status = await perm.Permission.camera.status;
      if (status != perm.PermissionStatus.granted) {
        status = await perm.Permission.camera.request();
      }
      return status;
    }

    ImagePicker picker = ImagePicker();
    //pick image from camera
    pickImageFromCamera(id) async {
      var permission = await getCameraPermission();
      if (permission == perm.PermissionStatus.granted) {
        final pickedFile = await picker.pickImage(
            source: ImageSource.camera, imageQuality: 50);
        if (pickedFile != null) {
          setState(() {
            if (id == 1) {
              shipLoadImage = pickedFile.path;
            } else {
              shipUnloadImage = pickedFile.path;
            }
            // _pickImage = false;
          });
        }
      } else {
        setState(() {
          _permission = 'noCamera';
        });
      }
    }

    var media = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didpop) {
        if (logout == false && choosenRide.isEmpty) {
          if (platform == TargetPlatform.android) {
            platforms.invokeMethod('pipmode');
          }
        }
      },
      // onWillPop: () async {
      //   else {
      //     Navigator.pop(context);
      //     return true;
      //   }
      // },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              if (_isDarkTheme != isDarkTheme && _controller != null) {
                _controller!.setMapStyle(mapStyle);
                _isDarkTheme = isDarkTheme;
              }
              if (navigated == false) {
                if (driverReq.isEmpty &&
                    choosenRide.isEmpty &&
                    userDetails.isNotEmpty &&
                    userDetails['role'] != 'owner') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RidePage()),
                        (route) => false);
                  });
                }
                if (isGeneral == true) {
                  isGeneral = false;
                  if (lastNotification != latestNotification) {
                    lastNotification = latestNotification;
                    pref.setString('lastNotification', latestNotification);
                    latestNotification = '';
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotificationPage()));
                    });
                  }
                }
                if (((choosenRide.isNotEmpty && _pickAnimateDone == false) ||
                        (driverReq.isNotEmpty && _pickAnimateDone == false)) &&
                    _controller != null) {
                  // Future.delayed(const Duration(milliseconds: 100), () {
                  _pickAnimateDone = true;
                  if (mounted) {
                    addMarkers();
                  }
                  // addPickDropMarker();
                  // addMarker();
                  // });
                }
                if (myMarkers
                    .where((element) => element.markerId == const MarkerId('1'))
                    .isNotEmpty) {
                  if (userDetails['vehicle_type_icon_for'] != 'motor_bike' &&
                      myMarkers
                              .firstWhere((element) =>
                                  element.markerId == const MarkerId('1'))
                              .icon ==
                          pinLocationIcon2) {
                    myMarkers.removeWhere(
                        (element) => element.markerId == const MarkerId('1'));
                  } else if (userDetails['vehicle_type_icon_for'] != 'taxi' &&
                      myMarkers
                              .firstWhere((element) =>
                                  element.markerId == const MarkerId('1'))
                              .icon ==
                          pinLocationIcon) {
                    myMarkers.removeWhere(
                        (element) => element.markerId == const MarkerId('1'));
                  } else if (userDetails['vehicle_type_icon_for'] != 'truck' &&
                      myMarkers
                              .firstWhere((element) =>
                                  element.markerId == const MarkerId('1'))
                              .icon ==
                          pinLocationIcon3) {
                    myMarkers.removeWhere(
                        (element) => element.markerId == const MarkerId('1'));
                  }
                }
                if (myMarkers
                        .where((element) =>
                            element.markerId == const MarkerId('1'))
                        .isNotEmpty &&
                    pinLocationIcon != null &&
                    _controller != null &&
                    center != null) {
                  var dist = calculateDistance(
                      myMarkers
                          .firstWhere((element) =>
                              element.markerId == const MarkerId('1'))
                          .position
                          .latitude,
                      myMarkers
                          .firstWhere((element) =>
                              element.markerId == const MarkerId('1'))
                          .position
                          .longitude,
                      center.latitude,
                      center.longitude);
                  if (dist > 100 &&
                      animationController == null &&
                      _controller != null) {
                    animationController = AnimationController(
                      duration: const Duration(
                          milliseconds: 1500), //Animation duration of marker

                      vsync: this, //From the widget
                    );
                    animateCar(
                        myMarkers
                            .firstWhere((element) =>
                                element.markerId == const MarkerId('1'))
                            .position
                            .latitude,
                        myMarkers
                            .firstWhere((element) =>
                                element.markerId == const MarkerId('1'))
                            .position
                            .longitude,
                        center.latitude,
                        center.longitude,
                        _mapMarkerSink,
                        this,
                        _controller,
                        '1',
                        (userDetails['vehicle_type_icon_for'] == 'motor_bike')
                            ? pinLocationIcon2
                            : (userDetails['vehicle_type_icon_for'] == 'taxi')
                                ? pinLocationIcon
                                : pinLocationIcon3,
                        '',
                        '');
                  }
                } else if (myMarkers
                        .where((element) =>
                            element.markerId == const MarkerId('1'))
                        .isEmpty &&
                    pinLocationIcon != null &&
                    center != null &&
                    userDetails['role'] != 'owner') {
                  myMarkers.add(Marker(
                      markerId: const MarkerId('1'),
                      rotation: heading,
                      position: center,
                      icon:
                          (userDetails['vehicle_type_icon_for'] == 'motor_bike')
                              ? pinLocationIcon2
                              : (userDetails['vehicle_type_icon_for'] == 'taxi')
                                  ? pinLocationIcon
                                  : pinLocationIcon3,
                      anchor: const Offset(0.5, 0.5)));
                }
                if (driverReq.isNotEmpty) {
                  if (_controller != null) {
                    mapPadding = media.width * 1;
                  }
                  if (driverReq['is_completed'] == 1 &&
                      driverReq['requestBill'] != null &&
                      currentpage == true) {
                    navigated = true;
                    currentpage = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Invoice()),
                          (route) => false);
                    });
                    _pickAnimateDone = false;
                    myMarkers.removeWhere(
                        (element) => element.markerId != const MarkerId('1'));
                    polyline.clear();
                    polylineGot = false;
                  }
                } else if (choosenRide.isEmpty && driverReq.isEmpty) {
                  mapPadding = 0;
                  if (myMarkers
                          .where((element) =>
                              element.markerId != const MarkerId('1'))
                          .isNotEmpty &&
                      userDetails['role'] != 'owner') {
                    myMarkers.removeWhere(
                        (element) => element.markerId != const MarkerId('1'));
                    polyline.clear();

                    if (userReject == true) {
                      reqCancel();
                    }
                    _pickAnimateDone = false;
                  }
                }
              }

              if (userDetails['approve'] == false && driverReq.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DocsProcess()),
                      (route) => false);
                });
              }
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  drawer: const NavDrawer(),
                  body: StreamBuilder(
                      stream: userDetails['role'] == 'owner'
                          ? FirebaseDatabase.instance
                              .ref('drivers')
                              .orderByChild('ownerid')
                              .equalTo(userDetails['id'].toString())
                              .onValue
                          : null,
                      builder: (context, AsyncSnapshot<DatabaseEvent> event) {
                        if (event.hasData) {
                          driverData.clear();
                          for (var element in event.data!.snapshot.children) {
                            driverData.add(element.value);
                          }

                          for (var element in driverData) {
                            if (element['l'] != null &&
                                element['is_deleted'] != 1) {
                              if (userDetails['role'] == 'owner') {
                                if (userDetails['role'] == 'owner' &&
                                    offlineicon != null &&
                                    onlineicon != null &&
                                    onrideicon != null &&
                                    offlinebikeicon != null &&
                                    onlinebikeicon != null &&
                                    onridebikeicon != null &&
                                    filtericon == 0) {
                                  if (myMarkers
                                      .where((e) => e.markerId
                                          .toString()
                                          .contains('car${element['id']}'))
                                      .isEmpty) {
                                    myMarkers.add(Marker(
                                      markerId: MarkerId('car${element['id']}'),
                                      rotation: double.parse(
                                          element['bearing'].toString()),
                                      position: LatLng(
                                          element['l'][0], element['l'][1]),
                                      infoWindow: InfoWindow(
                                          title: element['vehicle_number'],
                                          snippet: element['name']),
                                      anchor: const Offset(0.5, 0.5),
                                      icon: (element['is_active'] == 0)
                                          ? (element['vehicle_type_icon'] ==
                                                  'motor_bike')
                                              ? offlinebikeicon
                                              : (element['vehicle_type_icon'] ==
                                                      'taxi')
                                                  ? offlineicon
                                                  : offlinedeliveryicon
                                          : (element['is_available'] == true &&
                                                  element['is_active'] == 1)
                                              ? (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onlinebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onlineicon
                                                      : onlinedeliveryicon
                                              : (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onridebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onrideicon
                                                      : onridedeliveryicon,
                                    ));
                                  } else if ((element['is_active'] != 0 && myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon == offlineicon) ||
                                      (element['is_active'] != 0 &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon ==
                                              offlinebikeicon) ||
                                      (element['is_active'] != 0 &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon ==
                                              offlinedeliveryicon)) {
                                    myMarkers.removeWhere((e) => e.markerId
                                        .toString()
                                        .contains('car${element['id']}'));
                                    myMarkers.add(Marker(
                                      markerId: MarkerId('car${element['id']}'),
                                      rotation: double.parse(
                                          element['bearing'].toString()),
                                      position: LatLng(
                                          element['l'][0], element['l'][1]),
                                      infoWindow: InfoWindow(
                                          title: element['vehicle_number'],
                                          snippet: element['name']),
                                      anchor: const Offset(0.5, 0.5),
                                      icon: (element['is_active'] == 0)
                                          ? (element['vehicle_type_icon'] ==
                                                  'motor_bike')
                                              ? offlinebikeicon
                                              : (element['vehicle_type_icon'] ==
                                                      'taxi')
                                                  ? offlineicon
                                                  : offlinedeliveryicon
                                          : (element['is_available'] == true &&
                                                  element['is_active'] == 1)
                                              ? (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onlinebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onlineicon
                                                      : onlinedeliveryicon
                                              : (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onridebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onrideicon
                                                      : onridedeliveryicon,
                                    ));
                                  } else if ((element['is_available'] != true && myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon == onlineicon) ||
                                      (element['is_available'] != true &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon ==
                                              onlinebikeicon) ||
                                      (element['is_available'] != true &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon ==
                                              onlinedeliveryicon)) {
                                    myMarkers.removeWhere((e) => e.markerId
                                        .toString()
                                        .contains('car${element['id']}'));
                                    myMarkers.add(Marker(
                                      markerId: MarkerId('car${element['id']}'),
                                      rotation: double.parse(
                                          element['bearing'].toString()),
                                      position: LatLng(
                                          element['l'][0], element['l'][1]),
                                      infoWindow: InfoWindow(
                                          title: element['vehicle_number'],
                                          snippet: element['name']),
                                      anchor: const Offset(0.5, 0.5),
                                      icon: (element['is_active'] == 0)
                                          ? (element['vehicle_type_icon'] ==
                                                  'motor_bike')
                                              ? offlinebikeicon
                                              : (element['vehicle_type_icon'] ==
                                                      'taxi')
                                                  ? offlineicon
                                                  : offlinedeliveryicon
                                          : (element['is_available'] == true &&
                                                  element['is_active'] == 1)
                                              ? (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onlinebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onlineicon
                                                      : onlinedeliveryicon
                                              : (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onridebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onrideicon
                                                      : onridedeliveryicon,
                                    ));
                                  } else if ((element['is_active'] != 1 && myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon == onlineicon) ||
                                      (element['is_active'] != 1 &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon ==
                                              onlinebikeicon) ||
                                      (element['is_active'] != 1 &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon ==
                                              onlinedeliveryicon)) {
                                    myMarkers.removeWhere((e) => e.markerId
                                        .toString()
                                        .contains('car${element['id']}'));
                                    myMarkers.add(Marker(
                                      markerId: MarkerId('car${element['id']}'),
                                      rotation: double.parse(
                                          element['bearing'].toString()),
                                      position: LatLng(
                                          element['l'][0], element['l'][1]),
                                      infoWindow: InfoWindow(
                                          title: element['vehicle_number'],
                                          snippet: element['name']),
                                      anchor: const Offset(0.5, 0.5),
                                      icon: (element['is_active'] == 0)
                                          ? (element['vehicle_type_icon'] ==
                                                  'motor_bike')
                                              ? offlinebikeicon
                                              : (element['vehicle_type_icon'] ==
                                                      'taxi')
                                                  ? offlineicon
                                                  : offlinedeliveryicon
                                          : (element['is_available'] == true &&
                                                  element['is_active'] == 1)
                                              ? (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onlinebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onlineicon
                                                      : onlinedeliveryicon
                                              : (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onridebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onrideicon
                                                      : onridedeliveryicon,
                                    ));
                                  } else if ((element['is_available'] == true &&
                                          myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon == onrideicon) ||
                                      (element['is_available'] == true && myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon == onridebikeicon) ||
                                      (element['is_available'] == true && myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).icon == onridedeliveryicon)) {
                                    myMarkers.removeWhere((e) => e.markerId
                                        .toString()
                                        .contains('car${element['id']}'));
                                    myMarkers.add(Marker(
                                      markerId: MarkerId('car${element['id']}'),
                                      rotation: double.parse(
                                          element['bearing'].toString()),
                                      position: LatLng(
                                          element['l'][0], element['l'][1]),
                                      infoWindow: InfoWindow(
                                          title: element['vehicle_number'],
                                          snippet: element['name']),
                                      anchor: const Offset(0.5, 0.5),
                                      icon: (element['is_active'] == 0)
                                          ? (element['vehicle_type_icon'] ==
                                                  'motor_bike')
                                              ? offlinebikeicon
                                              : (element['vehicle_type_icon'] ==
                                                      'taxi')
                                                  ? offlineicon
                                                  : offlinedeliveryicon
                                          : (element['is_available'] == true &&
                                                  element['is_active'] == 1)
                                              ? (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onlinebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onlineicon
                                                      : onlinedeliveryicon
                                              : (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onridebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onrideicon
                                                      : onridedeliveryicon,
                                    ));
                                  } else if (_controller != null) {
                                    if (myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .latitude !=
                                            element['l'][0] ||
                                        myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .longitude !=
                                            element['l'][1]) {
                                      var dist = calculateDistance(
                                          myMarkers
                                              .lastWhere((e) => e.markerId
                                                  .toString()
                                                  .contains(
                                                      'car${element['id']}'))
                                              .position
                                              .latitude,
                                          myMarkers
                                              .lastWhere((e) => e.markerId
                                                  .toString()
                                                  .contains(
                                                      'car${element['id']}'))
                                              .position
                                              .longitude,
                                          element['l'][0],
                                          element['l'][1]);
                                      if (dist > 100 && _controller != null) {
                                        animationController =
                                            AnimationController(
                                          duration: const Duration(
                                              milliseconds:
                                                  1500), //Animation duration of marker

                                          vsync: this, //From the widget
                                        );

                                        animateCar(
                                            myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .latitude,
                                            myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .longitude,
                                            element['l'][0],
                                            element['l'][1],
                                            _mapMarkerSink,
                                            this,
                                            _controller,
                                            'car${element['id']}',
                                            (element['is_active'] == 0)
                                                ? (element['vehicle_type_icon'] ==
                                                        'motor_bike')
                                                    ? offlinebikeicon
                                                    : (element['vehicle_type_icon'] ==
                                                            'taxi')
                                                        ? offlineicon
                                                        : offlinedeliveryicon
                                                : (element['is_available'] ==
                                                            true &&
                                                        element['is_active'] ==
                                                            1)
                                                    ? (element['vehicle_type_icon'] ==
                                                            'motor_bike')
                                                        ? onlinebikeicon
                                                        : (element['vehicle_type_icon'] ==
                                                                'taxi')
                                                            ? onlineicon
                                                            : onlinedeliveryicon
                                                    : (element['vehicle_type_icon'] ==
                                                            'motor_bike')
                                                        ? onridebikeicon
                                                        : (element['vehicle_type_icon'] ==
                                                                'taxi')
                                                            ? onrideicon
                                                            : onridedeliveryicon,
                                            element['vehicle_number'],
                                            element['name']);
                                      }
                                    }
                                  }
                                } else if (filtericon == 1 &&
                                    userDetails['role'] == 'owner' &&
                                    onlineicon != null) {
                                  if (element['l'] != null) {
                                    if (element['is_active'] == 0 &&
                                        offlineicon != null) {
                                      if (myMarkers
                                          .where((e) => e.markerId
                                              .toString()
                                              .contains('car${element['id']}'))
                                          .isEmpty) {
                                        myMarkers.add(Marker(
                                          markerId: MarkerId(
                                              'carid${element['id']}idoffline'),
                                          rotation: double.parse(
                                              element['bearing'].toString()),
                                          position: LatLng(
                                              element['l'][0], element['l'][1]),
                                          anchor: const Offset(0.5, 0.5),
                                          icon: (element['vehicle_type_icon'] ==
                                                  'motor_bike')
                                              ? offlinebikeicon
                                              : (element['vehicle_type_icon'] ==
                                                      'taxi')
                                                  ? offlineicon
                                                  : offlinedeliveryicon,
                                        ));
                                      } else if (_controller != null) {
                                        if (myMarkers
                                                    .lastWhere((e) => e.markerId
                                                        .toString()
                                                        .contains(
                                                            'car${element['id']}'))
                                                    .position
                                                    .latitude !=
                                                element['l'][0] ||
                                            myMarkers
                                                    .lastWhere((e) => e.markerId
                                                        .toString()
                                                        .contains(
                                                            'car${element['id']}'))
                                                    .position
                                                    .longitude !=
                                                element['l'][1]) {
                                          var dist = calculateDistance(
                                              myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .longitude,
                                              element['l'][0],
                                              element['l'][1]);
                                          if (dist > 100 &&
                                              _controller != null) {
                                            animationController =
                                                AnimationController(
                                              duration: const Duration(
                                                  milliseconds:
                                                      1500), //Animation duration of marker

                                              vsync: this, //From the widget
                                            );

                                            animateCar(
                                                myMarkers
                                                    .lastWhere((e) => e.markerId
                                                        .toString()
                                                        .contains(
                                                            'car${element['id']}'))
                                                    .position
                                                    .latitude,
                                                myMarkers
                                                    .lastWhere((e) => e.markerId
                                                        .toString()
                                                        .contains(
                                                            'car${element['id']}'))
                                                    .position
                                                    .longitude,
                                                element['l'][0],
                                                element['l'][1],
                                                _mapMarkerSink,
                                                this,
                                                _controller,
                                                'car${element['id']}',
                                                (element['vehicle_type_icon'] ==
                                                        'motor_bike')
                                                    ? offlinebikeicon
                                                    : (element['vehicle_type_icon'] ==
                                                            'taxi')
                                                        ? offlineicon
                                                        : offlinedeliveryicon,
                                                element['vehicle_number'],
                                                element['name']);
                                          }
                                        }
                                      }
                                    } else {
                                      if (myMarkers
                                          .where((e) => e.markerId
                                              .toString()
                                              .contains('car${element['id']}'))
                                          .isNotEmpty) {
                                        myMarkers.removeWhere((e) => e.markerId
                                            .toString()
                                            .contains('car${element['id']}'));
                                      }
                                    }
                                  }
                                } else if (filtericon == 2 &&
                                    userDetails['role'] == 'owner' &&
                                    onlineicon != null) {
                                  if (element['is_available'] == false &&
                                      element['is_active'] == 1) {
                                    if (myMarkers
                                        .where((e) => e.markerId
                                            .toString()
                                            .contains('car${element['id']}'))
                                        .isEmpty) {
                                      myMarkers.add(Marker(
                                        markerId:
                                            MarkerId('car${element['id']}'),
                                        rotation: double.parse(
                                            element['bearing'].toString()),
                                        position: LatLng(
                                            element['l'][0], element['l'][1]),
                                        anchor: const Offset(0.5, 0.5),
                                        icon: (element['vehicle_type_icon'] ==
                                                'motor_bike')
                                            ? onridebikeicon
                                            : (element['vehicle_type_icon'] ==
                                                    'taxi')
                                                ? onrideicon
                                                : onridedeliveryicon,
                                      ));
                                    } else if (_controller != null) {
                                      if (myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .latitude !=
                                              element['l'][0] ||
                                          myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .longitude !=
                                              element['l'][1]) {
                                        var dist = calculateDistance(
                                            myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .latitude,
                                            myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .longitude,
                                            element['l'][0],
                                            element['l'][1]);
                                        if (dist > 100 && _controller != null) {
                                          animationController =
                                              AnimationController(
                                            duration: const Duration(
                                                milliseconds:
                                                    1500), //Animation duration of marker

                                            vsync: this, //From the widget
                                          );

                                          animateCar(
                                              myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .longitude,
                                              element['l'][0],
                                              element['l'][1],
                                              _mapMarkerSink,
                                              this,
                                              _controller,
                                              'car${element['id']}',
                                              (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onridebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onrideicon
                                                      : onridedeliveryicon,
                                              element['vehicle_number'],
                                              element['name']);
                                        }
                                      }
                                    }
                                  } else {
                                    if (myMarkers
                                        .where((e) => e.markerId
                                            .toString()
                                            .contains('car${element['id']}'))
                                        .isNotEmpty) {
                                      myMarkers.removeWhere((e) => e.markerId
                                          .toString()
                                          .contains('car${element['id']}'));
                                    }
                                  }
                                } else if (filtericon == 3 &&
                                    userDetails['role'] == 'owner' &&
                                    onlineicon != null) {
                                  if (element['is_available'] == true &&
                                      element['is_active'] == 1) {
                                    if (myMarkers
                                        .where((e) => e.markerId
                                            .toString()
                                            .contains('car${element['id']}'))
                                        .isEmpty) {
                                      myMarkers.add(Marker(
                                        markerId:
                                            MarkerId('car${element['id']}'),
                                        rotation: double.parse(
                                            element['bearing'].toString()),
                                        position: LatLng(
                                            element['l'][0], element['l'][1]),
                                        anchor: const Offset(0.5, 0.5),
                                        icon: (element['vehicle_type_icon'] ==
                                                'motor_bike')
                                            ? onlinebikeicon
                                            : (element['vehicle_type_icon'] ==
                                                    'taxi')
                                                ? onlineicon
                                                : onlinedeliveryicon,
                                      ));
                                    } else if (_controller != null) {
                                      if (myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .latitude !=
                                              element['l'][0] ||
                                          myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .longitude !=
                                              element['l'][1]) {
                                        var dist = calculateDistance(
                                            myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .latitude,
                                            myMarkers
                                                .lastWhere((e) => e.markerId
                                                    .toString()
                                                    .contains(
                                                        'car${element['id']}'))
                                                .position
                                                .longitude,
                                            element['l'][0],
                                            element['l'][1]);
                                        if (dist > 100 && _controller != null) {
                                          animationController =
                                              AnimationController(
                                            duration: const Duration(
                                                milliseconds:
                                                    1500), //Animation duration of marker

                                            vsync: this, //From the widget
                                          );

                                          animateCar(
                                              myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarkers
                                                  .lastWhere((e) => e.markerId
                                                      .toString()
                                                      .contains(
                                                          'car${element['id']}'))
                                                  .position
                                                  .longitude,
                                              element['l'][0],
                                              element['l'][1],
                                              _mapMarkerSink,
                                              this,
                                              _controller,
                                              'car${element['id']}',
                                              (element['vehicle_type_icon'] ==
                                                      'motor_bike')
                                                  ? onlinebikeicon
                                                  : (element['vehicle_type_icon'] ==
                                                          'taxi')
                                                      ? onlineicon
                                                      : onlinedeliveryicon,
                                              element['vehicle_number'],
                                              element['name']);
                                        }
                                      }
                                    }
                                  }
                                } else {
                                  if (myMarkers
                                      .where((e) => e.markerId
                                          .toString()
                                          .contains('car${element['id']}'))
                                      .isNotEmpty) {
                                    myMarkers.removeWhere((e) => e.markerId
                                        .toString()
                                        .contains('car${element['id']}'));
                                  }
                                }
                              }
                            } else {
                              if (myMarkers
                                  .where((e) => e.markerId
                                      .toString()
                                      .contains('car${element['id']}'))
                                  .isNotEmpty) {
                                myMarkers.removeWhere((e) => e.markerId
                                    .toString()
                                    .contains('car${element['id']}'));
                              }
                            }
                          }
                        }
                        return SingleChildScrollView(
                          child: Stack(
                            children: [
                              Container(
                                color: page,
                                height: media.height * 1,
                                width: media.width * 1,
                                child: Column(
                                    mainAxisAlignment:
                                        (state == '1' || state == '2')
                                            ? MainAxisAlignment.center
                                            : MainAxisAlignment.start,
                                    children: [
                                      (state == '1')
                                          ? Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              width: media.width * 0.6,
                                              height: media.width * 0.3,
                                              decoration: BoxDecoration(
                                                  color: page,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        blurRadius: 5,
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        spreadRadius: 2)
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    languages[choosenLanguage][
                                                        'text_enable_location'],
                                                    style: GoogleFonts.notoSans(
                                                        fontSize: media.width *
                                                            sixteen,
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Container(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          state = '';
                                                        });
                                                        getLocs();
                                                      },
                                                      child: Text(
                                                        languages[
                                                                choosenLanguage]
                                                            ['text_ok'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: media
                                                                        .width *
                                                                    twenty,
                                                                color:
                                                                    buttonColor),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                          : (state == '2')
                                              ? Container(
                                                  height: media.height * 1,
                                                  width: media.width * 1,
                                                  alignment: Alignment.center,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        height:
                                                            media.height * 0.31,
                                                        child: Image.asset(
                                                          'assets/images/allow_location_permission.png',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_trustedtaxi'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    eighteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.025,
                                                      ),
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_allowpermission1'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                        ),
                                                      ),
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_allowpermission2'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                media.width *
                                                                    0.05,
                                                                0,
                                                                media.width *
                                                                    0.05,
                                                                0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.075,
                                                                child: const Icon(
                                                                    Icons
                                                                        .location_on_outlined)),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.8,
                                                              child: Text(
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_loc_permission'],
                                                                style: GoogleFonts.notoSans(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.02,
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                media.width *
                                                                    0.05,
                                                                0,
                                                                media.width *
                                                                    0.05,
                                                                0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.075,
                                                                child: const Icon(
                                                                    Icons
                                                                        .location_on_outlined)),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.8,
                                                              child: Text(
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_background_permission'],
                                                                style: GoogleFonts.notoSans(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  media.width *
                                                                      0.05),
                                                          child: Button(
                                                              onTap: () async {
                                                                getLocationPermission();
                                                              },
                                                              text: languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_continue']))
                                                    ],
                                                  ),
                                                )
                                              : (state == '3')
                                                  ? Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        SizedBox(
                                                            height:
                                                                media.height *
                                                                    1,
                                                            width:
                                                                media.width * 1,
                                                            //google maps
                                                            child: StreamBuilder<
                                                                    List<
                                                                        Marker>>(
                                                                stream:
                                                                    mapMarkerStream,
                                                                builder: (context,
                                                                    snapshot) {
                                                                  return GoogleMap(
                                                                    padding: EdgeInsets.only(
                                                                        bottom:
                                                                            media.width *
                                                                                1,
                                                                        top: media.height *
                                                                                0.1 +
                                                                            MediaQuery.of(context).padding.top),
                                                                    onMapCreated:
                                                                        _onMapCreated,
                                                                    initialCameraPosition:
                                                                        CameraPosition(
                                                                      target: (center ==
                                                                              null)
                                                                          ? _center
                                                                          : center,
                                                                      zoom:
                                                                          11.0,
                                                                    ),
                                                                    markers: Set<
                                                                            Marker>.from(
                                                                        myMarkers),
                                                                    polylines:
                                                                        polyline,
                                                                    minMaxZoomPreference:
                                                                        const MinMaxZoomPreference(
                                                                            0.0,
                                                                            20.0),
                                                                    myLocationButtonEnabled:
                                                                        false,
                                                                    compassEnabled:
                                                                        false,
                                                                    buildingsEnabled:
                                                                        false,
                                                                    zoomControlsEnabled:
                                                                        false,
                                                                  );
                                                                })),

                                                        //driver status
                                                        (userDetails['role'] ==
                                                                    'owner' ||
                                                                driverReq
                                                                    .isNotEmpty ||
                                                                userDetails[
                                                                        'low_balance'] ==
                                                                    true ||
                                                                userDetails[
                                                                        'car_make_name'] ==
                                                                    null)
                                                            ? Container()
                                                            : Positioned(
                                                                top: MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top +
                                                                    24,
                                                                child: InkWell(
                                                                  onTap:
                                                                      () async {
                                                                    // await getUserDetails();
                                                                    if (userDetails['vehicle_type_id'] !=
                                                                            null &&
                                                                        choosenRide
                                                                            .isEmpty &&
                                                                        driverReq
                                                                            .isEmpty &&
                                                                        userDetails['role'] ==
                                                                            'driver') {
                                                                      if (locationAllowed ==
                                                                              true &&
                                                                          serviceEnabled ==
                                                                              true) {
                                                                        setState(
                                                                            () {
                                                                          _isLoading =
                                                                              true;
                                                                        });

                                                                        var val =
                                                                            await driverStatus();
                                                                        if (val ==
                                                                            'logout') {
                                                                          navigateLogout();
                                                                        }
                                                                        setState(
                                                                            () {
                                                                          _isLoading =
                                                                              false;
                                                                        });
                                                                      } else if (locationAllowed ==
                                                                              true &&
                                                                          serviceEnabled ==
                                                                              false) {
                                                                        await geolocator.Geolocator.getCurrentPosition(
                                                                            desiredAccuracy:
                                                                                geolocator.LocationAccuracy.low);
                                                                        if (await geolocator
                                                                            .GeolocatorPlatform
                                                                            .instance
                                                                            .isLocationServiceEnabled()) {
                                                                          serviceEnabled =
                                                                              true;
                                                                          setState(
                                                                              () {
                                                                            _isLoading =
                                                                                true;
                                                                          });

                                                                          var val =
                                                                              await driverStatus();
                                                                          if (val ==
                                                                              'logout') {
                                                                            navigateLogout();
                                                                          }
                                                                          setState(
                                                                              () {
                                                                            _isLoading =
                                                                                false;
                                                                          });
                                                                        }
                                                                      } else {
                                                                        if (serviceEnabled ==
                                                                            true) {
                                                                          setState(
                                                                              () {
                                                                            makeOnline =
                                                                                true;
                                                                            _locationDenied =
                                                                                true;
                                                                          });
                                                                        } else {
                                                                          await geolocator.Geolocator.getCurrentPosition(
                                                                              desiredAccuracy: geolocator.LocationAccuracy.low);

                                                                          setState(
                                                                              () {
                                                                            _isLoading =
                                                                                true;
                                                                          });
                                                                          await getLocs();
                                                                          if (serviceEnabled ==
                                                                              true) {
                                                                            setState(() {
                                                                              makeOnline = true;
                                                                              _locationDenied = true;
                                                                            });
                                                                          }
                                                                        }
                                                                      }
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    padding: EdgeInsets.only(
                                                                        left: media.width *
                                                                            0.01,
                                                                        right: media.width *
                                                                            0.01),
                                                                    height: media
                                                                            .width *
                                                                        0.08,
                                                                    width: media
                                                                            .width *
                                                                        0.3,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(media.width *
                                                                              0.04),
                                                                      color: (userDetails['active'] ==
                                                                              false)
                                                                          ? const Color(0xff707070)
                                                                              .withOpacity(0.6)
                                                                          : (driverReq['accepted_at'] != null && driverReq['is_driver_arrived'] == 0)
                                                                              ? const Color(0XFF127CE6).withOpacity(0.6)
                                                                              : (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0)
                                                                                  ? const Color(0XFFFEECD2)
                                                                                  : (driverReq['is_trip_start'] == 1)
                                                                                      ? const Color(0XFFF9D9D9)
                                                                                      : const Color(0xff00E688),
                                                                    ),
                                                                    child: (userDetails['active'] ==
                                                                            false)
                                                                        ? Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Container(
                                                                                padding: EdgeInsets.all(media.width * 0.01),
                                                                                height: media.width * 0.07,
                                                                                width: media.width * 0.07,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: onlineOfflineText),
                                                                                child: Image.asset(
                                                                                  'assets/images/offline.png',
                                                                                  color: const Color(0xff707070),
                                                                                ),
                                                                              ),
                                                                              MyText(
                                                                                text: languages[choosenLanguage]['text_on_duty'],
                                                                                size: media.width * twelve,
                                                                                color: (isDarkTheme == true) ? textColor.withOpacity(0.7) : const Color(0xff555555),
                                                                              ),
                                                                              Container(),
                                                                            ],
                                                                          )
                                                                        : Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Container(),
                                                                              MyText(
                                                                                text: (driverReq['accepted_at'] != null && driverReq['arrived_at'] == null)
                                                                                    ? languages[choosenLanguage]['text_in_the_way']
                                                                                    : (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0)
                                                                                        ? languages[choosenLanguage]['text_arrived']
                                                                                        : (driverReq['is_trip_start'] == 1)
                                                                                            ? languages[choosenLanguage]['text_onride']
                                                                                            : languages[choosenLanguage]['text_off_duty'],
                                                                                size: media.width * twelve,
                                                                                color: textColor,
                                                                              ),
                                                                              Container(
                                                                                padding: EdgeInsets.all(media.width * 0.01),
                                                                                height: media.width * 0.07,
                                                                                width: media.width * 0.07,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: onlineOfflineText),
                                                                                child: Image.asset(
                                                                                  'assets/images/offline.png',
                                                                                  color: (driverReq['accepted_at'] != null && driverReq['is_driver_arrived'] == 0)
                                                                                      ? const Color(0XFF127CE6).withOpacity(0.6)
                                                                                      : (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0)
                                                                                          ? const Color(0XFFFEECD2)
                                                                                          : (driverReq['is_trip_start'] == 1)
                                                                                              ? const Color(0XFFF95858).withOpacity(0.5)
                                                                                              : const Color(0xff00E688),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                  ),
                                                                )),

                                                        //menu bar
                                                        (driverReq.isNotEmpty)
                                                            ? Container()
                                                            : Positioned(
                                                                top: MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top +
                                                                    12.5,
                                                                child: SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        height: media.width *
                                                                            0.1,
                                                                        width: media.width *
                                                                            0.1,
                                                                        decoration: BoxDecoration(
                                                                            boxShadow: [
                                                                              BoxShadow(blurRadius: 2, color: textColor.withOpacity(0.2), spreadRadius: 2)
                                                                            ],
                                                                            color:
                                                                                page,
                                                                            borderRadius:
                                                                                BorderRadius.circular(media.width * 0.01)),
                                                                        child: StatefulBuilder(builder:
                                                                            (context,
                                                                                setState) {
                                                                          return InkWell(
                                                                              onTap: () async {
                                                                                if (userDetails['role'] == 'owner') {
                                                                                  Scaffold.of(context).openDrawer();
                                                                                } else {
                                                                                  Navigator.pop(context);
                                                                                }
                                                                              },
                                                                              child: Icon(
                                                                                (userDetails['role'] == 'owner') ? Icons.menu : Icons.arrow_back,
                                                                                size: media.width * 0.05,
                                                                                color: textColor,
                                                                              ));
                                                                        }),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )),
                                                        //online or offline button
                                                        (userDetails['role'] ==
                                                                'owner')
                                                            ? (languageDirection ==
                                                                    'rtl')
                                                                ? Positioned(
                                                                    top: MediaQuery.of(context)
                                                                            .padding
                                                                            .top +
                                                                        12.5,
                                                                    left: 10,
                                                                    child:
                                                                        AnimatedContainer(
                                                                      curve: Curves
                                                                          .fastLinearToSlowEaseIn,
                                                                      duration: const Duration(
                                                                          milliseconds:
                                                                              0),
                                                                      height: media
                                                                              .width *
                                                                          0.13,
                                                                      width: (show == true)
                                                                          ? media.width *
                                                                              0.13
                                                                          : media.width *
                                                                              0.7,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius: show ==
                                                                                true
                                                                            ? BorderRadius.circular(
                                                                                100.0)
                                                                            : const BorderRadius.only(
                                                                                topLeft: Radius.circular(100),
                                                                                bottomLeft: Radius.circular(100),
                                                                                topRight: Radius.circular(20),
                                                                                bottomRight: Radius.circular(20)),
                                                                        color: Colors
                                                                            .white,
                                                                        boxShadow: const [
                                                                          BoxShadow(
                                                                            color: ui.Color.fromARGB(
                                                                                255,
                                                                                8,
                                                                                38,
                                                                                172),
                                                                            offset:
                                                                                Offset(0.0, 1.0), //(x,y)
                                                                            blurRadius:
                                                                                10.0,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          show == false
                                                                              ? SizedBox(
                                                                                  width: media.width * 0.57,
                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                    children: [
                                                                                      OwnerCarImagecontainer(
                                                                                        color: Colors.green,
                                                                                        imgurl: (transportType == 'taxi' || transportType == 'both') ? 'assets/images/available.png' : 'assets/images/available_delivery.png',
                                                                                        text: languages[choosenLanguage]['text_available'],
                                                                                        ontap: () {
                                                                                          setState(() {
                                                                                            filtericon = 3;
                                                                                            myMarkers.clear();
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                      OwnerCarImagecontainer(
                                                                                        color: Colors.red,
                                                                                        imgurl: (transportType == 'taxi' || transportType == 'both') ? 'assets/images/onboard.png' : 'assets/images/onboard_delivery.png',
                                                                                        text: languages[choosenLanguage]['text_onboard'],
                                                                                        ontap: () {
                                                                                          setState(() {
                                                                                            filtericon = 2;
                                                                                            myMarkers.clear();
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                      OwnerCarImagecontainer(
                                                                                        color: Colors.grey,
                                                                                        imgurl: (transportType == 'taxi' || transportType == 'both') ? 'assets/images/offlinecar.png' : 'assets/images/offlinecar_delivery.png',
                                                                                        text: languages[choosenLanguage]['text_offline'],
                                                                                        ontap: () {
                                                                                          setState(() {
                                                                                            filtericon = 1;
                                                                                            myMarkers.clear();
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                )
                                                                              : Container(),
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                filtericon = 0;
                                                                                myMarkers.clear();
                                                                                if (show == false) {
                                                                                  show = true;
                                                                                } else {
                                                                                  show = false;
                                                                                }
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              width: media.width * 0.13,
                                                                              decoration: BoxDecoration(image: DecorationImage(image: (transportType == 'taxi' || transportType == 'both') ? const AssetImage('assets/images/bluecar.png') : const AssetImage('assets/images/bluecar_delivery.png'), fit: BoxFit.contain), borderRadius: BorderRadius.circular(100.0)),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Positioned(
                                                                    top: MediaQuery.of(context)
                                                                            .padding
                                                                            .top +
                                                                        12.5,
                                                                    right: 10,
                                                                    child:
                                                                        AnimatedContainer(
                                                                      curve: Curves
                                                                          .fastLinearToSlowEaseIn,
                                                                      duration: const Duration(
                                                                          milliseconds:
                                                                              0),
                                                                      height: media
                                                                              .width *
                                                                          0.13,
                                                                      width: (show == true)
                                                                          ? media.width *
                                                                              0.13
                                                                          : media.width *
                                                                              0.7,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius: show ==
                                                                                true
                                                                            ? BorderRadius.circular(
                                                                                100.0)
                                                                            : const BorderRadius.only(
                                                                                topLeft: Radius.circular(20),
                                                                                bottomLeft: Radius.circular(20),
                                                                                topRight: Radius.circular(100),
                                                                                bottomRight: Radius.circular(100)),
                                                                        color: Colors
                                                                            .white,
                                                                        boxShadow: const [
                                                                          BoxShadow(
                                                                            color: ui.Color.fromARGB(
                                                                                255,
                                                                                8,
                                                                                38,
                                                                                172),
                                                                            offset:
                                                                                Offset(0.0, 1.0), //(x,y)
                                                                            blurRadius:
                                                                                10.0,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          show == false
                                                                              ? SizedBox(
                                                                                  width: media.width * 0.57,
                                                                                  child: Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                    children: [
                                                                                      OwnerCarImagecontainer(
                                                                                        color: Colors.green,
                                                                                        imgurl: (transportType == 'taxi' || transportType == 'both') ? 'assets/images/available.png' : 'assets/images/available_delivery.png',
                                                                                        text: languages[choosenLanguage]['text_available'],
                                                                                        ontap: () {
                                                                                          setState(() {
                                                                                            filtericon = 3;
                                                                                            myMarkers.clear();
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                      OwnerCarImagecontainer(
                                                                                        color: Colors.red,
                                                                                        imgurl: (transportType == 'taxi' || transportType == 'both') ? 'assets/images/onboard.png' : 'assets/images/onboard_delivery.png',
                                                                                        text: languages[choosenLanguage]['text_onboard'],
                                                                                        ontap: () {
                                                                                          setState(() {
                                                                                            filtericon = 2;
                                                                                            myMarkers.clear();
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                      OwnerCarImagecontainer(
                                                                                        color: Colors.grey,
                                                                                        imgurl: (transportType == 'taxi' || transportType == 'both') ? 'assets/images/offlinecar.png' : 'assets/images/offlinecar_delivery.png',
                                                                                        text: 'Offline',
                                                                                        ontap: () {
                                                                                          setState(() {
                                                                                            filtericon = 1;
                                                                                            myMarkers.clear();
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                )
                                                                              : Container(),
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                filtericon = 0;
                                                                                myMarkers.clear();
                                                                                if (show == false) {
                                                                                  show = true;
                                                                                } else {
                                                                                  show = false;
                                                                                }
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              width: media.width * 0.13,
                                                                              decoration: BoxDecoration(image: DecorationImage(image: (transportType == 'taxi' || transportType == 'both') ? const AssetImage('assets/images/bluecar.png') : const AssetImage('assets/images/bluecar_delivery.png'), fit: BoxFit.contain), borderRadius: BorderRadius.circular(100.0)),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  )
                                                            : Container(),

                                                        //request popup accept or reject
                                                        Positioned(
                                                            bottom: 0,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                (driverReq.isNotEmpty &&
                                                                        driverReq['is_trip_start'] ==
                                                                            1)
                                                                    ? InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          setState(
                                                                              () {
                                                                            showSos =
                                                                                true;
                                                                          });
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              media.width * 0.1,
                                                                          width:
                                                                              media.width * 0.1,
                                                                          decoration: BoxDecoration(
                                                                              boxShadow: [
                                                                                BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)
                                                                              ],
                                                                              color: buttonColor,
                                                                              borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                          alignment:
                                                                              Alignment.center,
                                                                          child:
                                                                              Text(
                                                                            'SOS',
                                                                            style:
                                                                                GoogleFonts.notoSans(fontSize: media.width * fourteen, color: page),
                                                                          ),
                                                                        ))
                                                                    : Container(),
                                                                const SizedBox(
                                                                  height: 20,
                                                                ),
                                                                (driverReq.isNotEmpty &&
                                                                        driverReq['accepted_at'] !=
                                                                            null &&
                                                                        driverReq['drop_address'] !=
                                                                            null)
                                                                    ? Row(
                                                                        children: [
                                                                          (navigationtype == true)
                                                                              ? Container(
                                                                                  padding: EdgeInsets.all(media.width * 0.02),
                                                                                  decoration: BoxDecoration(boxShadow: [
                                                                                    BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)
                                                                                  ], color: page, borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                                  child: Row(
                                                                                    children: [
                                                                                      InkWell(
                                                                                        onTap: () {
                                                                                          if (driverReq['is_trip_start'] == 0) {
                                                                                            openMap(driverReq['pick_lat'], driverReq['pick_lng']);
                                                                                          }
                                                                                          if (tripStops.isEmpty && driverReq['is_trip_start'] != 0) {
                                                                                            openMap(driverReq['drop_lat'], driverReq['drop_lng']);
                                                                                          }
                                                                                        },
                                                                                        child: SizedBox(
                                                                                          width: media.width * 00.07,
                                                                                          child: Image.asset('assets/images/googlemaps.png', width: media.width * 0.05, fit: BoxFit.contain),
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(
                                                                                        width: media.width * 0.02,
                                                                                      ),
                                                                                      InkWell(
                                                                                        onTap: () {
                                                                                          if (driverReq['is_trip_start'] == 0) {
                                                                                            openWazeMap(driverReq['pick_lat'], driverReq['pick_lng']);
                                                                                          }
                                                                                          if (tripStops.isEmpty && driverReq['is_trip_start'] != 0) {
                                                                                            openWazeMap(driverReq['drop_lat'], driverReq['drop_lng']);
                                                                                          }
                                                                                        },
                                                                                        child: SizedBox(
                                                                                          width: media.width * 00.08,
                                                                                          child: Image.asset('assets/images/waze.png', width: media.width * 0.05, fit: BoxFit.contain),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                )
                                                                              : Container(),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.01,
                                                                          ),
                                                                          InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              if (userDetails['enable_vase_map'] == '1') {
                                                                                if (navigationtype == false) {
                                                                                  if (driverReq['is_trip_start'] == 0) {
                                                                                    setState(() {
                                                                                      navigationtype = true;
                                                                                    });
                                                                                  } else if (tripStops.isNotEmpty) {
                                                                                    setState(() {
                                                                                      _tripOpenMap = true;
                                                                                    });
                                                                                  } else {
                                                                                    setState(() {
                                                                                      navigationtype = true;
                                                                                    });
                                                                                  }
                                                                                } else {
                                                                                  setState(() {
                                                                                    navigationtype = false;
                                                                                  });
                                                                                }
                                                                              } else {
                                                                                if (driverReq['is_trip_start'] == 0) {
                                                                                  openMap(driverReq['pick_lat'], driverReq['pick_lng']);
                                                                                }
                                                                                if (tripStops.isEmpty && driverReq['is_trip_start'] != 0) {
                                                                                  openMap(driverReq['drop_lat'], driverReq['drop_lng']);
                                                                                }
                                                                              }
                                                                            },
                                                                            child: Container(
                                                                                height: media.width *
                                                                                    0.1,
                                                                                width: media.width *
                                                                                    0.1,
                                                                                decoration: BoxDecoration(boxShadow: [
                                                                                  BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)
                                                                                ], color: page, borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                                alignment: Alignment.center,
                                                                                child: Image.asset('assets/images/locationFind.png', width: media.width * 0.06, color: textColor)),
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Container(),
                                                                const SizedBox(
                                                                    height: 20),
                                                                //animate to current location button
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          if (locationAllowed ==
                                                                              true) {
                                                                            _controller?.animateCamera(CameraUpdate.newLatLngZoom(center,
                                                                                18.0));
                                                                          } else {
                                                                            if (serviceEnabled ==
                                                                                true) {
                                                                              setState(() {
                                                                                _locationDenied = true;
                                                                              });
                                                                            } else {
                                                                              await geolocator.Geolocator.getCurrentPosition(desiredAccuracy: geolocator.LocationAccuracy.low);

                                                                              setState(() {
                                                                                _isLoading = true;
                                                                              });
                                                                              await getLocs();
                                                                              if (serviceEnabled == true) {
                                                                                setState(() {
                                                                                  _locationDenied = true;
                                                                                });
                                                                              }
                                                                            }
                                                                          }
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              media.width * 0.1,
                                                                          width:
                                                                              media.width * 0.1,
                                                                          decoration: BoxDecoration(
                                                                              boxShadow: [
                                                                                BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)
                                                                              ],
                                                                              color: page,
                                                                              borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                          alignment:
                                                                              Alignment.center,
                                                                          child: Icon(
                                                                              Icons.my_location_sharp,
                                                                              color: textColor,
                                                                              size: media.width * 0.06),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.40),
                                                                (choosenRide.isNotEmpty &&
                                                                        driverReq
                                                                            .isEmpty)
                                                                    ? Column(
                                                                        children: [
                                                                          Container(
                                                                              padding: const EdgeInsets.fromLTRB(0, 0, 0,
                                                                                  0),
                                                                              width: media.width *
                                                                                  0.9,
                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: page, boxShadow: [
                                                                                BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)
                                                                              ]),
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Container(
                                                                                    padding: EdgeInsets.fromLTRB(media.width * 0.05, media.width * 0.02, media.width * 0.05, media.width * 0.05),
                                                                                    child: Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Row(
                                                                                          children: [
                                                                                            Container(
                                                                                              height: media.width * 0.15,
                                                                                              width: media.width * 0.15,
                                                                                              decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(choosenRide[0]['user_img']), fit: BoxFit.cover)),
                                                                                            ),
                                                                                            SizedBox(width: media.width * 0.05),
                                                                                            Expanded(
                                                                                              child: SizedBox(
                                                                                                height: media.width * 0.2,
                                                                                                child: Column(
                                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      choosenRide[0]['user_name'],
                                                                                                      maxLines: 1,
                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * eighteen, color: textColor),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            MyText(
                                                                                              text: choosenRide[0]['km'].toString(),
                                                                                              // maxLines: 1,
                                                                                              size: media.width * sixteen,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height: media.width * 0.02,
                                                                                        ),
                                                                                        Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                          children: [
                                                                                            Container(
                                                                                              height: media.width * 0.05,
                                                                                              width: media.width * 0.05,
                                                                                              alignment: Alignment.center,
                                                                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                              child: Container(
                                                                                                height: media.width * 0.025,
                                                                                                width: media.width * 0.025,
                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                              ),
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width: media.width * 0.06,
                                                                                            ),
                                                                                            Expanded(
                                                                                              child: MyText(
                                                                                                text: choosenRide[0]['pick_address'],
                                                                                                // maxLines: 1,
                                                                                                size: media.width * twelve,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height: media.width * 0.03,
                                                                                        ),
                                                                                        Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                          children: [
                                                                                            Container(
                                                                                              height: media.width * 0.06,
                                                                                              width: media.width * 0.06,
                                                                                              alignment: Alignment.center,
                                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                              child: Icon(
                                                                                                Icons.location_on_outlined,
                                                                                                color: const Color(0xFFFF0000),
                                                                                                size: media.width * eighteen,
                                                                                              ),
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width: media.width * 0.05,
                                                                                            ),
                                                                                            Expanded(
                                                                                              child: MyText(
                                                                                                text: choosenRide[choosenRide.length - 1]['drop_address'],
                                                                                                // maxLines: 1,
                                                                                                size: media.width * twelve,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height: media.width * 0.02,
                                                                                        ),
                                                                                        SizedBox(
                                                                                          child: Row(
                                                                                            children: [
                                                                                              InkWell(
                                                                                                onTap: () {
                                                                                                  if ((bidText.text.isEmpty && int.parse(choosenRide[0]['price'].toString()) > 10) || (bidText.text.isNotEmpty && int.parse(bidText.text.toString()) > 10)) {
                                                                                                    setState(() {
                                                                                                      bidText.text = (bidText.text.isEmpty) ? (int.parse(choosenRide[0]['price'].toString()) - 10).toString() : (int.parse(bidText.text.toString()) - 10).toString();
                                                                                                    });
                                                                                                  }
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: media.width * 0.2,
                                                                                                  alignment: Alignment.center,
                                                                                                  decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(media.width * 0.04)),
                                                                                                  padding: EdgeInsets.all(media.width * 0.025),
                                                                                                  child: Text(
                                                                                                    '-10',
                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: page),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.4,
                                                                                                child: TextField(
                                                                                                  textAlign: TextAlign.center,
                                                                                                  keyboardType: TextInputType.number,
                                                                                                  controller: bidText,
                                                                                                  decoration: InputDecoration(
                                                                                                    hintText: (choosenRide.isNotEmpty) ? choosenRide[0]['price'].toString() : '',
                                                                                                    hintStyle: GoogleFonts.notoSans(fontSize: media.width * sixteen, color: textColor),
                                                                                                    border: UnderlineInputBorder(borderSide: BorderSide(color: hintColor)),
                                                                                                  ),
                                                                                                  style: GoogleFonts.notoSans(fontSize: media.width * sixteen, color: textColor),
                                                                                                ),
                                                                                              ),
                                                                                              InkWell(
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    bidText.text = (bidText.text.isEmpty) ? (int.parse(choosenRide[0]['price'].toString()) + 10).toString() : (int.parse(bidText.text.toString()) + 10).toString();
                                                                                                  });
                                                                                                },
                                                                                                child: Container(
                                                                                                  width: media.width * 0.2,
                                                                                                  alignment: Alignment.center,
                                                                                                  decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(media.width * 0.04)),
                                                                                                  padding: EdgeInsets.all(media.width * 0.025),
                                                                                                  child: Text(
                                                                                                    '+10',
                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: page),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height: media.width * 0.02,
                                                                                        ),
                                                                                        SizedBox(
                                                                                            width: media.width * 0.9,
                                                                                            child: Button(
                                                                                                onTap: () async {
                                                                                                  if (bidText.text.isNotEmpty || choosenRide[0]['price'] != null) {
                                                                                                    setState(() {
                                                                                                      _isLoading = true;
                                                                                                    });
                                                                                                    try {
                                                                                                      await FirebaseDatabase.instance.ref().child('bid-meta/${choosenRide[0]["request_id"]}/drivers/driver_${userDetails["id"]}').update({
                                                                                                        'driver_id': userDetails['id'],
                                                                                                        'price': bidText.text.isNotEmpty ? bidText.text : choosenRide[0]['price'].toString(),
                                                                                                        'driver_name': userDetails['name'],
                                                                                                        'driver_img': userDetails['profile_picture'],
                                                                                                        'bid_time': ServerValue.timestamp,
                                                                                                        'is_rejected': 'none',
                                                                                                        'vehicle_make': userDetails['car_make_name'],
                                                                                                        'vehicle_model': userDetails['car_model_name'],
                                                                                                        'lat': center.latitude,
                                                                                                        'lng': center.longitude
                                                                                                      });
                                                                                                      setState(() {
                                                                                                        isAvailable = false;
                                                                                                      });
                                                                                                      FirebaseDatabase.instance.ref().child('drivers/driver_${userDetails['id']}').update({'is_available': false});
                                                                                                      // ignore: use_build_context_synchronously
                                                                                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RidePage()), (route) => false);
                                                                                                      // Navigator.pop(context);
                                                                                                    } catch (e) {
                                                                                                      debugPrint(e.toString());
                                                                                                    }
                                                                                                    setState(() {
                                                                                                      _isLoading = false;
                                                                                                    });
                                                                                                  }
                                                                                                },
                                                                                                text: languages[choosenLanguage]['text_bid']))
                                                                                      ],
                                                                                    ),
                                                                                  )
                                                                                ],
                                                                              )),
                                                                        ],
                                                                      )
                                                                    : (driverReq
                                                                            .isNotEmpty)
                                                                        ? (driverReq['accepted_at'] ==
                                                                                null)
                                                                            ? Column(
                                                                                children: [
                                                                                  (driverReq['is_later'] == 1 && driverReq['is_rental'] != true)
                                                                                      ? Container(
                                                                                          alignment: Alignment.center,
                                                                                          margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                                                          padding: EdgeInsets.all(media.width * 0.025),
                                                                                          decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(6)),
                                                                                          width: media.width * 1,
                                                                                          child: MyText(
                                                                                            text: '${languages[choosenLanguage]['text_rideLaterTime']} ${driverReq['cv_trip_start_time']}',
                                                                                            size: media.width * sixteen,
                                                                                            color: topBar,
                                                                                          ),
                                                                                        )
                                                                                      : (driverReq['is_rental'] == true && driverReq['is_later'] != 1)
                                                                                          ? Container(
                                                                                              alignment: Alignment.center,
                                                                                              margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                                                              padding: EdgeInsets.all(media.width * 0.025),
                                                                                              decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(6)),
                                                                                              width: media.width * 1,
                                                                                              child: MyText(
                                                                                                text: '${languages[choosenLanguage]['text_rental_ride']} - ${driverReq['rental_package_name']}',
                                                                                                size: media.width * sixteen,
                                                                                                color: Colors.black,
                                                                                              ),
                                                                                            )
                                                                                          : (driverReq['is_rental'] == true && driverReq['is_later'] == 1)
                                                                                              ? Container(
                                                                                                  alignment: Alignment.center,
                                                                                                  margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                                                                  padding: EdgeInsets.all(media.width * 0.025),
                                                                                                  decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(6)),
                                                                                                  width: media.width * 1,
                                                                                                  child: Column(
                                                                                                    children: [
                                                                                                      MyText(
                                                                                                        text: '${languages[choosenLanguage]['text_rideLaterTime']}  ${driverReq['cv_trip_start_time']}',
                                                                                                        size: media.width * sixteen,
                                                                                                        color: Colors.black,
                                                                                                      ),
                                                                                                      SizedBox(height: media.width * 0.02),
                                                                                                      MyText(
                                                                                                        text: '${languages[choosenLanguage]['text_rental_ride']} ${driverReq['rental_package_name']}',
                                                                                                        size: media.width * sixteen,
                                                                                                        color: Colors.black,
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                )
                                                                                              : Container(),
                                                                                  Container(
                                                                                      padding: const EdgeInsets.fromLTRB(0, 0, 0,
                                                                                          0),
                                                                                      width: media.width *
                                                                                          1,
                                                                                      decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(media.width * 0.02), topRight: Radius.circular(media.width * 0.02)), color: page, boxShadow: [
                                                                                        BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)
                                                                                      ]),
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        children: [
                                                                                          (duration != 0)
                                                                                              ? AnimatedContainer(
                                                                                                  duration: const Duration(milliseconds: 100),
                                                                                                  height: 10,
                                                                                                  width: (media.width * 0.9 / double.parse(userDetails['trip_accept_reject_duration_for_driver'].toString())) * (double.parse(userDetails['trip_accept_reject_duration_for_driver'].toString()) - duration),
                                                                                                  decoration: BoxDecoration(
                                                                                                      color: buttonColor,
                                                                                                      borderRadius: (languageDirection == 'ltr')
                                                                                                          ? BorderRadius.only(
                                                                                                              topLeft: const Radius.circular(100),
                                                                                                              topRight: (duration <= 2.0) ? const Radius.circular(100) : const Radius.circular(0),
                                                                                                            )
                                                                                                          : BorderRadius.only(
                                                                                                              topRight: const Radius.circular(100),
                                                                                                              topLeft: (duration <= 2.0) ? const Radius.circular(100) : const Radius.circular(0),
                                                                                                            )),
                                                                                                )
                                                                                              : Container(),
                                                                                          Container(
                                                                                            padding: EdgeInsets.fromLTRB(media.width * 0.05, media.width * 0.02, media.width * 0.05, media.width * 0.05),
                                                                                            child: Column(
                                                                                              children: [
                                                                                                Container(
                                                                                                  height: media.width * 0.15,
                                                                                                  width: media.width * 0.15,
                                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(driverReq['userDetail']['data']['profile_picture']), fit: BoxFit.cover)),
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.05,
                                                                                                ),
                                                                                                MyText(
                                                                                                  text: driverReq['userDetail']['data']['name'],
                                                                                                  size: media.width * eighteen,
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.05,
                                                                                                ),
                                                                                                (driverReq['drop_address'] == null && driverReq['is_rental'] == false)
                                                                                                    ? Container()
                                                                                                    : Row(
                                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                                        children: [
                                                                                                          Container(
                                                                                                            padding: EdgeInsets.all(media.width * 0.03),
                                                                                                            decoration: BoxDecoration(
                                                                                                              color: Colors.grey.withOpacity(0.1),
                                                                                                              border: Border.all(
                                                                                                                color: textColor.withOpacity(0.2),
                                                                                                              ),
                                                                                                              borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                                                            ),
                                                                                                            child: Row(
                                                                                                              children: [
                                                                                                                //payment image
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.06,
                                                                                                                  child: (driverReq['payment_opt'].toString() == '1')
                                                                                                                      ? Image.asset(
                                                                                                                          'assets/images/cash.png',
                                                                                                                          fit: BoxFit.contain,
                                                                                                                        )
                                                                                                                      : (driverReq['payment_opt'].toString() == '2')
                                                                                                                          ? Image.asset(
                                                                                                                              'assets/images/wallet.png',
                                                                                                                              fit: BoxFit.contain,
                                                                                                                            )
                                                                                                                          : (driverReq['payment_opt'].toString() == '0')
                                                                                                                              ? Image.asset(
                                                                                                                                  'assets/images/card.png',
                                                                                                                                  fit: BoxFit.contain,
                                                                                                                                )
                                                                                                                              : Container(),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.02,
                                                                                                                ),
                                                                                                                MyText(
                                                                                                                  text: driverReq['payment_type_string'].toString(),
                                                                                                                  size: media.width * sixteen,
                                                                                                                ),
                                                                                                                SizedBox(width: media.width * 0.02),
                                                                                                                (driverReq['show_request_eta_amount'] == true && driverReq['request_eta_amount'] != null)
                                                                                                                    ? Row(
                                                                                                                        children: [
                                                                                                                          MyText(
                                                                                                                            text: driverReq['request_eta_amount'].toStringAsFixed(2),
                                                                                                                            size: media.width * fourteen,
                                                                                                                            fontweight: FontWeight.w700,
                                                                                                                          ),
                                                                                                                          MyText(
                                                                                                                            text: userDetails['currency_symbol'],
                                                                                                                            size: media.width * fourteen,
                                                                                                                          )
                                                                                                                        ],
                                                                                                                      )
                                                                                                                    : Container()
                                                                                                              ],
                                                                                                            ),
                                                                                                          )
                                                                                                        ],
                                                                                                      ),
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.02,
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  height: (tripStops.isEmpty) ? media.width * 0.3 : media.width * 0.4,
                                                                                                  child: SingleChildScrollView(
                                                                                                    child: Column(
                                                                                                      children: [
                                                                                                        Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              height: media.width * 0.05,
                                                                                                              width: media.width * 0.05,
                                                                                                              alignment: Alignment.center,
                                                                                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                                              child: Container(
                                                                                                                height: media.width * 0.025,
                                                                                                                width: media.width * 0.025,
                                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                                              ),
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.06,
                                                                                                            ),
                                                                                                            Expanded(
                                                                                                              child: MyText(
                                                                                                                text: driverReq['pick_address'],
                                                                                                                size: media.width * twelve,
                                                                                                                // overflow: TextOverflow.ellipsis,
                                                                                                                // maxLines: 1,
                                                                                                              ),
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                        SizedBox(
                                                                                                          height: media.width * 0.02,
                                                                                                        ),
                                                                                                        (tripStops.isNotEmpty)
                                                                                                            ? Column(
                                                                                                                children: tripStops
                                                                                                                    .asMap()
                                                                                                                    .map((i, value) {
                                                                                                                      return MapEntry(
                                                                                                                          i,
                                                                                                                          (i < tripStops.length - 1)
                                                                                                                              ? Container(
                                                                                                                                  padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                                                  child: Column(
                                                                                                                                    children: [
                                                                                                                                      Row(
                                                                                                                                        children: [
                                                                                                                                          SizedBox(
                                                                                                                                            width: media.width * 0.8,
                                                                                                                                            child: Row(
                                                                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                                              children: [
                                                                                                                                                Container(
                                                                                                                                                  height: media.width * 0.06,
                                                                                                                                                  width: media.width * 0.06,
                                                                                                                                                  alignment: Alignment.center,
                                                                                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                                                                  child: MyText(
                                                                                                                                                    text: (i + 1).toString(),
                                                                                                                                                    // maxLines: 1,
                                                                                                                                                    color: const Color(0xFFFF0000),
                                                                                                                                                    fontweight: FontWeight.w600,
                                                                                                                                                    size: media.width * twelve,
                                                                                                                                                  ),
                                                                                                                                                ),
                                                                                                                                                SizedBox(
                                                                                                                                                  width: media.width * 0.05,
                                                                                                                                                ),
                                                                                                                                                Expanded(
                                                                                                                                                  child: MyText(
                                                                                                                                                    text: tripStops[i]['address'],
                                                                                                                                                    // maxLines: 1,
                                                                                                                                                    size: media.width * twelve,
                                                                                                                                                  ),
                                                                                                                                                ),
                                                                                                                                              ],
                                                                                                                                            ),
                                                                                                                                          ),
                                                                                                                                        ],
                                                                                                                                      ),
                                                                                                                                    ],
                                                                                                                                  ),
                                                                                                                                )
                                                                                                                              : Container());
                                                                                                                    })
                                                                                                                    .values
                                                                                                                    .toList(),
                                                                                                              )
                                                                                                            : Container(),
                                                                                                        SizedBox(
                                                                                                          height: media.width * 0.02,
                                                                                                        ),
                                                                                                        (driverReq['is_rental'] != true && driverReq['drop_address'] != null)
                                                                                                            ? Column(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                children: [
                                                                                                                  Row(
                                                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                    children: [
                                                                                                                      Container(
                                                                                                                        height: media.width * 0.06,
                                                                                                                        width: media.width * 0.06,
                                                                                                                        alignment: Alignment.center,
                                                                                                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                                        child: Icon(
                                                                                                                          Icons.location_on_outlined,
                                                                                                                          color: const Color(0xFFFF0000),
                                                                                                                          size: media.width * eighteen,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.05,
                                                                                                                      ),
                                                                                                                      Expanded(
                                                                                                                        child: MyText(
                                                                                                                          text: driverReq['drop_address'],
                                                                                                                          // maxLines: 1,
                                                                                                                          size: media.width * twelve,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                ],
                                                                                                              )
                                                                                                            : Container(),
                                                                                                      ],
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.02,
                                                                                                ),
                                                                                                (driverReq['goods_type'] != '-')
                                                                                                    ? MyText(
                                                                                                        text: driverReq['goods_type'].toString(),
                                                                                                        size: media.width * fourteen,
                                                                                                        color: verifyDeclined,
                                                                                                      )
                                                                                                    : Container(),
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.04,
                                                                                                ),
                                                                                                Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                  children: [
                                                                                                    Button(
                                                                                                        color: const Color(0xFFFF0000).withOpacity(0.2),
                                                                                                        width: media.width * 0.38,
                                                                                                        textcolor: const Color(0XFFFF0000),
                                                                                                        onTap: () async {
                                                                                                          setState(() {
                                                                                                            _isLoading = true;
                                                                                                          });
                                                                                                          //reject request
                                                                                                          await requestReject();
                                                                                                          setState(() {
                                                                                                            _isLoading = false;
                                                                                                          });
                                                                                                        },
                                                                                                        text: languages[choosenLanguage]['text_decline']),
                                                                                                    Button(
                                                                                                      onTap: () async {
                                                                                                        setState(() {
                                                                                                          _isLoading = true;
                                                                                                        });
                                                                                                        await requestAccept();
                                                                                                        setState(() {
                                                                                                          _isLoading = false;
                                                                                                        });
                                                                                                      },
                                                                                                      text: languages[choosenLanguage]['text_accept'],
                                                                                                      width: media.width * 0.38,
                                                                                                    )
                                                                                                  ],
                                                                                                )
                                                                                              ],
                                                                                            ),
                                                                                          )
                                                                                        ],
                                                                                      )),
                                                                                ],
                                                                              )
                                                                            : (driverReq['accepted_at'] != null)
                                                                                ? SizedBox(
                                                                                    width: media.width * 0.9,
                                                                                    height: media.width * 0.7,
                                                                                  )
                                                                                : Container(width: media.width * 0.9)
                                                                        : Container(
                                                                            width:
                                                                                media.width * 0.9,
                                                                          ),
                                                              ],
                                                            )),

                                                        //on ride bottom sheet
                                                        (driverReq['accepted_at'] !=
                                                                null)
                                                            ? (driverReq[
                                                                        'transport_type'] ==
                                                                    'taxi')
                                                                ? Positioned(
                                                                    bottom: 0,
                                                                    child:
                                                                        GestureDetector(
                                                                      onVerticalDragStart:
                                                                          (v) {
                                                                        start = v
                                                                            .globalPosition
                                                                            .dy;
                                                                        gesture
                                                                            .clear();
                                                                      },
                                                                      onVerticalDragUpdate:
                                                                          (v) {
                                                                        gesture.add(v
                                                                            .globalPosition
                                                                            .dy);
                                                                      },
                                                                      onVerticalDragEnd:
                                                                          (v) {
                                                                        if (gesture.isNotEmpty &&
                                                                            start >
                                                                                gesture[gesture.length -
                                                                                    1] &&
                                                                            _bottom ==
                                                                                0) {
                                                                          setState(
                                                                              () {
                                                                            _bottom =
                                                                                1;
                                                                          });
                                                                        } else if (gesture.isNotEmpty &&
                                                                            start <
                                                                                gesture[gesture.length - 1] &&
                                                                            _bottom == 1) {
                                                                          setState(
                                                                              () {
                                                                            _bottom =
                                                                                0;
                                                                          });
                                                                        }
                                                                      },
                                                                      child:
                                                                          AnimatedContainer(
                                                                        duration:
                                                                            const Duration(milliseconds: 200),
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.05),
                                                                        width:
                                                                            media.width *
                                                                                1,
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                                            color: page),
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Row(
                                                                                  children: [
                                                                                    Image.asset(
                                                                                        (driverReq['is_driver_arrived'] == 0)
                                                                                            ? 'assets/images/ontheway.png'
                                                                                            : (driverReq['is_trip_start'] == 1)
                                                                                                ? 'assets/images/ontheway_icon.png'
                                                                                                : 'assets/images/startonthe.png',
                                                                                        width: media.width * 0.075,
                                                                                        color: textColor),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.02,
                                                                                    ),
                                                                                    MyText(
                                                                                      text: (driverReq['is_driver_arrived'] == 0)
                                                                                          ? languages[choosenLanguage]['text_in_the_way']
                                                                                          : (driverReq['is_trip_start'] == 1)
                                                                                              ? languages[choosenLanguage]['text_onride']
                                                                                              : languages[choosenLanguage]['text_waiting_rider'],
                                                                                      size: media.width * fourteen,
                                                                                      fontweight: FontWeight.w700,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                (driverReq['is_driver_arrived'] == 1 && waitingTime != null)
                                                                                    ? (waitingTime / 60 >= 1)
                                                                                        ? Container(
                                                                                            padding: EdgeInsets.all(media.width * 0.03),
                                                                                            decoration: BoxDecoration(color: topBar, borderRadius: BorderRadius.circular(media.width * 0.02), border: Border.all(color: Colors.grey.withOpacity(0.5))),
                                                                                            child: (driverReq['accepted_at'] == null && driverReq['show_request_eta_amount'] == true && driverReq['request_eta_amount'] != null)
                                                                                                ? MyText(
                                                                                                    text: userDetails['currency_symbol'] + (driverReq['is_bid_ride'] == 1) ? driverReq['accepted_ride_fare'].toString() : driverReq['request_eta_amount'].toString(),
                                                                                                    size: media.width * fourteen,
                                                                                                    color: isDarkTheme == true ? Colors.black : textColor,
                                                                                                  )
                                                                                                : (driverReq['is_driver_arrived'] == 1 && waitingTime != null)
                                                                                                    ? (waitingTime / 60 >= 1)
                                                                                                        ? MyText(
                                                                                                            text: '${(waitingTime / 60).toInt()} mins',
                                                                                                            size: media.width * fourteen,
                                                                                                            color: isDarkTheme == true ? Colors.black : textColor,
                                                                                                          )
                                                                                                        : Container()
                                                                                                    : Container(),
                                                                                          )
                                                                                        : Container()
                                                                                    : Container(),
                                                                              ],
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.025,
                                                                            ),
                                                                            (driverReq['is_trip_start'] == 1 && _bottom == 0 && driverReq['drop_address'] != null)
                                                                                ? Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    children: [
                                                                                      Container(
                                                                                        height: media.width * 0.06,
                                                                                        width: media.width * 0.06,
                                                                                        alignment: Alignment.center,
                                                                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                        child: Icon(
                                                                                          Icons.location_on_outlined,
                                                                                          color: const Color(0xFFFF0000),
                                                                                          size: media.width * eighteen,
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(
                                                                                        width: media.width * 0.05,
                                                                                      ),
                                                                                      Expanded(
                                                                                        child: MyText(
                                                                                          text: driverReq['drop_address'],
                                                                                          // maxLines: 1,
                                                                                          size: media.width * twelve,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    children: [
                                                                                      Container(
                                                                                        height: media.width * 0.05,
                                                                                        width: media.width * 0.05,
                                                                                        alignment: Alignment.center,
                                                                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                        child: Container(
                                                                                          height: media.width * 0.025,
                                                                                          width: media.width * 0.025,
                                                                                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(
                                                                                        width: media.width * 0.06,
                                                                                      ),
                                                                                      Expanded(
                                                                                        child: MyText(
                                                                                          text: driverReq['pick_address'],
                                                                                          size: media.width * twelve,
                                                                                          // maxLines: 1,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                            SizedBox(
                                                                              height: media.width * 0.02,
                                                                            ),
                                                                            (driverReq['drop_address'] != null && _bottom == 1)
                                                                                ? Column(
                                                                                    children: [
                                                                                      (tripStops.isNotEmpty)
                                                                                          ? Column(
                                                                                              children: tripStops
                                                                                                  .asMap()
                                                                                                  .map((i, value) {
                                                                                                    return MapEntry(
                                                                                                        i,
                                                                                                        (i < tripStops.length - 1)
                                                                                                            ? Container(
                                                                                                                padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                                child: Column(
                                                                                                                  children: [
                                                                                                                    Row(
                                                                                                                      children: [
                                                                                                                        SizedBox(
                                                                                                                          width: media.width * 0.8,
                                                                                                                          child: Row(
                                                                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                            children: [
                                                                                                                              Container(
                                                                                                                                height: media.width * 0.06,
                                                                                                                                width: media.width * 0.06,
                                                                                                                                alignment: Alignment.center,
                                                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                                                child: MyText(
                                                                                                                                  text: (i + 1).toString(),
                                                                                                                                  // maxLines: 1,
                                                                                                                                  color: const Color(0xFFFF0000),
                                                                                                                                  fontweight: FontWeight.w600,
                                                                                                                                  size: media.width * twelve,
                                                                                                                                ),
                                                                                                                              ),
                                                                                                                              SizedBox(
                                                                                                                                width: media.width * 0.05,
                                                                                                                              ),
                                                                                                                              Expanded(
                                                                                                                                child: MyText(
                                                                                                                                  text: tripStops[i]['address'],
                                                                                                                                  // maxLines: 1,
                                                                                                                                  size: media.width * twelve,
                                                                                                                                ),
                                                                                                                              ),
                                                                                                                            ],
                                                                                                                          ),
                                                                                                                        ),
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                ),
                                                                                                              )
                                                                                                            : Container());
                                                                                                  })
                                                                                                  .values
                                                                                                  .toList(),
                                                                                            )
                                                                                          : Container(),
                                                                                      Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        children: [
                                                                                          Container(
                                                                                            height: media.width * 0.06,
                                                                                            width: media.width * 0.06,
                                                                                            alignment: Alignment.center,
                                                                                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                            child: Icon(
                                                                                              Icons.location_on_outlined,
                                                                                              color: const Color(0xFFFF0000),
                                                                                              size: media.width * eighteen,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Expanded(
                                                                                            child: MyText(
                                                                                              text: driverReq['drop_address'],
                                                                                              size: media.width * twelve,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  )
                                                                                : Container(),
                                                                            SizedBox(
                                                                              height: media.width * 0.03,
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.025,
                                                                            ),
                                                                            Column(children: [
                                                                              Container(
                                                                                padding: EdgeInsets.all(media.width * 0.02),
                                                                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: page, boxShadow: [
                                                                                  BoxShadow(blurRadius: 2.0, spreadRadius: 2.0, color: (isDarkTheme == true) ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2))
                                                                                ]),
                                                                                child: Row(
                                                                                  children: [
                                                                                    Container(
                                                                                      height: media.width * 0.15,
                                                                                      width: media.width * 0.15,
                                                                                      decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(driverReq['userDetail']['data']['profile_picture']), fit: BoxFit.cover)),
                                                                                    ),
                                                                                    SizedBox(width: media.width * 0.03),
                                                                                    (driverReq['is_trip_start'] == 1)
                                                                                        ? Row(
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.3,
                                                                                                child: MyText(
                                                                                                  text: driverReq['userDetail']['data']['name'],
                                                                                                  size: media.width * eighteen,
                                                                                                  color: textColor,
                                                                                                  maxLines: 1,
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.09,
                                                                                              ),
                                                                                              Row(
                                                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                                                children: [
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.06,
                                                                                                    child: (driverReq['payment_opt'].toString() == '1')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/cash.png',
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (driverReq['payment_opt'].toString() == '2')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/wallet.png',
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : (driverReq['payment_opt'].toString() == '0')
                                                                                                                ? Image.asset(
                                                                                                                    'assets/images/card.png',
                                                                                                                    fit: BoxFit.contain,
                                                                                                                  )
                                                                                                                : Container(),
                                                                                                  ),
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.03,
                                                                                                  ),
                                                                                                  MyText(text: driverReq['payment_type_string'].toString(), size: media.width * sixteen, color: textColor),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        : SizedBox(
                                                                                            width: media.width * 0.3,
                                                                                            height: media.width * 0.25,
                                                                                            child: Column(
                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                                              children: [
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.3,
                                                                                                  child: MyText(
                                                                                                    text: driverReq['userDetail']['data']['name'],
                                                                                                    size: media.width * eighteen,
                                                                                                    color: textColor,
                                                                                                    maxLines: 1,
                                                                                                  ),
                                                                                                ),
                                                                                                Row(
                                                                                                  children: [
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.06,
                                                                                                      child: (driverReq['payment_opt'].toString() == '1')
                                                                                                          ? Image.asset(
                                                                                                              'assets/images/cash.png',
                                                                                                              fit: BoxFit.contain,
                                                                                                            )
                                                                                                          : (driverReq['payment_opt'].toString() == '2')
                                                                                                              ? Image.asset(
                                                                                                                  'assets/images/wallet.png',
                                                                                                                  fit: BoxFit.contain,
                                                                                                                )
                                                                                                              : (driverReq['payment_opt'].toString() == '0')
                                                                                                                  ? Image.asset(
                                                                                                                      'assets/images/card.png',
                                                                                                                      fit: BoxFit.contain,
                                                                                                                    )
                                                                                                                  : Container(),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.03,
                                                                                                    ),
                                                                                                    MyText(text: driverReq['payment_type_string'].toString(), size: media.width * sixteen, color: textColor),
                                                                                                  ],
                                                                                                ),
                                                                                                Row(
                                                                                                  children: [
                                                                                                    Icon(
                                                                                                      Icons.star,
                                                                                                      color: buttonColor,
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.01,
                                                                                                    ),
                                                                                                    Text(
                                                                                                      driverReq['userDetail']['data']['rating'].toString(),
                                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * sixteen, color: textColor),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                    (driverReq['is_trip_start'] == 1)
                                                                                        ? Container()
                                                                                        : Expanded(
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                              children: [
                                                                                                (driverReq['if_dispatch'] == true)
                                                                                                    ? Container()
                                                                                                    : InkWell(
                                                                                                        onTap: () {
                                                                                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                                                                                                        },
                                                                                                        child: Column(
                                                                                                          children: [
                                                                                                            Row(
                                                                                                              children: [
                                                                                                                Stack(
                                                                                                                  children: [
                                                                                                                    Container(
                                                                                                                      alignment: Alignment.center,
                                                                                                                      height: media.width * 0.096,
                                                                                                                      width: media.width * 0.096,
                                                                                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0XFFf3f3f3), width: 1.5)),
                                                                                                                      child: Image.asset(
                                                                                                                        'assets/images/ridemessage.png',
                                                                                                                        width: media.width * 0.05,
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                    (chatList.where((element) => element['from_type'] == 1 && element['seen'] == 0).isNotEmpty)
                                                                                                                        ? Positioned(
                                                                                                                            right: media.width * 0.01,
                                                                                                                            top: media.width * 0.01,
                                                                                                                            child: MyText(
                                                                                                                              text: chatList.where((element) => element['from_type'] == 1 && element['seen'] == 0).length.toString(),
                                                                                                                              size: media.width * twelve,
                                                                                                                              color: const Color(0xffFF0000),
                                                                                                                            ))
                                                                                                                        : Container()
                                                                                                                  ],
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                InkWell(
                                                                                                  onTap: () {
                                                                                                    makingPhoneCall(driverReq['userDetail']['data']['mobile']);
                                                                                                  },
                                                                                                  child: Container(
                                                                                                    alignment: Alignment.center,
                                                                                                    height: media.width * 0.096,
                                                                                                    width: media.width * 0.096,
                                                                                                    decoration: BoxDecoration(border: Border.all(color: const Color(0XFFf3f3f3), width: 1.5)),
                                                                                                    child: Image.asset(
                                                                                                      'assets/images/callride.png',
                                                                                                      width: media.width * 0.05,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.03,
                                                                              ),
                                                                              (driverReq['is_trip_start'] == 1)
                                                                                  ? Container()
                                                                                  : Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      children: [
                                                                                        InkWell(
                                                                                          onTap: () async {
                                                                                            setState(() {
                                                                                              _isLoading = true;
                                                                                            });
                                                                                            var val = await cancelReason((driverReq['is_driver_arrived'] == 0) ? 'before' : 'after');
                                                                                            if (val == true) {
                                                                                              setState(() {
                                                                                                cancelRequest = true;
                                                                                                _cancelReason = '';
                                                                                                _cancellingError = '';
                                                                                              });
                                                                                            }
                                                                                            setState(() {
                                                                                              _isLoading = false;
                                                                                            });
                                                                                          },
                                                                                          child: Row(
                                                                                            children: [
                                                                                              Image.asset(
                                                                                                'assets/images/cancelride.png',
                                                                                                height: media.width * 0.064,
                                                                                                width: media.width * 0.064,
                                                                                                fit: BoxFit.contain,
                                                                                                color: verifyDeclined,
                                                                                              ),
                                                                                              MyText(
                                                                                                text: languages[choosenLanguage]['text_cancel_booking'],
                                                                                                size: media.width * twelve,
                                                                                                color: verifyDeclined,
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                            ]),
                                                                            SizedBox(
                                                                              height: media.width * 0.03,
                                                                            ),
                                                                            Button(
                                                                                onTap: () async {
                                                                                  navigationtype = false;
                                                                                  setState(() {
                                                                                    _isLoading = true;
                                                                                  });
                                                                                  if ((driverReq['is_driver_arrived'] == 0)) {
                                                                                    var val = await driverArrived();
                                                                                    if (val == 'logout') {
                                                                                      navigateLogout();
                                                                                    }
                                                                                  } else if (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0) {
                                                                                    if (driverReq['show_otp_feature'] == true) {
                                                                                      setState(() {
                                                                                        getStartOtp = true;
                                                                                      });
                                                                                    } else {
                                                                                      var val = await tripStartDispatcher();
                                                                                      if (val == 'logout') {
                                                                                        navigateLogout();
                                                                                      }
                                                                                    }
                                                                                  } else {
                                                                                    driverOtp = '';
                                                                                    var val = await endTrip();
                                                                                    if (val == 'logout') {
                                                                                      navigateLogout();
                                                                                    }
                                                                                  }

                                                                                  _isLoading = false;
                                                                                },
                                                                                text: (driverReq['is_driver_arrived'] == 0)
                                                                                    ? languages[choosenLanguage]['text_arrived']
                                                                                    : (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0)
                                                                                        ? languages[choosenLanguage]['text_startride']
                                                                                        : languages[choosenLanguage]['text_endtrip'])
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ))
                                                                : Positioned(
                                                                    bottom: 0,
                                                                    child:
                                                                        GestureDetector(
                                                                      onVerticalDragStart:
                                                                          (v) {
                                                                        start = v
                                                                            .globalPosition
                                                                            .dy;
                                                                        gesture
                                                                            .clear();
                                                                      },
                                                                      onVerticalDragUpdate:
                                                                          (v) {
                                                                        gesture.add(v
                                                                            .globalPosition
                                                                            .dy);
                                                                      },
                                                                      onVerticalDragEnd:
                                                                          (v) {
                                                                        if (gesture.isNotEmpty &&
                                                                            start >
                                                                                gesture[gesture.length -
                                                                                    1] &&
                                                                            _bottom ==
                                                                                0) {
                                                                          setState(
                                                                              () {
                                                                            _bottom =
                                                                                1;
                                                                          });
                                                                        } else if (gesture.isNotEmpty &&
                                                                            start <
                                                                                gesture[gesture.length - 1] &&
                                                                            _bottom == 1) {
                                                                          setState(
                                                                              () {
                                                                            _bottom =
                                                                                0;
                                                                          });
                                                                        }
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        // duration:
                                                                        //     const Duration(milliseconds: 200),
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.05),
                                                                        width:
                                                                            media.width *
                                                                                1,
                                                                        decoration: BoxDecoration(
                                                                            borderRadius:
                                                                                const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                                            color: page),
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            SizedBox(
                                                                              height: media.width * 0.025,
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Row(
                                                                                  children: [
                                                                                    Image.asset(
                                                                                        (driverReq['is_driver_arrived'] == 0)
                                                                                            ? 'assets/images/ontheway.png'
                                                                                            : (driverReq['is_trip_start'] == 1)
                                                                                                ? 'assets/images/ontheway_icon.png'
                                                                                                : 'assets/images/startonthe.png',
                                                                                        width: media.width * 0.075,
                                                                                        color: textColor),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.02,
                                                                                    ),
                                                                                    MyText(
                                                                                      text: (driverReq['is_driver_arrived'] == 0)
                                                                                          ? languages[choosenLanguage]['text_in_the_way']
                                                                                          : (driverReq['is_trip_start'] == 1)
                                                                                              ? languages[choosenLanguage]['text_on_ride']
                                                                                              : languages[choosenLanguage]['text_waiting_rider'],
                                                                                      size: media.width * fourteen,
                                                                                      fontweight: FontWeight.w700,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                                (driverReq['is_driver_arrived'] == 1 && waitingTime != null)
                                                                                    ? (waitingTime / 60 >= 1)
                                                                                        ? Container(
                                                                                            padding: EdgeInsets.all(media.width * 0.03),
                                                                                            decoration: BoxDecoration(color: topBar, borderRadius: BorderRadius.circular(media.width * 0.02), border: Border.all(color: Colors.grey.withOpacity(0.5))),
                                                                                            child: (driverReq['accepted_at'] == null && driverReq['show_request_eta_amount'] == true && driverReq['request_eta_amount'] != null)
                                                                                                ? MyText(
                                                                                                    text: userDetails['currency_symbol'] + (driverReq['is_bid_ride'] == 1) ? driverReq['accepted_ride_fare'].toString() : driverReq['request_eta_amount'].toString(),
                                                                                                    size: media.width * fourteen,
                                                                                                    color: isDarkTheme == true ? Colors.black : textColor,
                                                                                                  )
                                                                                                : (driverReq['is_driver_arrived'] == 1 && waitingTime != null)
                                                                                                    ? (waitingTime / 60 >= 1)
                                                                                                        ? MyText(
                                                                                                            text: '${(waitingTime / 60).toInt()} mins',
                                                                                                            size: media.width * fourteen,
                                                                                                            color: isDarkTheme == true ? Colors.black : textColor,
                                                                                                          )
                                                                                                        : Container()
                                                                                                    : Container(),
                                                                                          )
                                                                                        : Container()
                                                                                    : Container(),
                                                                              ],
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.05,
                                                                            ),
                                                                            (_bottom != 0)
                                                                                ? SizedBox(
                                                                                    // duration: const Duration(milliseconds: 200),
                                                                                    height: media.height * 0.4,
                                                                                    child: SingleChildScrollView(
                                                                                      physics: const BouncingScrollPhysics(),
                                                                                      child: Column(
                                                                                        children: [
                                                                                          SizedBox(
                                                                                            height: media.width * 0.02,
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.9,
                                                                                            child: Text(
                                                                                              '${driverReq['goods_type']} - ${driverReq['goods_type_quantity']}',
                                                                                              style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: buttonColor),
                                                                                              textAlign: TextAlign.center,
                                                                                              maxLines: 1,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            height: media.width * 0.02,
                                                                                          ),
                                                                                          Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                                            children: [
                                                                                              Container(
                                                                                                height: media.width * 0.05,
                                                                                                width: media.width * 0.05,
                                                                                                alignment: Alignment.center,
                                                                                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                                child: Container(
                                                                                                  height: media.width * 0.025,
                                                                                                  width: media.width * 0.025,
                                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.06,
                                                                                              ),
                                                                                              Expanded(
                                                                                                child: MyText(
                                                                                                  text: driverReq['pick_address'],
                                                                                                  size: media.width * twelve,
                                                                                                  // maxLines: 1,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          (driverReq['pickup_poc_instruction'] != null)
                                                                                              ? Container(
                                                                                                  padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                  child: Row(
                                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                                    children: [
                                                                                                      SizedBox(
                                                                                                        width: media.width * 0.1,
                                                                                                      ),
                                                                                                      SizedBox(
                                                                                                        width: media.width * 0.7,
                                                                                                        child: Text(
                                                                                                          ' ${languages[choosenLanguage]['text_instructions']} : ${driverReq['pickup_poc_instruction']}',
                                                                                                          style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xFFFF0000), fontWeight: FontWeight.w600),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ],
                                                                                                  ))
                                                                                              : Container(),
                                                                                          (tripStops.isNotEmpty)
                                                                                              ? Column(
                                                                                                  children: tripStops
                                                                                                      .asMap()
                                                                                                      .map((i, value) {
                                                                                                        return MapEntry(
                                                                                                            i,
                                                                                                            (i < tripStops.length - 1)
                                                                                                                ? Container(
                                                                                                                    padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                                    child: Column(
                                                                                                                      children: [
                                                                                                                        Row(
                                                                                                                          children: [
                                                                                                                            SizedBox(
                                                                                                                              width: media.width * 0.8,
                                                                                                                              child: Column(
                                                                                                                                children: [
                                                                                                                                  Row(
                                                                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                                    children: [
                                                                                                                                      Container(
                                                                                                                                        height: media.width * 0.06,
                                                                                                                                        width: media.width * 0.06,
                                                                                                                                        alignment: Alignment.center,
                                                                                                                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                                                        child: MyText(
                                                                                                                                          text: (i + 1).toString(),
                                                                                                                                          // maxLines: 1,
                                                                                                                                          color: const Color(0xFFFF0000),
                                                                                                                                          fontweight: FontWeight.w600,
                                                                                                                                          size: media.width * twelve,
                                                                                                                                        ),
                                                                                                                                      ),
                                                                                                                                      SizedBox(
                                                                                                                                        width: media.width * 0.05,
                                                                                                                                      ),
                                                                                                                                      Expanded(
                                                                                                                                        child: MyText(
                                                                                                                                          text: tripStops[i]['address'],
                                                                                                                                          // maxLines: 1,
                                                                                                                                          size: media.width * twelve,
                                                                                                                                        ),
                                                                                                                                      ),
                                                                                                                                    ],
                                                                                                                                  ),
                                                                                                                                ],
                                                                                                                              ),
                                                                                                                            ),
                                                                                                                            // SizedBox(width: media.width * 0.05),
                                                                                                                            (driverReq['is_trip_start'] == 1)
                                                                                                                                ? InkWell(
                                                                                                                                    onTap: () {
                                                                                                                                      makingPhoneCall(tripStops[i]['poc_mobile']);
                                                                                                                                    },
                                                                                                                                    child: Image.asset(
                                                                                                                                      'assets/images/Call.png',
                                                                                                                                      width: media.width * 0.05,
                                                                                                                                      color: textColor,
                                                                                                                                    ))
                                                                                                                                : Container(),
                                                                                                                          ],
                                                                                                                        ),
                                                                                                                        (tripStops[i]['poc_instruction'] != null)
                                                                                                                            ? Container(
                                                                                                                                padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                                                child: Row(
                                                                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                                  children: [
                                                                                                                                    SizedBox(
                                                                                                                                      width: media.width * 0.1,
                                                                                                                                    ),
                                                                                                                                    SizedBox(
                                                                                                                                      width: media.width * 0.7,
                                                                                                                                      child: Text(
                                                                                                                                        '${languages[choosenLanguage]['text_instructions']} : ${tripStops[i]['poc_instruction']}',
                                                                                                                                        style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xFFFF0000), fontWeight: FontWeight.w600),
                                                                                                                                      ),
                                                                                                                                    ),
                                                                                                                                  ],
                                                                                                                                ))
                                                                                                                            : Container(),
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                  )
                                                                                                                : Container());
                                                                                                      })
                                                                                                      .values
                                                                                                      .toList(),
                                                                                                )
                                                                                              : Container(),
                                                                                          SizedBox(height: media.width * 0.02),
                                                                                          (driverReq['is_rental'] != true)
                                                                                              ? driverReq['transport_type'] == 'delivery'
                                                                                                  ? Container(
                                                                                                      padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                      child: Column(
                                                                                                        children: [
                                                                                                          (tripStops.isNotEmpty)
                                                                                                              ? Row(
                                                                                                                  children: [
                                                                                                                    SizedBox(
                                                                                                                      width: media.width * 0.8,
                                                                                                                      child: Column(
                                                                                                                        children: [
                                                                                                                          Row(
                                                                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                            children: [
                                                                                                                              Container(
                                                                                                                                height: media.width * 0.06,
                                                                                                                                width: media.width * 0.06,
                                                                                                                                alignment: Alignment.center,
                                                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                                                child: Icon(
                                                                                                                                  Icons.location_on_outlined,
                                                                                                                                  color: const Color(0xFFFF0000),
                                                                                                                                  size: media.width * eighteen,
                                                                                                                                ),
                                                                                                                              ),
                                                                                                                              SizedBox(
                                                                                                                                width: media.width * 0.05,
                                                                                                                              ),
                                                                                                                              Expanded(
                                                                                                                                child: MyText(
                                                                                                                                  text: tripStops[tripStops.length - 1]['address'],
                                                                                                                                  // maxLines: 1,
                                                                                                                                  size: media.width * twelve,
                                                                                                                                ),
                                                                                                                              ),
                                                                                                                            ],
                                                                                                                          ),
                                                                                                                        ],
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                    (driverReq['is_trip_start'] == 1)
                                                                                                                        ? InkWell(
                                                                                                                            onTap: () {
                                                                                                                              makingPhoneCall(tripStops[tripStops.length - 1]['poc_mobile']);
                                                                                                                            },
                                                                                                                            child: Image.asset(
                                                                                                                              'assets/images/Call.png',
                                                                                                                              width: media.width * 0.05,
                                                                                                                              color: textColor,
                                                                                                                            ))
                                                                                                                        : Container(),
                                                                                                                  ],
                                                                                                                )
                                                                                                              : Container(),
                                                                                                          (tripStops.isNotEmpty && tripStops[tripStops.length - 1]['poc_instruction'] != null)
                                                                                                              ? Container(
                                                                                                                  padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                                  child: Row(
                                                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                    children: [
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.1,
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.7,
                                                                                                                        child: Text(
                                                                                                                          '${languages[choosenLanguage]['text_instructions']}  :  ${tripStops[tripStops.length - 1]['poc_instruction']}',
                                                                                                                          style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xFFFF0000), fontWeight: FontWeight.w600),
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ))
                                                                                                              : Container(),
                                                                                                          (tripStops.isEmpty)
                                                                                                              ? Column(
                                                                                                                  children: [
                                                                                                                    Row(
                                                                                                                      children: [
                                                                                                                        SizedBox(
                                                                                                                          width: media.width * 0.8,
                                                                                                                          child: Column(
                                                                                                                            children: [
                                                                                                                              Row(
                                                                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                                children: [
                                                                                                                                  Container(
                                                                                                                                    height: media.width * 0.06,
                                                                                                                                    width: media.width * 0.06,
                                                                                                                                    alignment: Alignment.center,
                                                                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                                                    child: Icon(
                                                                                                                                      Icons.location_on_outlined,
                                                                                                                                      color: const Color(0xFFFF0000),
                                                                                                                                      size: media.width * eighteen,
                                                                                                                                    ),
                                                                                                                                  ),
                                                                                                                                  SizedBox(
                                                                                                                                    width: media.width * 0.05,
                                                                                                                                  ),
                                                                                                                                  Expanded(
                                                                                                                                    child: MyText(
                                                                                                                                      text: driverReq['drop_address'],
                                                                                                                                      // maxLines: 1,
                                                                                                                                      size: media.width * twelve,
                                                                                                                                    ),
                                                                                                                                  ),
                                                                                                                                ],
                                                                                                                              ),
                                                                                                                            ],
                                                                                                                          ),
                                                                                                                        ),
                                                                                                                        (driverReq['is_trip_start'] == 1)
                                                                                                                            ? InkWell(
                                                                                                                                onTap: () {
                                                                                                                                  makingPhoneCall(driverReq['drop_poc_mobile']);
                                                                                                                                },
                                                                                                                                child: Image.asset(
                                                                                                                                  'assets/images/Call.png',
                                                                                                                                  width: media.width * 0.05,
                                                                                                                                  color: textColor,
                                                                                                                                ))
                                                                                                                            : Container(),
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                    (driverReq['drop_poc_instruction'] != null)
                                                                                                                        ? Container(
                                                                                                                            padding: EdgeInsets.only(top: media.width * 0.02),
                                                                                                                            child: Row(
                                                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                              children: [
                                                                                                                                SizedBox(
                                                                                                                                  width: media.width * 0.1,
                                                                                                                                ),
                                                                                                                                SizedBox(
                                                                                                                                  width: media.width * 0.7,
                                                                                                                                  child: Text(
                                                                                                                                    '${languages[choosenLanguage]['text_instructions']} : ${driverReq['drop_poc_instruction']}',
                                                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xFFFF0000), fontWeight: FontWeight.w600),
                                                                                                                                  ),
                                                                                                                                ),
                                                                                                                              ],
                                                                                                                            ))
                                                                                                                        : Container(),
                                                                                                                  ],
                                                                                                                )
                                                                                                              : Container()
                                                                                                        ],
                                                                                                      ),
                                                                                                    )
                                                                                                  : Row(
                                                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                                                      children: [
                                                                                                        Container(
                                                                                                          height: media.width * 0.06,
                                                                                                          width: media.width * 0.06,
                                                                                                          alignment: Alignment.center,
                                                                                                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                          child: Icon(
                                                                                                            Icons.location_on_outlined,
                                                                                                            color: const Color(0xFFFF0000),
                                                                                                            size: media.width * eighteen,
                                                                                                          ),
                                                                                                        ),
                                                                                                        SizedBox(
                                                                                                          width: media.width * 0.05,
                                                                                                        ),
                                                                                                        Expanded(
                                                                                                          child: MyText(
                                                                                                            text: driverReq['drop_address'],
                                                                                                            // maxLines: 1,
                                                                                                            size: media.width * twelve,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ],
                                                                                                    )
                                                                                              : Container(),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                : Container(),
                                                                            (driverReq['is_trip_start'] == 0)
                                                                                ? Column(
                                                                                    children: [
                                                                                      (_bottom == 0)
                                                                                          ? Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                                              children: [
                                                                                                Container(
                                                                                                  height: media.width * 0.05,
                                                                                                  width: media.width * 0.05,
                                                                                                  alignment: Alignment.center,
                                                                                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                                  child: Container(
                                                                                                    height: media.width * 0.025,
                                                                                                    width: media.width * 0.025,
                                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                                  ),
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.06,
                                                                                                ),
                                                                                                Expanded(
                                                                                                  child: MyText(
                                                                                                    text: driverReq['pick_address'],
                                                                                                    size: media.width * twelve,
                                                                                                    // maxLines: 1,
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            )
                                                                                          : Container(),
                                                                                    ],
                                                                                  )
                                                                                : (_bottom == 0 && driverReq['is_trip_start'] == 1 && driverReq['is_rental'] != true)
                                                                                    ? Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        children: [
                                                                                          Container(
                                                                                            height: media.width * 0.06,
                                                                                            width: media.width * 0.06,
                                                                                            alignment: Alignment.center,
                                                                                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                            child: Icon(
                                                                                              Icons.location_on_outlined,
                                                                                              color: const Color(0xFFFF0000),
                                                                                              size: media.width * eighteen,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Expanded(
                                                                                            child: MyText(
                                                                                              text: driverReq['drop_address'],
                                                                                              // maxLines: 1,
                                                                                              size: media.width * twelve,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      )
                                                                                    : (_bottom == 0)
                                                                                        ? Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                                            children: [
                                                                                              Container(
                                                                                                height: media.width * 0.05,
                                                                                                width: media.width * 0.05,
                                                                                                alignment: Alignment.center,
                                                                                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                                                                                child: Container(
                                                                                                  height: media.width * 0.025,
                                                                                                  width: media.width * 0.025,
                                                                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.06,
                                                                                              ),
                                                                                              Expanded(
                                                                                                child: MyText(
                                                                                                  text: driverReq['pick_address'],
                                                                                                  size: media.width * twelve,
                                                                                                  // maxLines: 1,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          )
                                                                                        : Container(),
                                                                            SizedBox(
                                                                              height: media.width * 0.02,
                                                                            ),
                                                                            Container(
                                                                              padding: EdgeInsets.all(media.width * 0.02),
                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: page, boxShadow: [
                                                                                BoxShadow(blurRadius: 2.0, spreadRadius: 2.0, color: (isDarkTheme == true) ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2))
                                                                              ]),
                                                                              child: Row(
                                                                                children: [
                                                                                  Container(
                                                                                    height: media.width * 0.15,
                                                                                    width: media.width * 0.15,
                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(driverReq['userDetail']['data']['profile_picture']), fit: BoxFit.cover)),
                                                                                  ),
                                                                                  SizedBox(width: media.width * 0.03),
                                                                                  (driverReq['is_trip_start'] == 1)
                                                                                      ? Row(
                                                                                          children: [
                                                                                            SizedBox(
                                                                                              width: media.width * 0.3,
                                                                                              child: MyText(
                                                                                                text: driverReq['userDetail']['data']['name'],
                                                                                                size: media.width * eighteen,
                                                                                                color: textColor,
                                                                                                maxLines: 1,
                                                                                              ),
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width: media.width * 0.09,
                                                                                            ),
                                                                                            Column(
                                                                                              children: [
                                                                                                (driverReq['is_bid_ride'] == 1)
                                                                                                    ? MyText(
                                                                                                        text: '${userDetails['currency_symbol']} ${driverReq['accepted_ride_fare'].toString()}',
                                                                                                        size: media.width * eighteen,
                                                                                                        color: textColor,
                                                                                                      )
                                                                                                    : MyText(
                                                                                                        text: '${userDetails['currency_symbol']}  ${driverReq['request_eta_amount'].toString()}',
                                                                                                        size: media.width * eighteen,
                                                                                                        color: textColor,
                                                                                                        maxLines: 1,
                                                                                                      ),
                                                                                                Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                  children: [
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.06,
                                                                                                      child: (driverReq['payment_opt'].toString() == '1')
                                                                                                          ? Image.asset(
                                                                                                              'assets/images/cash.png',
                                                                                                              fit: BoxFit.contain,
                                                                                                            )
                                                                                                          : (driverReq['payment_opt'].toString() == '2')
                                                                                                              ? Image.asset(
                                                                                                                  'assets/images/wallet.png',
                                                                                                                  fit: BoxFit.contain,
                                                                                                                )
                                                                                                              : (driverReq['payment_opt'].toString() == '0')
                                                                                                                  ? Image.asset(
                                                                                                                      'assets/images/card.png',
                                                                                                                      fit: BoxFit.contain,
                                                                                                                    )
                                                                                                                  : Container(),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.03,
                                                                                                    ),
                                                                                                    MyText(text: driverReq['payment_type_string'].toString(), size: media.width * sixteen, color: textColor),
                                                                                                  ],
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ],
                                                                                        )
                                                                                      : SizedBox(
                                                                                          width: media.width * 0.3,
                                                                                          height: media.width * 0.25,
                                                                                          child: Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.3,
                                                                                                child: MyText(
                                                                                                  text: driverReq['userDetail']['data']['name'],
                                                                                                  size: media.width * eighteen,
                                                                                                  color: textColor,
                                                                                                  maxLines: 1,
                                                                                                ),
                                                                                              ),
                                                                                              Row(
                                                                                                children: [
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.06,
                                                                                                    child: (driverReq['payment_opt'].toString() == '1')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/cash.png',
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (driverReq['payment_opt'].toString() == '2')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/wallet.png',
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : (driverReq['payment_opt'].toString() == '0')
                                                                                                                ? Image.asset(
                                                                                                                    'assets/images/card.png',
                                                                                                                    fit: BoxFit.contain,
                                                                                                                  )
                                                                                                                : Container(),
                                                                                                  ),
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.03,
                                                                                                  ),
                                                                                                  MyText(text: driverReq['payment_type_string'].toString(), size: media.width * sixteen, color: textColor),
                                                                                                ],
                                                                                              ),
                                                                                              Row(
                                                                                                children: [
                                                                                                  Icon(
                                                                                                    Icons.star,
                                                                                                    color: buttonColor,
                                                                                                  ),
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.01,
                                                                                                  ),
                                                                                                  Text(
                                                                                                    driverReq['userDetail']['data']['rating'].toString(),
                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * sixteen, color: textColor),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                  (driverReq['is_trip_start'] == 1)
                                                                                      ? Container()
                                                                                      : Expanded(
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                            children: [
                                                                                              (driverReq['if_dispatch'] == true)
                                                                                                  ? Container()
                                                                                                  : InkWell(
                                                                                                      onTap: () {
                                                                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                                                                                                      },
                                                                                                      child: Column(
                                                                                                        children: [
                                                                                                          Row(
                                                                                                            children: [
                                                                                                              Stack(
                                                                                                                children: [
                                                                                                                  Container(
                                                                                                                    alignment: Alignment.center,
                                                                                                                    height: media.width * 0.096,
                                                                                                                    width: media.width * 0.096,
                                                                                                                    decoration: BoxDecoration(border: Border.all(color: const Color(0XFFf3f3f3), width: 1.5)),
                                                                                                                    child: Image.asset(
                                                                                                                      'assets/images/ridemessage.png',
                                                                                                                      width: media.width * 0.05,
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                  (chatList.where((element) => element['from_type'] == 1 && element['seen'] == 0).isNotEmpty)
                                                                                                                      ? Positioned(
                                                                                                                          right: media.width * 0.01,
                                                                                                                          top: media.width * 0.01,
                                                                                                                          child: MyText(
                                                                                                                            text: chatList.where((element) => element['from_type'] == 1 && element['seen'] == 0).length.toString(),
                                                                                                                            size: media.width * twelve,
                                                                                                                            color: const Color(0xffFF0000),
                                                                                                                          ))
                                                                                                                      : Container()
                                                                                                                ],
                                                                                                              ),
                                                                                                            ],
                                                                                                          ),
                                                                                                        ],
                                                                                                      ),
                                                                                                    ),
                                                                                              InkWell(
                                                                                                onTap: () {
                                                                                                  makingPhoneCall(driverReq['userDetail']['data']['mobile']);
                                                                                                },
                                                                                                child: Container(
                                                                                                  alignment: Alignment.center,
                                                                                                  height: media.width * 0.096,
                                                                                                  width: media.width * 0.096,
                                                                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0XFFf3f3f3), width: 1.5)),
                                                                                                  child: Image.asset(
                                                                                                    'assets/images/callride.png',
                                                                                                    width: media.width * 0.05,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.03,
                                                                            ),
                                                                            (driverReq['is_trip_start'] == 1)
                                                                                ? Container()
                                                                                : Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                    children: [
                                                                                      InkWell(
                                                                                        onTap: () async {
                                                                                          setState(() {
                                                                                            _isLoading = true;
                                                                                          });
                                                                                          var val = await cancelReason((driverReq['is_driver_arrived'] == 0) ? 'before' : 'after');
                                                                                          if (val == true) {
                                                                                            setState(() {
                                                                                              cancelRequest = true;
                                                                                              _cancelReason = '';
                                                                                              _cancellingError = '';
                                                                                            });
                                                                                          }
                                                                                          setState(() {
                                                                                            _isLoading = false;
                                                                                          });
                                                                                        },
                                                                                        child: Row(
                                                                                          children: [
                                                                                            Image.asset(
                                                                                              'assets/images/cancelride.png',
                                                                                              height: media.width * 0.064,
                                                                                              width: media.width * 0.064,
                                                                                              fit: BoxFit.contain,
                                                                                              color: verifyDeclined,
                                                                                            ),
                                                                                            MyText(
                                                                                              text: languages[choosenLanguage]['text_cancel_booking'],
                                                                                              size: media.width * twelve,
                                                                                              color: verifyDeclined,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                            SizedBox(
                                                                              height: media.width * 0.03,
                                                                            ),
                                                                            Button(
                                                                                onTap: () async {
                                                                                  navigationtype = false;
                                                                                  setState(() {
                                                                                    _isLoading = true;
                                                                                  });
                                                                                  if ((driverReq['is_driver_arrived'] == 0)) {
                                                                                    var val = await driverArrived();
                                                                                    if (val == 'logout') {
                                                                                      navigateLogout();
                                                                                    }
                                                                                  } else if (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0) {
                                                                                    if (driverReq['show_otp_feature'] == false && driverReq['enable_shipment_load_feature'].toString() == '0') {
                                                                                      var val = await tripStartDispatcher();
                                                                                      if (val == 'logout') {
                                                                                        navigateLogout();
                                                                                      }
                                                                                    } else {
                                                                                      setState(() {
                                                                                        shipLoadImage = null;
                                                                                        _errorOtp = false;
                                                                                        getStartOtp = true;
                                                                                      });
                                                                                    }
                                                                                  } else {
                                                                                    if (driverReq['enable_shipment_unload_feature'].toString() == '1') {
                                                                                      setState(() {
                                                                                        unloadImage = true;
                                                                                      });
                                                                                    } else if (driverReq['enable_shipment_unload_feature'].toString() == '0' && driverReq['enable_digital_signature'].toString() == '1') {
                                                                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DigitalSignature()));
                                                                                    } else {
                                                                                      var val = await endTrip();
                                                                                      if (val == 'logout') {
                                                                                        navigateLogout();
                                                                                      }
                                                                                    }
                                                                                  }

                                                                                  _isLoading = false;
                                                                                },
                                                                                text: (driverReq['is_driver_arrived'] == 0)
                                                                                    ? languages[choosenLanguage]['text_arrived']
                                                                                    : (driverReq['is_driver_arrived'] == 1 && driverReq['is_trip_start'] == 0)
                                                                                        ? languages[choosenLanguage]['text_shipment_load']
                                                                                        : languages[choosenLanguage]['text_shipment_unload'])
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ))
                                                            : Container(),

                                                        //user cancelled request popup
                                                        (_reqCancelled == true)
                                                            ? Positioned(
                                                                bottom: media
                                                                        .height *
                                                                    0.5,
                                                                child:
                                                                    Container(
                                                                  padding: EdgeInsets
                                                                      .all(media
                                                                              .width *
                                                                          0.05),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(10),
                                                                      color: page,
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                            color: Colors.black.withOpacity(
                                                                                0.2),
                                                                            blurRadius:
                                                                                2,
                                                                            spreadRadius:
                                                                                2)
                                                                      ]),
                                                                  child: Text(languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_user_cancelled_request']),
                                                                ))
                                                            : Container(),
                                                      ],
                                                    )
                                                  : Container(),
                                    ]),
                              ),
                              (_locationDenied == true)
                                  ? Positioned(
                                      child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _locationDenied = false;
                                                    });
                                                  },
                                                  child: Container(
                                                    height: media.height * 0.05,
                                                    width: media.height * 0.05,
                                                    decoration: BoxDecoration(
                                                      color: page,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.cancel,
                                                        color: buttonColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.025),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page,
                                                boxShadow: [
                                                  BoxShadow(
                                                      blurRadius: 2.0,
                                                      spreadRadius: 2.0,
                                                      color: Colors.black
                                                          .withOpacity(0.2))
                                                ]),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                    width: media.width * 0.8,
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                          [
                                                          'text_open_loc_settings'],
                                                      style:
                                                          GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    )),
                                                SizedBox(
                                                    height: media.width * 0.05),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    InkWell(
                                                        onTap: () async {
                                                          await perm
                                                              .openAppSettings();
                                                        },
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_open_settings'],
                                                          style: GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color:
                                                                  buttonColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        )),
                                                    InkWell(
                                                        onTap: () async {
                                                          setState(() {
                                                            _locationDenied =
                                                                false;
                                                            _isLoading = true;
                                                          });

                                                          getLocs();
                                                        },
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              ['text_done'],
                                                          style: GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color:
                                                                  buttonColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ))
                                                  ],
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                  : Container(),
                              //enter otp
                              (getStartOtp == true &&
                                      driverReq.isNotEmpty &&
                                      driverReq['enable_shipment_load_feature']
                                              .toString() !=
                                          '1')
                                  ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color:
                                            Colors.transparent.withOpacity(0.5),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.8,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        getStartOtp = false;
                                                      });
                                                    },
                                                    child: Container(
                                                      height:
                                                          media.height * 0.05,
                                                      width:
                                                          media.height * 0.05,
                                                      decoration: BoxDecoration(
                                                        color: page,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(Icons.cancel,
                                                          color: buttonColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                                height: media.width * 0.025),
                                            Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              width: media.width * 0.8,
                                              height: media.width * 0.7,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: page,
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        spreadRadius: 2,
                                                        blurRadius: 2)
                                                  ]),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    languages[choosenLanguage]
                                                        ['text_driver_otp'],
                                                    style: GoogleFonts.notoSans(
                                                        fontSize: media.width *
                                                            eighteen,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textColor),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          media.width * 0.05),
                                                  Text(
                                                    languages[choosenLanguage]
                                                        ['text_enterdriverotp'],
                                                    style: GoogleFonts.notoSans(
                                                      fontSize:
                                                          media.width * twelve,
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      Container(
                                                        alignment:
                                                            Alignment.center,
                                                        width:
                                                            media.width * 0.12,
                                                        color: page,
                                                        child: TextFormField(
                                                          onChanged: (val) {
                                                            if (val.length ==
                                                                1) {
                                                              setState(() {
                                                                _otp1 = val;
                                                                driverOtp =
                                                                    _otp1 +
                                                                        _otp2 +
                                                                        _otp3 +
                                                                        _otp4;
                                                                FocusScope.of(
                                                                        context)
                                                                    .nextFocus();
                                                              });
                                                            }
                                                          },
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          maxLength: 1,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      textColor),
                                                          decoration: const InputDecoration(
                                                              counterText: '',
                                                              border: UnderlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      color: Colors
                                                                          .black,
                                                                      width:
                                                                          1.5,
                                                                      style: BorderStyle
                                                                          .solid))),
                                                        ),
                                                      ),
                                                      Container(
                                                        alignment:
                                                            Alignment.center,
                                                        width:
                                                            media.width * 0.12,
                                                        color: page,
                                                        child: TextFormField(
                                                          onChanged: (val) {
                                                            if (val.length ==
                                                                1) {
                                                              setState(() {
                                                                _otp2 = val;
                                                                driverOtp =
                                                                    _otp1 +
                                                                        _otp2 +
                                                                        _otp3 +
                                                                        _otp4;
                                                                FocusScope.of(
                                                                        context)
                                                                    .nextFocus();
                                                              });
                                                            } else {
                                                              setState(() {
                                                                FocusScope.of(
                                                                        context)
                                                                    .previousFocus();
                                                              });
                                                            }
                                                          },
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      textColor),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          maxLength: 1,
                                                          textAlign:
                                                              TextAlign.center,
                                                          decoration: const InputDecoration(
                                                              counterText: '',
                                                              border: UnderlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      color: Colors
                                                                          .black,
                                                                      width:
                                                                          1.5,
                                                                      style: BorderStyle
                                                                          .solid))),
                                                        ),
                                                      ),
                                                      Container(
                                                        alignment:
                                                            Alignment.center,
                                                        width:
                                                            media.width * 0.12,
                                                        color: page,
                                                        child: TextFormField(
                                                          onChanged: (val) {
                                                            if (val.length ==
                                                                1) {
                                                              setState(() {
                                                                _otp3 = val;
                                                                driverOtp =
                                                                    _otp1 +
                                                                        _otp2 +
                                                                        _otp3 +
                                                                        _otp4;
                                                                FocusScope.of(
                                                                        context)
                                                                    .nextFocus();
                                                              });
                                                            } else {
                                                              setState(() {
                                                                FocusScope.of(
                                                                        context)
                                                                    .previousFocus();
                                                              });
                                                            }
                                                          },
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      textColor),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          maxLength: 1,
                                                          textAlign:
                                                              TextAlign.center,
                                                          decoration: const InputDecoration(
                                                              counterText: '',
                                                              border: UnderlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      color: Colors
                                                                          .black,
                                                                      width:
                                                                          1.5,
                                                                      style: BorderStyle
                                                                          .solid))),
                                                        ),
                                                      ),
                                                      Container(
                                                        alignment:
                                                            Alignment.center,
                                                        width:
                                                            media.width * 0.12,
                                                        color: page,
                                                        child: TextFormField(
                                                          onChanged: (val) {
                                                            if (val.length ==
                                                                1) {
                                                              setState(() {
                                                                _otp4 = val;
                                                                driverOtp =
                                                                    _otp1 +
                                                                        _otp2 +
                                                                        _otp3 +
                                                                        _otp4;
                                                                FocusScope.of(
                                                                        context)
                                                                    .nextFocus();
                                                              });
                                                            } else {
                                                              setState(() {
                                                                FocusScope.of(
                                                                        context)
                                                                    .previousFocus();
                                                              });
                                                            }
                                                          },
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      textColor),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          maxLength: 1,
                                                          textAlign:
                                                              TextAlign.center,
                                                          decoration: const InputDecoration(
                                                              counterText: '',
                                                              border: UnderlineInputBorder(
                                                                  borderSide: BorderSide(
                                                                      color: Colors
                                                                          .black,
                                                                      width:
                                                                          1.5,
                                                                      style: BorderStyle
                                                                          .solid))),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.04,
                                                  ),
                                                  (_errorOtp == true)
                                                      ? Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_error_trip_otp'],
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  color: Colors
                                                                      .red,
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve),
                                                        )
                                                      : Container(),
                                                  SizedBox(
                                                      height:
                                                          media.width * 0.02),
                                                  Button(
                                                    onTap: () async {
                                                      if (driverOtp.length !=
                                                          4) {
                                                        setState(() {});
                                                      } else {
                                                        setState(() {
                                                          _errorOtp = false;
                                                          _isLoading = true;
                                                        });
                                                        var val =
                                                            await tripStart();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        } else if (val !=
                                                            'success') {
                                                          setState(() {
                                                            _errorOtp = true;
                                                            _isLoading = false;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            _isLoading = false;
                                                            getStartOtp = false;
                                                          });
                                                        }
                                                      }
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'],
                                                    color:
                                                        (driverOtp.length != 4)
                                                            ? Colors.grey
                                                            : buttonColor,
                                                    borcolor:
                                                        (driverOtp.length != 4)
                                                            ? Colors.grey
                                                            : buttonColor,
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : (getStartOtp == true &&
                                          driverReq.isNotEmpty)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            padding: EdgeInsets.fromLTRB(
                                                media.width * 0.1,
                                                MediaQuery.of(context)
                                                        .padding
                                                        .top +
                                                    media.width * 0.05,
                                                media.width * 0.1,
                                                media.width * 0.05),
                                            color: page,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: media.width * 0.8,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            getStartOtp = false;
                                                          });
                                                        },
                                                        child: Container(
                                                          height: media.height *
                                                              0.05,
                                                          width: media.height *
                                                              0.05,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: page,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                              Icons.cancel,
                                                              color:
                                                                  buttonColor),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        media.width * 0.025),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      children: [
                                                        (driverReq['show_otp_feature'] ==
                                                                true)
                                                            ? Column(children: [
                                                                Text(
                                                                  languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_driver_otp'],
                                                                  style: GoogleFonts.notoSans(
                                                                      fontSize:
                                                                          media.width *
                                                                              eighteen,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          textColor),
                                                                ),
                                                                SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.05),
                                                                Text(
                                                                  languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_enterdriverotp'],
                                                                  style: GoogleFonts
                                                                      .notoSans(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve,
                                                                    color: textColor
                                                                        .withOpacity(
                                                                            0.7),
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceAround,
                                                                  children: [
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      width: media
                                                                              .width *
                                                                          0.12,
                                                                      color:
                                                                          page,
                                                                      child:
                                                                          TextFormField(
                                                                        onChanged:
                                                                            (val) {
                                                                          if (val.length ==
                                                                              1) {
                                                                            setState(() {
                                                                              _otp1 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).nextFocus();
                                                                            });
                                                                          }
                                                                        },
                                                                        style: GoogleFonts.notoSans(
                                                                            color:
                                                                                textColor,
                                                                            fontSize:
                                                                                media.width * sixteen),
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        maxLength:
                                                                            1,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        decoration: InputDecoration(
                                                                            counterText:
                                                                                '',
                                                                            border:
                                                                                UnderlineInputBorder(borderSide: BorderSide(color: textColor, width: 1.5, style: BorderStyle.solid))),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      width: media
                                                                              .width *
                                                                          0.12,
                                                                      color:
                                                                          page,
                                                                      child:
                                                                          TextFormField(
                                                                        onChanged:
                                                                            (val) {
                                                                          if (val.length ==
                                                                              1) {
                                                                            setState(() {
                                                                              _otp2 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).nextFocus();
                                                                            });
                                                                          } else {
                                                                            setState(() {
                                                                              _otp2 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).previousFocus();
                                                                            });
                                                                          }
                                                                        },
                                                                        style: GoogleFonts.notoSans(
                                                                            color:
                                                                                textColor,
                                                                            fontSize:
                                                                                media.width * sixteen),
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        maxLength:
                                                                            1,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        decoration: InputDecoration(
                                                                            counterText:
                                                                                '',
                                                                            border:
                                                                                UnderlineInputBorder(borderSide: BorderSide(color: textColor, width: 1.5, style: BorderStyle.solid))),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      width: media
                                                                              .width *
                                                                          0.12,
                                                                      color:
                                                                          page,
                                                                      child:
                                                                          TextFormField(
                                                                        onChanged:
                                                                            (val) {
                                                                          if (val.length ==
                                                                              1) {
                                                                            setState(() {
                                                                              _otp3 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).nextFocus();
                                                                            });
                                                                          } else {
                                                                            setState(() {
                                                                              _otp3 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).previousFocus();
                                                                            });
                                                                          }
                                                                        },
                                                                        style: GoogleFonts.notoSans(
                                                                            color:
                                                                                textColor,
                                                                            fontSize:
                                                                                media.width * sixteen),
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        maxLength:
                                                                            1,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        decoration: InputDecoration(
                                                                            counterText:
                                                                                '',
                                                                            border:
                                                                                UnderlineInputBorder(borderSide: BorderSide(color: textColor, width: 1.5, style: BorderStyle.solid))),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      width: media
                                                                              .width *
                                                                          0.12,
                                                                      color:
                                                                          page,
                                                                      child:
                                                                          TextFormField(
                                                                        onChanged:
                                                                            (val) {
                                                                          if (val.length ==
                                                                              1) {
                                                                            setState(() {
                                                                              _otp4 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).nextFocus();
                                                                            });
                                                                          } else {
                                                                            setState(() {
                                                                              _otp4 = val;
                                                                              driverOtp = _otp1 + _otp2 + _otp3 + _otp4;
                                                                              FocusScope.of(context).previousFocus();
                                                                            });
                                                                          }
                                                                        },
                                                                        style: GoogleFonts.notoSans(
                                                                            color:
                                                                                textColor,
                                                                            fontSize:
                                                                                media.width * sixteen),
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        maxLength:
                                                                            1,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        decoration: InputDecoration(
                                                                            counterText:
                                                                                '',
                                                                            border:
                                                                                UnderlineInputBorder(borderSide: BorderSide(color: textColor, width: 1.5, style: BorderStyle.solid))),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.04,
                                                                ),
                                                                (_errorOtp ==
                                                                        true)
                                                                    ? Text(
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_error_trip_otp'],
                                                                        style: GoogleFonts.notoSans(
                                                                            color:
                                                                                Colors.red,
                                                                            fontSize: media.width * twelve),
                                                                      )
                                                                    : Container(),
                                                                SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02),
                                                              ])
                                                            : Container(),
                                                        SizedBox(
                                                          width:
                                                              media.width * 0.8,
                                                          child: Text(
                                                            languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_shipment_title'],
                                                            style: GoogleFonts
                                                                .notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      eighteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: textColor,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.02),
                                                        Container(
                                                            height:
                                                                media.width *
                                                                    0.5,
                                                            width: media.width *
                                                                0.5,
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color:
                                                                      borderLines,
                                                                  width: 1.1),
                                                            ),
                                                            child:
                                                                (shipLoadImage ==
                                                                        null)
                                                                    ? InkWell(
                                                                        onTap:
                                                                            () {
                                                                          pickImageFromCamera(
                                                                              1);
                                                                        },
                                                                        child:
                                                                            Center(
                                                                          child: Text(
                                                                              languages[choosenLanguage]['text_add_shipmentimage'],
                                                                              style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: hintColor),
                                                                              textAlign: TextAlign.center),
                                                                        ),
                                                                      )
                                                                    : InkWell(
                                                                        onTap:
                                                                            () {
                                                                          pickImageFromCamera(
                                                                              1);
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              media.width * 0.5,
                                                                          width:
                                                                              media.width * 0.5,
                                                                          decoration:
                                                                              BoxDecoration(image: DecorationImage(image: FileImage(File(shipLoadImage)), fit: BoxFit.contain, colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.5), BlendMode.dstATop))),
                                                                          child:
                                                                              Center(child: Text(languages[choosenLanguage]['text_edit_shipmentimage'], style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: textColor), textAlign: TextAlign.center)),
                                                                        ),
                                                                      )),
                                                        SizedBox(
                                                          height: media.width *
                                                              0.05,
                                                        ),
                                                        (beforeImageUploadError !=
                                                                '')
                                                            ? SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.9,
                                                                child: Text(
                                                                    beforeImageUploadError,
                                                                    style: GoogleFonts.notoSans(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        color: Colors
                                                                            .red),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center),
                                                              )
                                                            : Container()
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: media.width * 0.02),
                                                Button(
                                                  onTap: () async {
                                                    if (driverReq[
                                                            'show_otp_feature'] ==
                                                        true) {
                                                      if (driverOtp.length !=
                                                              4 ||
                                                          shipLoadImage ==
                                                              null) {
                                                        setState(() {});
                                                      } else {
                                                        setState(() {
                                                          _errorOtp = false;
                                                          beforeImageUploadError =
                                                              '';
                                                          _isLoading = true;
                                                        });
                                                        var upload =
                                                            await uploadLoadingImage(
                                                                shipLoadImage);
                                                        if (upload ==
                                                            'success') {
                                                          var val =
                                                              await tripStart();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          } else if (val !=
                                                              'success') {
                                                            setState(() {
                                                              _errorOtp = true;
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          } else {
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                              getStartOtp =
                                                                  false;
                                                            });
                                                          }
                                                        } else if (upload ==
                                                            'logout') {
                                                          navigateLogout();
                                                        } else {
                                                          setState(() {
                                                            beforeImageUploadError =
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_somethingwentwrong'];
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      }
                                                    } else {
                                                      if (shipLoadImage ==
                                                          null) {
                                                        setState(() {});
                                                      } else {
                                                        setState(() {
                                                          _errorOtp = false;
                                                          beforeImageUploadError =
                                                              '';
                                                          _isLoading = true;
                                                        });
                                                        var upload =
                                                            await uploadLoadingImage(
                                                                shipLoadImage);
                                                        if (upload ==
                                                            'success') {
                                                          var val =
                                                              await tripStartDispatcher();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          } else if (val !=
                                                              'success') {
                                                            setState(() {
                                                              _errorOtp = true;
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          } else {
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                              getStartOtp =
                                                                  false;
                                                            });
                                                          }
                                                        } else if (upload ==
                                                            'logout') {
                                                          navigateLogout();
                                                        } else {
                                                          setState(() {
                                                            beforeImageUploadError =
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_somethingwentwrong'];
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      }
                                                    }
                                                  },
                                                  text:
                                                      languages[choosenLanguage]
                                                          ['text_confirm'],
                                                  color: (driverReq[
                                                              'show_otp_feature'] ==
                                                          true)
                                                      ? (driverOtp.length !=
                                                                  4 ||
                                                              shipLoadImage ==
                                                                  null)
                                                          ? Colors.grey
                                                          : buttonColor
                                                      : (shipLoadImage == null)
                                                          ? Colors.grey
                                                          : buttonColor,
                                                  borcolor: (driverReq[
                                                              'show_otp_feature'] ==
                                                          true)
                                                      ? (driverOtp.length !=
                                                                  4 ||
                                                              shipLoadImage ==
                                                                  null)
                                                          ? Colors.grey
                                                          : buttonColor
                                                      : (shipLoadImage == null)
                                                          ? Colors.grey
                                                          : buttonColor,
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(),

                              //shipment unload image
                              (unloadImage == true)
                                  ? Positioned(
                                      child: Container(
                                      height: media.height,
                                      width: media.width * 1,
                                      color: page,
                                      padding: EdgeInsets.fromLTRB(
                                          media.width * 0.05,
                                          MediaQuery.of(context).padding.top +
                                              media.width * 0.05,
                                          media.width * 0.05,
                                          media.width * 0.05),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.8,
                                            child: Stack(
                                              children: [
                                                Container(
                                                    padding: EdgeInsets.only(
                                                        left:
                                                            media.width * 0.05,
                                                        right:
                                                            media.width * 0.05),
                                                    alignment: Alignment.center,
                                                    // color:Colors.red,
                                                    height: media.width * 0.15,
                                                    width: media.width * 0.9,
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                          ['text_unload_title'],
                                                      style:
                                                          GoogleFonts.notoSans(
                                                              color: textColor,
                                                              fontSize:
                                                                  media.width *
                                                                      eighteen),
                                                      maxLines: 1,
                                                      textAlign:
                                                          TextAlign.center,
                                                    )),
                                                Positioned(
                                                  right: 0,
                                                  top: media.width * 0.025,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        unloadImage = false;
                                                      });
                                                    },
                                                    child: Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                        color: page,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(Icons.cancel,
                                                          color: buttonColor),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  Container(
                                                    height: media.width * 0.5,
                                                    width: media.width * 0.5,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.1),
                                                    ),
                                                    child:
                                                        (shipUnloadImage ==
                                                                null)
                                                            ? InkWell(
                                                                onTap: () {
                                                                  pickImageFromCamera(
                                                                      2);
                                                                },
                                                                child: Center(
                                                                  child: Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_add_unloadImage'],
                                                                      style: GoogleFonts.notoSans(
                                                                          fontSize: media.width *
                                                                              twelve,
                                                                          color:
                                                                              hintColor),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center),
                                                                ),
                                                              )
                                                            : InkWell(
                                                                onTap: () {
                                                                  pickImageFromCamera(
                                                                      2);
                                                                },
                                                                child:
                                                                    Container(
                                                                  height: media
                                                                          .width *
                                                                      0.5,
                                                                  width: media
                                                                          .width *
                                                                      0.5,
                                                                  decoration:
                                                                      BoxDecoration(

                                                                          // color: Colors.transparent.withOpacity(0.4),
                                                                          image: DecorationImage(
                                                                              image: FileImage(File(shipUnloadImage)),
                                                                              fit: BoxFit.contain,
                                                                              colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.5), BlendMode.dstATop))),
                                                                  child: Center(
                                                                      child: Text(
                                                                          languages[choosenLanguage]
                                                                              [
                                                                              'text_edit_unloadimage'],
                                                                          style: GoogleFonts.notoSans(
                                                                              fontSize: media.width *
                                                                                  twelve,
                                                                              color:
                                                                                  textColor),
                                                                          textAlign:
                                                                              TextAlign.center)),
                                                                ),
                                                              ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          media.width * 0.05),
                                                  (afterImageUploadError != '')
                                                      ? SizedBox(
                                                          width:
                                                              media.width * 0.9,
                                                          child: Text(
                                                              afterImageUploadError,
                                                              style: GoogleFonts.notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color: Colors
                                                                      .red),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center),
                                                        )
                                                      : Container()
                                                ],
                                              ),
                                            ),
                                          ),
                                          (shipUnloadImage != null)
                                              ? Button(
                                                  onTap: () async {
                                                    setState(() {
                                                      _isLoading = true;
                                                      afterImageUploadError =
                                                          '';
                                                    });
                                                    var val =
                                                        await uploadUnloadingImage(
                                                            shipUnloadImage);
                                                    if (val == 'success') {
                                                      if (driverReq[
                                                                  'enable_digital_signature']
                                                              .toString() ==
                                                          '1') {
                                                        navigate();
                                                      } else {
                                                        var val =
                                                            await endTrip();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      }
                                                    } else if (val ==
                                                        'logout') {
                                                      navigateLogout();
                                                    } else {
                                                      setState(() {
                                                        afterImageUploadError =
                                                            languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_somethingwentwrong'];
                                                      });
                                                    }
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  },
                                                  text: 'Upload')
                                              : Container()
                                        ],
                                      ),
                                    ))
                                  : Container(),

                              //permission denied popup
                              (_permission != '')
                                  ? Positioned(
                                      child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _permission = '';
                                                    });
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: page),
                                                    child: Icon(
                                                        Icons.cancel_outlined,
                                                        color: textColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page,
                                                boxShadow: [
                                                  BoxShadow(
                                                      blurRadius: 2.0,
                                                      spreadRadius: 2.0,
                                                      color: Colors.black
                                                          .withOpacity(0.2))
                                                ]),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                    width: media.width * 0.8,
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                          [
                                                          'text_open_camera_setting'],
                                                      style:
                                                          GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color: textColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    )),
                                                SizedBox(
                                                    height: media.width * 0.05),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    InkWell(
                                                        onTap: () async {
                                                          await perm
                                                              .openAppSettings();
                                                        },
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_open_settings'],
                                                          style: GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color:
                                                                  buttonColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        )),
                                                    InkWell(
                                                        onTap: () async {
                                                          // pickImageFromCamera();
                                                          setState(() {
                                                            _permission = '';
                                                          });
                                                        },
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              ['text_done'],
                                                          style: GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color:
                                                                  buttonColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ))
                                                  ],
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                  : Container(),

                              //popup for cancel request
                              (cancelRequest == true && driverReq.isNotEmpty)
                                  ? Positioned(
                                      child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Column(children: [
                                              Container(
                                                height: media.width * 0.18,
                                                width: media.width * 0.18,
                                                decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xffFEF2F2)),
                                                alignment: Alignment.center,
                                                child: Container(
                                                  height: media.width * 0.14,
                                                  width: media.width * 0.14,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFF0000)),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.cancel_outlined,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                children: cancelReasonsList
                                                    .asMap()
                                                    .map((i, value) {
                                                      return MapEntry(
                                                          i,
                                                          InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                _cancelReason =
                                                                    cancelReasonsList[
                                                                            i][
                                                                        'reason'];
                                                              });
                                                            },
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .all(media
                                                                          .width *
                                                                      0.01),
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    height: media
                                                                            .height *
                                                                        0.05,
                                                                    width: media
                                                                            .width *
                                                                        0.05,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        border: Border.all(
                                                                            color:
                                                                                textColor,
                                                                            width:
                                                                                1.2)),
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: (_cancelReason ==
                                                                            cancelReasonsList[i]['reason'])
                                                                        ? Container(
                                                                            height:
                                                                                media.width * 0.03,
                                                                            width:
                                                                                media.width * 0.03,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: textColor,
                                                                            ),
                                                                          )
                                                                        : Container(),
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.05,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.65,
                                                                    child:
                                                                        MyText(
                                                                      text: cancelReasonsList[
                                                                              i]
                                                                          [
                                                                          'reason'],
                                                                      size: media
                                                                              .width *
                                                                          twelve,
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ));
                                                    })
                                                    .values
                                                    .toList(),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _cancelReason = 'others';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color:
                                                                    textColor,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child: (_cancelReason ==
                                                                'others')
                                                            ? Container(
                                                                height: media
                                                                        .width *
                                                                    0.03,
                                                                width: media
                                                                        .width *
                                                                    0.03,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color:
                                                                      textColor,
                                                                ),
                                                              )
                                                            : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.05,
                                                      ),
                                                      MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_others'],
                                                        size: media.width *
                                                            twelve,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              (_cancelReason == 'others')
                                                  ? Container(
                                                      margin:
                                                          EdgeInsets.fromLTRB(
                                                              0,
                                                              media.width *
                                                                  0.025,
                                                              0,
                                                              media.width *
                                                                  0.025),
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.05),
                                                      width: media.width * 0.9,
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  borderLines,
                                                              width: 1.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      12)),
                                                      child: TextField(
                                                        decoration: InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            hintText: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_cancelRideReason'],
                                                            hintStyle: GoogleFonts
                                                                .notoSans(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve)),
                                                        maxLines: 4,
                                                        minLines: 2,
                                                        onChanged: (val) {
                                                          setState(() {
                                                            cancelReasonText =
                                                                val;
                                                          });
                                                        },
                                                      ),
                                                    )
                                                  : Container(),
                                              (_cancellingError != '')
                                                  ? Container(
                                                      padding: EdgeInsets.only(
                                                          top: media.width *
                                                              0.02,
                                                          bottom: media.width *
                                                              0.02),
                                                      width: media.width * 0.9,
                                                      child: Text(
                                                          _cancellingError,
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  color: Colors
                                                                      .red)))
                                                  : Container(),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Button(
                                                      color: page,
                                                      textcolor: buttonColor,
                                                      borcolor: buttonColor,
                                                      width: media.width * 0.39,
                                                      onTap: () async {
                                                        setState(() {
                                                          _isLoading = true;
                                                        });
                                                        if (_cancelReason !=
                                                            '') {
                                                          if (_cancelReason ==
                                                              'others') {
                                                            if (cancelReasonText !=
                                                                    '' &&
                                                                cancelReasonText
                                                                    .isNotEmpty) {
                                                              _cancellingError =
                                                                  '';
                                                              var val =
                                                                  await cancelRequestDriver(
                                                                      cancelReasonText);
                                                              if (val ==
                                                                  'logout') {
                                                                navigateLogout();
                                                              }
                                                              setState(() {
                                                                cancelRequest =
                                                                    false;
                                                              });
                                                            } else {
                                                              setState(() {
                                                                _cancellingError =
                                                                    languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_add_cancel_reason'];
                                                              });
                                                            }
                                                          } else {
                                                            var val =
                                                                await cancelRequestDriver(
                                                                    _cancelReason);
                                                            if (val ==
                                                                'logout') {
                                                              navigateLogout();
                                                            }
                                                            setState(() {
                                                              cancelRequest =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_cancel']),
                                                  Button(
                                                      width: media.width * 0.39,
                                                      onTap: () {
                                                        setState(() {
                                                          cancelRequest = false;
                                                        });
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['tex_dontcancel'])
                                                ],
                                              )
                                            ]),
                                          ),
                                        ],
                                      ),
                                    ))
                                  : Container(),

                              //loader
                              (state == '')
                                  ? const Positioned(top: 0, child: Loading())
                                  : Container(),

                              //logout popup
                              (logout == true)
                                  ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color:
                                            Colors.transparent.withOpacity(0.6),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.9,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                      height:
                                                          media.height * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: page),
                                                      child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              logout = false;
                                                            });
                                                          },
                                                          child: const Icon(Icons
                                                              .cancel_outlined))),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              width: media.width * 0.9,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: page),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    languages[choosenLanguage]
                                                        ['text_confirmlogout'],
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.notoSans(
                                                        fontSize: media.width *
                                                            sixteen,
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Button(
                                                      onTap: () async {
                                                        setState(() {
                                                          _isLoading = true;
                                                          logout = false;
                                                        });
                                                        var result =
                                                            await userLogout();
                                                        if (result ==
                                                            'success') {
                                                          setState(() {
                                                            navigateLogout();
                                                            userDetails.clear();
                                                          });
                                                        } else if (result ==
                                                            'logout') {
                                                          navigateLogout();
                                                        } else {
                                                          setState(() {
                                                            logout = true;
                                                          });
                                                        }
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_confirm'])
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ))
                                  : Container(),

                              //waiting time popup
                              (_showWaitingInfo == true)
                                  ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color:
                                            Colors.transparent.withOpacity(0.6),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.9,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                      height:
                                                          media.height * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: page),
                                                      child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _showWaitingInfo =
                                                                  false;
                                                            });
                                                          },
                                                          child: const Icon(Icons
                                                              .cancel_outlined))),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              width: media.width * 0.9,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: page),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    languages[choosenLanguage]
                                                        ['text_waiting_time_1'],
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.notoSans(
                                                        fontSize: media.width *
                                                            sixteen,
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_waiting_time_2'],
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      fourteen,
                                                                  color:
                                                                      textColor)),
                                                      Text(
                                                          '${driverReq['free_waiting_time_in_mins_before_trip_start']} mins',
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      fourteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_waiting_time_3'],
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      fourteen,
                                                                  color:
                                                                      textColor)),
                                                      Text(
                                                          '${driverReq['free_waiting_time_in_mins_after_trip_start']} mins',
                                                          style: GoogleFonts
                                                              .notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      fourteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ))
                                  : Container(),

                              //no internet
                              (internet == false)
                                  ? Positioned(
                                      top: 0,
                                      child: NoInternet(
                                        onTap: () {
                                          setState(() {
                                            internetTrue();
                                            getUserDetails();
                                          });
                                        },
                                      ))
                                  : Container(),

                              //sos popup
                              (showSos == true)
                                  ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color:
                                            Colors.transparent.withOpacity(0.6),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: media.width * 0.7,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          notifyCompleted =
                                                              false;
                                                          showSos = false;
                                                        });
                                                      },
                                                      child: Container(
                                                        height:
                                                            media.width * 0.1,
                                                        width:
                                                            media.width * 0.1,
                                                        decoration:
                                                            BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: page),
                                                        child: const Icon(Icons
                                                            .cancel_outlined),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                height: media.height * 0.5,
                                                width: media.width * 0.7,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    color: page),
                                                child: SingleChildScrollView(
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        InkWell(
                                                          onTap: () async {
                                                            setState(() {
                                                              notifyCompleted =
                                                                  false;
                                                            });
                                                            var val =
                                                                await notifyAdmin();
                                                            if (val == true) {
                                                              setState(() {
                                                                notifyCompleted =
                                                                    true;
                                                              });
                                                            }
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.05),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_notifyadmin'],
                                                                      style: GoogleFonts.notoSans(
                                                                          fontSize: media.width *
                                                                              sixteen,
                                                                          color:
                                                                              textColor,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                    (notifyCompleted ==
                                                                            true)
                                                                        ? Container(
                                                                            padding:
                                                                                EdgeInsets.only(top: media.width * 0.01),
                                                                            child:
                                                                                Text(
                                                                              languages[choosenLanguage]['text_notifysuccess'],
                                                                              style: GoogleFonts.notoSans(
                                                                                fontSize: media.width * twelve,
                                                                                color: const Color(0xff319900),
                                                                              ),
                                                                            ),
                                                                          )
                                                                        : Container()
                                                                  ],
                                                                ),
                                                                const Icon(Icons
                                                                    .notification_add)
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        (sosData.isNotEmpty)
                                                            ? Column(
                                                                children: sosData
                                                                    .asMap()
                                                                    .map((i, value) {
                                                                      return MapEntry(
                                                                          i,
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              makingPhoneCall(sosData[i]['number'].toString().replaceAll(' ', ''));
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              padding: EdgeInsets.all(media.width * 0.05),
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      SizedBox(
                                                                                        width: media.width * 0.4,
                                                                                        child: Text(
                                                                                          sosData[i]['name'],
                                                                                          style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(
                                                                                        height: media.width * 0.01,
                                                                                      ),
                                                                                      Text(
                                                                                        sosData[i]['number'],
                                                                                        style: GoogleFonts.notoSans(
                                                                                          fontSize: media.width * twelve,
                                                                                          color: textColor,
                                                                                        ),
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                  const Icon(Icons.call)
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ));
                                                                    })
                                                                    .values
                                                                    .toList(),
                                                              )
                                                            : Container(
                                                                width: media
                                                                        .width *
                                                                    0.7,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Text(
                                                                  languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_noDataFound'],
                                                                  style: GoogleFonts.notoSans(
                                                                      fontSize:
                                                                          media.width *
                                                                              eighteen,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          textColor),
                                                                ),
                                                              )
                                                      ],
                                                    )),
                                              )
                                            ]),
                                      ))
                                  : Container(),

                              //choose option for seeing location on map while having multiple stops
                              (_tripOpenMap == true)
                                  ? Positioned(
                                      top: 0,
                                      child: Container(
                                        height: media.height * 1,
                                        width: media.width * 1,
                                        color:
                                            Colors.transparent.withOpacity(0.6),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.9,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _tripOpenMap = false;
                                                      });
                                                    },
                                                    child: Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: page),
                                                      child: Icon(
                                                        Icons.cancel_outlined,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Container(
                                                width: media.width * 0.9,
                                                padding: EdgeInsets.fromLTRB(
                                                    media.width * 0.02,
                                                    media.width * 0.05,
                                                    media.width * 0.02,
                                                    media.width * 0.05),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    color: page),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      width: media.width * 0.8,
                                                      child: Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_choose_address_nav'],
                                                        style: GoogleFonts
                                                            .notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    sixteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.03,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.2,
                                                      child:
                                                          SingleChildScrollView(
                                                        physics:
                                                            const BouncingScrollPhysics(),
                                                        child: Column(
                                                          children: tripStops
                                                              .asMap()
                                                              .map((i, value) {
                                                                return MapEntry(
                                                                    i,
                                                                    Container(
                                                                      // width: media.width*0.5,
                                                                      padding: EdgeInsets.all(
                                                                          media.width *
                                                                              0.025),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              tripStops[i]['address'],
                                                                              style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.01,
                                                                          ),
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              openMap(tripStops[i]['latitude'], tripStops[i]['longitude']);
                                                                            },
                                                                            child:
                                                                                SizedBox(
                                                                              width: media.width * 00.08,
                                                                              child: Image.asset('assets/images/googlemaps.png', width: media.width * 0.05, fit: BoxFit.contain),
                                                                            ),
                                                                          ),
                                                                          (userDetails['enable_vase_map'] == '1')
                                                                              ? SizedBox(
                                                                                  width: media.width * 0.02,
                                                                                )
                                                                              : Container(),
                                                                          (userDetails['enable_vase_map'] == '1')
                                                                              ? InkWell(
                                                                                  onTap: () {
                                                                                    openWazeMap(tripStops[i]['latitude'], tripStops[i]['longitude']);
                                                                                  },
                                                                                  child: SizedBox(
                                                                                    width: media.width * 00.1,
                                                                                    child: Image.asset('assets/images/waze.png', width: media.width * 0.05, fit: BoxFit.contain),
                                                                                  ),
                                                                                )
                                                                              : Container(),
                                                                        ],
                                                                      ),
                                                                    ));
                                                              })
                                                              .values
                                                              .toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ))
                                          ],
                                        ),
                                      ))
                                  : Container(),

                              //loader
                              (_isLoading == true)
                                  ? const Positioned(top: 0, child: Loading())
                                  : Container(),
                              //pickup marker
                              Positioned(
                                top: media.height * 1.5,
                                left: 100,
                                child: RepaintBoundary(
                                    key: iconKey,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                  colors: [
                                                    (isDarkTheme == true)
                                                        ? const Color(
                                                            0xff000000)
                                                        : const Color(
                                                            0xffFFFFFF),
                                                    (isDarkTheme == true)
                                                        ? const Color(
                                                            0xff808080)
                                                        : const Color(
                                                            0xffEFEFEF),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          width: media.width * 0.7,
                                          padding: const EdgeInsets.all(5),
                                          child: (driverReq.isNotEmpty &&
                                                  driverReq['pick_address'] !=
                                                      null)
                                              ? MyText(
                                                  text:
                                                      driverReq['pick_address'],
                                                  size: media.width * twelve,
                                                  overflow: TextOverflow.fade,
                                                  // maxLines: 1,
                                                )
                                              : (choosenRide.isNotEmpty)
                                                  ? MyText(
                                                      text: choosenRide[0]
                                                          ['pick_address'],
                                                      size:
                                                          media.width * twelve,
                                                      overflow:
                                                          TextOverflow.fade,
                                                      // maxLines: 1,
                                                    )
                                                  : Container(),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/pick_icon.png'),
                                                  fit: BoxFit.contain)),
                                          height: media.width * 0.07,
                                          width: media.width * 0.08,
                                        )
                                      ],
                                    )),
                              ),

                              //drop marker
                              Positioned(
                                  top: media.height * 2.5,
                                  left: 100,
                                  child: Column(
                                    children: [
                                      (tripStops.isNotEmpty)
                                          ? Column(
                                              children: tripStops
                                                  .asMap()
                                                  .map((i, value) {
                                                    iconDropKeys[i] =
                                                        GlobalKey();
                                                    return MapEntry(
                                                      i,
                                                      RepaintBoundary(
                                                          key: iconDropKeys[i],
                                                          child: Column(
                                                            children: [
                                                              (i <=
                                                                      tripStops
                                                                              .length -
                                                                          2)
                                                                  ? Column(
                                                                      children: [
                                                                        Container(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              bottom: 5),
                                                                          child:
                                                                              Text(
                                                                            (i + 1).toString(),
                                                                            style: GoogleFonts.notoSans(
                                                                                fontSize: media.width * sixteen,
                                                                                fontWeight: FontWeight.w600,
                                                                                color: Colors.red),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              10,
                                                                        ),
                                                                      ],
                                                                    )
                                                                  : (i ==
                                                                          tripStops.length -
                                                                              1)
                                                                      ? Column(
                                                                          children: [
                                                                            Container(
                                                                              decoration: BoxDecoration(
                                                                                  gradient: LinearGradient(colors: [
                                                                                    (isDarkTheme == true) ? const Color(0xff000000) : const Color(0xffFFFFFF),
                                                                                    (isDarkTheme == true) ? const Color(0xff808080) : const Color(0xffEFEFEF),
                                                                                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                                                  borderRadius: BorderRadius.circular(5)),
                                                                              width: media.width * 0.7,
                                                                              padding: const EdgeInsets.all(5),
                                                                              child: (driverReq.isNotEmpty && driverReq['drop_address'] != null)
                                                                                  ? Text(driverReq['drop_address'],
                                                                                      style: GoogleFonts.notoSans(
                                                                                        fontSize: media.width * twelve,
                                                                                      ))
                                                                                  : (choosenRide.isNotEmpty && choosenRide[0]['drop_address'] != null)
                                                                                      ? Text(
                                                                                          choosenRide[choosenRide.length - 1]['drop_address'],
                                                                                          style: GoogleFonts.notoSans(
                                                                                            fontSize: media.width * twelve,
                                                                                          ),
                                                                                          overflow: TextOverflow.fade,
                                                                                        )
                                                                                      : Container(),
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                            Container(
                                                                              decoration: const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage('assets/images/drop_icon.png'), fit: BoxFit.contain)),
                                                                              height: media.width * 0.07,
                                                                              width: media.width * 0.08,
                                                                            )
                                                                          ],
                                                                        )
                                                                      : Container(),
                                                            ],
                                                          )),
                                                    );
                                                  })
                                                  .values
                                                  .toList(),
                                            )
                                          : Container(),
                                    ],
                                  )),

                              //drop marker
                              Positioned(
                                top: media.height * 2.5,
                                left: 100,
                                child: Column(
                                  children: [
                                    RepaintBoundary(
                                        key: iconDropKey,
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        (isDarkTheme == true)
                                                            ? const Color(
                                                                0xff000000)
                                                            : const Color(
                                                                0xffFFFFFF),
                                                        (isDarkTheme == true)
                                                            ? const Color(
                                                                0xff808080)
                                                            : const Color(
                                                                0xffEFEFEF),
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter),
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              width: media.width * 0.7,
                                              padding: const EdgeInsets.all(5),
                                              child: (driverReq.isNotEmpty &&
                                                      driverReq[
                                                              'drop_address'] !=
                                                          null)
                                                  ? MyText(
                                                      text: driverReq[
                                                          'drop_address'],
                                                      size:
                                                          media.width * twelve,
                                                      overflow:
                                                          TextOverflow.fade,

                                                      // maxLines: 1,
                                                    )
                                                  : (choosenRide.isNotEmpty &&
                                                          choosenRide[0][
                                                                  'drop_address'] !=
                                                              null)
                                                      ? MyText(
                                                          text: choosenRide[0]
                                                              ['drop_address'],
                                                          size: media.width *
                                                              twelve,
                                                          overflow:
                                                              TextOverflow.fade,

                                                          // maxLines: 1,
                                                        )
                                                      : Container(),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/drop_icon.png'),
                                                      fit: BoxFit.contain)),
                                              height: media.width * 0.07,
                                              width: media.width * 0.08,
                                            )
                                          ],
                                        )),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                ),
              );
            }),
      ),
    );
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();

    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return -1;
  }

  animateCar(
      double fromLat, //Starting latitude

      double fromLong, //Starting longitude

      double toLat, //Ending latitude

      double toLong, //Ending longitude

      StreamSink<List<Marker>>
          mapMarkerSink, //Stream build of map to update the UI

      TickerProvider
          provider, //Ticker provider of the widget. This is used for animation

      GoogleMapController controller, //Google map controller of our widget

      markerid,
      icon,
      name,
      number) async {
    final double bearing =
        getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));

    dynamic carMarker;
    if (name == '' && number == '') {
      carMarker = Marker(
          markerId: MarkerId(markerid),
          position: LatLng(fromLat, fromLong),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          draggable: false);
    } else {
      carMarker = Marker(
          markerId: MarkerId(markerid),
          position: LatLng(fromLat, fromLong),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: number, snippet: name),
          flat: true,
          draggable: false);
    }

    myMarkers.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarkers
            .removeWhere((element) => element.markerId == MarkerId(markerid));

        final v = _animation!.value;

        double lng = v * toLong + (1 - v) * fromLong;

        double lat = v * toLat + (1 - v) * fromLat;

        LatLng newPos = LatLng(lat, lng);

        //New marker location

        if (name == '' && number == '') {
          carMarker = Marker(
              markerId: MarkerId(markerid),
              position: newPos,
              icon: icon,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              rotation: bearing,
              draggable: false);
        } else {
          carMarker = Marker(
              markerId: MarkerId(markerid),
              position: newPos,
              icon: icon,
              infoWindow: InfoWindow(title: number, snippet: name),
              anchor: const Offset(0.5, 0.5),
              flat: true,
              rotation: bearing,
              draggable: false);
        }

        //Adding new marker to our list and updating the google map UI.

        myMarkers.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());
      });

    //Starting the animation

    animationController.forward();

    if (driverReq.isEmpty || driverReq['is_trip_start'] == 1) {
      controller.getVisibleRegion().then((value) {
        if (value.contains(myMarkers
            .firstWhere((element) => element.markerId == MarkerId(markerid))
            .position)) {
        } else {
          controller.animateCamera(CameraUpdate.newLatLng(center));
        }
      });
    }
    animationController = null;
  }
}

class OwnerCarImagecontainer extends StatelessWidget {
  final String imgurl;
  final String text;
  final Color color;
  final void Function()? ontap;
  const OwnerCarImagecontainer(
      {Key? key,
      required this.imgurl,
      required this.text,
      required this.ontap,
      required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return InkWell(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.all(
          media.width * 0.01,
        ),
        width: media.width * 0.15,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: AssetImage(imgurl), fit: BoxFit.contain)),
              height: media.width * 0.07,
              width: media.width * 0.15,
            ),
            Container(
              height: media.width * 0.03,
              width: media.width * 0.13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: color,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            )
          ],
        ),
      ),
    );
  }
}
