import controlP5.*;  // Libraries for user interface components
import beads.*;      // Libraries for handling audio
import org.jaudiolibs.beads.*; // Extended functionality for audio processing

// Global Variables
AudioContext ac; // Main audio processing context

// Audio processing components
BiquadFilter filter;  // Filter for audio effects
float HP_CUTOFF = 1000.0;  // High-pass filter threshold

// User interface elements
ControlP5 p5;  // Controller for GUI elements
SamplePlayer backgroundMusic, v1, v2;  // Players for various audio tracks

// Volume control
Gain gain, duckGain;  // Controllers for audio volume

// Smooth transitions
Glide gainGlide, duckGainGlide, filterGlide;  // Tools for smooth parameter changes

// Variables for storing gain values
float gainAmount, duckGainAmount;
boolean isPlaying = true;
// Function to load an audio sample
Sample getSample(String fileName) {
  return SampleManager.sample(dataPath(fileName)); 
}

SamplePlayer getSamplePlayer(String fileName) {
  SamplePlayer player = null;
  try {
    player = new SamplePlayer(ac, getSample(fileName));
    player.setKillOnEnd(false);
    player.setName(fileName);
  } catch(Exception e) {
    println("Error occurred loading " + fileName);
  }
  return player;
}

// Initial setup
void setup() {
  size(320, 240);
  ac = new AudioContext();
  p5 = new ControlP5(this);
  
  // Load audio samples
  backgroundMusic = getBGM("background_loop.wav");
  v1 = getVoice("voice1.wav");
  v2 = getVoice("voice2.wav");
  
  // Set up audio controls
  gainGlide = new Glide(ac, 1.0, 500);
  gain = new Gain(ac, 1, gainGlide);
 
  duckGainGlide = new Glide(ac, 1.0, 500);
  duckGain = new Gain(ac, 1, duckGainGlide);
  
  filterGlide = new Glide(ac, 10.0, 500);
  filter = new BiquadFilter(ac, BiquadFilter.Type.HP, filterGlide, .5);
  
  // Configure audio pipeline
  filter.addInput(backgroundMusic);
  duckGain.addInput(filter);
  gain.addInput(duckGain);
  gain.addInput(v1);
  gain.addInput(v2);
  
  // Create GUI elements
  p5.addSlider("GainSlider").setPosition(20, 20)
    .setSize(20, 200)
    .setValue(50)
    .setRange(0, 100)
    .setLabel("Master Gain");
  p5.addButton("voice1")
    .setPosition(width/2 - 20, 80)
    .setSize(width/2 - 20, 20)
    .setLabel("Voice 1");
  p5.addButton("voice2")
    .setPosition(width/2 - 20, 110)
    .setSize(width/2 - 20, 20)
    .setLabel("Voice 2");
  p5.addButton("toggleBGM")
    .setPosition(width/2 - 20, 140)
    .setSize(width/2 - 20, 20)
    .setLabel("START/STOP BGM");
  p5.addButton("stopVoice")
    .setPosition(width/2 - 20, 170)
    .setSize(width/2 - 20, 20)
    .setLabel("STOP VOICE");   
  ac.out.addInput(gain);
  ac.start();
}

// Function for handling voice 1
void voice1() {
  v2.pause(true);  // Pause second voice
  v1.setToLoopStart();        // Play first voice
  v1.start();
  duckGainGlide.setValue(.5);  // Adjust ducking gain
  filterGlide.setValue(HP_CUTOFF);  // Adjust filter cutoff
}

// Function for handling voice 2
void voice2() {
  v1.pause(true);  // Pause first voice
  v2.setToLoopStart();        // Play second voice
  v2.start();
  duckGainGlide.setValue(.5);  // Adjust ducking gain
  filterGlide.setValue(HP_CUTOFF);  // Adjust filter cutoff
}

// Function to control overall gain through a slider
void GainSlider(float val) {
  gainGlide.setValue(val / 100);  // Convert slider value to gain value
}

// Function to prepare background music player
SamplePlayer getBGM(String file) {
  SamplePlayer b = getSamplePlayer(file);
  b.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  return b;
}

// Function to prepare voice player
SamplePlayer getVoice(String file) {
  final SamplePlayer voice = getSamplePlayer(file);
  voice.pause(true);
  voice.setEndListener(new Bead() {
    public void messageReceived(Bead m) {
      voice.pause(true);
      voice.setToLoopStart();
      filterGlide.setValue(isTalking() ? HP_CUTOFF : 1);
      duckGainGlide.setValue(1.0);
    }
  });
  return voice;
}

// Function to check if either voice is playing
boolean isTalking() {
  return !v1.isPaused() || !v2.isPaused();
}

void toggleBGM() {
  if (isPlaying) {
    backgroundMusic.pause(true);
    isPlaying = false;
  } else {
    backgroundMusic.start();
    isPlaying = true;
  }
}

void stopVoice() {
  v1.pause(true);
  v2.pause(true);
  filterGlide.setValue(1.0);
  duckGainGlide.setValue(1.0);
}

// Function to draw the interface
void draw() {
  background(0);  // Clear the screen
}
