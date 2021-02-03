// in this particular program, projector is at (0, 0, 0)

float nearPlane;     // distance from projector to close plane
float farPlane;      // distance from projector to far plane
PVector renderField; // x left right, y is near far
int numOfStrings;
PVector[] strings;
float projectorRatio;

float unitsPerStringNear;
float unitsPerStringFar;

void setup() {
  size(1024, 768);
  numOfStrings = 102;
  strings = new PVector[numOfStrings];
  renderField = new PVector(17.0, 16.0);
  farPlane = 39.0;
  nearPlane = farPlane - renderField.y;
  projectorRatio = nearPlane / (renderField.x);

  unitsPerStringNear = renderField.x / float(numOfStrings);
  unitsPerStringFar = unitsPerStringNear * (farPlane / nearPlane);

  String[] output = new String[numOfStrings];

  int outCount = 9999;
  while (outCount > 22) {
    outCount = 0;
    //makePoints(2.125);
    //makePoints(1.925);
    makePoints(1.8);

    for (int i = 0; i < numOfStrings; i++) {
      PVector string = strings[i];
      output[i] = str(string.x) + " " + str(string.y);
      if (string.x < -renderField.x / 2 || string.x > renderField.x / 2) {
        outCount ++;
      }
    }
    //println(outCount);
  }

  saveStrings("lines.txt", output);
  //saveStrings("lines.txt", strings); // hehe, funny that saveStrings is a native function meaning save "String"s
}

void makePoints(float thresh) {
  int counterForThree = 0;
  int counterForSeven = 0;
  int counterForFifteen = 0;
  for (int i = 0; i < numOfStrings; i++) {
    boolean findNewPotential = true;
    PVector potentialPoint = getPoint(i);
    while(findNewPotential) {
      counterForThree++;
      findNewPotential = false;
      potentialPoint = getPoint(i);
      for(int j = 0; j < i; j++) {
        if(potentialPoint.dist(strings[j]) < thresh) {
          findNewPotential = true;
        }
      }
      if (counterForThree > 200) {
        counterForThree = 0;
        counterForSeven++;
        i = i - 3;
        if (i < 0) {
          i = 0;
        }
      }

      if (counterForSeven > 200) {
        counterForSeven = 0;
        counterForFifteen++;
        i = i - 7;
        if (i < 0) {
          i = 0;
        }
      }

      if (counterForFifteen > 200) {
        counterForFifteen = 0;
        i = i - 15;
        if (i < 0) {
          i = 0;
        }
        println("for Fifteen");
        println(i);
      }
    }
    strings[i] = potentialPoint;
  }
}

PVector getPoint(int i) {
  float depth = getWeightedRandom();
  float nearPlaneXOffset = -(renderField.x / 2) + (float(i) * unitsPerStringNear);
  float xLocation = (depth + nearPlane) * (nearPlaneXOffset / nearPlane);
  PVector point = new PVector(xLocation, depth);
  return point;
}

void draw() {
  float radius = 2.0;
  for (int i = 0; i < numOfStrings; i++) {
    float x = map(strings[i].x, -(renderField.x / 2), renderField.x / 2, 0, 1024);
    float y = map(strings[i].y, 0, renderField.y, 0, 768);
    ellipse(x, y, radius, radius);
  }
}

float getWeightedRandom() {
  /*
    If not weighted, string placement will have higher density close to the near plane.
    Weighting is done by finding potential spots, and statistically removing an reassigning
  */
  boolean findNewPotential = true;
  float potentialSpot = 0;
  float lowestChance, chance;
  lowestChance = unitsPerStringNear / unitsPerStringFar; // something like .58
  while (findNewPotential) {
    potentialSpot = random(renderField.y); // 0 and 15

    chance = map(potentialSpot, 0, renderField.y, lowestChance, 1.0);

    if (random(1) < chance) {
      findNewPotential = false;
    }
  }
  return potentialSpot;
}
