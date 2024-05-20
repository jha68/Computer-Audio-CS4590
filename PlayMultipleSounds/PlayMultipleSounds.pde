import controlP5.*;
import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;

//declare global variables at the top of your sketch
//AudioContext ac; is declared in helper_functions

ControlP5 p5;

Gain masterGain;

// queue of sound filenames to play //<>//
Queue<String> soundsToPlay;

boolean isSoundPlaying = false; 

//end global variables

//runs once when the Play button above is pressed
void setup() {
  size(320, 240); //size(width, height) must be the first line in setup()

  ac = new AudioContext(); //AudioContext ac; is declared in helper_functions  //<>//
  p5 = new ControlP5(this);

  // Button to play SamplePlayer from beginning
  p5.addButton("Play")
    .setPosition(width / 2 - 20, 110)
    .setSize(width / 2 - 20, 20)
    .activateBy((ControlP5.RELEASE));
  
  // create queue of sound filenames to play in sequence
  soundsToPlay = new LinkedList<String>();

  // set up a master gain object
  masterGain = new Gain(ac, 1, 0.8);
  ac.out.addInput(masterGain);

  ac.start();
}

// load filenames for sounds into the global soundsToPlay Queue before calling PlaySounds()
// Note: You should have a way to prent PlaySounds() from being called again while the current
// list of sounds is still playing. For example, you could use the global isSoundPlaying, or another
// global flag, to prevent PlaySounds from being called while the current list of sounds is still playing.
public void PlaySounds() {
  String soundFile = soundsToPlay.poll();
  
  if (soundFile != null) {
    // These SamplePlayers are set to killOnEnd
    SamplePlayer sound = getSamplePlayer(soundFile, true);
    sound.pause(true);
    masterGain.addInput(sound);
    
    // create endListener for first sound
    Bead endListener = new Bead() {
      public void messageReceived(Bead message) {
        // the message parameter is the SamplePlayer that triggered the
        // endListener handler, so cast it to SamplePlayer to use
        // use it's member functions
        SamplePlayer sp = (SamplePlayer) message;
        // necessary to remove this endListener or it could fire again - bug in Beads?
        sp.setEndListener(null);
        
        println("Done playing " + sp.getSample().getFileName());
        // Try to play next sound in the queue
        PlaySounds();
      }
    };
    
    // start playing first sound
    if (!isSoundPlaying) {
      println("isSoundPlaying = true");
    }
    isSoundPlaying = true;
    sound.setEndListener(endListener);
    sound.start();
  }
  else {
    isSoundPlaying = false;
    println("isSoundPlaying = false");
  }  
} //<>//

// Button handler for Play button
public void Play(int value){
  soundsToPlay.add("one.wav");
  soundsToPlay.add("meow.wav");
  soundsToPlay.add("two.wav");
  soundsToPlay.add("meow.wav");
  soundsToPlay.add("three.wav");
  soundsToPlay.add("four.wav");
  soundsToPlay.add("meow.wav");
  soundsToPlay.add("five.wav");
  PlaySounds();
  
  println("play button pressed");
}


// Main draw loop - normally only used for immediate mode graphics rendering
void draw() {
  background(0);  //fills the canvas with black (0) each frame
}
