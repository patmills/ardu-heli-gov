/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

#define THISFIRMWARE "ArduHeliGov V0.1"

/*
ArduHeliGov 0.1
Lead author:	Robert Lefebvre

This firmware is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is intended to operate with a maximum rotorspeed of 4000rpm.
4000rpm = 66.667rev/sec = 0.015sec/rev = 15ms/rev = 15000uS/rev
Also:
800rpm = 13.333rev/sec = 0.075sec/rev = 75ms/rev = 75000uS/rev

1ms accuracy would give between 10 and 250rpm resolution which is not acceptable
Thus, we must use microseconds to measure RPM.
Atmega chip operating at 16MHz has 4uS resolution, 8MHz gives 8uS resolution. 
4uS resolution will give an RPM resolution of ~ 0.05 to 1 rpm.
Better than 0.025% accuracy!

Maximum intended motor RPM is 50,000 representing a 450 heli running 4S battery
50000rpm = 833rev/sec = 0.0012sec/rev = 1200uS/rev
4uS accuracy would give 166rpm accuracy, or 0.3%.

micros() counter will overflow after ~70 minutes, we must protect for that
to avoid an error or blip in the speed reading.


*/

#include <SCDriver.h> 

unsigned int rpm;								// Latest RPM value
volatile unsigned long trigger_time;			// Trigger time of latest interrupt
volatile unsigned long trigger_time_old;		// Trigger time of last interrupt
unsigned long last_calc_time;					// Trigger time of last speed calculated
unsigned int timing;							// Timing of last rotation
unsigned int timing_old;						// Old rotation timing



static unsigned long fast_loopTimer;			// Time in microseconds of 1000hz control loop
static unsigned long fiftyhz_loopTimer;			// Time in microseconds of 50hz control loop
static unsigned long tenhz_loopTimer;			// Time in microseconds of the 10hz control loop
static unsigned long onehz_loopTimer;			// Time in microseconds of the 1hz control loop

unsigned int rotation_time;						// Time in microseconds for one rotation of rotor

SCDriver SCOutput;								// Create Speed Control output object

void setup(){
   Serial.begin(9600);
   attachInterrupt(0, rpm_fun, RISING);
   rpm = 0;
   SCOutput.attach(9);
}

void loop(){

	unsigned long timer = micros();

	if ((timer - fast_loopTimer) >= 1000){
	
		fast_loopTimer = timer;
		fastloop();

	}	
	
	if ((timer - fiftyhz_loopTimer) >= 20000) {
	
		fiftyhz_loopTimer = timer;
		mediumloop();
	
	}
	
	if ((timer - tenhz_loopTimer) >= 100000) {
	
		tenhz_loopTimer = timer;
		slowloop();
	
	}
	
	if ((timer - onehz_loopTimer) >= 1000000) {
	
		onehz_loopTimer = timer;
		superslowloop();
	
	}
	
}

void rpm_fun(){							//Each rotation, this interrupt function is run
	trigger_time_old = trigger_time;
	trigger_time = micros();
}

void fastloop(){			//1000hz stuff goes here

	if (last_calc_time < trigger_time){					//micros() timer has not overflowed
		
		if (last_calc_time != trigger_time){			//We have new timing data
			timing = trigger_time - trigger_time_old;
			timing = (timing + timing_old)/2;			//Simple filter
			last_calc_time = trigger_time;
		}
	}else{												//micros() timer has overflowed

		last_calc_time = trigger_time;					//we will skip this iteration

	}
}

void mediumloop(){			//50hz stuff goes here

	rpm = 60000000/timing;

}

void slowloop(){			//10hz stuff goes here

}

void superslowloop(){		//1hz stuff goes here

}



