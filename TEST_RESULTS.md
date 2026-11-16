# Approved art + temple update verification

- Rules/content/audio/save suite: 189 checks, no failures.
- Independent chess.js legal move comparison: 294 positions, no mismatches.
- Entire campaign: 56/56 missions completed over 292 legal plies.
- Learning: evidence separation, due review, backup restore and old-save migration passed.
- UI: first mission completion, wrong-move restoration, hints, AI response, undo, review save isolation and settings navigation passed.
- Ending and free-play transition passed.
- Revised temple 4-3 through 4-8: all six have an actual initial threat and at least one valid solution. Defense is absent initially; escape missions start with an attacked bishop. Only already-taught pawn/rook/bishop pieces are used.
- Character selection: 74 visible character centers across 4×4, 6×6 and dense 8×8 boards, at landscape and portrait viewport sizes; no incorrect selections. Transparent atlas margins do not count as character hits; ground-tile selection remains available.
- Old in-progress temple positions migrate to the new puzzle revision while retaining completed missions. A new temple capture was completed through the UI.
- Chrome: approved atlas rendered, character-body click selected the pawn, destination tap completed the mission, 19 game files cached, saved completion restored after offline reload, no console errors.
- Visual captures: full 8×8 board, portrait dense board, temple defense and post-success explanation in `evidence/`.

Rendering is a real Godot 3D board with original AI-rendered 2.5D character sprites, not rigged 3D character models. Two expression frames per character switch with movement/check state; idle, selection, movement and victory use transform animation. Pawn hops and knight L-path jumps are distinct. Motion can be reduced in settings.

Native captures and desktop Chrome viewport simulation do not establish real iPad/Z Fold frame rates, home-screen installation reliability, or educational effectiveness. Real-device testing remains outstanding. Asset provenance and complete generation prompts are in `art-source/README.md`.
