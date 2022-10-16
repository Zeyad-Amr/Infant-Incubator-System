#include <dht.h>

#define dht_apin A0 // Analog Pin dht

#define thermoTR A1 // Analog Pin for thermistor
#define thermoTL A2 // Analog Pin for thermistor
#define thermoBR A3 // Analog Pin for thermistor
#define thermoBL A4 // Analog Pin for thermistor
#define thermoBM A5 // Analog Pin for thermistor

#define heater 7
#define blower 8

dht DHT;

double thermoReadTR;
double thermoReadTL;
double thermoReadBR;
double thermoReadBL;
double thermoReadBM;
double dhtRead;

bool temperature_mode;

double temp;
double humidity;

void setup()
{

    Serial.begin(9600);
    delay(500);  // Delay to let system boot
    delay(1000); // Wait before accessing Sensor

} // end "setup()"

void loop()
{
    // Start of Program
    thermoReadTR = getTemp(thermoTR);
    thermoReadTL = getTemp(thermoTL);
    thermoReadBR = getTemp(thermoBR);
    thermoReadBL = getTemp(thermoBL);
    thermoReadBM = getTemp(thermoBM);

    dhtRead = getDHT();
    // Declaring the message's dilamiter
    String x = ",";

    /*
     *   0 ---> Air Mode
     *   1 ---> Baby Mode
     */
    String customed_reference_temperature = String(Serial.parseInt(), DEC);

    if (temperature_mode)
    {

        double AVG_temp = (thermoReadTR + thermoReadTL + thermoReadBR + thermoReadBM) / 4;

        // get the four readings for the temperature sensed
        /*
         *   Top Right thermistor readings
         *   Top Left thermistor readings
         *   Bottom Right thermistor readings
         *   Bottom left thermistor readings
         */
        String thermoReadTR_notification = x + "TR_" + String(thermoReadTR);
        Serial.print(thermoReadTR_notification);
        delay(1000);

        String thermoReadTL_notification = x + "TL_" + String(thermoReadTL);
        Serial.print(thermoReadTL_notification);
        delay(1000);

        String thermoReadBR_notification = x + "BR_" + String(thermoReadBR);
        Serial.print(thermoReadBR_notification);
        delay(1000);

        String thermoReadBL_notification = x + "BL_" + String(thermoReadBL);
        Serial.print(thermoReadBL_notification);
        delay(1000);

        // getting humidity AND sending Humidity in Air Mode
        humidity = dhtRead;
        String humidity_notification = x + "HR_" + String(humidity);
        Serial.print(humidity_notification);
        delay(1000);
    }
    else
    {
        String thermoReadBM_notification = x + "BM_" + String(thermoReadBM);
        Serial.print(thermoReadBM_notification);
        delay(1000);

        // getting humidity AND sending Humidity in Air Mode
        humidity = dhtRead;
        String humidity_notification = x + "HR_" + String(humidity);
        Serial.print(humidity_notification);
        delay(1000);
    }
    // Fastest should be once every two seconds.

} // end loop(

double getDHT()
{
    double dht = DHT.read11(dht_apin);
    delay(5000); // Wait 5 seconds before accessing sensor again.
    return DHT.humidity;
}

double getTemp(double thermistor_output)
{
    int thermistor_adc_val;
    double output_voltage, thermistor_resistance, therm_res_ln, temperature;
    thermistor_adc_val = analogRead(thermistor_output);
    output_voltage = ((thermistor_adc_val * 5.0) / 1023.0);
    thermistor_resistance = ((5 * (10.0 / output_voltage)) - 10); /* Resistance in kilo ohms */
    thermistor_resistance = thermistor_resistance * 1000;         /* Resistance in ohms   */
    therm_res_ln = log(thermistor_resistance);
    /*  Steinhart-Hart Thermistor Equation: */
    /*  Temperature in Kelvin = 1 / (A + B[ln(R)] + C[ln(R)]^3)   */
    /*  where A = 0.001129148, B = 0.000234125 and C = 8.76741*10^-8  */
    temperature = (1 / (0.001129148 + (0.000234125 * therm_res_ln) + (0.0000000876741 * therm_res_ln * therm_res_ln * therm_res_ln))); /* Temperature in Kelvin */
    temperature = temperature - 273.15;                                                                                                /* Temperature in degree Celsius */

    return temperature;
}