import gab.opencv.*;
import processing.video.*;
import ddf.minim.*;
import java.awt.*;
import java.util.ArrayList;
import processing.serial.*;

Capture video;
OpenCV opencv;
Minim minim;
ArrayList<Face> faces = new ArrayList<Face>();
boolean contactDetected = false;
AudioPlayer player;
Serial myPort; // Oggetto Serial per la comunicazione seriale

void setup() {
  size(640, 480);
  video = new Capture(this, 640/2, 480/2);
  opencv = new OpenCV(this, 640/2, 480/2);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  video.start();
  minim = new Minim(this);

  // Carica la canzone da riprodurre (sostituisci il percorso con il tuo file MP3)
  player = minim.loadFile("abbraccio.mp3");

  // Configura la comunicazione seriale con Arduino
  String portName = Serial.list()[0]; // Assumiamo che Arduino sia sulla prima porta seriale disponibile
  myPort = new Serial(this, portName, 9600); // Baud rate 9600, lo stesso usato in Arduino
}

void draw() {
  scale(2);
  opencv.loadImage(video);
  image(video, 0, 0);

  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);

  // Clear the list of faces on each frame
  faces.clear();
  Rectangle[] detectedFaces = opencv.detect();

  for (Rectangle face : detectedFaces) {
    rect(face.x, face.y, face.width, face.height + 50); // Extend the height of the rectangle
    faces.add(new Face(face.x, face.y, face.width, face.height + 50));
  }

  // Check for contact and play the song
  if (faces.size() >= 2 && !contactDetected) {
    Face face1 = faces.get(0);
    Face face2 = faces.get(1);

    if (facesIntersect(face1, face2)) {
      contactDetected = true;
      
      // Riavvolgi la canzone e riproducila
      player.rewind();
      player.play();

      // Accendi il LED inviando un segnale seriale ad Arduino
      myPort.write('H'); // Invia il carattere 'H' ad Arduino
    }
  } else if (faces.size() < 2) {
    contactDetected = false;
    
    // Spegni il LED inviando un segnale seriale ad Arduino
    myPort.write('L'); // Invia il carattere 'L' ad Arduino
  }
}

void captureEvent(Capture c) {
  c.read();
}

boolean facesIntersect(Face face1, Face face2) {
  // Check if two faces intersect based on the bounding rectangles
  return (face1.x < face2.x + face2.width &&
          face1.x + face1.width > face2.x &&
          face1.y < face2.y + face2.height + 50 &&
          face1.y + face1.height > face2.y - 50);
}

class Face {
  float x, y, width, height;

  Face(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }
}
