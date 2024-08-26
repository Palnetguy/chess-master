/*

Chess legal moves magic numbers generator
for pawns
in Dart
feb.2024

*/

import 'dart:io';

const int signbit = 1 << 63;
const int int_min = (signbit) >>> 0;
const int int_max = (signbit - 1) >>> 0;
const int int32mask = ((1 << 32) - 1);
const int MAX_SAFE_INTEGER_52bit = 9007199254740991; // for JS conversion

// user definitions

// constant shift bits
int bitCnt = 4; // fixed, or can be 8,...

// global variables needed for calculation
bool legalck = false;

int Board = 0; // Board occupancy
int Bo2 = 0; // to move squares
int square = 0;

int b_w = 0; // 0 white/ 1-black

int LEN = 0;

int T = 0;
int T_max = 0; // to calculate max. needed memory buffer

/*
 U64 masks [64][2][16][2];

 U64 numbers as masks:
 [] for 64 squares...
 [] color while or black...
 [] on e2 can move 4 squares, but buffer is for all squares...
 [] for each occupancy mask[0] -> move to mask[1]

*/
var Mask = [];

// buffer needed for each square
var TbLen = [];

var file, fh; // file to write, handler

// results of magics for while and black pawns to write to file
var res_wp_shifts = "";
var res_wp_magics = "";
var res_bp_shifts = "";
var res_bp_magics = "";

void main2() {
  prepare_tables();

  file = File('magicsP.txt');
  fh = file.openWrite();

  find_Magics();

  fh.write('//Magics found for 64 squares\n');
  fh.write('//Multiply by ((Magic << 32) | Magic)\n');

  fh.write('//White Pawns\n');
  fh.write('Shift_wp = [' + res_wp_shifts + '];\n');
  fh.write('Magic_wp = [' + res_wp_magics + '];\n');
  fh.write('//Black Pawns\n');
  fh.write('Shift_bp = [' + res_bp_shifts + '];\n');
  fh.write('Magic_bp = [' + res_bp_magics + '];\n');

  fh.close();

  print("T_max buffer needed=" + T_max.toString());
  print("Ok");
}

int p_Masks(int square, int b_w, int n, int m) {
  int p = 0;
  p += (b_w << 11);
  p += (square << 5);
  p += (n << 1);
  p += m;
  return p;
}

bool BoSet(int sq, bool capt) {
  bool b = false;
  int B = (1 << sq);
  if (legalck) {
    if ((Board & B) != 0) b = true;
    if (capt == b) Bo2 |= B;
  } else {
    Board |= B;
  }
  return b;
}

void gen_pawnmoves() {
  int V = (square >> 3), H = (square & 7);
  if (V > 0 && V < 7) {
    if (b_w != 0)
      V--;
    else
      V++;

    int sq = (V << 3) | H;
    bool f = BoSet(sq, false);
    if (H > 0) BoSet(sq - 1, true);
    if (H < 7) BoSet(sq + 1, true);
    if (!f) {
      if (b_w != 0) {
        if (V == 5) BoSet(sq - 8, false);
      } else {
        if (V == 2) BoSet(sq + 8, false);
      }
    }
  }
}

// to debug bitboards
logBitsOfInt(int N) {
  for (int v = 7; v >= 0; v--) {
    String s = "";
    for (int h = 0; h < 7; h++) {
      int sq = (v << 3) | h;
      int bit = 1 << sq;
      s += " " + ((N & bit) != 0 ? "1" : ".");
    }
    print(s);
  }
}

// Does all the permutations for the current square and Board
void Permutate() {
  var bits = []; // This will contain square numbers
  int n = 0, sq = 0;
  for (; sq < 64; sq++) {
    bits.add(0);
    if ((Board & (1 << sq)) != 0) bits[n++] = sq;
  }

  LEN = (1 << n); // length of permutations table

  T = 0;
  int p = p_Masks(square, b_w, T, 0);

  for (int i = 0; i < LEN; i++) {
    // go through all the cases

    Board = 0;

    for (int j = 0; j < n; j++) // scan as bits
    {
      sq = bits[j];
      // set bit on Board
      if ((i & (1 << j)) != 0) Board |= (1 << sq);
    }

    // now Board contains occupancy

    Bo2 = 0;

    gen_pawnmoves(); // find legal moves for square, put in Bo2

    Mask[p++] = Board;
    Mask[p++] = Bo2; // legalmoves
    T++;
  }

  TbLen[(64 * b_w) + square] = T;

  if (T_max < T) T_max = T;
}

void prepare_tables() {
  int i = 0;
  for (i = 0; i < (1 << 12); i++) Mask.add(0); // prepare array
  for (i = 0; i < 128; i++) TbLen.add(0); // prepare array

  for (square = 0; square < 64; square++) {
    for (b_w = 0; b_w < 2; b_w++) {
      legalck = false;
      Board = 0;
      gen_pawnmoves();
      legalck = true;
      Permutate();
    }
  }
}

String square2at(int sq) {
  int V = sq >> 3, H = sq & 7;
  return String.fromCharCode(H + 65) + String.fromCharCode(V + 49);
}

// a random number generator
int RANDOMIZER = 20;
int r_x = 30903, r_y = 30903, r_z = 30903, r_w = 30903, r_carry = 0;

int rand32() {
  int t;
  r_x = r_x * 69069 + RANDOMIZER;
  r_y ^= r_y << 13;
  r_y ^= r_y >> 17;
  r_y ^= r_y << 5;
  t = (r_w << 1) + r_z + r_carry;
  r_carry = ((r_z >> 2) + (r_w >> 3) + (r_carry >> 2)) >> 30;
  r_z = r_w;
  r_w = t;
  return (r_x + r_y + r_w).abs();
}

// find magic number
void find_Magics_pawns() {
  String bufSq = square2at(square);

  int table_p = p_Masks(square, b_w, 0, 0);

  int LEN = TbLen[(64 * b_w) + square];

  int t = 0;

  bool found = false;

  print("sq# " + square.toString());

  var TB2 = [];
  for (t = 0; t < (1 << bitCnt); t++) TB2.add(0);

  for (; !found;) {
    print("searching: square " +
        bufSq +
        " " +
        (b_w == 1 ? "white" : "black") +
        " pawn bits=" +
        bitCnt.toString());

    int toN = (1 << 23);
    for (int N = 0; N != toN; N++) {
      int k = (1 << bitCnt); // clear previous search
      for (int z = 0; z < k;) TB2[z++] = 0;

      // find the magic number!

      int Magic = 0;
      while (true) {
        Magic = rand32();
        if (Magic <= MAX_SAFE_INTEGER_52bit) break;
      }

      // This allows to remmain Magic under 52 bits
      // and includes all possible results for pawns only
      int Magic2 = (Magic << 32) | Magic;

      int p = table_p;

      bool good = true;
      for (int w = 0; w < LEN; w++) {
        Board = Mask[p++];
        Bo2 = Mask[p++];

        // Magic for chess calculation in action

        int mult = (Board * Magic2);

        int shft = mult >>> (64 - bitCnt);
        int index = shft;

        if (index < 0 || index >= t) {
          print("index error");
          break;
        }

        if (TB2[index] == 0) {
          // put value or mark that this is used for containing "0"
          TB2[index] = (Bo2 == 0 ? -1 : Bo2);
        } else if (TB2[index] == -1 && Bo2 == 0) {
          // good already
        } else if (TB2[index] != Bo2) {
          good = false;
          break;
        }
      }

      if (good) {
        found = true;
        print("found magic");
        print("Multiply by ((Magic << 32) | Magic) ");
        print(bitCnt.toString() + ", " + Magic.toString());
        if (b_w == 1) {
          res_bp_shifts += bitCnt.toString() + ',';
          res_bp_magics += Magic.toString() + ',';
        } else {
          res_wp_shifts += bitCnt.toString() + ',';
          res_wp_magics += Magic.toString() + ',';
        }

        break;
      }
    }
  }

  if (!found) print("Error!");
}

void find_Magics() {
  for (b_w = 0; b_w < 2; b_w++) {
    print("Magics for " + (b_w != 0 ? "white" : "black") + "pawns");

    for (square = 0; square < 64; square++) {
      find_Magics_pawns();
    }
  }
}
