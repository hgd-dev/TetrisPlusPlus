void updateGravityAndLock() {
  int now = millis();
  int dy = fallDirection();
  if (canPlace(current, current.col, current.row + dy, current.rot)) {
    lockStartTime = -1;
    int fallInterval = gravityIntervalMs();
    if (softDropHeld) { fallInterval = SOFT_DROP_INTERVAL_MS; }
    if (now - lastFallTime >= fallInterval) {
      current.row += dy;
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
int fallDirection() {
  if (flippingEnabled) { return gravityDirection; }
  return SIDE_BOTTOM;
}
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
  if (canPlace(current, current.col, current.row + fallDirection(), current.rot)) {
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
  int dy = fallDirection();
  while (canPlace(current, current.col, current.row + dy, current.rot)) {
    current.row += dy;
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
  int side = fallDirection();
  for (int i = 0; i < 4; i++) {
    int c = current.col + cells[i][0];
    int r = current.row + cells[i][1];
    if (r >= 0 && r < ROWS && c >= 0 && c < COLS) {
      board[r][c] = current.pieceColor;
      blockSide[r][c] = side;
    }
  }
  int cleared = clearFullLinesForSide(side);
  if (cleared > 0) {
    int[] lineScores = {0, 100, 300, 500, 800};
    score += lineScores[min(cleared, 4)] * level;
    lines += cleared;
    level = 1 + lines / 10;
  }
  spawnNextPiece();
}
int clearFullLinesForSide(int side) {
  int cleared = 0;

  if (side == SIDE_BOTTOM) {
    int r = ROWS - 1;
    while (r >= 0) {
      if (isFullLineForSide(r, side)) {
        shiftSideRowsAfterClear(r, side);
        cleared++;
        // Recheck this same row because the row shifted into it may also be full.
      }
      else { r--; }
    }
  }
  else {
    int r = 0;
    while (r < ROWS) {
      if (isFullLineForSide(r, side)) {
        shiftSideRowsAfterClear(r, side);
        cleared++;
        // Recheck this same row because the row shifted into it may also be full.
      }
      else { r++; }
    }
  }

  return cleared;
}
boolean isFullLineForSide(int r, int side) {
  for (int c = 0; c < COLS; c++) {
    if (board[r][c] == 0 || blockSide[r][c] != side) { return false; }
  }
  return true;
}
boolean rowHasOppositeSide(int r, int side) {
  int opposite = -side;
  for (int c = 0; c < COLS; c++) {
    if (blockSide[r][c] == opposite) { return true; }
  }
  return false;
}
void copySideRowOnly(int fromRow, int toRow, int side) {
  for (int c = 0; c < COLS; c++) {
    if (blockSide[toRow][c] == -side) { continue; }

    if (blockSide[fromRow][c] == side) {
      board[toRow][c] = board[fromRow][c];
      blockSide[toRow][c] = side;
    }
    else {
      board[toRow][c] = 0;
      blockSide[toRow][c] = 0;
    }
  }
}
void clearSideCellsInRow(int r, int side) {
  for (int c = 0; c < COLS; c++) {
    if (blockSide[r][c] == side) {
      board[r][c] = 0;
      blockSide[r][c] = 0;
    }
  }
}
void shiftSideRowsAfterClear(int clearedRow, int side) {
  clearSideCellsInRow(clearedRow, side);

  if (side == SIDE_BOTTOM) {
    int writeRow = clearedRow;
    while (writeRow > 0 && !rowHasOppositeSide(writeRow - 1, side)) {
      copySideRowOnly(writeRow - 1, writeRow, side);
      writeRow--;
    }
    clearSideCellsInRow(writeRow, side);
  }
  else {
    int writeRow = clearedRow;
    while (writeRow < ROWS - 1 && !rowHasOppositeSide(writeRow + 1, side)) {
      copySideRowOnly(writeRow + 1, writeRow, side);
      writeRow++;
    }
    clearSideCellsInRow(writeRow, side);
  }
}
boolean canPlace(ActivePiece p, int testCol, int testRow, int testRot) {
  int[][] cells = getCells(p.kind, testRot);
  for (int i = 0; i < 4; i++) {
    int c = testCol + cells[i][0], r = testRow + cells[i][1];
    if (c < 0 || c >= COLS || r >= ROWS) { return false; }
    if (r < 0) {
      if (fallDirection() == SIDE_TOP) { return false; }
    }
    else if (board[r][c] != 0) { return false; }
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
  current.rot = 0;
  boolean spawned = false;
  int dy = fallDirection();
  if (flippingEnabled) {
    if (dy == SIDE_TOP) {
      // Falling up means the pile grows from the top, so spawn from the bottom side.
      for (int r = ROWS - 1; r >= 0; r--) {
        if (canPlace(current, current.col, r, current.rot)) {
          current.row = r;
          spawned = true;
          break;
        }
      }
    }
    else {
      // Falling down means the pile grows from the bottom, so spawn from the top side.
      for (int r = -2; r < ROWS; r++) {
        if (canPlace(current, current.col, r, current.rot)) {
          current.row = r;
          spawned = true;
          break;
        }
      }
    }
  }
  else {
    current.row = -1;
    spawned = canPlace(current, current.col, current.row, current.rot);
  }
  lastFallTime = millis();
  lockStartTime = -1;
  lockResets = 0;
  if (!spawned) { gameOver = true; }
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

void performFlip() {
  if (!flippingEnabled || gameOver || current == null) { return; }
  gravityDirection *= -1;
  lastFallTime = millis();
  lockStartTime = -1;
  lockResets = 0;
}
