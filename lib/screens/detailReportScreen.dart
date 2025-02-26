import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tanood/net/authenticationService.dart';
import 'package:tanood/screens/detailAssignedTanodsReportScreen.dart';
import 'package:tanood/screens/detailDocumentedViolatorsScreen.dart';
import 'package:tanood/screens/detailImageFullscreen.dart';
import 'package:tanood/screens/documentReportScreen.dart';
import 'package:tanood/screens/mainScreen.dart';
import 'package:tanood/shared/constants.dart';
import 'package:tanood/shared/myButtons.dart';
import 'package:tanood/shared/myContainers.dart';
import 'package:tanood/shared/mySpinKits.dart';
import 'package:tanood/shared/myText.dart';

class DetailReportScreen extends StatefulWidget {
  final String id;
  final bool isFromNotification;
  final BaseAuth auth;
  final VoidCallback onSignOut;
  const DetailReportScreen({
    required this.id,
    required this.isFromNotification,
    required this.auth,
    required this.onSignOut,
  });

  @override
  _DetailReportScreenState createState() => _DetailReportScreenState();
}

class _DetailReportScreenState extends State<DetailReportScreen> {
  late Size screenSize;
  GlobalKey<ScaffoldState> _scaffoldKeyDetailReports =
      GlobalKey<ScaffoldState>();
  late DateTime dateTime;
  final dbRef = FirebaseDatabase.instance.reference();
  bool isAssigned = false;
  bool isAssignedToUser = false;
  bool isUserHasActiveReport = false;
  bool isTaggedReport = false;
  bool isLoading = false;
  late Timer _timer;
  var tanods;
  var userData;
  var reports;
  var selectedReport;
  var violators;
  var locations;
  String userUID = '';

  static const _DropReason = [
    "Violator Escaped",
    "Invalid Detection",
    "Purpose is valid",
    "Duplicate",
    "Others",
  ];

  late String _selectedReason = "Violator Escaped";

  _buildCreateAssignConfirmaModal(BuildContext context, String title) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              title: Text(
                'Confirmation',
                style: tertiaryText.copyWith(fontSize: 18),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      style: tertiaryText.copyWith(fontSize: 16),
                      children: [
                        TextSpan(
                            text: title == 'Assign'
                                ? 'Do you want to apprehend the violator${selectedReport[0]['ViolatorCount'] != 1 ? 's' : ''} in '
                                : 'Do you want to '),
                        title == 'Assign'
                            ? TextSpan(
                                text: getLocationName(
                                    locations, selectedReport[0]['LocationId']),
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : TextSpan(
                                text: 'Drop',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        title == 'Assign'
                            ? TextSpan(
                                text: '?',
                              )
                            : TextSpan(
                                text: ' the report?',
                              ),
                      ],
                    ),
                  ),
                  title == 'Drop'
                      ? Container(
                          margin: EdgeInsets.only(
                            top: 20,
                            bottom: 10,
                          ),
                          child: Text(
                            'Tell us why:',
                            style: tertiaryText.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Container(),
                  title == 'Drop'
                      ? Container(
                          height: 50,
                          child: FormField<String>(
                            builder: (FormFieldState<String> state) {
                              return InputDecorator(
                                decoration: InputDecoration(
                                  //      labelStyle: textStyle,
                                  errorStyle: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 16.0,
                                  ),
                                  isDense: true,
                                  hintText: 'Please select reason',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                ),
                                isEmpty: _selectedReason == '',
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isDense: true,
                                    value: _selectedReason,
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedReason = newValue!;
                                        state.didChange(newValue);
                                      });
                                    },
                                    items: _DropReason.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: tertiaryText.copyWith(
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(),
                ],
              ),
              actions: [
                Container(
                  width: 100,
                  child: MyOutlineButton(
                    color: Color(0xff1640ac),
                    elavation: 5,
                    isLoading: false,
                    radius: 10,
                    text: Text(
                      'Cancel',
                      style: tertiaryText.copyWith(
                          fontSize: 14, color: customColor[140]),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Container(
                  width: 100,
                  child: MyRaisedButton(
                    color: Color(0xff1640ac),
                    elavation: 5,
                    isLoading: isLoading,
                    radius: 10,
                    text: Text(
                      'Confirm',
                      style: tertiaryText.copyWith(
                          fontSize: 14, color: Colors.white),
                    ),
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      if (title == 'Assign') {
                        if (checkAssignableReport() == true) {
                          _saveAssignReportToTanod().then((value) {
                            isAssigned = true;
                            Navigator.pop(context);
                            _buildModalSuccessMessage(context, title);
                            isLoading = false;
                          });
                        } else {
                          Navigator.pop(context);
                          _buildModalFailedMessage(context);
                          isLoading = false;
                        }
                      } else {
                        _dropAssignReportToTanod().then((value) {
                          Navigator.pop(context);
                          isAssigned = false;
                          _buildModalSuccessMessage(context, title);
                          isLoading = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            );
          });
        });
  }

  bool checkAssignableReport() {
    bool result = false;
    if (selectedReport[0]['AssignedTanod'] != null) {
      if (selectedReport[0]['AssignedTanod']
              [selectedReport[0]['AssignedTanod'].length - 1]['Status'] ==
          'Dropped') {
        result = true;
      }
    } else {
      result = true;
    }
    return result;
  }

  Future<String> _saveAssignReportToTanod() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    await dbRef.child('Tanods').child(userData['TanodId']).update({
      'Status': 'Responding',
    });
    if (selectedReport[0]['AssignedTanod'] != null) {
      await dbRef
          .child('Reports')
          .child(selectedReport[0]['Id'].toString())
          .child('AssignedTanod')
          .update({
        (selectedReport[0]['AssignedTanod'].length).toString(): {
          'DateAssign': dateFormat.format(DateTime.now()).toString(),
          'Status': 'Responding',
          'TanodId': userData['TanodId'],
        },
      });
    } else {
      await dbRef
          .child('Reports')
          .child(selectedReport[0]['Id'].toString())
          .update({
        'AssignedTanod': {
          '0': {
            'DateAssign': dateFormat.format(DateTime.now()).toString(),
            'Status': 'Responding',
            'TanodId': userData['TanodId'],
          }
        },
      });
    }

    return '';
  }

  Future<String> _dropAssignReportToTanod() async {
    await dbRef.child('Tanods').child(userData['TanodId']).update({
      'Status': 'Standby',
    });
    await dbRef
        .child('Reports')
        .child(selectedReport[0]['Id'].toString())
        .update({
      'Category': 'Dropped',
    });
    await dbRef
        .child('Reports')
        .child(selectedReport[0]['Id'].toString())
        .child('AssignedTanod')
        .child((selectedReport[0]['AssignedTanod'].length - 1).toString())
        .update({
      'DateAssign': selectedReport[0]['AssignedTanod']
          [selectedReport[0]['AssignedTanod'].length - 1]['DateAssign'],
      'Status': 'Dropped',
      'TanodId': selectedReport[0]['AssignedTanod']
          [selectedReport[0]['AssignedTanod'].length - 1]['TanodId'],
      "Reason": _selectedReason,
    });

    return '';
  }

  Future<void> _buildModalSuccessMessage(
      BuildContext context, String title) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _timer = Timer(Duration(seconds: 1), () {
          Navigator.of(context).pop();
        });
        return AlertDialog(
          backgroundColor: title == 'Assign' ? customColor[130] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(30),
            ),
          ),
          content: Container(
            height: 80,
            width: screenSize.width * .8,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title == 'Assign'
                        ? 'Report Assigned Successfully'
                        : 'Report Dropped Successfully',
                    style: tertiaryText.copyWith(
                      fontSize: 25,
                      color: title == 'Assign' ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
        );
      },
    ).then((value) {
      if (_timer.isActive) {
        _timer.cancel();
      }
    });
  }

  Future<void> _buildModalFailedMessage(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _timer = Timer(Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(30),
            ),
          ),
          content: Container(
            height: 80,
            width: screenSize.width * .8,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'This report is already assigned to other Tanod',
                    style: tertiaryText.copyWith(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
        );
      },
    ).then((value) {
      if (_timer.isActive) {
        _timer.cancel();
      }
    });
  }

  void validateActions() {
    if (selectedReport[0]['AssignedTanod'] != null) {
      if (selectedReport[0]['AssignedTanod']
                  [selectedReport[0]['AssignedTanod'].length - 1]['Status']
              .compareTo('Responding') ==
          0) {
        isAssigned = true;
        if (selectedReport[0]['AssignedTanod']
                [selectedReport[0]['AssignedTanod'].length - 1]['TanodId'] ==
            userData['TanodId']) {
          isAssignedToUser = true;
        }
      }
    }
  }

  void checkUserHasActiveReport() {
    isUserHasActiveReport = false;
    if (userData['Status'] == 'Responding') {
      isUserHasActiveReport = true;
    }
  }

  void checkReportIsTagged() {
    isTaggedReport = false;
    if (selectedReport[0]['Category'] == 'Tagged') {
      isTaggedReport = true;
    }
  }

  String setAssignTanodName() {
    String tanodName = '';
    for (int i = 0; i < tanods.length; i++) {
      if (tanods[i]['TanodId'] ==
          selectedReport[0]['AssignedTanod']
              [selectedReport[0]['AssignedTanod'].length - 1]['TanodId']) {
        tanodName = "${tanods[i]['Firstname']} ${tanods[i]['Lastname']}";
      }
    }
    return tanodName;
  }

  int _calculateApprehendedViolatorCount() {
    num count = 0;
    if (selectedReport[0]['AssignedTanod'] != null) {
      for (int i = 0; i < selectedReport[0]['AssignedTanod'].length; i++) {
        if (selectedReport[0]['AssignedTanod'][i]['Documentation'] != null) {
          count +=
              selectedReport[0]['AssignedTanod'][i]['Documentation'].length;
        }
      }
    }
    return count.toInt();
  }

  List filterDocuments() {
    int count = _calculateApprehendedViolatorCount();
    var documents = new List.filled(count, []);
    int y = 0;
    if (selectedReport[0]['AssignedTanod'] != null) {
      for (int i = 0; i < selectedReport[0]['AssignedTanod'].length; i++) {
        if (selectedReport[0]['AssignedTanod'][i]['Documentation'] != null) {
          for (int x = 0;
              x < selectedReport[0]['AssignedTanod'][i]['Documentation'].length;
              x++) {
            documents[y++]
                .add(selectedReport[0]['AssignedTanod'][i]['Documentation'][x]);
          }
        }
      }
    }
    return documents[0];
  }

  bool checkIsAssigned(String selectedViolatorId) {
    bool isAssignedDocument = false;
    for (int i = 0; i < selectedReport[0]['AssignedTanod'].length; i++) {
      if (selectedReport[0]['AssignedTanod'][i]['Documentation'] != null) {
        for (int x = 0;
            x < selectedReport[0]['AssignedTanod'][i]['Documentation'].length;
            x++) {
          if (selectedReport[0]['AssignedTanod'][i]['Documentation'][x]
                      ['ViolatorId'] ==
                  selectedViolatorId &&
              selectedReport[0]['AssignedTanod'][i]['TanodId'] ==
                  userData['TanodId']) {
            isAssignedDocument = true;
            break;
          }
        }
      }
    }
    return isAssignedDocument;
  }

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    setState(() {
      getCurrentUserUID().then((valueID) {
        setState(() {
          userUID = valueID;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return userUID.isNotEmpty
        ? SafeArea(
            child: StreamBuilder(
                stream: dbRef.child('Locations').onValue,
                builder: (context, locationsSnapshot) {
                  if (locationsSnapshot.hasData &&
                      !locationsSnapshot.hasError &&
                      (locationsSnapshot.data! as Event).snapshot.value !=
                          null) {
                    locations =
                        (locationsSnapshot.data! as Event).snapshot.value;
                  } else {
                    return MySpinKitLoadingScreen();
                  }
                  return StreamBuilder(
                    stream: dbRef.child('Tanods').onValue,
                    builder: (context, tanodSnapshot) {
                      if (tanodSnapshot.hasData &&
                          !tanodSnapshot.hasError &&
                          (tanodSnapshot.data! as Event).snapshot.value !=
                              null) {
                        tanods = (tanodSnapshot.data! as Event).snapshot.value;
                      } else {
                        return Scaffold(body: MySpinKitLoadingScreen());
                      }
                      userData =
                          filterCurrentUserInformation(tanods, userUID)[0];
                      return StreamBuilder(
                          stream: dbRef.child('Reports').onValue,
                          builder: (context, reportSnapshot) {
                            if (reportSnapshot.hasData &&
                                !reportSnapshot.hasError &&
                                (reportSnapshot.data! as Event)
                                        .snapshot
                                        .value !=
                                    null) {
                              reports = (reportSnapshot.data! as Event)
                                  .snapshot
                                  .value;
                            } else {
                              return Scaffold(body: MySpinKitLoadingScreen());
                            }
                            selectedReport = getSelectedReportInformation(
                                reports, widget.id);
                            dateTime =
                                DateTime.parse(selectedReport[0]['Date']);
                            validateActions();
                            checkUserHasActiveReport();
                            checkReportIsTagged();
                            return StreamBuilder(
                                stream: dbRef.child('Violators').onValue,
                                builder: (context, violatorSnapshot) {
                                  if (violatorSnapshot.hasData &&
                                      !violatorSnapshot.hasError &&
                                      (violatorSnapshot.data! as Event)
                                              .snapshot
                                              .value !=
                                          null) {
                                    violators =
                                        (violatorSnapshot.data! as Event)
                                            .snapshot
                                            .value;
                                  } else {
                                    return Scaffold(
                                        body: MySpinKitLoadingScreen());
                                  }

                                  return Scaffold(
                                    backgroundColor: customColor[110],
                                    key: _scaffoldKeyDetailReports,
                                    appBar: PreferredSize(
                                      preferredSize: Size.fromHeight(200),
                                      child: AppBar(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        leading: IconButton(
                                          icon: Icon(
                                            FontAwesomeIcons.chevronDown,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            if (widget.isFromNotification) {
                                              Navigator.of(context)
                                                  .pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (ctx) => MainScreen(
                                                      leading: 'Home',
                                                      auth: widget.auth,
                                                      onSignOut:
                                                          widget.onSignOut),
                                                ),
                                              );
                                            } else {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                        flexibleSpace: Stack(
                                          children: [
                                            ClipRRect(
                                              child: Hero(
                                                tag: 'report_${widget.id}',
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                          selectedReport[0]
                                                              ['Image']),
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: -5,
                                              right: -3,
                                              child: IconButton(
                                                icon: Icon(
                                                    FontAwesomeIcons.expand),
                                                color: Colors.white,
                                                iconSize: 18,
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (ctx) =>
                                                          ImageFullScreen(
                                                        tag: widget.id,
                                                        image: selectedReport[0]
                                                            ['Image'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    body: ListView(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 15),
                                          padding: EdgeInsets.only(top: 15),
                                          width: screenSize.width,
                                          child: Row(
                                            children: [
                                              Text(
                                                'Details',
                                                style: secandaryText.copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              Container(
                                                width: 5,
                                              ),
                                              MyReportStatusIndicator(
                                                height: 10,
                                                width: 10,
                                                color: selectedReport[0]['AssignedTanod'] !=
                                                            null &&
                                                        selectedReport[0]
                                                                ['AssignedTanod'][selectedReport[0]
                                                                        [
                                                                        'AssignedTanod']
                                                                    .length -
                                                                1]['Status'] ==
                                                            'Responding'
                                                    ? Colors.orange
                                                    : selectedReport[0]
                                                                ['Category'] ==
                                                            'Latest'
                                                        ? Colors.green
                                                        : selectedReport[0]
                                                                    ['Category'] ==
                                                                'Dropped'
                                                            ? Colors.red
                                                            : Colors.grey,
                                              )
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          thickness: 1.5,
                                        ),
                                        MyReportDetails(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 15),
                                          width: screenSize.width,
                                          label: Text(
                                            'Area: ${getLocationName(locations, selectedReport[0]['LocationId'])}',
                                            style: tertiaryText.copyWith(
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        MyReportDetails(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 15),
                                          width: screenSize.width,
                                          label: Text(
                                            'Time: ${convertHour(dateTime.hour, 0)}:${dateTime.minute}:${dateTime.second} ${convertHour(dateTime.hour, 1)}',
                                            style: tertiaryText.copyWith(
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        MyReportDetails(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 15),
                                          width: screenSize.width,
                                          label: Text(
                                            'Date: ${convertMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year}',
                                            style: tertiaryText.copyWith(
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        MyReportDetails(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 15),
                                          width: screenSize.width,
                                          label: Text(
                                            "Violators Detected: ${selectedReport[0]['ViolatorCount']}",
                                            style: tertiaryText.copyWith(
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.only(
                                            top: 5,
                                          ),
                                          child: Divider(
                                            thickness: 5,
                                            color: Colors.grey[200],
                                          ),
                                        ),
                                        isAssigned ||
                                                selectedReport[0]['Category'] !=
                                                    'Latest'
                                            ? Container(
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                ),
                                                width: screenSize.width,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Apprehension Summary',
                                                          style: tertiaryText
                                                              .copyWith(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            print(
                                                                'Load Report Activity');
                                                            Navigator.of(
                                                                    context)
                                                                .push(
                                                              MaterialPageRoute(
                                                                builder: (ctx) =>
                                                                    DetailAssignedTanodsReport(
                                                                        id: widget
                                                                            .id),
                                                              ),
                                                            );
                                                          },
                                                          child: Text(
                                                            'View History',
                                                            style: tertiaryText
                                                                .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  customColor[
                                                                      130],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    MyReportDetails(
                                                      margin: EdgeInsets.only(
                                                        left: 10,
                                                        right: 10,
                                                        top: 5,
                                                      ),
                                                      width: screenSize.width,
                                                      label: Text(
                                                        'Tanod: ${setAssignTanodName()}',
                                                        style: tertiaryText
                                                            .copyWith(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    MyReportDetails(
                                                      margin: EdgeInsets.only(
                                                        left: 10,
                                                        right: 10,
                                                        top: 5,
                                                      ),
                                                      width: screenSize.width,
                                                      label: Text(
                                                        "Date: ${setDateTime(selectedReport[0]['AssignedTanod'][selectedReport[0]['AssignedTanod'].length - 1]['DateAssign'], 'Date')}",
                                                        style: tertiaryText
                                                            .copyWith(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    MyReportDetails(
                                                      margin: EdgeInsets.only(
                                                        left: 10,
                                                        right: 10,
                                                        top: 5,
                                                      ),
                                                      width: screenSize.width,
                                                      label: Text(
                                                        "Time: ${setDateTime(selectedReport[0]['AssignedTanod'][selectedReport[0]['AssignedTanod'].length - 1]['DateAssign'], 'Time')}",
                                                        style: tertiaryText
                                                            .copyWith(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    MyReportDetails(
                                                      margin: EdgeInsets.only(
                                                        left: 10,
                                                        right: 10,
                                                        top: 5,
                                                      ),
                                                      width: screenSize.width,
                                                      label: Text(
                                                        'Caught Violator: ${_calculateApprehendedViolatorCount()}',
                                                        style: tertiaryText
                                                            .copyWith(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    MyReportDetails(
                                                      margin: EdgeInsets.only(
                                                        left: 10,
                                                        right: 10,
                                                        top: 5,
                                                      ),
                                                      width: screenSize.width,
                                                      label: Text(
                                                        'Status: ${selectedReport[0]['AssignedTanod'][selectedReport[0]['AssignedTanod'].length - 1]['Status']}',
                                                        style: tertiaryText
                                                            .copyWith(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    MyReportDetails(
                                                      margin: EdgeInsets.only(
                                                        left: 10,
                                                        right: 10,
                                                        top: 5,
                                                        bottom: 5,
                                                      ),
                                                      width: screenSize.width,
                                                      label: Text(
                                                        'Remarks: ${selectedReport[0]['AssignedTanod'][selectedReport[0]['AssignedTanod'].length - 1]['Reason'] != null ? selectedReport[0]['AssignedTanod'][selectedReport[0]['AssignedTanod'].length - 1]['Reason'] : ''}',
                                                        style: tertiaryText
                                                            .copyWith(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                height: 250,
                                                alignment: Alignment.center,
                                                width: screenSize.width,
                                                child: Text(
                                                  'No Apprehension Yet',
                                                  style: tertiaryText.copyWith(
                                                    fontSize: 20,
                                                    color: Colors.grey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                        _calculateApprehendedViolatorCount() > 0
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Divider(
                                                    thickness: 1,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                          left: 15,
                                                        ),
                                                        child: Text(
                                                          'Documented Violators',
                                                          style: tertiaryText
                                                              .copyWith(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          print(
                                                              'Load Documented Violators');
                                                          Navigator.of(context)
                                                              .push(
                                                                  MaterialPageRoute(
                                                            builder: (ctx) =>
                                                                DetailDocumentedViolatorScreen(
                                                                    id: widget
                                                                        .id),
                                                          ));
                                                        },
                                                        child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                            right: 15,
                                                          ),
                                                          child: Text(
                                                            'View all',
                                                            style: tertiaryText
                                                                .copyWith(
                                                              fontSize: 14,
                                                              color:
                                                                  customColor[
                                                                      130],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  for (var item
                                                      in filterDocuments()
                                                          .reversed
                                                          .toList())
                                                    Card(
                                                      child: ListTile(
                                                        onTap: () {
                                                          if (checkIsAssigned(item[
                                                              'ViolatorId'])) {
                                                            print(
                                                                'Load Specific Documented Violator');
                                                            Navigator.of(
                                                                    context)
                                                                .push(
                                                              MaterialPageRoute(
                                                                builder: (ctx) =>
                                                                    ReportDocumentation(
                                                                  id: widget.id,
                                                                  tanodId: userData[
                                                                      'TanodId'],
                                                                  selectedViolatorId:
                                                                      item[
                                                                          "ViolatorId"],
                                                                  isFromNotification:
                                                                      widget
                                                                          .isFromNotification,
                                                                  auth: widget
                                                                      .auth,
                                                                  onSignOut: widget
                                                                      .onSignOut,
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            _scaffoldKeyDetailReports
                                                                .currentState!
                                                                // ignore: deprecated_member_use
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'The documentation you selected is not assigned to you',
                                                                ),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            3),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        leading: Container(
                                                          height: 30,
                                                          width: 30,
                                                          child: Image.asset(
                                                            'assets/images/verified-account.png',
                                                            width: 20,
                                                            height: 20,
                                                            fit: BoxFit
                                                                .fitHeight,
                                                            color: customColor[
                                                                130],
                                                          ),
                                                        ),
                                                        title: Align(
                                                          alignment: Alignment(
                                                              -1.1, 0),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                getViolatorSpecifiedInformation(
                                                                    violators,
                                                                    item[
                                                                        'ViolatorId'],
                                                                    'Name'),
                                                                style: tertiaryText
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14),
                                                              ),
                                                              Text(
                                                                "${setDateTime(item['DateApprehended'], 'Time')} / ${setDateTime(item['DateApprehended'], 'Date')}",
                                                                style: tertiaryText
                                                                    .copyWith(
                                                                        fontSize:
                                                                            11),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        trailing: Text(
                                                          "₱${item['Fine']}",
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    height: 80,
                                                  )
                                                ],
                                              )
                                            : Text('')
                                      ],
                                    ),
                                    floatingActionButtonLocation:
                                        FloatingActionButtonLocation
                                            .centerDocked,
                                    floatingActionButton: Container(
                                      width: screenSize.width,
                                      height: 90,
                                      child: isAssigned
                                          ? isAssignedToUser
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                        width:
                                                            screenSize.width *
                                                                .46,
                                                        height: 50,
                                                        child: MyOutlineButton(
                                                          elavation: 0,
                                                          color:
                                                              Color(0xff1c52dd),
                                                          radius: 10,
                                                          onPressed: () {
                                                            _buildCreateAssignConfirmaModal(
                                                                    context,
                                                                    'Drop')
                                                                .then((value) {
                                                              setState(() {});
                                                            });
                                                          },
                                                          isLoading: false,
                                                          text: Text(
                                                            'Drop Report',
                                                            style: tertiaryText
                                                                .copyWith(
                                                              fontSize: 18,
                                                              letterSpacing: 0,
                                                              color: Color(
                                                                  0xff1c52dd),
                                                            ),
                                                          ),
                                                        )),
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          left: 10),
                                                      height: 50,
                                                      width: screenSize.width *
                                                          .46,
                                                      child: MyFloatingButton(
                                                        onPressed: () {
                                                          print(
                                                              'Load Report Documentation');
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder: (ctx) =>
                                                                  ReportDocumentation(
                                                                id: widget.id,
                                                                tanodId: userData[
                                                                    'TanodId'],
                                                                isFromNotification:
                                                                    widget
                                                                        .isFromNotification,
                                                                auth:
                                                                    widget.auth,
                                                                onSignOut: widget
                                                                    .onSignOut,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        title: Text(
                                                          'Document Report',
                                                          style: tertiaryText
                                                              .copyWith(
                                                            fontSize: 18,
                                                            letterSpacing: 0,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        radius: 10,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Container()
                                          : isUserHasActiveReport ||
                                                  isTaggedReport
                                              ? Container()
                                              : Column(
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                        left: screenSize.width /
                                                            7.5,
                                                        bottom: 5,
                                                      ),
                                                      child: Text(
                                                        'Immediately respond to the scene',
                                                        style: tertiaryText
                                                            .copyWith(
                                                          color:
                                                              Colors.grey[700],
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                    ),
                                                    Container(
                                                      width:
                                                          screenSize.width * .8,
                                                      height: 50,
                                                      child: MyFloatingButton(
                                                        onPressed: () {
                                                          _buildCreateAssignConfirmaModal(
                                                                  context,
                                                                  'Assign')
                                                              .then((value) {
                                                            setState(() {});
                                                          });
                                                        },
                                                        title: Text(
                                                          'Respond',
                                                          style: tertiaryText
                                                              .copyWith(
                                                            fontSize: 20,
                                                            letterSpacing: 2,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        radius: 30,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                    ),
                                  );
                                });
                          });
                    },
                  );
                }))
        : Scaffold(body: MySpinKitLoadingScreen());
  }
}
