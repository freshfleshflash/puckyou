class Obstacle extends FCircle {
  float x, y;
  //int id;  

  Obstacle() {
    super(0);
  }

  Obstacle(int id, float x, float y) {
    super(100);

    //this.id = id;
    this.x = x;
    this.y = y;

    this.setGroupIndex(-id);
    this.setPosition(x, y);
    this.setStatic(true);
    this.setNoFill();
    this.setFriction(0);

    this.setRestitution(1);
  }
}