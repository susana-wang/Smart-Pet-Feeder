import 'package:flutter/material.dart';

class Machine {
  int machineID;
  String animalID;
  String userID;
  int openTimes;
  static int counter = 0;


  Machine(this.animalID, this.userID, this.openTimes): machineID= counter++;

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
