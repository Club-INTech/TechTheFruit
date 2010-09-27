#include <HardwareSerial.h>
#include <wiring.h>

#include "LectureSerieActionneurs.h"

LectureSerie::LectureSerie() 
{
	// Moteur orange
	pinMode(9, OUTPUT);
	pinMode(10, OUTPUT);
	
	analogWrite(9, 0);  // Puissance
	analogWrite(10, 0); // Sens
	
	// Jumper
	pinMode(2, INPUT);
	
	// Led ready
	pinMode(12, OUTPUT);
	digitalWrite(12, 0);
}

/*
 * Fonction à mettre dans le loop()
 */
void
LectureSerie::traitement() {
	char premierCaractere;
	while (Serial.available() == 0) {
		asm("nop");
	}
	premierCaractere = Serial.read();
	
	long int i;
	long int p, q;
	switch (premierCaractere) {
	case '?':
		Serial.println("1");
		break;
	case 'a':
		analogWrite(9, 0);
		analogWrite(10, 0); 
		Serial.println("1");
		break;
	case 'b':
		analogWrite(9, 64); 
		analogWrite(10, 0); 
		Serial.println("1");
		break;
	case 'c':
		analogWrite(9, 64); 
		digitalWrite(10, 1);
		Serial.println("1"); 
		break;
	case 'd':
		Serial.println(digitalRead(2));
		break;
	case 'e':
		digitalWrite(12, 1);
		break;
	default:
		break;
	}
}

bool
LectureSerie::litEntierLong(long int *i)
{
	long int aux = 0;
	int j;
	long int k = 10000000;
	char c = 0;
	for (j = 0; j < 8; j++) {
		while (Serial.available()==0) { 
			asm("nop");
		}
		c = Serial.read();
		if (c < 48 || c > 57) {
			aux = -1;
			break;
		}
		aux += (c - 48) * k;
		k /= 10;
	} 
	*i = aux;
}

LectureSerie lectureSerie;
