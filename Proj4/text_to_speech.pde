//IMPORTANT:
//to use this you must import 'ttslib' into Processing, as this code uses the included FreeTTS library
//e.g. from the Menu Bar select Sketch -> Import Library... -> ttslib
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.FloatControl;
import javax.sound.sampled.LineUnavailableException;
import javax.sound.sampled.UnsupportedAudioFileException;
import javax.sound.sampled.Line;
import java.io.File;
import java.io.IOException;
import com.sun.speech.freetts.FreeTTS;
import com.sun.speech.freetts.Voice;
import com.sun.speech.freetts.VoiceManager;

class TextToSpeechMaker {

  final String TTS_FILE_DIRECTORY_NAME = "tts_samples";
  final String TTS_FILE_PREFIX = "tts";
  private String lastTTSFile = "";
  
  File ttsDir;
  boolean isSetup = false;
  
  int fileID = 0;
  
  FreeTTS freeTTS;
  
  private Voice voice;
    
  public TextToSpeechMaker() {
    
    System.setProperty("freetts.voices", "com.sun.speech.freetts.en.us.cmu_us_kal.KevinVoiceDirectory");
    voice = VoiceManager.getInstance().getVoice("kevin16");
    //using other voices is not supported (unfortunately), so you are stuck with Kevin16
    
    //find our tts_sample directory and clean it out if it has files from a previous running of this sketch
    findTTSDirectory();
    cleanTTSDirectory();
    
    freeTTS = new FreeTTS(voice);
    freeTTS.setMultiAudio(true);
    freeTTS.setAudioFile(getTTSFilePath() + "/" + TTS_FILE_PREFIX + ".wav");
    
    freeTTS.startup();
    voice.allocate();
  }
  public void replayLastTTS() {
        if (!lastTTSFile.isEmpty()) {
            playAudioFile(lastTTSFile);
        }
  }
  //creates a WAV file of the input speech and returns the path to that file 
  public void createTTSWavFile(String input) {
    String filePath = getTTSFilePath() + "/" + TTS_FILE_PREFIX + Integer.toString(fileID) + ".wav";
    fileID++;
    voice.speak(input);
    playAudioFile(filePath); //you will need to use dataPath(filePath) if you need the full path to this file, see Example
    lastTTSFile = filePath;
  }
  void playAudioFile(String filePath) {
      try {
          File file = new File(dataPath(filePath));
          if (file.exists()) {
              AudioInputStream ais = AudioSystem.getAudioInputStream(file);
              Clip clip = AudioSystem.getClip();
              clip.open(ais);
  
              // Check if volume control is supported
              if (clip.isControlSupported(FloatControl.Type.MASTER_GAIN)) {
                  FloatControl gainControl = (FloatControl) clip.getControl(FloatControl.Type.MASTER_GAIN);
                  
                  // Adjust the volume (values in decibels)
                  float dB = (float) (Math.log(2.0) / Math.log(10.0) * 20.0); // Adjust 1.0 to your desired volume multiplier
                  gainControl.setValue(dB);
              }
  
              clip.start();
          } else {
              System.out.println("Audio file not found: " + filePath);
          }
      } catch (UnsupportedAudioFileException | IOException | LineUnavailableException e) {
          e.printStackTrace();
      }
  }


  //cleans up voice and FreeTTS object, use this if you are going to destroy the TextToSpeechServer object
  void cleanup() {
    voice.deallocate();
    freeTTS.shutdown();
  }
  
  String getTTSFilePath() {
    return dataPath(TTS_FILE_DIRECTORY_NAME);
  }
  
  //finds the tts file directory under the data path and creates it if it does not exist
  void findTTSDirectory() {
    File dataDir = new File(dataPath(""));
    if (!dataDir.exists()) {
      try {
        dataDir.mkdir();
      }
      catch(SecurityException se) {
        println("Data directory not present, and could not be automatically created.");
      }
    }
    
    ttsDir = new File(getTTSFilePath());
    boolean directoryExists = ttsDir.exists();
    if (!directoryExists) {
      try {
        ttsDir.mkdir();
        directoryExists = true;
      }
      catch(SecurityException se) {
        println("Error creating tts file directory '" + TTS_FILE_DIRECTORY_NAME + "' in the data directory.");
      }
    }
  }
  
  //deletes ALL files in the tts file directory found/created by this object ('tts_samples')
  void cleanTTSDirectory() {
    //delete existing files
    if (ttsDir.exists()) {
      for (File file: ttsDir.listFiles()) {
        if (!file.isDirectory())
          file.delete();
      }
    }
  }
  
}
