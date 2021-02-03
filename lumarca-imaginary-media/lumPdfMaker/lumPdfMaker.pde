/*

this makes a pdf image from lines.txt
lines.txt should be copied from lumPointMaker.pde's folder

Print and paste onto two sheets of ply and drill holes through the X's

*/


import processing.pdf.*;
float ppi = 300.0;
//float ppi = 50.0;

PVector renderField; // x left right, y is near far

void setup() {
  renderField = new PVector(17.0, 16.0);
  size(int(renderField.x * ppi), int(renderField.y * ppi), PDF, "print.pdf");
  //size(int(renderField.x * ppi), int(renderField.y * ppi));
}

void draw() {
  background(255);
  String lines[] = loadStrings("lines.txt");
  textSize(32);
  for (int i = 0; i < lines.length; i++) {
    float x = (float(lines[i].split(" ")[0]) + (renderField.x / 2.0)) * ppi;
    float y = float(lines[i].split(" ")[1]) * ppi;
    fill(255);
    rect(x-20, y-20, 40, 40);
    line(x-20, y-20, x+20, y+20);
    line(x-20, y+20, x+20, y-20);
    fill(0);
    text(str(i), x-20, y-20); 
  }
  exit();
}
