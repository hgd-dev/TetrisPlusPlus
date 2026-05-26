import java.util.Collections;
import java.util.ArrayList;
final int COLS = 10, ROWS = 20;
final int CELL = 28;
final int BORDER = 3;
final int BOARD_X = 16, BOARD_Y = 16;
final int BOARD_W = BORDER + COLS * (CELL + BORDER), BOARD_H = BORDER + ROWS * (CELL + BORDER);
final int SIDE_X = BOARD_X + BOARD_W + 24;
final int LOCK_DELAY_MS = 500;
final int MAX_LOCK_RESETS = 15;
final int SOFT_DROP_INTERVAL_MS = 40;
final int SCREEN_MENU = 0, SCREEN_GAME = 1, SCREEN_OPTIONS = 2, SCREEN_HOW_TO_PLAY = 3, SCREEN_CREDITS = 4;
int screenState = SCREEN_MENU;
boolean ghostEnabled = true, softDropHeld = false;
boolean flippingEnabled = false;
final int SIDE_TOP = -1, SIDE_BOTTOM = 1;
int gravityDirection = SIDE_BOTTOM;
int[][] board = new int[ROWS][COLS];
int[][] blockSide = new int[ROWS][COLS];
ArrayList<Tetromino> nextQueue = new ArrayList<Tetromino>();
ArrayList<Integer> pieceBag = new ArrayList<Integer>(), colorBag = new ArrayList<Integer>();
ActivePiece current;
Tetromino heldPiece;
boolean holdUsedThisPiece = false, gameOver = false;
long score = 0;
int lines = 0;
int level = 1;
int lastFallTime = 0;
int lockStartTime = -1;
int lockResets = 0;
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
  if (screenState == SCREEN_MENU) {
    drawMenuScreen();
    return;
  }
  if (screenState == SCREEN_OPTIONS) {
    drawOptionsScreen();
    return;
  }
  if (screenState == SCREEN_HOW_TO_PLAY) {
    drawHowToPlayScreen();
    return;
  }
  if (screenState == SCREEN_CREDITS) {
    drawCreditsScreen();
    return;
  }
  if (screenState == SCREEN_GAME) {
    if (!gameOver) {
      updateGravityAndLock();
    }
    drawBoard();
    drawGhostPiece();
    drawCurrentPiece();
    drawSidePanel();
    if (gameOver) { drawGameOverOverlay(); }
  }
}
void keyPressed() {
  if (screenState != SCREEN_GAME) {
    if (key == ESC) {
      key = 0;
      screenState = SCREEN_MENU;
    }
    return;
  }
  if (key == ESC) {
    key = 0;
    screenState = SCREEN_MENU;
    softDropHeld = false;
    return;
  }
  if (key == 'r' || key == 'R') {
    resetGame();
    return;
  }
  if (gameOver || current == null) return;
  if (keyCode == LEFT) { tryMoveCurrent(-1, 0, true); }
  else if (keyCode == RIGHT) { tryMoveCurrent(1, 0, true); }
  else if (keyCode == UP) { holdCurrentPiece(); }
  else if (keyCode == DOWN) { softDropHeld = true; }
  else if (key == 'a' || key == 'A') { tryRotateCurrent(-1); }
  else if (key == 'd' || key == 'D') { tryRotateCurrent(1); }
  else if (key == 's' || key == 'S') { hardDropCurrent(); }
  else if (key == 'f' || key == 'F') { performFlip(); }
}

void keyReleased() {
  if (keyCode == DOWN) {
    softDropHeld = false;
  }
}
void mousePressed() {
  if (screenState == SCREEN_MENU) {
    int buttonW = 220;
    int buttonH = 46;
    int gap = 14;
    int x = width / 2 - buttonW / 2;
    int y = height / 2 - 60;
    if (buttonHit(x, y, buttonW, buttonH)) {
      resetGame();
      screenState = SCREEN_GAME;
    }
    else if (buttonHit(x, y + buttonH + gap, buttonW, buttonH)) { screenState = SCREEN_OPTIONS; }
    else if (buttonHit(x, y + 2 * (buttonH + gap), buttonW, buttonH)) { screenState = SCREEN_HOW_TO_PLAY; }
    else if (buttonHit(x, y + 3 * (buttonH + gap), buttonW, buttonH)) { screenState = SCREEN_CREDITS; }
  }
  else if (screenState == SCREEN_OPTIONS) {
    int boxX = width / 2 - 130, boxY = height / 2 - 80;
    if (buttonHit(boxX, boxY, 280, 32)) { ghostEnabled = !ghostEnabled; }
    else if (buttonHit(boxX, boxY + 44, 280, 32)) { flippingEnabled = !flippingEnabled; }
    else if (backButtonHit()) { screenState = SCREEN_MENU; }
  }
  else if (screenState == SCREEN_HOW_TO_PLAY || screenState == SCREEN_CREDITS) { if (backButtonHit()) { screenState = SCREEN_MENU; } }
}
void resetGame() {
  softDropHeld = false;
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      board[r][c] = 0;
      blockSide[r][c] = 0;
    }
  }
  nextQueue.clear();
  pieceBag.clear();
  colorBag.clear();
  gravityDirection = SIDE_BOTTOM;
  heldPiece = null;
  current = null;
  score = 0;
  lines = 0;
  level = 1;
  gameOver = false;
  ensureQueueSize(5);
  spawnNextPiece();
}
