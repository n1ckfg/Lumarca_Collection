/*

  This program makes two image files.

  pxMap1.png is a 3d pixel map.  It identifies where each 2d px coordinate lands in 3d space when sent through a projector onto string.

  A px, rgb color val of:
    128, 0, 255

  maps to an xyz coordinate of
    .5, 0, 1

  or, in other words, half the X dimension, none of the Y dimension, and 1 of the Z dimension

  To get further granularity, use pxMap2.png, which further subdivides each dimension into 255, giving 255 * 255 resolution

  To note, the program you use to run this will require a definition of what x=0 and x=1 means, but there you have it...

*/

PGraphics pg;

String rawLines[];
PVector renderField; // x left right, y is near far, z is up down

float nearPlane;     // distance from projector to close plane
float farPlane;      // distance from projector to far plane
int numOfStrings;
PVector[] strings;
float projectorRatio;

float unitsPerStringNear;
float unitsPerStringFar;
float pxPerString;
float pxPerInch;

void setup() {
  noSmooth();
  size(1024, 768, P2D);
  pg = createGraphics(width, height, P2D, "map.png");
  renderField = new PVector(17.0, 16.0, 0);
  pxPerInch =  float(pg.width) / renderField.x;
  renderField.z = float(pg.height) / pxPerInch;
  rawLines = loadStrings("lines.txt");
  farPlane = 39.0;
  nearPlane = farPlane - renderField.y;
  projectorRatio = nearPlane / (renderField.x);
  strings = new PVector[rawLines.length];
  for (int i = 0; i < rawLines.length; i++) {
    float x = float(rawLines[i].split(" ")[0]);
    float y = float(rawLines[i].split(" ")[1]);
    strings[i] = new PVector(x, y);
  }
  pxPerString = float(width) / float(rawLines.length);
}

/*
float clamp(float number, float low, float high) {
  if (number < low) {
    number = low;
  } else if (number > high) {
    number = high;
  }
  return number;
}
*/

void draw() {
  pg.beginDraw();
    // Positive Z is UP!
    String hoverColor = "";
    for (int pxX = 0; pxX < pg.width; pxX++) {
      for (int pxZ = 0; pxZ < pg.height; pxZ++) {
        PVector currString = strings[int(floor(float(pxX) / pxPerString))];
        float pointX = currString.x;
        float pointY = currString.y;
        float pointZ; // this requires some trig
        // pointZ is to (pointY + nearPlane) as pxZInInches is to nearPlane
        float pxZInInches = pxZ / pxPerInch;
        pointZ = (pointY + nearPlane) * (pxZInInches / nearPlane);

        float pointXNorm = map(pointX, -renderField.x / 2, renderField.x / 2, 0, 1);
        float pointYNorm = map(pointY, 0, renderField.y, 0, 1);
        float pointZNorm = map(pointZ, 0, renderField.z, 0, 1);

        if (pointXNorm < 0 || pointXNorm > 1 || pointZNorm > 1) {
        } else {
          pg.stroke(pointZNorm * 255, pointZNorm * 255, pointZNorm * 255, 255);
          pg.point(pxX, height - pxZ);
        }

        if (mouseX == pxX && mouseY == height - pxZ) {
          hoverColor = "X: " + str(pointXNorm * 255) + "  Y: " + str(pointYNorm * 255) + "  Z: " + str(pointZNorm * 255);
        }
      }
    }
    text(hoverColor, 20, 20);
  pg.endDraw();
  pg.save("map.png");
  exit();
}
