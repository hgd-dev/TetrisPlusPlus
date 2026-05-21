void updateGravityAndLock() {
  int now = millis();
  if (canPlace(current, current.col, current.row + 1, current.rot)) {
    lockStartTime = -1;
    int fallInterval = gravityIntervalMs();
    if (softDropHeld) { fallInterval = SOFT_DROP_INTERVAL_MS; }
    if (now - lastFallTime >= fallInterval) {
      current.row++;
      if (softDropHeld) { score += 1; }
      lastFallTime = now;
    }
  }
  else {
    if (lockStartTime < 0) { lockStartTime = now; }
    else if (now - lockStartTime >= LOCK_DELAY_MS) { lockCurrentPiece(); }
  }
}
int gravityIntervalMs() { return max(60, 1000 - (level - 1) * 80); }
boolean tryMoveCurrent(int dx, int dy, boolean playerMove) {
  if (canPlace(current, current.col + dx, current.row + dy, current.rot)) {
    current.col += dx; current.row += dy;
    if (playerMove) { resetLockDelayAfterSuccessfulAction(); }
    return true;
  }
  return false;
}
void tryRotateCurrent(int direction) {
  int oldRot = current.rot;
  int newRot = (current.rot + direction + 4) % 4;
  int[][] kicks = getKickTests(current.kind, oldRot, newRot);
  for (int i = 0; i < kicks.length; i++) {
    int kickedCol = current.col + kicks[i][0];
    int kickedRow = current.row + kicks[i][1];
    if (canPlace(current, kickedCol, kickedRow, newRot)) {
      current.col = kickedCol; current.row = kickedRow;
      current.rot = newRot;
      resetLockDelayAfterSuccessfulAction();
      return;
    }
  }
}
void resetLockDelayAfterSuccessfulAction() {
  if (canPlace(current, current.col, current.row + 1, current.rot)) {
    lockStartTime = -1;
    return;
  }
  if (lockResets < MAX_LOCK_RESETS) {
    lockStartTime = millis();
    lockResets++;
  }
}
void hardDropCurrent() {
  int dropped = 0;
  while (canPlace(current, current.col, current.row + 1, current.rot)) {
    current.row++;
    dropped++;
  }
  score += dropped * 2;
  lockCurrentPiece();
}
void holdCurrentPiece() {
  if (holdUsedThisPiece) { return; }
  Tetromino oldCurrent = current.toTetromino();
  if (heldPiece == null) {
    heldPiece = oldCurrent;
    spawnNextPiece();
    holdUsedThisPiece = true;
  }
  else {
    spawnSpecificPiece(heldPiece);
    heldPiece = oldCurrent;
    holdUsedThisPiece = true;
  }
}
void lockCurrentPiece() {
  int[][] cells = getCells(current.kind, current.rot);
  boolean lockedAboveTop = false;
  for (int i = 0; i < 4; i++) {
    int c = current.col + cells[i][0];
    int r = current.row + cells[i][1];
    if (r < 0) { lockedAboveTop = true; }
    else if (r < ROWS && c >= 0 && c < COLS) { board[r][c] = current.pieceColor; }
  }
  if (lockedAboveTop) {
    gameOver = true;
    return;
  }
  int cleared = clearFullLines();
  if (cleared > 0) {
    int[] lineScores = {0, 100, 300, 500, 800};
    score += lineScores[cleared] * level;
    lines += cleared;
    level = 1 + lines / 10;
  }
  spawnNextPiece();
}
int clearFullLines() {
  int cleared = 0;
  for (int r = ROWS - 1; r >= 0; r--) {
    boolean full = true;
    for (int c = 0; c < COLS; c++) {
      if (board[r][c] == 0) {
        full = false;
        break;
      }
    }
    if (full) {
      cleared++;
      for (int pull = r; pull > 0; pull--) {
        for (int c = 0; c < COLS; c++) { board[pull][c] = board[pull - 1][c]; }
      }
      for (int c = 0; c < COLS; c++) { board[0][c] = 0; }
      r++;
    }
  }
  return cleared;
}
boolean canPlace(ActivePiece p, int testCol, int testRow, int testRot) {
  int[][] cells = getCells(p.kind, testRot);
  for (int i = 0; i < 4; i++) {
    int c = testCol + cells[i][0], r = testRow + cells[i][1];
    if (c < 0 || c >= COLS || r >= ROWS) { return false; }
    if (r >= 0 && board[r][c] != 0) { return false; }
  }
  return true;
}
void spawnNextPiece() {
  ensureQueueSize(5);
  Tetromino next = nextQueue.remove(0);
  ensureQueueSize(5);
  spawnSpecificPiece(next);
  holdUsedThisPiece = false;
}
void spawnSpecificPiece(Tetromino t) {
  current = new ActivePiece(t.kind, t.pieceColor);
  current.col = 3;
  current.row = -1;
  current.rot = 0;
  lastFallTime = millis();
  lockStartTime = -1;
  lockResets = 0;
  if (!canPlace(current, current.col, current.row, current.rot)) { gameOver = true; }
}
void ensureQueueSize(int wantedSize) {
  while (nextQueue.size() < wantedSize) {
    nextQueue.add(new Tetromino(drawPieceKindFromBag(), drawColorFromBag()));
  }
}
int drawPieceKindFromBag() {
  if (pieceBag.size() == 0) {
    for (int k = 0; k < 7; k++) { pieceBag.add(k); }
    Collections.shuffle(pieceBag);
  }
  return pieceBag.remove(pieceBag.size() - 1);
}
int drawColorFromBag() {
  if (colorBag.size() == 0) {
    for (int i = 0; i < 7; i++) { colorBag.add(palette[i]); }
    Collections.shuffle(colorBag);
  }
  return colorBag.remove(colorBag.size() - 1);
}
