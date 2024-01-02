#include <FirebaseArduino.h>
#include <SoftwareSerial.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>


#define firebase_host "hidden_for_privacy"
#define firebase_auth "hidden_for_privacy"
const char *Wifissid = "hidden_for_privacy";
const char *Wifipassword = "hidden_for_privacy";
const char *mqtt_server = "Broker.hivemq.com";
const char *port = "1883";
const int alarmreset = D7;
int totalCars = 0;
int carsToday =0;

WiFiClient espClient;
PubSubClient client(espClient);     
SoftwareSerial mySerial(D5, D6);

void setup()
{
  Serial.begin(9600);
  mySerial.begin(9600);
  connectToWifi();
  connectToBroker();
  Firebase.begin(firebase_host,firebase_auth); 
  pinMode(alarmreset, INPUT_PULLUP);
  carsToday = 0;
  delay(2000);
}

void loop()
{
  int resetbuttonstate = digitalRead(alarmreset);
  if (resetbuttonstate == LOW)
  {
    carsToday = 0;
  }
  if (WiFi.status() != WL_CONNECTED)
  {
    connectToWifi();
  }
  if (!client.connected())
  {
    connectToBroker();
  }
  while (mySerial.available() > 0)
  {
    char dataChar = mySerial.read();
    
    String data;
    if (dataChar == 'A')
    {
      data = "Slot1 is Free";
      client.publish("Slot1IoT2022CS", data.c_str());
      Firebase.setString("/Parking Slot 1", data);
       if (Firebase.failed()) {
      Serial.print("slot 1   freee /number failed:");
      Serial.println(Firebase.error());  
      return;
  }
  else
  {
    Serial.println("A Done");
  }
    }
    else if (dataChar == 'B')
    {
      data = "Slot1 is Full";
      client.publish("Slot1IoT2022CS", data.c_str());
      Firebase.setString("/Parking Slot 1", data);
       if (Firebase.failed()) {
      Serial.print("slot 1 fill /number failed:");
      Serial.println(Firebase.error());  
      return;
  }
  else
  {
    Serial.println("B Done");
  }
    }
    else if (dataChar == 'C')
    {
      data = "Slot2 is Free";
      client.publish("Slot2IoT2022CS", data.c_str());
      Firebase.setString("/Parking Slot 2", data);
       if (Firebase.failed()) {
      Serial.print("slot 2 ffree /number failed:");
      Serial.println(Firebase.error());  
      return;
  }else
  {
    Serial.println("C Done");
  }
    }
    else if (dataChar == 'D')
    {
      data = "Slot2 is Full";
      client.publish("Slot2IoT2022CS", data.c_str());
      Firebase.setString("/Parking Slot 2", data);
       if (Firebase.failed()) {
      Serial.print("slot 2 fill /number failed:");
      Serial.println(Firebase.error());  
      return;
  }else
  {
    Serial.println("Done");
  }
    }
    else if (dataChar == 'E')
    {
      totalCars++;
      data = String(totalCars);
      client.publish("CarEntryIoT2022CS", data.c_str());
      Firebase.setString("/Total Cars", data);
       if (Firebase.failed()) {
      Serial.print("Total car /number failed:");
      Serial.println(Firebase.error());  
      return;
  }else
  {
    Serial.println("E Total Done");
  }
      carsToday++;
      data = String(carsToday);
      client.publish("NewCarEntryIoT2022CS", data.c_str());
      Firebase.setString("/Cars Today", data);
       if (Firebase.failed()) {
      Serial.print("New Car /number failed:");
      Serial.println(Firebase.error());  
      return;
  }else
  {
    Serial.println("E new Done");
  }
    }
  }
}

void connectToBroker()
{
  client.setServer(mqtt_server, atoi(port));
  while (!client.connected())
  {
    if (client.connect("ESP8266Client"))
    {
    }
    else
    {
      Serial.print("Failed to Connect to Broker, rc=");
      Serial.print(client.state());
    }
  }
}

void connectToWifi()
{
  WiFi.begin(Wifissid, Wifipassword);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");
}
