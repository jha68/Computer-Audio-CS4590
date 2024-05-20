// FFT_01.pde
// This example is based in part on an example included with
// the Beads download originally written by Beads creator
// Ollie Bown. It draws the frequency information for a
// sound on screen.
import beads.*;
import controlP5.*;

ControlP5 p5;

Button noFilter;
Button lowPassFilter;
Button highPassFilter;
Button bandPassFilter;
Button micOn;
Button resynthButton;
Slider resynthGainSlider;
Slider cutOffFreqSlider;

PowerSpectrum ps;
Frequency f;
Glide frequencyGlide;
WavePlayer wp;
Gain gain;
Glide glide;
PeakDetector beatDetector;

float meanFrequency = 400.0;

color fore = color(255, 255, 255);
color back = color(0,0,0);
color highlight = color(255, 0, 0);

int setHeight = 600;
boolean isResynth = false;

SamplePlayer player = null;
Gain g;
boolean micToggle = false;
UGen microphoneIn;

float ellipseColor = 0;
BiquadFilter filter;
void setup() {
  size(1000, 750);
  p5 = new ControlP5(this);
  
  ac = new AudioContext();
  microphoneIn = ac.getAudioInput();
  
  // set up a master gain object
  g = new Gain(ac, 1, 0.5);
  ac.out.addInput(g);
  
  // set up second gain for resynthesized sine wave and add to ac.out
  //ac.out.addInput(yourSecondGain);
  
  // load up a sample included in code download
  try {
    // Load up a new SamplePlayer using an included audio
    // file.
    
    player = getSamplePlayer("accordian.wav",false);
    player.setLoopType(SamplePlayer.LoopType.valueOf("LOOP_FORWARDS"));
  }
  catch(Exception e) {
    // If there is an error, print the steps that got us to
    // that error.
    e.printStackTrace();
  }

  // Set up a WavePlayer and a Glide that will control its frequency
  // This WavePlayer will resynthesize the detected strongest frequency from FFT analysis
  //yourSecondGain.addInput(yourResynthesizedWavePlayer); // connect the WavePlayer to the second Gain
  filter = new BiquadFilter(ac, BiquadFilter.AP, 1000.0, 0.5f);
  filter.addInput(player);
  g.addInput(filter);  
  
  // In this block of code, we build an analysis chain
  // the ShortFrameSegmenter breaks the audio into short,
  // discrete chunks.
  ShortFrameSegmenter sfs = new ShortFrameSegmenter(ac);
  sfs.addInput(filter);

  // FFT stands for Fast Fourier Transform
  // all you really need to know about the FFT is that it
  // lets you see what frequencies are present in a sound
  // the waveform we usually look at when we see a sound
  // displayed graphically is time domain sound data
  // the FFT transforms that into frequency domain data
  FFT fft = new FFT();
  // connect the FFT object to the ShortFrameSegmenter
  sfs.addListener(fft);

  // the PowerSpectrum pulls the Amplitude information from
  // the FFT calculation (essentially)
  ps = new PowerSpectrum();
  // connect the PowerSpectrum to the FFT
  fft.addListener(ps);
  
  // The Frequency object tries to guess the strongest
  // frequency for the incoming data. This is a tricky
  // calculation, as there are many frequencies in any real
  // world sound. Further, the incoming frequencies are
  // effected by the microphone being used, and the cables
  // and electronics that the signal flows through.
  
  // Create a new Frequency UGen and add it to th ps PowerSpectrum via addListener() - see 9.3
  f = new Frequency(44100.0f);
  ps.addListener(f);
  frequencyGlide = new Glide(ac, 50, 10);
  gain = new Gain(ac, 1, 0);
  wp = new WavePlayer(ac, frequencyGlide, Buffer.SINE);
  gain.addInput(wp);
  ac.out.addInput(gain);
  
  SpectralDifference spec = new SpectralDifference(ac.getSampleRate());
  ps.addListener(spec);
  beatDetector = new PeakDetector();
  spec.addListener(beatDetector);
  beatDetector.setAlpha(.9f);
  beatDetector.setThreshold(.2f);
  beatDetector.addMessageListener(
    new Bead() {
      protected void messageReceived(Bead b) { ellipseColor = 1.0; }
    }
  );
  // list the frame segmenter as a dependent, so that the
  // AudioContext knows when to update it.
  ac.out.addDependent(sfs);

  noFilter = p5.addButton("noFilter")
    .setPosition(20, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("No Filter");

  lowPassFilter = p5.addButton("lowPassFilter")
    .setPosition(120, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Low Pass");

  highPassFilter = p5.addButton("highPassFilter")
    .setPosition(220, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("High Pass");
  
  bandPassFilter = p5.addButton("bandPassFilter")
    .setPosition(320, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Band Pass");
  
  cutOffFreqSlider = p5.addSlider("cutOffFreqSlider")
    .setPosition(20, height - 100)
    .setSize(380, 20)
    .setRange(20, 15000)
    .setValue(2000)
    .setLabel("Cutoff Frequency");

  micOn = p5.addButton("micOn")
    .setPosition(500, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Mic Toggle");

  resynthButton = p5.addButton("resynthButton")
    .setPosition(600, height - 70)
    .setSize(80, 50)
    .activateBy((ControlP5.RELEASE))
    .setLabel("Resynth Toggle");
    
  resynthGainSlider = p5.addSlider("resynthGainSlider")
    .setPosition(600, height - 100)
    .setSize(300 ,20)
    .setRange(0, 100)
    .setValue(50)
    .setLabel("Resynth Gain");

  // start processing audio
  ac.start();
}
// In the draw routine, we will interpret the FFT results and
// draw them on screen.

void draw()
{
  int strongestFreqIndex = 0;
  
  background(back);
  stroke(fore);
  // Find strongest frequency and comput meanFrequency - see 9.3
  //
  
  // draw the average frequency on screen
  fill(255);
  text(" Dectected Strongest Frequency: " + meanFrequency, 500, 100);
  text(" Beat Indicator: ", 500, 125);
  
  if (f.getFeatures() != null && random(1.0) > .75) {
    float freq = f.getFeatures();
    if (freq < 3000) {
      meanFrequency = 0.6 * meanFrequency + 0.4 * freq;
      frequencyGlide.setValue(meanFrequency);
    }
  }
  
  strongestFreqIndex = (int) ((meanFrequency / 19980.0) * 256.0);

  // The getFeatures() function is a key part of the Beads
  // analysis library. It returns an array of floats
  // how this array of floats is defined (1 dimension, 2
  // dimensions ... etc) is based on the calling unit
  // generator. In this case, the PowerSpectrum returns an
  // array with the power of 256 spectral bands.
  float[] features = ps.getFeatures();
  // if any features are returned
  if(features != null)
    {
    // for each x coordinate in the Processing window
    for(int x = 0; x < width; x++)
    {
      // figure out which featureIndex corresponds to this x-
      // position
      int featureIndex = (x * features.length) / width;
      // calculate the bar height for this feature
      int barHeight = Math.min((int)(features[featureIndex] *
      setHeight), setHeight - 1);
      // draw a vertical line corresponding to the frequency
      // represented by this x-position
      
      // Draw strongest frequency as a red bar
      if (featureIndex == strongestFreqIndex) {
        stroke(highlight);
      }
      else {
        stroke(fore);
      }
      line(x, setHeight, x, setHeight - barHeight);
    }
  }
  drawBeatIndicator(600, 122);
}

int time;
void drawBeatIndicator(float x, float y) {
  fill(255 * ellipseColor);
  ellipse(x, y, 15, 15);
  int dt = millis() - time;
  ellipseColor -= (dt * 0.01);
  if (ellipseColor < 0) ellipseColor = 0;
  time = millis();
}
void cutOffFreqSlider(float value) {
  filter.setFrequency(value);
}

void lowPassFilter() {
  filter.setType(BiquadFilter.LP);
}
void highPassFilter() {
  filter.setType(BiquadFilter.HP);
}
void bandPassFilter() {
  filter.setType(BiquadFilter.BP_SKIRT);
}

void noFilter() {
  filter.setType(BiquadFilter.AP);
}

void micOn() {
  if(!micToggle){
    g.setGain(1.0f);
    micToggle = true;
    stateSwitcher();
  } else {
    g.setGain(.3f);
    micToggle = false;
    stateSwitcher();
  }
}
float resynth = 0;
void resynthGainSlider(float value) {
  // change resynthesis gain
  if (isResynth) {
    gain.setGain(value / 100);
  }
  resynth = value / 100;
}

void resynthButton() {
  // switch on resynthesis
  isResynth = !isResynth;
  if (isResynth) {
    g.setGain(0.075);
    gain.setGain(resynth);
  } else {
    g.setGain(0.5);
    gain.setGain(0);
  }
}

void stateSwitcher() {
  filter.clearInputConnections();
  
  if (micToggle) {
    filter.addInput(microphoneIn);
  } else {
    filter.addInput(player);
  }
  
  // if resynthesis is on, modify UGen graph to play your WavePlayer
  if (isResynth) {
    filter.addInput(gain);
  }
}
