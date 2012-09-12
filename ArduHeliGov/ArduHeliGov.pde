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

Measurement Type can be either Direct_Measurement, meaning actual
propeller measurement.  Or it can be Motor_Measurement.  Motor_Measurement
requires input of number of poles, and gear ratio.

*/

#include <SCDriver.h> 

#define BoardLED 13
#define RPM_Input_1 2
#define Direct_Measurement 1
#define Motor_Measurement 2
#define Measurement_Type Direct_Measurement
#define Motor_Poles 2
#define Gear_Ratio 2
#define PulsesPerRevolution 1


float rpm;										// Latest RPM value
volatile unsigned long trigger_time;			// Trigger time of latest interrupt
volatile unsigned long trigger_time_old;		// Trigger time of last interrupt
unsigned long last_calc_time;					// Trigger time of last speed calculated
unsigned long timing;							// Timing of last rotation
unsigned long timing_old;						// Old rotation timing



static unsigned long fast_loopTimer;			// Time in microseconds of 1000hz control loop
static unsigned long fiftyhz_loopTimer;			// Time in microseconds of 50hz control loop
static unsigned long tenhz_loopTimer;			// Time in microseconds of the 10hz control loop
static unsigned long onehz_loopTimer;			// Time in microseconds of the 1hz control loop
unsigned long timer;


unsigned int rotation_time;						// Time in microseconds for one rotation of rotor

SCDriver SCOutput;								// Create Speed Control output object



void setup(){
   Serial.begin(9600);
   pinMode(RPM_Input_1, INPUT_PULLUP);
   attachInterrupt(0, rpm_fun, RISING);
   rpm = 0;
   SCOutput.attach(9);
   Serial.println("Tachometer Test");
   pinMode(BoardLED, OUTPUT);
   
   
   
}

void loop(){

	timer = micros();

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
	
	trigger_time = micros();
}



void fastloop(){			//1000hz stuff goes here

	
	if (last_calc_time < trigger_time){					//micros() timer has not overflowed
		
		if (last_calc_time != trigger_time){			//We have new timing data
			timing_old = timing;
			timing = trigger_time - trigger_time_old;
			last_calc_time = trigger_time;
			trigger_time_old = trigger_time;
		}
	}else{												//micros() timer has overflowed

		last_calc_time = trigger_time;					//we will skip this iteration
		trigger_time_old = trigger_time;

	}
	
	}

void mediumloop(){			//50hz stuff goes here

#if Measurement_Type == Direct_Measurement
	rpm = (60000000.0/(float)timing)/PulsesPerRevolution;
#elif Measurement_Type == Motor_Measurement
	rpm = (((60000000.0/(float)timing)/Gear_Ratio)/(Motor_Poles/2));
#endif
	
}

void slowloop(){			//10hz stuff goes here

}

void superslowloop(){		//1hz stuff goes here

Serial.print ("RPM =");
Serial.println(rpm);
Serial.print ("Timing =");
Serial.println(timing);

}



