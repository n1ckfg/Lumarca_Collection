import java.util.HashMap;

import netP5.NetAddress;
import oscP5.OscMessage;
import oscP5.*;
import processing.core.PApplet;
import processing.core.PMatrix3D;
import processing.core.PVector;
import processing.data.JSONObject;
import SimpleOpenNI.*;

public class SimpleOpenNIKinectSkeletonOSCWrapper extends PApplet {

  float confLevel = 0.5f;
  boolean hasKinect = true;
  
  HashMap<Integer, PVector> skeltonMap = new HashMap<Integer, PVector>();
  HashMap<Integer, PVector> prevSkeltonMap = new HashMap<Integer, PVector>();

  public static void main(String _args[]) {
    PApplet.main(new String[] { SimpleOpenNIKinectSkeletonOSCWrapper.class
        .getName() });
  }
  
  OscP5 oscP5;
  NetAddress myRemoteLocation;
  
  JSONObject pvector2JSON(PVector vec){
    JSONObject json = new JSONObject();

    json.setFloat("x", vec.x);
    json.setFloat("y", vec.y);
    json.setFloat("z", vec.z);
    
    return json;
  }
  
  public JSONObject skeltonMap2JSON(){
    JSONObject json = new JSONObject();
    
    for(Integer key: skeltonMap.keySet()){
      PVector value = skeltonMap.get(key);
      
      if(value != null && !value.equals(prevSkeltonMap.get(key))){
        println("z: " + value.z);
        json.setJSONObject(key.toString(), pvector2JSON(value));
        prevSkeltonMap.put(key, value);
      }
    }
    
    return json;
  }
  
  public void sendOSCMessage(String label, JSONObject json) {
//    System.out.println("json: " + json.toString());
    
    if(!json.isNull(SimpleOpenNI.SKEL_TORSO + "")){
      OscMessage myMessage = new OscMessage(label);
      myMessage.add(json.toString());
      oscP5.send(myMessage, myRemoteLocation);
    }
  }

  /*
   * --------------------------------------------------------------------------
   * SimpleOpenNI User3d Test
   * --------------------------------------------------
   * ------------------------ Processing Wrapper for the OpenNI/Kinect 2
   * library http://code.google.com/p/simple-openni
   * ----------------------------
   * ---------------------------------------------- prog: Max Rheiner /
   * Interaction Design / Zhdk / http://iad.zhdk.ch/ date: 12/12/2012 (m/d/y)
   * --
   * ------------------------------------------------------------------------
   * --
   */

  SimpleOpenNI context;
  float zoomF = 0.5f;
  float rotX = radians(180); // by default rotate the hole scene 180deg around
                // the x-axis,
                // the data from openni comes upside down
  float rotY = radians(0);
  boolean autoCalib = true;

  PVector bodyCenter = new PVector();
  PVector bodyDir = new PVector();
  PVector com = new PVector();
  PVector com2d = new PVector();
  int[] userClr = new int[] { color(255, 0, 0), color(0, 255, 0),
      color(0, 0, 255), color(255, 255, 0), color(255, 0, 255),
      color(0, 255, 255) };

  public void setup() {
    size(1024, 768, P3D); // strange, get drawing error in the cameraFrustum
                // if i use P3D, in opengl there is no problem

    /* start oscP5, listening for incoming messages at port 12000 */
    oscP5 = new OscP5(this, 12000);
    myRemoteLocation = new NetAddress("127.0.0.1", 3333);
    
    if (hasKinect) {
      context = new SimpleOpenNI(this);
      
      print("1");
      if (context.isInit() == false) {
        println("Can't init SimpleOpenNI, maybe the camera is not connected!");
        exit();
        return;
      }

      print("2");
      // disable mirror
//      context.setMirror(false);

      // enable depthMap generation
      context.enableDepth();

      print("3");
      // enable skeleton generation for all joints
      context.enableUser();
      
      print("4");
    }

    stroke(255, 255, 255);
    smooth();
    perspective(radians(45), (float) width / (float) height, 10, 150000);
  }

  public void draw() {
    // update the cam

    if (hasKinect) {
      context.update();
    }

    background(0, 0, 0);

    // set the scene pos
    translate(width / 2, height / 2, 0);
    rotateX(rotX);
    rotateY(rotY);
    scale(zoomF);

    if (hasKinect) {
      int[] depthMap = context.depthMap();
      int[] userMap = context.userMap();
      int steps = 3; // to speed up the drawing, draw every third point
      int index;
      PVector realWorldPoint;

      translate(0, 0, -1000); // set the rotation center of the scene 1000
                  // infront of the camera

      // draw the pointcloud
      beginShape(POINTS);
      for (int y = 0; y < context.depthHeight(); y += steps) {
        for (int x = 0; x < context.depthWidth(); x += steps) {
          index = x + y * context.depthWidth();
          if (depthMap[index] > 0) {
            // draw the projected point
            realWorldPoint = context.depthMapRealWorld()[index];
            if (userMap[index] == 0)
              stroke(100);
            else
              stroke(userClr[(userMap[index] - 1)
                  % userClr.length]);

            point(realWorldPoint.x, realWorldPoint.y,
                realWorldPoint.z);
          }
        }
      }
      endShape();

      // draw the skeleton if it's available
      int[] userList = context.getUsers();
      
      for (int i = 0; i < userList.length; i++) {
        if (context.isTrackingSkeleton(userList[i]))
          drawSkeleton(userList[i]);

        // draw the center of mass
        if (context.getCoM(userList[i], com)) {
          stroke(100, 255, 0);
          strokeWeight(1);
          beginShape(LINES);
          vertex(com.x - 15, com.y, com.z);
          vertex(com.x + 15, com.y, com.z);

          vertex(com.x, com.y - 15, com.z);
          vertex(com.x, com.y + 15, com.z);

          vertex(com.x, com.y, com.z - 15);
          vertex(com.x, com.y, com.z + 15);
          endShape();

          fill(0, 255, 100);
          text(Integer.toString(userList[i]), com.x, com.y, com.z);
        }
      }

      // draw the kinect cam
      context.drawCamFrustum();
    }
    

//    addToSkelMap(new Integer(SimpleOpenNI.SKEL_HEAD), new PVector());
//    addToSkelMap(new Integer(1), new PVector(0, 1, 0));
    sendOSCMessage("skeleton", skeltonMap2JSON());
    
    skeltonMap.clear();
  }

  // draw the skeleton with the selected joints
  void drawSkeleton(int userId) {
    strokeWeight(3);

    // to get the 3d joint data
    drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

    drawLimb(userId, SimpleOpenNI.SKEL_NECK,
        SimpleOpenNI.SKEL_LEFT_SHOULDER);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER,
        SimpleOpenNI.SKEL_LEFT_ELBOW);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW,
        SimpleOpenNI.SKEL_LEFT_HAND);

    drawLimb(userId, SimpleOpenNI.SKEL_NECK,
        SimpleOpenNI.SKEL_RIGHT_SHOULDER);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER,
        SimpleOpenNI.SKEL_RIGHT_ELBOW);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW,
        SimpleOpenNI.SKEL_RIGHT_HAND);

    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER,
        SimpleOpenNI.SKEL_TORSO);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER,
        SimpleOpenNI.SKEL_TORSO);

    drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP,
        SimpleOpenNI.SKEL_LEFT_KNEE);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE,
        SimpleOpenNI.SKEL_LEFT_FOOT);

    drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP,
        SimpleOpenNI.SKEL_RIGHT_KNEE);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE,
        SimpleOpenNI.SKEL_RIGHT_FOOT);

    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP,
        SimpleOpenNI.SKEL_RIGHT_HIP);

    // draw body direction
    getBodyDirection(userId, bodyCenter, bodyDir);

    bodyDir.mult(200); // 200mm length
    bodyDir.add(bodyCenter);

    stroke(255, 200, 200);
    line(bodyCenter.x, bodyCenter.y, bodyCenter.z, bodyDir.x, bodyDir.y,
        bodyDir.z);

    strokeWeight(1);

  }

  void drawLimb(int userId, int jointType1, int jointType2) {
    PVector jointPos1 = new PVector();
    PVector jointPos2 = new PVector();
    float confidence;

    // draw the joint position
    confidence = context.getJointPositionSkeleton(userId, jointType1,
        jointPos1);
    if(confidence > confLevel){
      confidence = context.getJointPositionSkeleton(userId, jointType2,
        jointPos2);
    }
    
    float divAmt = 3500;
        
    jointPos1 = modPos(jointPos1, confidence);
    
    if(SimpleOpenNI.SKEL_HEAD == jointType1){     //    0 == HEAD
      addToSkelMap(new Integer(0), jointPos1);
    }
    if(SimpleOpenNI.SKEL_LEFT_FOOT == jointType2){   //    1 == LEFT FOOT
      jointPos2 = modPos(jointPos2, confidence);
      addToSkelMap(new Integer(1), jointPos2);
    }
    if(SimpleOpenNI.SKEL_RIGHT_FOOT == jointType2){ //    2 == RIGHT FOOT
      jointPos2 = modPos(jointPos2, confidence);
      addToSkelMap(new Integer(2), jointPos2);
    }
    if(SimpleOpenNI.SKEL_LEFT_HAND == jointType2){ //    3 == LEFT HAND
      jointPos2 = modPos(jointPos2, confidence);
      addToSkelMap(new Integer(3), jointPos2);
    }
    if(SimpleOpenNI.SKEL_RIGHT_HAND == jointType2){ //    4 == RIGHT HAND
      jointPos2 = modPos(jointPos2, confidence);
      addToSkelMap(new Integer(4), jointPos2);
    }
    if(SimpleOpenNI.SKEL_LEFT_ELBOW == jointType1){ //    5 == LEFT ELBOW
      addToSkelMap(new Integer(5), jointPos1);
    }
    if(SimpleOpenNI.SKEL_RIGHT_ELBOW == jointType1){ //    6 == RIGHT ELBOW
      addToSkelMap(new Integer(6), jointPos1);
    }
    if(SimpleOpenNI.SKEL_LEFT_KNEE == jointType1){ //    7 == LEFT KNEE
      addToSkelMap(new Integer(7), jointPos1);
    }
    if(SimpleOpenNI.SKEL_RIGHT_KNEE == jointType1){ //    8 == RIGHT KNEE
      addToSkelMap(new Integer(8), jointPos1);
    }
    if(SimpleOpenNI.SKEL_TORSO == jointType1){ //    9 == TOP TORSO
      addToSkelMap(new Integer(9), jointPos1);
    }
    if(SimpleOpenNI.SKEL_LEFT_HIP == jointType1 && SimpleOpenNI.SKEL_RIGHT_HIP == jointType2){ //    10 == BOTTOM TORSO
      jointPos2 = modPos(jointPos2, confidence);
      
      if(jointPos1 != null && jointPos2 != null){
        PVector hip = PVector.add(jointPos1,jointPos2);
        
        hip.div(2);
        
        addToSkelMap(new Integer(10), hip);
      }
    }

   if(jointPos1 != null && jointPos2 != null){
    stroke(255, 0, 0, confidence * 200 + 55);
    line(jointPos1.x, jointPos1.y, jointPos1.z, jointPos2.x, jointPos2.y,
        jointPos2.z);
   }

//    drawJointOrientation(userId, jointType1, jointPos1, 50);
  }
  
  void addToSkelMap(Integer id, PVector pos){
    if(pos != null){
      skeltonMap.put(id, pos);
    }
  }
  
  PVector modPos(PVector pos, float conf){
      
    if(conf < confLevel){
//      println(conf);
      return null;
    }
    
    pos.div(3500);
    pos.x *= 2;
    pos.z -= 0.66f;
    
    return pos;
  }

  // -----------------------------------------------------------------
  // SimpleOpenNI user events

  void onNewUser(SimpleOpenNI curContext, int userId) {
    println("onNewUser - userId: " + userId);
    println("\tstart tracking skeleton");

    context.startTrackingSkeleton(userId);
  }

  void onLostUser(SimpleOpenNI curContext, int userId) {
    println("onLostUser - userId: " + userId);
  }

  void onVisibleUser(SimpleOpenNI curContext, int userId) {
    // println("onVisibleUser - userId: " + userId);
  }

  // -----------------------------------------------------------------
  // Keyboard events

  void getBodyDirection(int userId, PVector centerPoint, PVector dir) {
    PVector jointL = new PVector();
    PVector jointH = new PVector();
    PVector jointR = new PVector();
    float confidence;

    // draw the joint position
    confidence = context.getJointPositionSkeleton(userId,
        SimpleOpenNI.SKEL_LEFT_SHOULDER, jointL);
    confidence = context.getJointPositionSkeleton(userId,
        SimpleOpenNI.SKEL_HEAD, jointH);
    confidence = context.getJointPositionSkeleton(userId,
        SimpleOpenNI.SKEL_RIGHT_SHOULDER, jointR);

    // take the neck as the center point
    confidence = context.getJointPositionSkeleton(userId,
        SimpleOpenNI.SKEL_NECK, centerPoint);

    /*
     * // manually calc the centerPoint PVector shoulderDist =
     * PVector.sub(jointL,jointR);
     * centerPoint.set(PVector.mult(shoulderDist,.5));
     * centerPoint.add(jointR);
     */

    PVector up = PVector.sub(jointH, centerPoint);
    PVector left = PVector.sub(jointR, centerPoint);

    dir.set(up.cross(left));
    dir.normalize();
  }
}

