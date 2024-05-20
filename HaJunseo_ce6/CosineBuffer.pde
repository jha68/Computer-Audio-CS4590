import beads.*;

public class CosineBuffer extends BufferFactory {
  public Buffer generateBuffer(int bufferSize) {
    Buffer b = new Buffer(bufferSize);
    for (int i = 0; i < bufferSize; i++){
      b.buf[i] = (float) Math.cos(2.0 * Math.PI * (double) i / (double) bufferSize);
    }
    return b;
  }
  public String getName() {
    return "Cosine";
  }
}
