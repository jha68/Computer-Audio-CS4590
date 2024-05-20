import controlP5.*;
import processing.video.*;
import ddf.minim.*;
import ddf.minim.effects.*;

BandPass highPassFilter;
ControlP5 cp5;
Button btnScenario1, btnScenario2, btnScenario3, btnReplayTTS, btnMinimizeAlerts, btnMaximizeAlerts;;
Toggle blurVideo;
Slider[] volumeSliders1 = new Slider[5];
Slider[] volumeSliders2 = new Slider[4];
Movie subwayScenario;
Movie subwayScenarioBlurred;
Movie shoppingScenario;
Movie shoppingScenarioBlurred;
NotificationServer server;
TextToSpeechMaker ttsMaker;
Minim minim;
AudioPlayer objectAlertSound;
AudioPlayer directionalGuidanceSound;
AudioPlayer amenitiesAlertSound;
AudioPlayer trainIncomingMusic;
AudioPlayer subwayAudio;
AudioPlayer shoppingAudio;
boolean isScenario1 = false;
boolean isScenario2 = false;

AudioPlayer itemFoundAlertSound;
AudioPlayer itemLocatorAlertSound;
AudioPlayer itemLocatorMusic;
boolean showFirstSet = true;  // This boolean controls which set of sliders is shown
Toggle toggleSliderSet;

void setup() {
  size(800, 500);
  cp5 = new ControlP5(this);
  server = new NotificationServer();
  ttsMaker = new TextToSpeechMaker();
  minim = new Minim(this);
  objectAlertSound = minim.loadFile("object_alert.mp3");
  directionalGuidanceSound = minim.loadFile("directional_guidance.mp3");
  amenitiesAlertSound = minim.loadFile("amenities_alert.mp3");
  trainIncomingMusic = minim.loadFile("train_incoming_music.mp3");
  server.addListener(new NotificationListener() {
    void notificationReceived(Notification notification) {
      if (!notification.getNote().isEmpty()) {
          // Before playing TTS, decrease volumes
          decreaseVolume(0.4); // Decrease volumes by 30%
          ttsMaker.createTTSWavFile(notification.getNote());
          
          // Schedule volume restoration after the TTS duration
          new java.util.Timer().schedule(new TimerTask() {
              @Override
              public void run() {
                  restoreVolume();
              }
          }, notification.getDuration());
      }
      float panValue = 0; // Center by default
      if (notification.getLocation().equals("Left")) {
          panValue = -1; // Pan fully to the left
      } else if (notification.getLocation().equals("Right")) {
          panValue = 1; // Pan fully to the right
      }
      switch (notification.getType()) {
          case ObstacleAlert:
              objectAlertSound.setPan(panValue);
              playObstacleAlertWithIncreasingFrequency(notification.getDuration());
              break;
          case DirectionalGuidance:
              directionalGuidanceSound.setPan(panValue);
              playDirectionalGuidanceWithIncreasingFrequency(notification.getDuration());
              break;
          case AmenitiesAlert:
              amenitiesAlertSound.setPan(panValue);
              playAmenitiesAlertWithIncreasingFrequency(notification.getDuration());
              break;
          case TrainIncomingMusic:
              trainIncomingMusic.setPan(panValue);
              playSingleTrainIncomingMusic(notification.getDuration());
              break;
          case ItemFoundAlert:
              itemFoundAlertSound.play(); // Play the alert sound
              break;
          case ItemLocator:
              if (notification.getDuration() > 0) { // Check if duration is provided
                  playItemLocatorWithDuration(notification.getDuration());
              }
              adjustLocatorMusicPan(notification.getLocation());
              break;
      }
    }
  });
  subwayScenario = new Movie(this, "subway.mp4");
  subwayAudio = minim.loadFile("subway_audio.mp3", 2048);
  subwayScenarioBlurred = new Movie(this, "subway_blurred.mp4");
  shoppingScenario = new Movie(this, "shopping.mp4");
  shoppingAudio = minim.loadFile("shopping_audio.mp3", 2048);
  shoppingScenarioBlurred = new Movie(this, "shopping_blurred.mp4");

  // Scenario buttons
  btnScenario1 = cp5.addButton("Scenario 1")
                    .setPosition(20, height - 100)
                    .setSize(100, 40)
                    .setId(1);
  
  btnScenario2 = cp5.addButton("Scenario 2")
                    .setPosition(130, height - 100)
                    .setSize(100, 40)
                    .setId(2);
                    
  btnScenario3 = cp5.addButton("Stop")
                    .setPosition(20, height - 50)
                    .setSize(100, 40)
                    .setId(3);

  // Volume sliders
  String[] labels1 = {"Outside", "Obstacle", "Amenity", "Navigator", "Transit"};
  for (int i = 0; i < volumeSliders1.length; i++) {
    volumeSliders1[i] = cp5.addSlider(labels1[i])
                          .setPosition(380 + i*60, height - 100)
                          .setSize(20, 80)
                          .setRange(0, 100)
                          .setValue(50)
                          .setLabel(labels1[i]);
  }
  String[] labels2 = {"outside", "Proximity", "ItemFound", "ItemLocator"};
  for (int i = 0; i < volumeSliders2.length; i++) {
    volumeSliders2[i] = cp5.addSlider(labels2[i])
                          .setPosition(440 + i*60, height - 100)
                          .setSize(20, 80)
                          .setRange(0, 100)
                          .setValue(50)
                          .setLabel(labels2[i]);
  }
  cp5.getController("Outside").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      subwayAudio.setGain(map(val, 0, 100, -10, 10)); // Map slider value to gain
    }
  });

  cp5.getController("Obstacle").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      objectAlertSound.setGain(map(val, 0, 100, -10, 10));
    }
  });

  cp5.getController("Amenity").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      amenitiesAlertSound.setGain(map(val, 0, 100, -10, 10));
    }
  });

  cp5.getController("Navigator").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      directionalGuidanceSound.setGain(map(val, 0, 100, -10, 10));
    }
  });
  cp5.getController("Transit").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      trainIncomingMusic.setGain(map(val, 0, 100, -10, 10));
    }
  });
  btnReplayTTS = cp5.addButton("Replay TTS")
                    .setPosition(130, height - 50)
                    .setSize(100, 40)
                    .setLabel("Replay TTS")
                    .onClick(new CallbackListener() {
                        public void controlEvent(CallbackEvent event) {
                            ttsMaker.replayLastTTS();
                        }
                    });
  btnMinimizeAlerts = cp5.addButton("Minimize Alerts")
  .setPosition(680, height - 100)  // Adjust position as needed
  .setSize(100, 40)
  .setLabel("Minimize Alerts")
  .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
          setMinimizedAlertVolumes();
      }
  });

  btnMaximizeAlerts = cp5.addButton("Maximize Alerts")
    .setPosition(680, height - 50)  // Adjust position as needed
    .setSize(100, 40)
    .setLabel("Maximize Alerts")
    .onClick(new CallbackListener() {
        public void controlEvent(CallbackEvent event) {
            setMaximizedAlertVolumes();
        }
  });

  // Video blur toggle
  blurVideo = cp5.addToggle("Blur Video")
                   .setPosition(250, height - 100)
                   .setSize(50, 20)
                   .setValue(false)
                   .setMode(ControlP5.SWITCH);
                   
  itemFoundAlertSound = minim.loadFile("item_found_alert.mp3");
  itemLocatorAlertSound = minim.loadFile("item_locator_alert.mp3");
  itemLocatorMusic = minim.loadFile("item_locator_music.mp3", 2048);
  highPassFilter = new BandPass(500, 200, itemLocatorMusic.sampleRate());
  cp5.getController("outside").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      shoppingAudio.setGain(map(val, 0, 100, -10, 10));
    }
  });
  cp5.getController("Proximity").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      itemLocatorAlertSound.setGain(map(val, 0, 100, -10, 10));
    }
  });
  cp5.getController("ItemFound").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      itemFoundAlertSound.setGain(map(val, 0, 100, -10, 10));
    }
  });
  cp5.getController("ItemLocator").addListener(new ControlListener() {
    public void controlEvent(ControlEvent e) {
      float val = e.getValue();
      itemLocatorMusic.setGain(map(val, 0, 100, -10, 10));
    }
  });
  toggleSliderSet = cp5.addToggle("toggleSliderSet")
                     .setPosition(310, height - 100)
                     .setSize(50, 20)
                     .setValue(true)
                     .setMode(ControlP5.SWITCH)
                     .setLabel("Toggle Sliders")
                     .onChange(new CallbackListener() {
                        public void controlEvent(CallbackEvent event) {
                            showFirstSet = !showFirstSet; // Toggle between true and false
                            updateSliderVisibility();
                        }
                     });
    updateSliderVisibility();
}

void updateSliderVisibility() {
    for (Slider slider : volumeSliders1) {
        slider.setVisible(showFirstSet); // Set visibility based on the toggle state
    }
    for (Slider slider : volumeSliders2) {
        slider.setVisible(!showFirstSet); // Set visibility opposite to the toggle state
    }
}

void setMinimizedAlertVolumes() {
    volumeSliders1[0].setValue(70); // Set Outside noise higher
    volumeSliders1[1].setValue(30); // Lower alert sounds
    volumeSliders1[2].setValue(30); // Lower alert sounds
    volumeSliders1[3].setValue(30); // Lower alert sounds
    volumeSliders1[4].setValue(30); // Lower alert sounds
    volumeSliders2[0].setValue(70);
    volumeSliders2[1].setValue(30);
    volumeSliders2[2].setValue(30);
    volumeSliders2[3].setValue(30);
    updateAudioGains();
}

void setMaximizedAlertVolumes() {
    volumeSliders1[0].setValue(30); // Set Outside noise lower
    volumeSliders1[1].setValue(70); // Maximize alert sounds
    volumeSliders1[2].setValue(70); // Maximize alert sounds
    volumeSliders1[3].setValue(70); // Maximize alert sounds
    volumeSliders1[4].setValue(70); // Maximize alert sounds
    volumeSliders2[0].setValue(30);
    volumeSliders2[1].setValue(70);
    volumeSliders2[2].setValue(70);
    volumeSliders2[3].setValue(70);
    updateAudioGains();
}

void updateAudioGains() {
    subwayAudio.setGain(map(volumeSliders1[0].getValue(), 0, 100, -10, 10));
    objectAlertSound.setGain(map(volumeSliders1[1].getValue(), 0, 100, -10, 10));
    amenitiesAlertSound.setGain(map(volumeSliders1[2].getValue(), 0, 100, -10, 10));
    directionalGuidanceSound.setGain(map(volumeSliders1[3].getValue(), 0, 100, -10, 10));
    trainIncomingMusic.setGain(map(volumeSliders1[4].getValue(), 0, 100, -10, 10));
}

float[] originalVolumes = new float[5]; // Array to hold original volume levels
float originalVolume;
// Method to decrease volume by a certain percentage (e.g., 30%)
void decreaseVolume(float percentage) {
  originalVolumes[0] = volumeSliders1[0].getValue();
  originalVolumes[1] = volumeSliders1[1].getValue();
  originalVolumes[2] = volumeSliders1[2].getValue();
  originalVolumes[3] = volumeSliders1[3].getValue();
  originalVolumes[4] = volumeSliders1[4].getValue();
  originalVolume = volumeSliders2[3].getValue();

  // Decrease volume of all audio players by the given percentage
  subwayAudio.setGain(map(originalVolumes[0] * percentage, 0, 100, -10, 10));
  trainIncomingMusic.setGain(map(originalVolumes[4] * percentage, 0, 100, -10, 10));
  itemLocatorMusic.setGain(map(originalVolume * percentage, 0, 100, -10, 10));
}

// Method to restore original volume
void restoreVolume() {
  subwayAudio.setGain(map(originalVolumes[0], 0, 100, -10, 10));
  trainIncomingMusic.setGain(map(originalVolumes[4], 0, 100, -10, 10));
  itemLocatorMusic.setGain(map(originalVolume, 0, 100, -10, 10));
}

void playSingleTrainIncomingMusic(int duration) {
  trainIncomingMusic.rewind();
  trainIncomingMusic.play();
}
void playObstacleAlertWithIncreasingFrequency(final int duration) {
  new Thread(new Runnable() {
    public void run() {
      long startTime = millis();
      int interval = 1000; // Start with 1 second between plays
      while (millis() - startTime < duration) {
        objectAlertSound.rewind();
        objectAlertSound.play();
        
        try {
          Thread.sleep(interval);
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
        
        interval = max(200, interval - 300);
      }
    }
  }).start();
}

void playDirectionalGuidanceWithIncreasingFrequency(final int duration) {
  new Thread(new Runnable() {
    public void run() {
      long startTime = millis();
      int interval = 1000;
      while (millis() - startTime < duration) {
        directionalGuidanceSound.rewind();
        directionalGuidanceSound.play();
        
        try {
          Thread.sleep(interval);
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
        interval = max(150, interval - 150);
      }
    }
  }).start();
}

void playAmenitiesAlertWithIncreasingFrequency(final int duration) {
  new Thread(new Runnable() {
    public void run() {
      long startTime = millis();
      int interval = 1000;
      while (millis() - startTime < duration) {
        amenitiesAlertSound.rewind();
        amenitiesAlertSound.play();
        
        try {
          Thread.sleep(interval);
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
        interval = max(150, interval - 150);
      }
    }
  }).start();
}

void draw() {
  background(0);
  // UI elements are drawn by ControlP5
  if (isScenario1) {
      if (!blurVideo.getState()) {
        pushMatrix();
        translate(width/2, height/2);
        image(subwayScenario, -subwayScenario.height, -subwayScenario.width / 5);
        popMatrix();
      } else {
        // Play the blurred Video
        pushMatrix();
        translate(width/2, height/2);
        image(subwayScenarioBlurred, -subwayScenario.height, -subwayScenario.width / 5);
        popMatrix();
      }
  } else if (isScenario2) {
      if (!blurVideo.getState()) {
        pushMatrix();
        translate(width/2, height/2); 
        image(shoppingScenario, -shoppingScenario.height, -shoppingScenario.width / 5);
        popMatrix();
      } else {
        // Play the blurred Video
        pushMatrix();
        translate(width/2, height/2);
        image(shoppingScenarioBlurred, -shoppingScenario.height, -shoppingScenario.width / 5);
        popMatrix();
      }
  }
}

void movieEvent(Movie m) {
  m.read();
}

// These methods will be called when the scenario buttons are pressed
public void controlEvent(ControlEvent event) {
  if (event.isAssignableFrom(Button.class)) {
    switch(event.getController().getId()) {
      case 1:
        triggerScenario(1);
        isScenario1 = true;
        isScenario2 = false;
        break;
      case 2:
        triggerScenario(2);
        itemLocatorMusic.loop();
        isScenario2 = true;
        isScenario1 = false;
        break;
      case 3:
        stopAllMedia();
    }
  }
}

void triggerScenario(int scenarioNumber) {
  if (scenarioNumber == 1) {
    stopAllMedia();
    subwayAudio.play();
    subwayScenario.play();
    subwayScenarioBlurred.play();
    server.loadEventStream("subwayEvents.json");
  } else if (scenarioNumber == 2) {
    stopAllMedia();
    shoppingAudio.play();
    shoppingScenario.play();
    shoppingScenarioBlurred.play();
    server.loadEventStream("shoppingEvents.json");
  }
  println("Scenario " + scenarioNumber + " triggered with blur effect: " + !blurVideo.getState());
}

void stopAllMedia() {
    subwayScenario.pause();
    subwayScenario.jump(0);
    subwayScenarioBlurred.pause();
    subwayScenarioBlurred.jump(0);
    subwayAudio.pause();
    subwayAudio.rewind();
    trainIncomingMusic.pause();
    trainIncomingMusic.rewind();
    server.stopEventStream();
    shoppingScenario.pause();
    shoppingScenario.jump(0);
    shoppingScenarioBlurred.pause();
    shoppingScenario.jump(0);
    shoppingAudio.pause();
    shoppingAudio.rewind();
    itemLocatorMusic.pause();
    itemLocatorMusic.rewind();
}

void playItemLocatorWithDuration(final int duration) {
    new Thread(new Runnable() {
        public void run() {
            long startTime = millis();
            int interval = 1000;
            int factor = 2;
            while (millis() - startTime < duration) {
                itemLocatorAlertSound.rewind();
                itemLocatorAlertSound.play();
                
                try {
                    Thread.sleep(interval);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                factor = (int) Math.ceil(factor * 1.2);
                interval = Math.max(500, interval - factor);
            }
        }
    }).start();
}

void adjustLocatorMusicPan(String location) {
    if (location.equals("Left")) {
        itemLocatorMusic.setPan(-1.0); // Pan fully to the left
    } else if (location.equals("Right")) {
        itemLocatorMusic.setPan(1.0); // Pan fully to the right
    } else if (location.equals("Straight")) {
        itemLocatorMusic.setPan(0.0); // Centered, play on both speakers
    }
    if (location.equals("Back")) {
        itemLocatorMusic.setPan(0.0); // Keep centered
        itemLocatorMusic.addEffect(highPassFilter); // Apply high pass filter
    } else {
      itemLocatorMusic.removeEffect(highPassFilter);
    }
}
