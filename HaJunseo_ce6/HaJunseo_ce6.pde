import controlP5.*;
import beads.*;
import java.util.Arrays;
  
AudioContext ac;
ControlP5 p5;

int waveCount = 10;
float baseFrequency = 440.0;
Buffer CosineBuffer = new CosineBuffer().getDefault();
Glide[] waveFrequency = new Glide[waveCount];
Gain[] waveGain = new Gain[waveCount];
Gain masterGain;
Glide masterGainGlide;
WavePlayer[] waveTone = new WavePlayer[waveCount];

Button b1, b2, b3, b4;
Slider [] s = new Slider[10];

void setup() {
  size(600, 400);
  float waveIntensity = 1.0;
  ac = new AudioContext();
  p5 = new ControlP5(this);
  
  masterGainGlide = new Glide(ac, .2, 200);  
  masterGain = new Gain(ac, 1, masterGainGlide);
  ac.out.addInput(masterGain);
  for( int i = 0, n = 1; i < waveCount; i++, n++) {
    waveFrequency[i] = new Glide(ac, baseFrequency * n, 200);
    
    waveTone[i] = new WavePlayer(ac, waveFrequency[i], Buffer.SINE);
    
    waveIntensity = n == 1 ? 1.0 : 0;
    waveGain[i] = new Gain(ac, 1, waveIntensity);
    waveGain[i].addInput(waveTone[i]);
    masterGain.addInput(waveGain[i]);
  }
  p5.addButton("modeSwitch").setPosition(410, 10).setSize(180, 30).setLabel("Mode").activateBy((ControlP5.RELEASE));
  b1 = p5.addButton("sineButton").setPosition(410, 50).setSize(180, 30).setLabel("Sine").activateBy((ControlP5.RELEASE));
  b2 = p5.addButton("squareButton").setPosition(410, 90).setSize(180, 30).setLabel("Square").activateBy((ControlP5.RELEASE));
  b3 = p5.addButton("triangleButton").setPosition(410, 130).setSize(180, 30).setLabel("Triangle").activateBy((ControlP5.RELEASE));
  b4 = p5.addButton("sawtoothButton").setPosition(410, 170).setSize(180, 30).setLabel("Sawtooth").activateBy((ControlP5.RELEASE));
  
  s[0] = p5.addSlider("fundamentalFreqSlider").setPosition(410, 50).setSize(180, 15). setRange(55, 3520).setValue(baseFrequency).setLabel("F").hide();
  s[1] = p5.addSlider("gainSlider1").setPosition(410, 70).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("1").hide();
  s[2] = p5.addSlider("gainSlider2").setPosition(410, 90).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("2").hide();
  s[3] = p5.addSlider("gainSlider3").setPosition(410, 110).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("3").hide();
  s[4] = p5.addSlider("gainSlider4").setPosition(410, 130).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("4").hide();
  s[5] = p5.addSlider("gainSlider5").setPosition(410, 150).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("5").hide();
  s[6] = p5.addSlider("gainSlider6").setPosition(410, 170).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("6").hide();
  s[7] = p5.addSlider("gainSlider7").setPosition(410, 190).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("7").hide();
  s[8] = p5.addSlider("gainSlider8").setPosition(410, 210).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("8").hide();
  s[9] = p5.addSlider("gainSlider9").setPosition(410, 230).setSize(180, 15). setRange(0, 1).setValue(0).setLabel("9").hide();
  ac.start();
}

boolean sliders = false;

public void modeSwitch() {
  sliders = !sliders;
  if (sliders) {
    b1.hide();
    b2.hide();
    b3.hide();
    b4.hide();
    for (int i = 0; i < 10; i++) {
      s[i].show();
    }
  } else {
    b1.show();
    b2.show();
    b3.show();
    b4.show();
    for (int i = 0; i < 10; i++) {
      s[i].hide();
    }
  }
}

public void fundamentalFreqSlider(float v) {
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveFrequency[i].setValue(v * n);
  }
}
public void gainSlider1(float v) {waveGain[1].setGain(v);}
public void gainSlider2(float v) {waveGain[2].setGain(v);}
public void gainSlider3(float v) {waveGain[3].setGain(v);}
public void gainSlider4(float v) {waveGain[4].setGain(v);}
public void gainSlider5(float v) {waveGain[5].setGain(v);}
public void gainSlider6(float v) {waveGain[6].setGain(v);}
public void gainSlider7(float v) {waveGain[7].setGain(v);}
public void gainSlider8(float v) {waveGain[8].setGain(v);}
public void gainSlider9(float v) {waveGain[9].setGain(v);}

public void sineButton() {
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(Buffer.SINE);
    if (i > 0) {
      s[i].setValue(n == 1 ? 1.0 : 0);
    }
  }
}
public void squareButton() {
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(Buffer.SINE);
    if (i > 0) {
      s[i].setValue((n % 2 == 1) ? (float) (1.0 / n) : 0);
    }
  }
}

public void triangleButton() {
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(CosineBuffer);
    if (i > 0) {
      s[i].setValue((n % 2 == 1) ? (1.0 / sq(n)) : 0);
    }
  }
}

public void sawtoothButton() {
  for (int i = 0, n = 1; i < waveCount; i++, n++) {
    waveTone[i].setBuffer(Buffer.SINE);
    if (i > 0) {
      s[i].setValue(1.0 / n);
    }
  }
}

void draw() {
  fill (0, 32, 0 , 32);
  rect (0, 0, 400, 400);
  stroke(32);
  for (int i = 0; i < 11; i++) {
    line(0, i * 75, 400, i * 75);
    line( i * 75 + 25, 0, i * 75 + 25, 400);
  }
  stroke(0);
  line(400 / 2, 0, 400/2, 400);
  line(0, 400/2, 400, 400/2);
  stroke(128, 255, 128);
  int crossing = 0;
  for (int i = 0; i < ac.getBufferSize() - 1 && i < 400 + crossing; i++) {
    if (crossing == 0 && ac.out.getValue(0, i) < 0 && ac.out.getValue(0, i + 1) > 0) crossing = i;
    if (crossing != 0) {
      line( i - crossing, 400/2 + ac.out.getValue(0, i) * 300, i + 1 - crossing, 400/2 + ac.out.getValue(0, i + 1) * 300);
    }
  }
  
  fill(0);
  stroke(0);
  rect(400, 0, 200, 400);
}
