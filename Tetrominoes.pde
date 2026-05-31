final int I = 0, J = 1, L = 2, O = 3, S = 4, T = 5, Z = 6;
final String[] kindNames = {"I", "J", "L", "O", "S", "T", "Z"};
class Tetromino {
  int kind, pieceColor;
  Tetromino(int kind, int pieceColor) {
    this.kind = kind;
    this.pieceColor = pieceColor;
  }
}
int[][] getCells(int kind, int rot) {
  rot = ((rot % 4) + 4) % 4;
  if (kind == I) {
    if (rot == 0) return new int[][] {{0, 1}, {1, 1}, {2, 1}, {3, 1}};
    if (rot == 1) return new int[][] {{2, 0}, {2, 1}, {2, 2}, {2, 3}};
    if (rot == 2) return new int[][] {{0, 2}, {1, 2}, {2, 2}, {3, 2}};
    return new int[][] {{1, 0}, {1, 1}, {1, 2}, {1, 3}};
  }
  if (kind == J) {
    if (rot == 0) return new int[][] {{0, 0}, {0, 1}, {1, 1}, {2, 1}};
    if (rot == 1) return new int[][] {{1, 0}, {2, 0}, {1, 1}, {1, 2}};
    if (rot == 2) return new int[][] {{0, 1}, {1, 1}, {2, 1}, {2, 2}};
    return new int[][] {{1, 0}, {1, 1}, {0, 2}, {1, 2}};
  }
  if (kind == L) {
    if (rot == 0) return new int[][] {{2, 0}, {0, 1}, {1, 1}, {2, 1}};
    if (rot == 1) return new int[][] {{1, 0}, {1, 1}, {1, 2}, {2, 2}};
    if (rot == 2) return new int[][] {{0, 1}, {1, 1}, {2, 1}, {0, 2}};
    return new int[][] {{0, 0}, {1, 0}, {1, 1}, {1, 2}};
  }
  if (kind == O) {
    return new int[][] {{1, 0}, {2, 0}, {1, 1}, {2, 1}};
  }
  if (kind == S) {
    if (rot == 0) return new int[][] {{1, 0}, {2, 0}, {0, 1}, {1, 1}};
    if (rot == 1) return new int[][] {{1, 0}, {1, 1}, {2, 1}, {2, 2}};
    if (rot == 2) return new int[][] {{1, 1}, {2, 1}, {0, 2}, {1, 2}};
    return new int[][] {{0, 0}, {0, 1}, {1, 1}, {1, 2}};
  }
  if (kind == T) {
    if (rot == 0) return new int[][] {{1, 0}, {0, 1}, {1, 1}, {2, 1}};
    if (rot == 1) return new int[][] {{1, 0}, {1, 1}, {2, 1}, {1, 2}};
    if (rot == 2) return new int[][] {{0, 1}, {1, 1}, {2, 1}, {1, 2}};
    return new int[][] {{1, 0}, {0, 1}, {1, 1}, {1, 2}};
  }
  if (rot == 0) return new int[][] {{0, 0}, {1, 0}, {1, 1}, {2, 1}};
  if (rot == 1) return new int[][] {{2, 0}, {1, 1}, {2, 1}, {1, 2}};
  if (rot == 2) return new int[][] {{0, 1}, {1, 1}, {1, 2}, {2, 2}};
  return new int[][] {{1, 0}, {0, 1}, {1, 1}, {0, 2}};
}
int[][] getKickTests(int kind, int oldRot, int newRot) {
  if (kind == O) { return new int[][] {{0, 0}}; }
  if (kind == I) { return getIKickTests(oldRot, newRot); }
  return getJLSTZKickTests(oldRot, newRot);
}
int[][] getJLSTZKickTests(int oldRot, int newRot) {
  if (oldRot == 0 && newRot == 1) return new int[][] {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}};
  if (oldRot == 1 && newRot == 0) return new int[][] {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}};
  if (oldRot == 1 && newRot == 2) return new int[][] {{0, 0}, {1, 0}, {1, 1}, {0, -2}, {1, -2}};
  if (oldRot == 2 && newRot == 1) return new int[][] {{0, 0}, {-1, 0}, {-1, -1}, {0, 2}, {-1, 2}};
  if (oldRot == 2 && newRot == 3) return new int[][] {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}};
  if (oldRot == 3 && newRot == 2) return new int[][] {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}};
  if (oldRot == 3 && newRot == 0) return new int[][] {{0, 0}, {-1, 0}, {-1, 1}, {0, -2}, {-1, -2}};
  if (oldRot == 0 && newRot == 3) return new int[][] {{0, 0}, {1, 0}, {1, -1}, {0, 2}, {1, 2}};
  return new int[][] {{0, 0}};
}
int[][] getIKickTests(int oldRot, int newRot) {
  if (oldRot == 0 && newRot == 1) return new int[][] {{0, 0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2}};
  if (oldRot == 1 && newRot == 0) return new int[][] {{0, 0}, {2, 0}, {-1, 0}, {2, -1}, {-1, 2}};
  if (oldRot == 1 && newRot == 2) return new int[][] {{0, 0}, {-1, 0}, {2, 0}, {-1, -2}, {2, 1}};
  if (oldRot == 2 && newRot == 1) return new int[][] {{0, 0}, {1, 0}, {-2, 0}, {1, 2}, {-2, -1}};
  if (oldRot == 2 && newRot == 3) return new int[][] {{0, 0}, {2, 0}, {-1, 0}, {2, -1}, {-1, 2}};
  if (oldRot == 3 && newRot == 2) return new int[][] {{0, 0}, {-2, 0}, {1, 0}, {-2, 1}, {1, -2}};
  if (oldRot == 3 && newRot == 0) return new int[][] {{0, 0}, {1, 0}, {-2, 0}, {1, -2}, {-2, 1}};
  if (oldRot == 0 && newRot == 3) return new int[][] {{0, 0}, {-1, 0}, {2, 0}, {-1, 2}, {2, -1}};
  return new int[][] {{0, 0}};
}
