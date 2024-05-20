import controlP5.*;
import beads.*;

ControlP5 p5;
SamplePlayer music;
double musicLength;
Bead musicEndListener;
Glide musicRateGlide;
AudioContext ac;

SamplePlayer play;
SamplePlayer stop;
SamplePlayer fastforward;
SamplePlayer rewind;
SamplePlayer reset;

void setup() {
  size(200, 150);
  ac = new AudioContext();
  p5 = new ControlP5(this);

  play = getSamplePlayer("play.wav", ac);
  stop = getSamplePlayer("stop.wav", ac);
  reset = getSamplePlayer("reset.wav", ac);
  fastforward = getSamplePlayer("fastforward.wav", ac);
  rewind = getSamplePlayer("rewind.wav", ac);
  
  music = getSamplePlayer("musictoplay.mp3");
  musicLength = music.getSample().getLength();
  musicRateGlide = new Glide(ac, 0, 550);
  music.setRate(musicRateGlide);

  musicEndListener =  new Bead() {
    public void messageReceived(Bead message) {
      music.setEndListener(null);
      if (music.getPosition() >= musicLength && musicRateGlide.getValue() > 0) {
        musicRateGlide.setValueImmediately(0);
        music.setToEnd();
      }
      if (music.getPosition() <= 0.0 && musicRateGlide.getValue() < 0) {
        musicRateGlide.setValueImmediately(0);
        music.reset();
      }
    }
  };
  p5.addButton("Play")
    .setSize(width / 2, 20)
    .setPosition(width / 2 - 50, 10);

  p5.addButton("Rewind")
    .setSize(width / 2, 20)
    .setPosition(width / 2 - 50, 35);

  p5.addButton("FastForward")
    .setSize(width / 2, 20)
    .setPosition(width / 2 - 50, 60);
    
  p5.addButton("Stop")
    .setSize(width / 2, 20)
    .setPosition(width / 2 - 50, 85);

  p5.addButton("Reset")
    .setSize(width / 2, 20)
    .setPosition(width / 2 - 50, 110);
    
  ac.out.addInput(music);
  ac.out.addInput(play);
  ac.out.addInput(stop);
  ac.out.addInput(reset);
  ac.out.addInput(fastforward);
  ac.out.addInput(rewind);
  ac.start();
}

public void setPlaybackRate(float rate, boolean isNow) {
  if (music.getPosition() >= musicLength) {
    println("End of tape");
    music.setToEnd();
  }
  
  if (music.getPosition() < 0) {
    println("Beginning of the tape");
    music.reset();
  }
  
  if(isNow) {
    musicRateGlide.setValueImmediately(rate);
  } else {
    musicRateGlide.setValue(rate);
  }
}

public void Play()
{
  println("Now playing");
  play.getRateUGen().setValue(1);
  if (music.getPosition() < musicLength) {
    setPlaybackRate(1, false);
    music.setEndListener(musicEndListener);
    musicRateGlide.setValue(1);
  }
}
// Create similar button handlers for fast-forward and rewind

public void Stop() {
  stop.getRateUGen().setValue(1);
  println("Music stopped");
  setPlaybackRate(0, false);
  musicRateGlide.setValue(0);
}

public void Rewind() {
  println("Rewinding...");
  rewind.getRateUGen().setValue(1);
  if (music.getPosition() > 0) {
    setPlaybackRate(-4, false);
    music.setEndListener(musicEndListener);
  }
}

public void Reset() {
  reset.getRateUGen().setValue(1);
  music.reset();
  setPlaybackRate(0, true);
}

public void FastForward() {
  println("Forwarding...");
  fastforward.getRateUGen().setValue(1);
  if (music.getPosition() < musicLength) {
    setPlaybackRate(4, false);
    music.setEndListener(musicEndListener);
  }
}
public SamplePlayer getSamplePlayer(String fileName, AudioContext ac) {
  final SamplePlayer sp = getSamplePlayer(fileName);
  final Glide gl = new Glide(ac, 0, 0); // initially, set rate to 0, otherwise, music will play when you start the sketch
  sp.setRate(gl);
  sp.setEndListener(new Bead() {
    public void messageReceived(Bead b) {
      gl.setValueImmediately(0);
      sp.setToLoopStart();
    }
  });
  return sp;
}

SamplePlayer getSamplePlayer(String fileName) {
  SamplePlayer player = null;
  try {
    player = new SamplePlayer(ac, SampleManager.sample(dataPath(fileName)));
    player.setKillOnEnd(false);
    player.setName(fileName);
  } catch(Exception e) {
    println("Error occurred loading " + fileName);
  }
  return player;
}
void draw() {
  background(0);  //fills the canvas with black (0) each frame
}
