class ActivePiece extends Tetromino {
  int col, row, rot;
  ActivePiece(int kind, int pieceColor) { super(kind, pieceColor); }
  Tetromino toTetromino() { return new Tetromino(kind, pieceColor); }
}
