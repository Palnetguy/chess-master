/*

Chess legal moves magic numbers generator
for rooks and bishops
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

// can set more loops to get shorter >> bits count
// 0 is much faster performance for tests
// set 6 to get better results
int usr_searchtime = 5;

// can set 0 to calc.rooks only, or 1 to calc.bishops only
int usr_b_r = -1;

// can set [0 to 63] square, -1 means all squares
int usr_square = -1;

// can set >> shift bits to constant as 14,..16
bool usr_bits_const = false;
int usr_bits = 15; // to limit user bits

// ignore cases outside B2-G7 rectangle squares
bool usr_B2G7 = true;

// global variables needed for calculation
bool legalck = false;

int Board = 0; // Board occupancy
int Bo2 = 0; // to move squares
int square = 0;
int LEN = 0;

int T = 0;
int T_max = 0; // to calculate max. needed memory buffer

int b_r = 0; // 1-bishops, 0-rooks

/*
 U64 masks [64][2][16384][2];

 U64 numbers as masks:
 [] for 64 squares...
 [] rook or bishop...
 [] on e4 can move 14 squares (1<<14=16384)...
 [] for each occupancy mask[0] -> move to mask[1]

*/
var Mask = [];

// buffer needed for each square
var TbLen = [];

var file, fh; // file to write, handler

// results of magics for rooks and bishops to write to file
var res_R_shifts = "";
var res_R_magics = "";
var res_B_shifts = "";
var res_B_magics = "";

void main2() {
  prepare_tables();

  file = File('magicsRB.txt');
  fh = file.openWrite();

  find_Magics();

  fh.write('//Magics found for 64 squares\n');
  fh.write('//Rooks\n');
  fh.write('Shift_rooks = [$res_R_shifts];\n');
  fh.write('Magic_rooks = [$res_R_magics];\n');
  fh.write('//Bishops\n');
  fh.write('Shift_bishops = [$res_B_shifts];\n');
  fh.write('Magic_bishops = [$res_B_magics];\n');

  fh.close();

  print("T_max buffer needed=$T_max");
  print("Ok");
}

int p_Masks(int square, int bR, int n, int m) {
  int p = 0;
  p += (bR << 21);
  p += (square << 15);
  p += (n << 1);
  p += m;
  return p;
}

void dir(int dv, int dh) {
  int V = (square >> 3), H = (square & 7);
  V += dv;
  H += dh;
  while ((V >= 0 && V < 8) && (H >= 0 && H < 8)) {
    int sq = (V << 3) | H;
    if (legalck) {
      Bo2 |= (1 << sq);
      if ((Board & (1 << sq)) != 0) return;
    } else {
      Board |= (1 << sq);
    }
    V += dv;
    H += dh;
  }
}

void gen2dir() {
  if (legalck) {
    Bo2 = 0;
  } else {
    Board = 0;
  }

  if (b_r != 0) {
    //bishops
    dir(-1, -1);
    dir(1, -1);
    dir(-1, 1);
    dir(1, 1);
  } else {
    // rooks
    dir(-1, 0);
    dir(1, 0);
    dir(0, 1);
    dir(0, -1);
  }
}

// Does all the permutations for the current square and Board
void Permutate() {
  int inner = ((1 << square) & 0x007E7E7E7E7E7E00);

  var bits = []; // This will contain square numbers
  int n = 0, sq = 0;
  for (; sq < 64; sq++) {
    bits.add(0);
    if ((Board & (1 << sq)) != 0) bits[n++] = sq;
  }

  LEN = (1 << n); // length of permutations table

  T = 0;
  int p = p_Masks(square, b_r, T, 0);

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

    gen2dir(); // find legal moves for square, put in Bo2

    // if to ignore occupancies on A1-H1,A8-H1,A1-A8,H1-H8
    if (usr_B2G7 && (inner != 0)) Board &= 0x007E7E7E7E7E7E00;

    Mask[p++] = Board;
    Mask[p++] = Bo2; // legalmoves
    T++;
  }

  TbLen[(64 * b_r) + square] = T;

  if (T_max < T) T_max = T;
}

void prepare_tables() {
  int i = 0;
  for (i = 0; i < 4194304; i++) {
    Mask.add(0); // prepare array
  }
  for (i = 0; i < 128; i++) {
    TbLen.add(0); // prepare array
  }

  for (square = 0; square < 64; square++) {
    for (b_r = 0; b_r < 2; b_r++) {
      legalck = false;
      gen2dir();
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
int RANDOMIZER = 10;
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

// find magic number for square, bishop or rook
void find_SqBR() {
  String bufSq = square2at(square);

  int tableP = p_Masks(square, b_r, 0, 0);

  int LEN = TbLen[(64 * b_r) + square];

  int t = 0;

  bool found = false;
  int bitCnt = (usr_bits_const ? usr_bits : 3); // will increase

  print("sq# $square");

  var TB2 = [];
  for (t = 0; t < (1 << 16); t++) {
    TB2.add(0);
  }

  for (; !found;) {
    if (bitCnt < 16) bitCnt++; // do again, but limit below (1<<16)

    if (usr_bits_const || (usr_bits >= 0 && bitCnt > usr_bits)) {
      bitCnt = usr_bits;
    }

    print("searching: square $bufSq ${b_r == 1 ? "bishops" : "rooks"}bits=$bitCnt");

    int toN = (1 << (14 + usr_searchtime));
    for (int N = 0; N != toN; N++) {
      int k = (1 << bitCnt); // clear previous search
      for (int z = 0; z < k;) {
        TB2[z++] = 0;
      }

      // find the magic number!

      int Magic = 0;
      while (true) {
        Magic = rand32();
        if (Magic <= MAX_SAFE_INTEGER_52bit) break;
      }
      int p = tableP;

      bool good = true;
      for (int w = 0; w < LEN; w++) {
        Board = Mask[p++];
        Bo2 = Mask[p++];

        // Magic for chess calculation in action

        int mult = (Board * Magic);

        int shft = mult >>> (64 - bitCnt);
        int index = shft;

        if (index < 0 || index >= t) {
          print("index error");
          break;
        }

        if (TB2[index] == 0) {
          TB2[index] = Bo2;
        } else if (TB2[index] != Bo2) {
          good = false;
          break;
        }
      }

      if (good) {
        found = true;
        print("found magic");
        print("$bitCnt, $Magic");
        if (b_r == 1) {
          res_B_shifts += '$bitCnt,';
          res_B_magics += '$Magic,';
        } else {
          res_R_shifts += '$bitCnt,';
          res_R_magics += '$Magic,';
        }

        break;
      }
    }
  }

  if (!found) print("Error!");
}

void find_Magics() {
  for (b_r = 1; b_r >= 0; b_r--) {
    if (usr_b_r < 0 || usr_b_r == b_r) {
      print("Magics");
      if (b_r != 0) {
        print("bishops");
      } else {
        print("rooks");
      }

      for (square = 0; square < 64; square++) {
        if (usr_square < 0 || usr_square == square) {
          find_SqBR();
        }
      }
    }
  }
}
