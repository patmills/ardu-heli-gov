/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

#define THISFIRMWARE "ArduHeliGov V0.1"

/*
ArduHeliGov 0.1
Lead author:	Robert Lefebvre

This firmware is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

*/

#include <SCDriver.h> 

volatile byte rpmcount;
unsigned int rpm;
unsigned long timeold;
int pos = 0;    // variable to store the servo position 

SCDriver SCOutput;

void setup(){
   Serial.begin(9600);
   attachInterrupt(0, rpm_fun, RISING);
   rpmcount = 0;
   rpm = 0;
   timeold = 0;
   SCOutput.attach(9);
}

void loop(){

	if (rpmcount >= 20) { 
		//Update RPM every 20 counts, increase this for better RPM resolution,
		//decrease for faster update
		rpm = 30*1000/(millis() - timeold)*rpmcount;
		timeold = millis();
		rpmcount = 0;
		Serial.println(rpm,DEC);
	}
	
	for(pos = 0; pos < 1000; pos += 10){ 	// goes from 0% to 100% 
											// in steps of 1%
		SCOutput.write(pos);            	// tell servo to go to position in variable 'pos' 
		delay(15);                      	// waits 15ms for the servo to reach the position 
	} 
	
	for(pos = 1000; pos>=10; pos-=10){    	// goes from 100% to 0%                              
		SCOutput.write(pos);              	// tell servo to go to position in variable 'pos' 
		delay(15);                       	// waits 15ms for the servo to reach the position 
	} 
}

void rpm_fun(){
	rpmcount++;
	//Each rotation, this interrupt function is run twice
}

