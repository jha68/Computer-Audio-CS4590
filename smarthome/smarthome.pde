import beads.*;
import org.jaudiolibs.beads.*;
import controlP5.*;
import com.sun.speech.freetts.*;

ControlP5 p5;

Button startEventStream;
Button pauseEventStream;
Button stopEventStream;

//to use text to speech functionality, copy text_to_speech.pde from this sketch to yours
//example usage below

//IMPORTANT (notice from text_to_speech.pde):
//to use this you must import 'ttslib' into Processing, as this code uses the included FreeTTS library
//e.g. from the Menu Bar select Sketch -> Import Library... -> ttslib

TextToSpeechMaker ttsMaker; 

//<import statements here>

//to use this, copy notification.pde, notification_listener.pde and notification_server.pde from this sketch to yours.
//Example usage below.

//name of a file to load from the data directory
String eventDataJSON2 = "smarthome_party.json";
String eventDataJSON1 = "smarthome_parent_night_out.json";

NotificationServer notificationServer;
ArrayList<Notification> notifications;

MyNotificationListener myNotificationListener;

void setup() {
  size(300,180);
  p5 = new ControlP5(this);
  
  ac = new AudioContext(); //ac is defined in helper_functions.pde
  
  //this will create WAV files in your data directory from input speech 
  //which you will then need to hook up to SamplePlayer Beads
  ttsMaker = new TextToSpeechMaker();
  
  String exampleSpeech = "Text to speech is okay, I guess.";
  
  ttsExamplePlayback(exampleSpeech); //see ttsExamplePlayback below for usage
  
  //START NotificationServer setup
  notificationServer = new NotificationServer();
  
  //instantiating a custom class (seen below) and registering it as a listener to the server
  myNotificationListener = new MyNotificationListener();
  notificationServer.addListener(myNotificationListener);
    
  //END NotificationServer setup
  
  startEventStream = p5.addButton("startEventStream")
    .setPosition(40,20)
    .setSize(150,20)
    .setLabel("Start Event Stream");
    
  startEventStream = p5.addButton("pauseEventStream")
    .setPosition(40,60)
    .setSize(150,20)
    .setLabel("Pause Event Stream");
 
  startEventStream = p5.addButton("stopEventStream")
    .setPosition(40,100)
    .setSize(150,20)
    .setLabel("Stop Event Stream");
    
  ac.start();
}

void startEventStream(int value) {
  //loading the event stream, which also starts the timer serving events
  notificationServer.loadEventStream(eventDataJSON1);
}

void pauseEventStream(int value) {
  //loading the event stream, which also starts the timer serving events
  notificationServer.pauseEventStream();
}

void stopEventStream(int value) {
  //loading the event stream, which also starts the timer serving events
  notificationServer.stopEventStream();
}

void draw() {
  //this method must be present (even if empty) to process events such as keyPressed()  
}

void keyPressed() {
  //example of stopping the current event stream and loading the second one
  if (key == RETURN || key == ENTER) {
    notificationServer.stopEventStream(); //always call this before loading a new stream
    notificationServer.loadEventStream(eventDataJSON2);
    println("**** New event stream loaded: " + eventDataJSON2 + " ****");
  }
    
}

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class MyNotificationListener implements NotificationListener {
  
  public MyNotificationListener() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) { 
    println("<Example> " + notification.getType().toString() + " notification received at " 
    + Integer.toString(notification.getTimestamp()) + " ms");
    
    String debugOutput = ">>> ";
    switch (notification.getType()) {
      case Door:
        debugOutput += "Door moved: ";
        break;
      case PersonMove:
        debugOutput += "Person moved: ";
        break;
      case ObjectMove:
        debugOutput += "Object moved: ";
        break;
      case ApplianceStateChange:
        debugOutput += "Appliance changed state: ";
        break;
      case PackageDelivery:
        debugOutput += "Package delivered: ";
        break;
      case Message:
        debugOutput += "New message: ";
        break;
    }
    debugOutput += notification.toString();
    //debugOutput += notification.getLocation() + ", " + notification.getTag();
    
    println(debugOutput);
    
   //You can experiment with the timing by altering the timestamp values (in ms) in the exampleData.json file
    //(located in the data directory)
  }
}

void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file
  
  //see helper_functions.pde for actual loading of the WAV file into a SamplePlayer
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!
  
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}
