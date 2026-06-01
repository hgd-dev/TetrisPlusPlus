final int gpb = 14;
final int sandPx = 2;
final int sandW = m * gpb, sandH = n * gpb;
final int sandBX = bX + border, sandBY = bY + border;
final int sandBlinkFrames = 8, sandBlinkCycles = 6;
int[][] sand = new int[sandH][sandW];
int[][] sandSide = new int[sandH][sandW];
int[] sandClearX = new int[sandW * sandH];
int[] sandClearY = new int[sandW * sandH];
float sandCurX, sandCurY;
int sandStep = 0, sandClearCount = 0, sandClearFrame = 0, sandClearColor = 0;
boolean sandClearActive = false;
void resetSand() {
  for (int y = 0; y < sandH; y++) {
    for (int x = 0; x < sandW; x++) {
      sand[y][x] = 0;
      sandSide[y][x] = 0;
    }
  }
  sandCurX = 0;
  sandCurY = 0;
  sandStep = 0;
  sandClearCount = 0;
  sandClearFrame = 0;
  sandClearColor = 0;
  sandClearActive = false;
}
void updateSandGame() {
  if (sandClearActive) {
    updateSandClearBlink();
    return;
  }
  handleSandAim();
  updateSandPieceFall();
  for (int i = 0; i < 3; i++) { updateSandPhysics(); }
  clearSandLines();
}
boolean initSandCur() {
  int[][] cells = getCells(current.kind, current.rot);
  int minX = cells[0][0], maxX = cells[0][0], minY = cells[0][1], maxY = cells[0][1];
  for (int i = 1; i < 4; i++) {
    minX = min(minX, cells[i][0]);
    maxX = max(maxX, cells[i][0]);
    minY = min(minY, cells[i][1]);
    maxY = max(maxY, cells[i][1]);
  }
  int shapeW = (maxX - minX + 1) * gpb;
  sandCurX = (sandW - shapeW) / 2 - minX * gpb;
  if (fallDir() == sTop) { sandCurY = sandH - (maxY + 1) * gpb; }
  else { sandCurY = -minY * gpb; }
  return findSandSpawn();
}
boolean findSandSpawn() {
  if (current == null) { return false; }
  int[][] cells = getCells(current.kind, current.rot);
  int minY = cells[0][1], maxY = cells[0][1];
  for (int i = 1; i < 4; i++) { minY = min(minY, cells[i][1]); maxY = max(maxY, cells[i][1]); }
  int firstY = -minY * gpb;
  int lastY = sandH - (maxY + 1) * gpb;
  if (fallDir() == sTop) { for (int y = lastY; y >= firstY; y--) { if (findSandSpawnX(y)) { return true; } } }
  else { for (int y = firstY; y <= lastY; y++) { if (findSandSpawnX(y)) { return true; } } }
  return false;
}
boolean findSandSpawnX(float y) {
  for (int off = 0; off < sandW; off++) {
    float leftX = sandCurX - off;
    float rightX = sandCurX + off;
    if (canSandCurAt(leftX, y, current.rot)) { sandCurX = leftX; sandCurY = y; return true; }
    if (off != 0 && canSandCurAt(rightX, y, current.rot)) { sandCurX = rightX; sandCurY = y; return true; }
  }
  return false;
}
void handleSandAim() {
  if (current == null) { return; }
  float speed = 1.25f;
  if (leftHeld) { moveSandCurX(-speed); }
  if (rightHeld) { moveSandCurX(speed); }
}
void moveSandCurX(float dx) {
  int steps = ceil(abs(dx));
  float each = dx / max(1, steps);
  for (int i = 0; i < steps; i++) { if (canSandCurAt(sandCurX + each, sandCurY, current.rot)) { sandCurX += each; } }
}
void updateSandPieceFall() {
  if (current == null) { return; }
  float dy = fallDir() * (softDropHeld ? 2.3f : 0.72f);
  int steps = ceil(abs(dy));
  float each = dy / max(1, steps);
  for (int i = 0; i < steps; i++) {
    if (canSandCurAt(sandCurX, sandCurY + each, current.rot)) { sandCurY += each; }
    else { lockSandCur(); return; }
  }
}
void sandRot(int direction) {
  if (current == null) { return; }
  int oldRot = current.rot;
  int newRot = (current.rot + direction + 4) % 4;
  int[][] kicks = getKickTests(current.kind, oldRot, newRot);
  for (int i = 0; i < kicks.length; i++) {
    float tx = sandCurX + kicks[i][0] * gpb;
    float ty = sandCurY + kicks[i][1] * gpb;
    if (canSandCurAt(tx, ty, newRot)) {
      sandCurX = tx;
      sandCurY = ty;
      current.rot = newRot;
      return;
    }
  }
}
boolean canSandCurAt(float tx, float ty, int testRot) {
  int[][] cells = getCells(current.kind, testRot);
  for (int i = 0; i < 4; i++) {
    int left = floor(tx + cells[i][0] * gpb);
    int top = floor(ty + cells[i][1] * gpb);
    for (int y = 0; y < gpb; y++) {
      int gy = top + y;
      if (gy < 0 || gy >= sandH) { return false; }
      for (int x = 0; x < gpb; x++) {
        int gx = left + x;
        if (gx < 0 || gx >= sandW) { return false; }
        if (sand[gy][gx] != 0) { return false; }
      }
    }
  }
  return true;
}
void sandHardDrop() {
  if (current == null) { return; }
  int d = fallDir();
  while (canSandCurAt(sandCurX, sandCurY + d, current.rot)) { sandCurY += d; score += 1; }
  lockSandCur();
}
void lockSandCur() {
  if (current == null) { return; }
  int[][] cells = getCells(current.kind, current.rot);
  int side = fallDir();
  for (int i = 0; i < 4; i++) {
    int left = floor(sandCurX + cells[i][0] * gpb), top = floor(sandCurY + cells[i][1] * gpb);
    for (int y = 0; y < gpb; y++) {
      int gy = top + y;
      if (gy < 0 || gy >= sandH) { continue; }
      for (int x = 0; x < gpb; x++) {
        int gx = left + x;
        if (gx >= 0 && gx < sandW && sand[gy][gx] == 0) {
          sand[gy][gx] = current.pieceColor;
          sandSide[gy][gx] = side;
        }
      }
    }
  }
  current = null;
  queueSpawn();
}
void updateSandPhysics() {
  sandStep++;
  if (sandStep % 2 == 0) {
    for (int y = sandH - 1; y >= 0; y--) { updateSandRow(y, sBottom); }
    for (int y = 0; y < sandH; y++) { updateSandRow(y, sTop); }
  }
  else {
    for (int y = sandH - 1; y >= 0; y--) { updateSandRowReverse(y, sBottom); }
    for (int y = 0; y < sandH; y++) { updateSandRowReverse(y, sTop); }
  }
}
void updateSandRow(int y, int side) { for (int x = 0; x < sandW; x++) { tryMoveSand(x, y, side); } }
void updateSandRowReverse(int y, int side) { for (int x = sandW - 1; x >= 0; x--) { tryMoveSand(x, y, side); } }
void tryMoveSand(int x, int y, int side) {
  if (sand[y][x] == 0 || sandSide[y][x] != side) { return; }
  int ny = y + side;
  if (ny < 0 || ny >= sandH) { return; }
  if (sand[ny][x] == 0) { swapSand(x, y, x, ny); return; }
  int first = random(1) < 0.5f ? -1 : 1;
  int nx = x + first;
  if (nx >= 0 && nx < sandW && sand[ny][nx] == 0) { swapSand(x, y, nx, ny); return; }
  nx = x - first;
  if (nx >= 0 && nx < sandW && sand[ny][nx] == 0) { swapSand(x, y, nx, ny); }
}
void swapSand(int x1, int y1, int x2, int y2) {
  sand[y2][x2] = sand[y1][x1];
  sandSide[y2][x2] = sandSide[y1][x1];
  sand[y1][x1] = 0;
  sandSide[y1][x1] = 0;
}
void clearSandLines() {
  boolean[] seen = new boolean[sandW * sandH];
  for (int y = 0; y < sandH; y++) {
    int col = sand[y][0];
    if (col == 0) { continue; }
    int id = y * sandW;
    if (seen[id]) { continue; }
    if (startSandBridgeBlink(0, y, col, seen)) { return; }
  }
}
boolean startSandBridgeBlink(int sx, int sy, int col, boolean[] seen) {
  int maxCount = sandW * sandH;
  int[] qx = new int[maxCount], qy = new int[maxCount];
  int head = 0, tail = 0, count = 0;
  boolean reachesRight = false;
  qx[tail] = sx; qy[tail] = sy; tail++;
  seen[sy * sandW + sx] = true;
  while (head < tail) {
    int x = qx[head], y = qy[head];
    head++;
    sandClearX[count] = x; sandClearY[count] = y; count++;
    if (x == sandW - 1) { reachesRight = true; }
    int nx = x + 1, ny = y;
    if (validSandNeighbor(nx, ny, col, seen)) { seen[ny * sandW + nx] = true; qx[tail] = nx; qy[tail] = ny; tail++; }
    nx = x - 1;
    if (validSandNeighbor(nx, ny, col, seen)) { seen[ny * sandW + nx] = true; qx[tail] = nx; qy[tail] = ny; tail++; }
    nx = x; ny = y + 1;
    if (validSandNeighbor(nx, ny, col, seen)) { seen[ny * sandW + nx] = true; qx[tail] = nx; qy[tail] = ny; tail++; }
    ny = y - 1;
    if (validSandNeighbor(nx, ny, col, seen)) { seen[ny * sandW + nx] = true; qx[tail] = nx; qy[tail] = ny; tail++; }
  }
  if (!reachesRight) { return false; }
  sandClearCount = count;
  sandClearFrame = 0;
  sandClearColor = col;
  sandClearActive = true;
  return true;
}
boolean validSandNeighbor(int x, int y, int col, boolean[] seen) {
  if (x < 0 || x >= sandW || y < 0 || y >= sandH) { return false; }
  if (seen[y * sandW + x]) { return false; }
  return (sand[y][x] == col);
}
void updateSandClearBlink() {
  sandClearFrame++;
  if (sandClearFrame >= sandBlinkFrames * sandBlinkCycles) { finishSandClear(); }
}
boolean sandClearWhite() { return sandClearActive && (sandClearFrame / sandBlinkFrames) % 2 == 0; }
void finishSandClear() {
  for (int i = 0; i < sandClearCount; i++) {
    int x = sandClearX[i], y = sandClearY[i];
    if (sand[y][x] == sandClearColor) { sand[y][x] = 0; sandSide[y][x] = 0; }
  }
  sandClearActive = false;
  sandClearCount = 0;
  sandClearFrame = 0;
  sandClearColor = 0;
  lines++;
  score += 100 * level;
  level = 1 + lines / 10;
}
void flipSandBoardVert() {
  gravityDirection = sBottom;
  for (int y = 0; y < sandH / 2; y++) {
    int my = sandH - 1 - y;
    for (int x = 0; x < sandW; x++) {
      int tc = sand[y][x];
      sand[y][x] = sand[my][x];
      sand[my][x] = tc;
      int ts = sandSide[y][x];
      sandSide[y][x] = mirrorSide(sandSide[my][x]);
      sandSide[my][x] = mirrorSide(ts);
    }
  }
  if (sandClearActive) { for (int i = 0; i < sandClearCount; i++) { sandClearY[i] = sandH - 1 - sandClearY[i]; } }
  if (current != null) {
    mirrorSandCurY();
    if (!pushSandCurMid()) { lockSandCur(); }
  }
}
void mirrorSandCurY() {
  int[][] cells = getCells(current.kind, current.rot);
  int minY = cells[0][1], maxY = cells[0][1];
  for (int i = 1; i < 4; i++) { minY = min(minY, cells[i][1]); maxY = max(maxY, cells[i][1]); }
  float bottom = sandCurY + (maxY + 1) * gpb;
  float newTop = sandH - bottom;
  sandCurY = newTop - minY * gpb;
}
boolean pushSandCurMid() {
  if (current == null) { return true; }
  if (canSandCurAt(sandCurX, sandCurY, current.rot)) { return true; }
  int[][] cells = getCells(current.kind, current.rot);
  int minY = cells[0][1], maxY = cells[0][1];
  for (int i = 1; i < 4; i++) { minY = min(minY, cells[i][1]); maxY = max(maxY, cells[i][1]); }
  int firstY = -minY * gpb;
  int lastY = sandH - (maxY + 1) * gpb;
  for (int y = firstY; y <= lastY; y++) {
    for (int off = 0; off < sandW; off++) {
      float leftX = sandCurX - off;
      float rightX = sandCurX + off;
      if (canSandCurAt(leftX, y, current.rot)) { sandCurX = leftX; sandCurY = y; return true; }
      if (off != 0 && canSandCurAt(rightX, y, current.rot)) { sandCurX = rightX; sandCurY = y; return true; }
    }
  }
  return false;
}
