#include "Asservissement.h"

#define ABS(x) 		((x) < 0 ? - (x) : (x))
#define MAX(a,b) 	((a) > (b) ? (a) : (b)) 
#define MIN(a,b) 	((a) < (b) ? (a) : (b)) 

Asservissement::Asservissement()
{
	// Constante de l'asservissement et du mouvement
	maxPWM = 	PUISSANCE;
	Kp = 		KP;
	Vmax = 		VMAX;
	Acc = 		ACC;
	
	// Consigne par défaut et position du robot à l'initialisation
	positionIntermediaire = 0;
	consigne = 0;
	
	positionIntermediaireZoom = 0;
	consigneZoom = 0;
	
	// Palier de vitesse
	n = 0;
	
	// Aucun blocage à l'initialisation
	blocageDetecte = 0;
	
	// Calcul de l'erreur maximum afin de détecter les blocages
	calculeErreurMax();
}

/*
 * Calcule la puissance moteur à fournir pour atteindre la nouvelle position théorique
 */
 
int 
Asservissement::calculePwm(long int positionReelle)
{
	long int pwm = Kp * (positionIntermediaire - positionReelle) / 2;
	
	if (pwm > maxPWM) {
		pwm = maxPWM;
	}
	else if (pwm < -maxPWM ) {
		pwm = -maxPWM;
	}
	
	
	return pwm;
}

/*
 * Calcule la nouvelle position à atteindre
 */
 
void 
Asservissement::calculePositionIntermediaire(long int positionReelle)
{
	long int delta = consigneZoom - positionIntermediaireZoom;
	
	dFreinage = (Acc * (ABS(n) + 1) * (ABS(n) + 2)) / 2;
	if (ABS(delta) >=  dFreinage) {
		if (delta >= 0) {
			n++;
			if (Acc * n >  Vmax) {
				n--;
				if (Acc * n > Vmax)
					n--;
			}
		}
		else {
			n--;
			if (Acc * n < -Vmax) {
				n++;
				if (Acc * n < -Vmax)
					n++;
			}
		}
	}
	else {
		if (n > 0) {
			n--;
		}
		else if (n < 0) {
			n++;
		}
	}

	long int erreur = positionIntermediaireZoom - positionReelle * PRESCALER;

	if (ABS(erreur) < erreurMax) {
		positionIntermediaireZoom += n * Acc;
		blocageDetecte = 0;
	}
	else if (erreur >= 0) {	
		positionIntermediaireZoom = positionReelle * PRESCALER + erreurMax;
		blocageDetecte = 1;
	}
	else {
		positionIntermediaireZoom = positionReelle * PRESCALER - erreurMax;
		blocageDetecte = -1;
	}
	
	positionIntermediaire = positionIntermediaireZoom / PRESCALER;
}

/*
 * Calcule l'erreur maximum (positionReelle et positionIntermediaire) afin de déterminer le blocage
 */

void 
Asservissement::calculeErreurMax()
{
	erreurMax = PRESCALER * 2 * maxPWM / Kp;  
}

/*
 * Arrêt progressif du moteur
 */
 
void 
Asservissement::stop()
{
	if (n > 0)
		consigneZoom = positionIntermediaireZoom + dFreinage;
	else
		consigneZoom = positionIntermediaireZoom - dFreinage;	
}

/*
 * Arrete le moteur à la position courante
 */
 
void 
Asservissement::stopUrgence(long int positionReelle)
{
	changeConsigne(positionReelle);
	n = 0;
}


/*
 * Définit la nouvelle consigne
 */
 
void 
Asservissement::changeConsigne(long int consigneDonnee)
{
	consigne = consigneDonnee;
	consigneZoom = consigneDonnee * PRESCALER;
}

/*
 * Définition dynamique des constantes
 */
void 
Asservissement::changeKp(int KpDonne)
{
	Kp = KpDonne;
	calculeErreurMax();
}


void 
Asservissement::changePWM(int maxPwmDonne)
{
	maxPWM = maxPwmDonne;
	calculeErreurMax();
}

void 
Asservissement::changeAcc(long int AccDonne)
{
	Acc = AccDonne;
}

void
Asservissement::changeVmax(long int VmaxDonne)
{
	Vmax = VmaxDonne;
}

void
Asservissement::reset() 
{
	positionIntermediaire = 0;
	consigne = 0;
	
	positionIntermediaireZoom = 0;
	consigneZoom = 0;
	
	n = 0;
	
	blocageDetecte = 0;
}
