import 'package:flutter/material.dart';

class Machine {
  int machineID;
  String animalID;
  String userID;
  int openTimes;
  static int counter = 0;

  Machine({
    required this.machineID,
    required this.animalID,
    required this.userID,
    required this.openTimes,
  });

  void openFood() {

  }

  void setOpenTimes(int times) {
    openTimes = times;
  }

  void setAnimalID(String animal) {
    animalID=animal;
  }


  void setUserID(String userID) {
    this.userID = userID;
  }

  int getMachineID() {
    return machineID;
  }
}
