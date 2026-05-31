void updateGL() {
  int now = millis(), dy = fallDir();
  if (canPlace(current, current.col, current.row + dy, current.rot)) {
    lockStartTime = -1;
    int fallInt = gravInt();
    if (softDropHeld) { fallInt = softDropT; }
    if (now - lastFallTime >= fallInt) {
      current.row += dy;
      if (softDropHeld) { score += 1; }
      lastFallTime = now;
    }
  }
  else {
    if (lockStartTime < 0) { lockStartTime = now; }
    else if (now - lockStartTime >= lockDelay) { lockCur(); }
  }
}
int gravInt() { return max(60, 1000 - (level - 1) * 80); }
int fallDir() {
  if (flippingEnabled && flipMode == flipGrav) { return gravityDirection; }
  return sBottom;
}
boolean moveCur(int dx, int dy, boolean playerMove) {
  if (canPlace(current, current.col + dx, current.row + dy, current.rot)) {
    current.col += dx; current.row += dy;
    if (playerMove) { resLockDelay(); }
    return true;
  }
  return false;
}
void rotCur(int direction) {
  int oldRot = current.rot;
  int newRot = (current.rot + direction + 4) % 4;
  int[][] kicks = getKickTests(current.kind, oldRot, newRot);
  for (int i = 0; i < kicks.length; i++) {
    int kickedCol = current.col + kicks[i][0];
    int kickedRow = current.row + kicks[i][1];
    if (canPlace(current, kickedCol, kickedRow, newRot)) {
      current.col = kickedCol; current.row = kickedRow;
      current.rot = newRot;
      resLockDelay();
      return;
    }
  }
}
void resLockDelay() {
  if (canPlace(current, current.col, current.row + fallDir(), current.rot)) {
    lockStartTime = -1;
    return;
  }
  if (lockResets < maxLRes) {
    lockStartTime = millis();
    lockResets++;
  }
}
void hardDropCur() {
  int dropped = 0;
  int dy = fallDir();
  while (canPlace(current, current.col, current.row + dy, current.rot)) {
    current.row += dy;
    dropped++;
  }
  score += dropped * 2;
  lockCur();
}
void holdCur() {
  if (holdUsed) { return; }
  Tetromino oldCurrent = current.toTetromino();
  if (heldPiece == null) {
    heldPiece = oldCurrent;
    spawnNext();
    holdUsed = true;
  }
  else {
    spawnSpecific(heldPiece);
    heldPiece = oldCurrent;
    holdUsed = true;
  }
}
void lockCur() {
  int[][] cells = getCells(current.kind, current.rot);
  int side = fallDir();
  for (int i = 0; i < 4; i++) {
    int c = current.col + cells[i][0];
    int r = current.row + cells[i][1];
    if (r >= 0 && r < n && c >= 0 && c < m) {
      board[r][c] = current.pieceColor;
      blockSide[r][c] = side;
    }
  }
  int cleared = clearLinesSide(side);
  if (cleared > 0) {
    int[] lineScores = {0, 100, 300, 500, 800};
    score += lineScores[min(cleared, 4)] * level;
    lines += cleared;
    level = 1 + lines / 10;
  }
  spawnNext();
}
int clearLinesSide(int side) {
  int cleared = 0;
  if (side == sBottom) {
    int r = n - 1;
    while (r >= 0) {
      if (fullLineSide(r, side)) { shiftSide(r, side); cleared++; }
      else { r--; }
    }
  }
  else {
    int r = 0;
    while (r < n) {
      if (fullLineSide(r, side)) { shiftSide(r, side); cleared++; }
      else { r++; }
    }
  }
  return cleared;
}
boolean fullLineSide(int r, int side) {
  for (int c = 0; c < m; c++) {
    if (board[r][c] == 0 || blockSide[r][c] != side) { return false; }
  }
  return true;
}
boolean hasOppSide(int r, int side) {
  int opposite = -side;
  for (int c = 0; c < m; c++) {
    if (blockSide[r][c] == opposite) { return true; }
  }
  return false;
}
void copySideRow(int fromRow, int toRow, int side) {
  for (int c = 0; c < m; c++) {
    if (blockSide[toRow][c] == -side) { continue; }
    if (blockSide[fromRow][c] == side) {
      board[toRow][c] = board[fromRow][c];
      blockSide[toRow][c] = side;
    }
    else { board[toRow][c] = 0; blockSide[toRow][c] = 0; }
  }
}
void clearSideRow(int r, int side) { for (int c = 0; c < m; c++) { if (blockSide[r][c] == side) { board[r][c] = 0; blockSide[r][c] = 0; } } }
void shiftSide(int clearedRow, int side) {
  clearSideRow(clearedRow, side);
  if (side == sBottom) {
    int writeRow = clearedRow;
    while (writeRow > 0 && !hasOppSide(writeRow - 1, side)) {
      copySideRow(writeRow - 1, writeRow, side);
      writeRow--;
    }
    clearSideRow(writeRow, side);
  }
  else {
    int writeRow = clearedRow;
    while (writeRow < n - 1 && !hasOppSide(writeRow + 1, side)) {
      copySideRow(writeRow + 1, writeRow, side);
      writeRow++;
    }
    clearSideRow(writeRow, side);
  }
}
boolean canPlace(ActivePiece p, int testCol, int testRow, int testRot) {
  int[][] cells = getCells(p.kind, testRot);
  for (int i = 0; i < 4; i++) {
    int c = testCol + cells[i][0], r = testRow + cells[i][1];
    if (c < 0 || c >= m || r >= n) { return false; }
    if (r < 0) { if (fallDir() == sTop) { return false; } }
    else if (board[r][c] != 0) { return false; }
  }
  return true;
}
boolean inRange(ActivePiece p, int testCol, int testRow, int testRot) {
  int[][] cells = getCells(p.kind, testRot);
  for (int i = 0; i < 4; i++) {
    int c = testCol + cells[i][0], r = testRow + cells[i][1];
    if (c < 0 || c >= m || r < 0 || r >= n) { return false; }
    if (board[r][c] != 0) { return false; }
  }
  return true;
}
int findSpawn(ActivePiece p, int spawnCol, int spawnRot) {
  int[][] cells = getCells(p.kind, spawnRot);
  int minY = cells[0][1], maxY = cells[0][1];
  for (int i = 1; i < 4; i++) { minY = min(minY, cells[i][1]); maxY = max(maxY, cells[i][1]); }
  int dy = fallDir();
  if (dy == sTop) { for (int r = n - 1 - maxY; r >= -minY; r--) { if (inRange(p, spawnCol, r, spawnRot)) { return r; } } }
  else { for (int r = -minY; r <= n - 1 - maxY; r++) { if (inRange(p, spawnCol, r, spawnRot)) { return r; } } }
  return -999;
}
void spawnNext() {
  fixQueue(5);
  Tetromino next = nextQueue.remove(0);
  fixQueue(5);
  spawnSpecific(next);
  holdUsed = false;
}
void spawnSpecific(Tetromino t) {
  current = new ActivePiece(t.kind, t.pieceColor);
  current.col = 3;
  current.rot = 0;
  int spawnRow = findSpawn(current, current.col, current.rot);
  boolean spawned = (spawnRow != -999);
  if (spawned) { current.row = spawnRow; }
  lastFallTime = millis();
  lockStartTime = -1;
  lockResets = 0;
  if (!spawned) { gameOver = true; }
}
void fixQueue(int wantedSize) { while (nextQueue.size() < wantedSize) { nextQueue.add(new Tetromino(getPiece(), getColor())); } }
int getPiece() {
  if (pieceBag.size() == 0) {
    for (int k = 0; k < 7; k++) { pieceBag.add(k); }
    Collections.shuffle(pieceBag);
  }
  return pieceBag.remove(pieceBag.size() - 1);
}
int getColor() {
  if (colorBag.size() == 0) {
    for (int i = 0; i < 7; i++) { colorBag.add(palette[i]); }
    Collections.shuffle(colorBag);
  }
  return colorBag.remove(colorBag.size() - 1);
}
void performFlip() {
  if (!flippingEnabled || gameOver || current == null) { return; }
  if (flipMode == flipGrav) { flipGravity(); }
  else if (flipMode == flipBoard) { flipBoardVert(); }
}
void flipGravity() {
  gravityDirection *= -1;
  lastFallTime = millis();
  lockStartTime = -1;
  lockResets = 0;
}
void flipBoardVert() {
  gravityDirection = sBottom;
  for (int r = 0; r < n / 2; r++) {
    int mirrorR = n - 1 - r;
    for (int c = 0; c < m; c++) {
      int tempColor = board[r][c];
      board[r][c] = board[mirrorR][c];
      board[mirrorR][c] = tempColor;
      int tempSide = blockSide[r][c];
      blockSide[r][c] = mirrorSide(blockSide[mirrorR][c]);
      blockSide[mirrorR][c] = mirrorSide(tempSide);
    }
  }
  if (!pushCurMid()) {
    gameOver = true;
    return;
  }
  lastFallTime = millis();
  lockStartTime = -1;
  lockResets = 0;
}
int mirrorSide(int side) {
  if (side == sTop) { return sBottom; }
  if (side == sBottom) { return sTop; }
  return 0;
}
boolean pushCurMid() {
  if (current == null) { return true; }
  int[][] cells = getCells(current.kind, current.rot);
  int minY = cells[0][1], maxY = cells[0][1];
  for (int i = 1; i < 4; i++) { minY = min(minY, cells[i][1]); maxY = max(maxY, cells[i][1]); }
  int firstRow = -minY, lastRow = n - 1 - maxY;
  if (inRange(current, current.col, current.row, current.rot)) { return true; }
  for (int r = firstRow; r <= lastRow; r++) {
    if (inRange(current, current.col, r, current.rot)) {
      current.row = r;
      return true;
    }
  }
  return false;
}
