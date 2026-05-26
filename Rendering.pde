void drawBoard() {
  noStroke();
  fill(60);
  rect(BOARD_X, BOARD_Y, BOARD_W, BOARD_H);
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      int x = gridToPixelX(c), y = gridToPixelY(r);
      if (board[r][c] == 0) {
        fill(28);
        rect(x, y, CELL, CELL);
      }
      else { drawBlockPixels(x, y, board[r][c], 255); }
    }
  }
}
void drawCurrentPiece() {
  if (current == null) return;
  int[][] cells = getCells(current.kind, current.rot);
  for (int i = 0; i < 4; i++) {
    int c = current.col + cells[i][0], r = current.row + cells[i][1];
    if (r >= 0 && r < ROWS) { drawBlockPixels(gridToPixelX(c), gridToPixelY(r), current.pieceColor, 255); }
  }
}
void drawGhostPiece() {
  if (!ghostEnabled || current == null || gameOver) { return; }
  int ghostRow = current.row;
  int dy = fallDirection();
  while (canPlace(current, current.col, ghostRow + dy, current.rot)) { ghostRow += dy; }
  int[][] cells = getCells(current.kind, current.rot);
  for (int i = 0; i < 4; i++) {
    int c = current.col + cells[i][0], r = ghostRow + cells[i][1];
    if (r >= 0 && r < ROWS) { drawBlockPixels(gridToPixelX(c), gridToPixelY(r), current.pieceColor, 65); }
  }
}
void drawSidePanel() {
  fill(235);
  textAlign(LEFT, TOP);
  textSize(24);
  text("TETRIS++", SIDE_X, BOARD_Y);
  textSize(14);
  int y = BOARD_Y + 36;
  text("Score", SIDE_X, y);
  textSize(18);
  text("" + score, SIDE_X, y + 17);
  y += 46;
  textSize(14);
  text("Lines", SIDE_X, y);
  textSize(18);
  text("" + lines, SIDE_X, y + 17);
  y += 46;
  textSize(14);
  text("Level", SIDE_X, y);
  textSize(18);
  text("" + level, SIDE_X, y + 17);
  y += 56;
  textSize(14);
  text("Hold", SIDE_X, y);
  drawPreviewBox(SIDE_X, y + 22, 125, 72);
  if (heldPiece != null) { drawMiniTetromino(heldPiece, SIDE_X + 10, y + 30, 14); }
  y += 104;
  textSize(14);
  text("Next", SIDE_X, y);
  for (int i = 0; i < 2; i++) {
    int boxY = y + 22 + i * 82;
    drawPreviewBox(SIDE_X, boxY, 125, 72);
    if (nextQueue.size() > i) { drawMiniTetromino(nextQueue.get(i), SIDE_X + 10, boxY + 8, 14); }
  }
  y += 202;
  textSize(13);
  fill(215);
  text("Controls", SIDE_X, y);
  y += 19;
  text("Left/Right move", SIDE_X, y);
  y += 17;
  text("A/D rotate", SIDE_X, y);
  y += 17;
  text("S hard drop", SIDE_X, y);
  y += 17;
  text("Up hold/swap", SIDE_X, y);
  y += 17;
  text("Down soft drop", SIDE_X, y);
  y += 17;
  text("F flip", SIDE_X, y);
  y += 17;
  text("Esc menu", SIDE_X, y);
  y += 17;
  text("R restart", SIDE_X, y);
}
void drawGameOverOverlay() {
  fill(0, 180);
  rect(BOARD_X, BOARD_Y, BOARD_W, BOARD_H);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(36);
  text("GAME OVER", BOARD_X + BOARD_W / 2, BOARD_Y + BOARD_H / 2 - 30);
  textSize(18);
  text("Press R to restart", BOARD_X + BOARD_W / 2, BOARD_Y + BOARD_H / 2 + 20);
}
void drawMenuScreen() {
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(54);
  text("Tetris++", width / 2, 90);
  fill(180);
  textSize(16);
  text("A Processing block-stacking game", width / 2, 135);
  int buttonW = 220, buttonH = 46;
  int gap = 14;
  int x = width / 2 - buttonW / 2, y = height / 2 - 60;
  drawUIButton("Play", x, y, buttonW, buttonH);
  drawUIButton("Options", x, y + buttonH + gap, buttonW, buttonH);
  drawUIButton("How to Play", x, y + 2 * (buttonH + gap), buttonW, buttonH);
  drawUIButton("Credits", x, y + 3 * (buttonH + gap), buttonW, buttonH);
}
void drawOptionsScreen() {
  drawBackButton();
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(42);
  text("Options", width / 2, 90);
  int boxX = width / 2 - 130, boxY = height / 2 - 80;
  drawCheckboxOption("Ghost piece", boxX, boxY, ghostEnabled);
  drawCheckboxOption("Flipping", boxX, boxY + 44, flippingEnabled);
  if (flippingEnabled) {
    fill(190);
    textAlign(LEFT, TOP);
    textSize(13);
    text("Press F during play to reverse gravity.", boxX, boxY + 88, 300, 50);
  }
  noStroke();
}
void drawHowToPlayScreen() {
  String body =
    "Goal:\n" +
    "Place falling tetrominoes to complete full horizontal lines. Completed lines disappear and give points.\n\n" +
    "Controls:\n" +
    "Left/Right: move piece\n" +
    "A: rotate counterclockwise\n" +
    "D: rotate clockwise\n" +
    "S: hard drop\n" +
    "Up Arrow: hold the current piece, or swap if hold is already filled\n" +
    "Down Arrow: soft drop / speed up falling\n" +
    "F: flip, if Flipping is enabled in Options\n" +
    "R: restart during a game\n" +
    "Esc: return to the menu\n\n" +
    "The ghost piece shows where the current piece will land. You can turn it on or off in Options. Flipping reverses gravity.";
  drawTextPage("How to Play", body);
}
void drawCreditsScreen() {
  String body =
    "Tetris++\n\n" +
    "Created in Processing / Java.\n\n" +
    "Programming, UI, and gameplay implementation by: Your Name Here\n\n" +
    "Features include 7-bag randomization, SRS rotations, hold, next queue, ghost piece, scoring, soft drop, hard drop, and line clears.";
  drawTextPage("Credits", body);
}
void drawTextPage(String heading, String body) {
  drawBackButton();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(42);
  text(heading, width / 2, 90);
  int margin = 60;
  fill(220);
  textAlign(LEFT, TOP);
  textSize(17);
  textLeading(24);
  text(body, margin, 145, width - margin * 2, height - 190);
}
void drawUIButton(String label, int x, int y, int w, int h) {
  boolean hovered = buttonHit(x, y, w, h);
  noStroke();
  if (hovered) { fill(85); }
  else { fill(50); }
  rect(x, y, w, h, 8);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(20);
  text(label, x + w / 2, y + h / 2 - 1);
}
void drawBackButton() { drawUIButton("Back", 20, 20, 90, 34); }
boolean backButtonHit() { return buttonHit(20, 20, 90, 34); }
boolean buttonHit(int x, int y, int w, int h) {
  return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
}
void drawPreviewBox(int x, int y, int w, int h) {
  noStroke();
  fill(45);
  rect(x, y, w, h);
  fill(24);
  rect(x + 5, y + 5, w - 10, h - 10);
}
void drawMiniTetromino(Tetromino t, int x, int y, int miniCell) {
  int[][] cells = getCells(t.kind, 0);
  int minX = 10, maxX = -10, minY = 10, maxY = -10;
  for (int i = 0; i < 4; i++) {
    minX = min(minX, cells[i][0]);
    maxX = max(maxX, cells[i][0]);
    minY = min(minY, cells[i][1]);
    maxY = max(maxY, cells[i][1]);
  }
  int shapeW = (maxX - minX + 1) * (miniCell + 3) - 3, shapeH = (maxY - minY + 1) * (miniCell + 3) - 3;
  int startX = x + (88 - shapeW) / 2, startY = y + (48 - shapeH) / 2;
  for (int i = 0; i < 4; i++) {
    int px = startX + (cells[i][0] - minX) * (miniCell + 3), py = startY + (cells[i][1] - minY) * (miniCell + 3);
    drawMiniBlock(px, py, miniCell, t.pieceColor);
  }
  fill(230);
  textAlign(LEFT, CENTER);
  textSize(13);
  text(KIND_NAMES[t.kind], x + 100, y + 33);
}
void drawMiniBlock(int x, int y, int s, int pieceColor) {
  noStroke();
  fill(pieceColor);
  rect(x, y, s, s);
  fill(255, 80);
  rect(x + 2, y + 2, s - 4, 4);
  fill(0, 70);
  rect(x + 2, y + s - 6, s - 4, 4);
}
void drawBlockPixels(int x, int y, int pieceColor, int alphaValue) {
  noStroke();
  fill(red(pieceColor), green(pieceColor), blue(pieceColor), alphaValue);
  rect(x, y, CELL, CELL);
  fill(255, alphaValue * 0.32f);
  rect(x + 4, y + 4, CELL - 8, 5);
  fill(0, alphaValue * 0.28f);
  rect(x + 4, y + CELL - 9, CELL - 8, 5);
}
int gridToPixelX(int c) { return BOARD_X + BORDER + c * (CELL + BORDER); }
int gridToPixelY(int r) { return BOARD_Y + BORDER + r * (CELL + BORDER); }

void drawCheckboxOption(String label, int x, int y, boolean checked) {
  noStroke();
  fill(235);
  textAlign(LEFT, CENTER);
  textSize(20);
  text(label, x + 42, y + 14);
  stroke(235);
  strokeWeight(3);
  if (checked) { fill(80, 180, 110); }
  else { fill(35); }
  rect(x, y, 26, 26, 4);
  if (checked) {
    stroke(255);
    strokeWeight(4);
    line(x + 6, y + 14, x + 11, y + 20);
    line(x + 11, y + 20, x + 21, y + 7);
  }
  noStroke();
}
void drawRadioOption(String label, int x, int y, boolean selected) {
  noStroke();
  fill(225);
  textAlign(LEFT, CENTER);
  textSize(18);
  text(label, x + 36, y + 14);
  stroke(235);
  strokeWeight(3);
  fill(35);
  ellipse(x + 13, y + 13, 24, 24);
  if (selected) {
    noStroke();
    fill(80, 180, 110);
    ellipse(x + 13, y + 13, 12, 12);
  }
  noStroke();
}
