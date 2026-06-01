import java.util.Collections;
import java.util.ArrayList;
final int m = 10, n = 20;
final int cell = 28;
final int border = 3;
final int bX = 16, bY = 16;
final int bW = border + m * (cell + border), bH = border + n * (cell + border);
final int side = bX + bW + 24;
final int lockDelay = 500;
final int maxLRes = 15;
final int softDropT = 40;
final int screenMenu = 0, screenGame = 1, screenOpts = 2, screenHTP = 3, screenCreds = 4;
int screenState = screenMenu;
boolean ghostEnabled = true, softDropHeld = false;
boolean leftHeld = false, rightHeld = false;
final int modeClassic = 0, modeSand = 1;
int gameMode = modeClassic;
boolean flippingEnabled = false;
final int flipGrav = 0, flipBoard = 1;
int flipMode = flipGrav;
final int sTop = -1, sBottom = 1;
int gravityDirection = sBottom;
int[][] board = new int[n][m];
int[][] blockSide = new int[n][m];
ArrayList <Tetromino> nextQueue = new ArrayList<Tetromino>();
ArrayList <Integer> pieceBag = new ArrayList<Integer>(), colorBag = new ArrayList<Integer>();
ActivePiece current;
Tetromino heldPiece;
boolean holdUsed = false, gameOver = false;
long score = 0;
int lines = 0, level = 1;
int lastFallTime = 0, lockStartTime = -1;
int lockResets = 0;
int spawnDelay = 250, spawnAt = -1;
boolean waitingSpawn = false;
int[] palette;
PFont uiFont;
void settings() { size(560, 660); }
void setup() {
  frameRate(60);
  uiFont = createFont("Arial", 18, true);
  textFont(uiFont);
  palette = new int[] {
    color(0, 240, 240),
    color(0, 80, 240),
    color(240, 160, 0),
    color(240, 240, 0),
    color(0, 240, 0),
    color(160, 0, 240),
    color(240, 0, 0)
  };
}
void draw() {
  background(18);
  if (screenState == screenMenu) { drawMenuScreen(); return; }
  if (screenState == screenOpts) { drawOptionsScreen(); return; }
  if (screenState == screenHTP) { drawHowToPlayScreen(); return; }
  if (screenState == screenCreds) { drawCreditsScreen(); return; }
  if (screenState == screenGame) {
    if (!gameOver) { updateGL(); }
    drawBoard();
    drawGhost();
    drawCur();
    drawSidePanel();
    if (gameOver) { drawGameOverOverlay(); }
  }
}
void keyPressed() {
  if (screenState != screenGame) {
    if (key == ESC) { key = 0; screenState = screenMenu; }
    return;
  }
  if (key == ESC) { key = 0; screenState = screenMenu; softDropHeld = false; leftHeld = false; rightHeld = false; return; }
  if (key == 'r' || key == 'R') { resetGame(); return; }
  if (gameOver || current == null) return;
  if (gameMode == modeSand) {
    if (keyCode == LEFT) { leftHeld = true; }
    else if (keyCode == RIGHT) { rightHeld = true; }
    else if (keyCode == UP) { holdCur(); }
    else if (keyCode == DOWN) { softDropHeld = true; }
    else if (key == 'a' || key == 'A') { rotCur(-1); }
    else if (key == 'd' || key == 'D') { rotCur(1); }
    else if (key == 's' || key == 'S') { hardDropCur(); }
    else if (key == 'f' || key == 'F') { performFlip(); }
    return;
  }
  if (keyCode == LEFT) { moveCur(-1, 0, true); }
  else if (keyCode == RIGHT) { moveCur(1, 0, true); }
  else if (keyCode == UP) { holdCur(); }
  else if (keyCode == DOWN) { softDropHeld = true; }
  else if (key == 'a' || key == 'A') { rotCur(-1); }
  else if (key == 'd' || key == 'D') { rotCur(1); }
  else if (key == 's' || key == 'S') { hardDropCur(); }
  else if (key == 'f' || key == 'F') { performFlip(); }
}
void keyReleased() {
  if (keyCode == DOWN) { softDropHeld = false; }
  if (keyCode == LEFT) { leftHeld = false; }
  if (keyCode == RIGHT) { rightHeld = false; }
}
void mousePressed() {
  if (screenState == screenMenu) {
    int buttonW = 220, buttonH = 46, gap = 14;
    int x = width / 2 - buttonW / 2, y = height / 2 - 60;
    if (buttonHit(x, y, buttonW, buttonH)) {
      resetGame();
      screenState = screenGame;
    }
    else if (buttonHit(x, y + buttonH + gap, buttonW, buttonH)) { screenState = screenOpts; }
    else if (buttonHit(x, y + 2 * (buttonH + gap), buttonW, buttonH)) { screenState = screenHTP; }
    else if (buttonHit(x, y + 3 * (buttonH + gap), buttonW, buttonH)) { screenState = screenCreds; }
  }
  else if (screenState == screenOpts) {
    int boxX = width / 2 - 130, boxY = height / 2 - 110;
    if (buttonHit(boxX + 28, boxY, 230, 30)) { gameMode = modeClassic; }
    else if (buttonHit(boxX + 28, boxY + 34, 230, 30)) { gameMode = modeSand; }
    else if (gameMode == modeClassic && buttonHit(boxX, boxY + 84, 280, 32)) { ghostEnabled = !ghostEnabled; }
    else if (buttonHit(boxX, boxY + 128, 280, 32)) {
      flippingEnabled = !flippingEnabled;
      if (!flippingEnabled) { gravityDirection = sBottom; }
    }
    else if (flippingEnabled && buttonHit(boxX + 28, boxY + 172, 230, 30)) { flipMode = flipGrav; }
    else if (flippingEnabled && buttonHit(boxX + 28, boxY + 206, 230, 30)) { flipMode = flipBoard; gravityDirection = sBottom; }
    else if (backButtonHit()) { screenState = screenMenu; }
  }
  else if (screenState == screenHTP || screenState == screenCreds) { if (backButtonHit()) { screenState = screenMenu; } }
}
void resetGame() {
  softDropHeld = false;
  leftHeld = false;
  rightHeld = false;
  for (int r = 0; r < n; r++) { for (int c = 0; c < m; c++) { board[r][c] = 0; blockSide[r][c] = 0; } }
  resetSand();
  nextQueue.clear();
  pieceBag.clear();
  colorBag.clear();
  gravityDirection = sBottom;
  heldPiece = null;
  current = null;
  waitingSpawn = false;
  spawnAt = -1;
  score = 0;
  lines = 0;
  level = 1;
  gameOver = false;
  fixQueue(5);
  spawnNext();
}
