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

int temperature_mode = 0;

double temp;
double humidity;

double reference_humidity = 50;
double reference_temperature = 37.0;

double FSR;

void setup()
{
    /*
     * Heater relay PinMode direction as Output
     * intialized as Low signal.
     */
    pinMode(heater, OUTPUT);
    digitalWrite(heater, LOW);

    /*
     * Blower relay PinMode direction as Output
     * intialized as Low signal.
     */
    pinMode(blower, OUTPUT);
    digitalWrite(blower, LOW);

    /*
     * Baud Rate Serial as 9600
     * Delay for 500 ms to untill checking stablity state
     * Delay for 1000 ms before accessing Sensor
     */
    Serial.begin(9600);
    delay(500);  // Delay to let system boot
    delay(1000); // Wait before accessing Sensor

} // end "setup()"

void loop()
{
    // Start of Program

    // get the four readings for the temperature sensed
    /*
     *   Top Right thermistor readings
     *   Top Left thermistor readings
     *   Bottom Right thermistor readings
     *   Bottom left thermistor readings
     */
    thermoReadTR = getTemp(thermoTR);
    thermoReadTL = getTemp(thermoTL);
    thermoReadBR = getTemp(thermoBR);
    thermoReadBL = getTemp(thermoBL);
    thermoReadBM = getTemp(thermoBM);

    /*
     * Get Humidity rate
     */
    dhtRead = getDHT();

    // Declaring the message's dilamiter
    String x = ",";
    String start_end = "#";

    /*
     * Send data stream as array of strings
     * ["#", "thermoReadTR", "," , "thermoReadTL", "," , "thermoReadBR", "," , "thermoReadBL", ","
     * , "thermoReadBM", ",", "Humidity", "#"]
     */
    String Data = start_end + String(thermoReadTR) + x + String(thermoReadTL) + x + String(thermoReadBR) + x +
                  String(thermoReadBL) + x + String(thermoReadBM) + x + String(humidity) + start_end;
    Serial.print(Data);
    delay(1000);

    String message = String(Serial.parseInt(), DEC);
    /*
     *  Recieve tempMode 
     */
    String message_tempMode = String(message[0]);
    temperature_mode = message_tempMode.toDouble();

    /*
     *  Check if temp_mode not equal zero --> take the whole data stream   
     */
    if (temperature_mode != 0)
    {
    // Temperature Notification
    String message_temp = String(message[1]) + String(message[2]) + '.' + String(message[3]);
    reference_temperature = message_temp.toDouble();

    // Humidity Notification
    String message_humidity = String(message[4]) + String(message[5]) + '.' + string(message[6]);
    reference_humidity = message_humidity.toDouble();
    }

    /*
     *   1 ---> Air Mode
     *   0 ---> Baby Mode
     */
    if (temperature_mode == 1)
    {
        /*
         * Air Mode activated
         *     --> Get Average temperature of the four thermistors
         *           ~ Condition (Average temperature < refrence temperature sent)
         *               # Turn on Blower to heat
         *           ~ Otherwise
         *               # Close turn off the blower
         *           ~ Condition (Humidity < reference humidity sent)
         *               # Turn on the heater to get water vabour to increase the humidity
         *           ~  Otherwise
         *                # Turn off the heater
         */
        double AVG_temp = (thermoReadTR + thermoReadTL + thermoReadBR + thermoReadBM) / 4;

        if (AVG_temp < reference_temperature)
        {
            digitalWrite(blower, HIGH);
        }
        else
        {
            digitalWrite(blower, LOW);
        }

        if (humidity < reference_humidity)
        {
            digitalWrite(heater, HIGH);
        }
        else
        {
            digitalWrite(heater, LOW);
        }
    }
    else if (temperature_mode == 2)
    {
        /*
         * Baby Mode activated
         *           ~ Condition (Baby temperature < refrence temperature sent)
         *               # Turn on Blower to heat
         *           ~ Otherwise
         *               # Close turn off the blower
         *           ~ Condition (Humidity < reference humidity sent)
         *               # Turn on the heater to get water vabour to increase the humidity
         *           ~  Otherwise
         *                # Turn off the heater
         */

        if (thermoReadBM < reference_temperature)
        {
            digitalWrite(blower, HIGH);
        }
        else
        {
            digitalWrite(blower, LOW);
        }

        if (humidity < reference_humidity)
        {
            digitalWrite(heater, HIGH);
        }
        else
        {
            digitalWrite(heater, LOW);
        }
    }

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
    temperature = (1 / (0.001129148 + (0.000234125 * therm_res_ln) + (0.0000000876741 * therm_res_ln * therm_res_ln * therm_res_ln))); /* Temperature in Kelvin */
    temperature = temperature - 273.15;                                                                                                /* Temperature in degree Celsius */

    return temperature;
}