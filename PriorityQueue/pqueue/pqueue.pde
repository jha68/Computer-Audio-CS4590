import beads.*;
import org.jaudiolibs.beads.*;
import java.util.*;

//Comparator<Notification> comparator;
PriorityQueue<Notification> queue;
Notification notification;

void setup() {
  // create a comparator to keep queued items in priority order
  Comparator<Notification> priorityComp = new Comparator<Notification>() {
    public int compare(Notification n1, Notification n2) {
      return min(n1.getPriorityLevel(), n2.getPriorityLevel());
    }
  };
  
  queue = new PriorityQueue<Notification>(10, priorityComp);
}

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class Example implements NotificationListener {
  
  public Example() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) {
    // add this notification to the priority queue
    queue.add(notification);
  }
}

void draw() {
  //this method must be present (even if empty) to process events such as keyPressed()
  
  // check to see if events are in the queue, if so sonify them
  notification = queue.poll();
  
  if (notification != null) {
    // sonify based on type, priority, queue.size(), etc.
  }
}
