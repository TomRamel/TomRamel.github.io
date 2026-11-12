# Checkmate Mate — public files

Checkmate Mate is an Android app for analysing chess games.
This repository holds its privacy policy and the information required by the licence of the chess engine it ships.
The source code of the app itself is not published here.

## Privacy policy

- English: [privacy-en.html](privacy-en.html)
- Français : [privacy-fr.html](privacy-fr.html)

## Stockfish (GNU GPL version 3)

The app ships **Stockfish 18** as a separate executable (`libstockfish.so`, arm64-v8a), driven through the UCI
protocol. Stockfish is free software, distributed under the GNU General Public License version 3.

- **Source code**: the official repository at tag `sf_18`, compiled **without any modification** —
  https://github.com/official-stockfish/Stockfish/tree/sf_18
- **NNUE networks** embedded in the binary: `nn-c288c895ea92.nnue` and `nn-37f18f62d772.nnue`, downloaded by the
  official Makefile (https://tests.stockfishchess.org/nns).
- **Build script**: [build-stockfish-android.sh](build-stockfish-android.sh) (Android NDK r29, Ubuntu).
- **Licence text**: [COPYING](COPYING).

To rebuild the exact binary: install the Android NDK r29, set `ANDROID_NDK_HOME`, then run the build script.

---

## En français

Checkmate Mate est une application Android d'analyse de parties d'échecs. Ce dépôt contient sa politique de
confidentialité et les informations demandées par la licence du moteur d'échecs qu'elle embarque. Le code de
l'application elle-même n'est pas publié ici.

L'application embarque **Stockfish 18** sous la forme d'un programme séparé, piloté par le protocole UCI. Stockfish
est un logiciel libre distribué sous licence GNU GPL version 3. Son code source est celui du dépôt officiel au tag
`sf_18`, compilé sans aucune modification avec le script [build-stockfish-android.sh](build-stockfish-android.sh).
Le texte de la licence est dans [COPYING](COPYING).
