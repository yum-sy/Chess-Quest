# Chess Quest: The Lost Crown

[바로 플레이](https://yum-sy.github.io/Chess-Quest/) · [소스 저장소](https://github.com/yum-sy/Chess-Quest) · [소스 ZIP](https://yum-sy.github.io/Chess-Quest/source.zip)

Godot 4 Compatibility + GDScript로 만든 터치 중심 체스·영어 모험 게임입니다. 기존 SDGO-like와 Mew's Escape 프로젝트와 독립적으로 실행됩니다.

## 실행

- Godot 4.7.2에서 `project.godot`를 열어 실행합니다.
- 웹 빌드: `npm ci --omit=dev` 후 `python3 tools/build_web.py`.
- 로컬 웹 실행: `python3 -m http.server 8765 --directory dist`, 브라우저에서 `http://localhost:8765` 접속.
- `file://`로 열면 WebAssembly와 저장 기능이 동작하지 않습니다.

빌드 스크립트는 상위 폴더의 `.tools/Godot.app/Contents/MacOS/Godot`를 사용합니다. 다른 환경에서는 `GODOT_BIN` 환경변수로 Godot 실행 파일을 지정하세요. 자동 검사 도구까지 설치하려면 `npm ci`를 사용하세요. Godot 웹 내보내기 템플릿도 필요합니다.

## 구성

- 7개 챕터, 챕터별 일반 미션 5개와 보스 미션 3개, 총 56개 슬롯.
- 4×4 / 6×6 훈련, 8×8 정식 체스. 9가지 퍼즐 목표, 복수 해답 판정.
- Chapter 6의 마지막 3개는 진행된 배치에서 시작하는 자유로운 AI 대국. Chapter 7의 8개는 기본 배치에서 시작하는 매우 쉬운 AI 정식 대국.
- 폰·나이트·룩·비숍·퀸·킹 캐릭터는 승인된 디자인으로 생성한 렌더링 스프라이트이며, 실제 3D 보드 위에 배치됩니다. 아군·적군 6종과 웃음·놀람 표정을 포함합니다. 마법책은 벡터 그림입니다.
- 영어 미션 음성, 단어 소개, 다시 듣기, 느리게 듣기, 도감 및 행동 복습.
- 영어 노출/재생/목표 식별/보조 여부/독립 수행/다른 배치 경험/복습 시점과 체스 기록을 분리합니다. 한 번의 정답으로 영어 숙달을 확정하지 않습니다.
- 단계별 힌트, 합법적인 오답 응수와 원위치 복귀, 대국 무르기, 4종 승격 선택.
- 자동 저장, 현재 대국 복원, 테마·장식·이동 효과, 스토리와 엔딩, 최종 완료 후 자유 대전.

## 규칙과 학습 설계

웹의 정식 체스 합법 수와 기보는 **chess.js 1.4.0**을 사용합니다. 네이티브에서는 GDScript 규칙 미러를 사용하며 독립 chess.js 포지션과 perft로 검사합니다. 작은 보드는 훈련 모드로 분리되어 있으며 킹이 없는 훈련은 정식 대국이 아닙니다. 작은 보드에서는 폰의 첫 두 칸 전진을 허용하지만 승격·캐슬링·앙파상은 사용하지 않습니다. 끝줄에 도착한 폰은 더 전진하지 않습니다.

대국 AI는 합법 수 중 무작위로 선택하는 매우 쉬운 상대입니다. 힌트는 즉시 체크메이트와 포획/위험을 살피는 가벼운 탐색입니다. Stockfish는 포함하지 않습니다. 3회 반복과 50수는 어린이용 UI에서 별도 청구 없이 무승부 처리합니다. 체크메이트가 우선합니다. PROTECT 퍼즐은 명시된 기물에 대한 실제 합법 포획 위협과 합법 되잡기가 있어야 성공합니다.

힌트를 사용해도 보상은 동일합니다. 영어 FAMILIAR는 음성을 듣고 한국어·시각 보조 없이 서로 다른 배치에서 반복적으로 행동한 증거가 있어야 합니다. 영어 능력의 확정 진단이 아닙니다. 도감의 단어 복습 버튼은 해당 기물/행동을 배우는 보드로 연결됩니다.

## PWA 설치와 저장

- iPad: Safari에서 배포 주소를 열고 공유 → 홈 화면에 추가. Chrome 브라우저 플레이도 지원 대상으로 구성했습니다.
- Galaxy Z Fold: Chrome 메뉴 → 앱 설치 또는 홈 화면에 추가.
- 첫 실행 시 네트워크가 필요합니다. 약 50MB의 게임 파일 캐시가 완료된 뒤 오프라인 실행할 수 있습니다.
- 브라우저와 설치 앱은 저장 공간을 공유하지 않을 수 있습니다. 기기 간 동기화는 없습니다.
- 진행은 `user://quest-v3.json`에 버전 3으로 저장됩니다. 임시 파일과 백업을 사용하며 구버전의 알려진 필드는 유지합니다. 웹에서는 Godot의 IndexedDB 저장소를 사용합니다.
- 브라우저 데이터 삭제·저장소 축출 시 진행이 사라질 수 있습니다.

## 소스 구조

- `scripts/game.gd`: 장면, 입력, 마법책, 스토리, 음성, 대국 흐름
- `scripts/board_3d.gd`: 3D 보드, 카메라 투영, 승인된 캐릭터 스프라이트, 이동·표정, 알파 기반 선택
- `assets/characters/approved-atlas-v1.png`: 12종 캐릭터 × 2종 표정 아틀라스
- `art-source/README.md`: 생성 도구·출처·프롬프트와 아틀라스 구조
- `scripts/rules.gd`: 훈련/네이티브 규칙, 체크와 무승부, 쉬운 AI
- `scripts/objectives.gd`: 퍼즐 목표와 복수 해답 판정
- `scripts/learning.gd`: 별도 학습 기록, 복습 우선순위, 버전 저장
- `data/`: 콘텐츠와 영어 표현 JSON
- `assets/audio/`: 포함된 WAV 음성
- `web/bridge.js`: chess.js 연결
- `tools/build_web.py`: 웹 내보내기, PWA, 오프라인 캐시, 소스 ZIP
- `tests/`, `evidence/`: 자동 검사와 확인 화면

콘텐츠 재생성: `python3 tools/content.py`. 이후 headless 검사를 실행하면 각 퍼즐의 `acceptedSolutions`를 현재 규칙으로 다시 계산합니다. 승인된 GPT 음성(v11.17.3)은 그대로 유지하며 콘텐츠 재생성으로 변경되지 않습니다.

## 학습 흐름 개편

- 7-1~7-5는 26~27개 기물이 남은 중반에서 1·1·2·2·3수 안에 체크메이트하는 문제입니다. 수 제한은 백의 이동 횟수입니다. 7-6~7-8만 표준 시작 배치에서 정식 대국을 진행합니다.
- `tools/puzzle_book.mjs`가 chess.js로 모든 합법적 방어를 검증합니다. 힌트와 상대 응수는 이 정답 트리를 사용하며, 수 제한 안에 이기는 모든 검증된 수를 허용합니다.
- 1-4, 2-4, 2-8은 두 번의 올바른 이동을 이어서 해결하는 경로 연습입니다. 상대는 움직이지 않으며 두 단계를 모두 마쳐야 보상을 받습니다. 중간 단계도 저장됩니다.
- 각 장의 1·4·8번과 최종 첫 정식 대국에는 짧은 이야기 장면이 있습니다. 편지 배달, 다리 복구, 탑의 등불, 사원 문양, 여왕의 귀환, 왕의 구출, 왕관 회복으로 연결합니다.
- 변경된 문제의 이전 중간 배치만 revision 검사로 초기화하며 완료 기록과 보상은 유지합니다.
- `tests/puzzles.gd`는 13개 정답 트리 노드, 모든 방어, 수 제한, 단계별 완료, 힌트, 오답, 저장·복원, 무르기를 검증합니다.

## 검증 명령

```sh
GODOT=../.tools/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path . --script tests/headless.gd
node tests/oracle.mjs
"$GODOT" --headless --path . --script tests/oracle.gd
"$GODOT" --headless --path . --script tests/ui.gd
python3 tools/build_web.py
# localhost:8765 서버를 별도 실행한 뒤
node tests/browser.mjs
```

## 미검증 및 제약

실제 iPad·Galaxy Z Fold 하드웨어에서 터치, 홈 화면 설치, 음성 출력, 30/60FPS 성능은 별도 실기기 검증이 필요합니다. 데스크톱 Chrome의 화면 크기 시뮬레이션은 실기기 검증을 대체하지 않습니다. 그래픽은 실제 3D 보드와 렌더링된 캐릭터 스프라이트를 조합한 2.5D입니다. 스켈레톤으로 변형하는 3D 캐릭터 모델은 아닙니다. 승인된 시안에 맞춘 24프레임 아틀라스를 사용합니다.

라이선스와 출처는 `CREDITS.txt`, `LICENSE`, `assets/OFL.txt`, `vendor/chess.js.LICENSE`를 참고하세요.

## 확인된 검사 결과

- 규칙·콘텐츠·저장: 192개 검사 통과
- 독립 chess.js 대조: 294개 포지션의 합법 수 일치
- 전체 캠페인: 56/56 완료, 154개의 합법 수 검증
- 학습 기록 분리·복습·백업 복원·마이그레이션 통과
- 터치 미션 완료·오답 복귀·AI 응수·무르기·엔딩·자유 대전 통과
- Chrome 웹: 규칙 엔진 실행, 첫 미션 완료, 오프라인 재실행 후 저장 복원, 콘솔 오류 없음
- 360×780 / 1024×768 / 1280×800 화면 확인. 실제 하드웨어 검증은 위 미검증 항목 참고.

테스트용 Stockfish는 승리 수순을 생성하는 독립 검사 도구로만 사용합니다. 게임에 포함된 상대 AI는 무작위 합법 수를 두는 초급 AI입니다. 이 검사는 어린이에게 적절한 체감 난이도나 실제 학습 효과를 입증하는 사용자 테스트가 아닙니다.

## 승인된 디자인 적용 및 사원 수정

- 팔·손 없는 아군/적군 6종. 기본 웃음과 이동·체크 시 놀람 표정, 선택 반응, 폰 점프, 나이트의 L 경로 점프, 다른 기물의 이동과 승리 반응.
- 플레이어 진영은 아래 파란 테두리, 상대 진영은 위 보라 테두리. 약 17도 측면 회전·52도 내려다보는 카메라와 작은 기물 크기로 앞뒤 겹침을 줄였습니다.
- 보이는 기물 픽셀을 우선 선택합니다. 투명한 이미지 여백은 터치를 가로채지 않습니다. 기물 밖의 칸도 선택할 수 있으며 선택 링과 좌표·기물 이름이 표시됩니다.
- 사원 3~8: 긴 대각선 구조 / 공격선 열기 / 핀 / 대각선 수비 / 먼 거리 체크 / 안전한 룩 공격.
- 방어는 상대 포획을 금지하는 것이 아니라 합법적으로 되잡을 수 있는 상태입니다. 설명과 판정 모두 이를 따릅니다. 이미 안전하거나 이미 방어 중인 상태를 정답 목표로 삼지 않습니다.
- 수정된 사원 문제에 저장되어 있던 진행 중 배치는 새 버전으로 시작하며 완료 기록과 보상은 유지합니다.

7장 전술 주제: 열린 파일의 뒷줄 메이트 → 비숍·나이트의 지원 공격 → 퀸 희생으로 수비 룩 유인 → 퀸 희생과 나이트의 질식 메이트 → 더블 체크에서 시작하는 3수 조합. 마지막 두 문제는 같은 전술을 한 수 더 멀리 내다보는 연결 학습입니다. 단순히 장식용 기물을 더한 종반이 아니라 양쪽 왕이 후방에 있고, 기물이 전개되어 서로의 공격과 방어에 관여하는 배치입니다.

## Piece-specific curriculum (v11.17.7)

The 48 lessons in chapters 1–6 are authored in `tools/piece_curriculum.py`.

| Piece | Distinctive lessons |
|---|---|
| Pawn | Forward versus capture, first double step, blocked file, promotion, en passant and expiry |
| Knight | Jump over either side, landing capture, route, fork, queen attack, edge trap, underpromotion |
| Rook | Straight lines, detour, safe attack, recapture defense, battery, seventh rank, skewer, fork |
| Bishop | Square colors, long diagonal, discovered attack, pin, diagonal defense and check |
| Queen | Straight/diagonal routes, safe attack, fork, defense, skewer, mate versus stalemate, retreat/counterattack |
| King | Separation, escape/capture/block check, both castles, forbidden castle in check, cooperative mate |

Special rules use full 8×8 boards, following [FIDE articles 3.7 and 3.8](https://handbook.fide.com/chapter/E012023). En passant displays the actual previous double step. Castling rights do not return after the king or rook returns to its original square.

Attack, fork, pin, skewer and discovered-attack solutions reject any move allowing an immediate legal capture of the moved piece, including en passant. Pinned opponents' illegal captures are excluded without changing king-square control rules. Defense separately requires a legal recapture. Route exercises explicitly keep opponents stationary.

The dedicated curriculum suite passes 118 checks, including 20 safe tactical solutions, special-move UI completion, and an unsafe queen attack being captured and restored for retry. Chapter 7 and every voice WAV remain unchanged. Completed missions and rewards persist; obsolete intermediate positions restart the revised lesson.

## Watch before playing (v11.17.8)

The first unfinished en-passant lesson (1-7) and both castling lessons (6-5, 6-6) automatically show a short, three-step board demonstration. En passant shows the opponent's double step, the diagonal landing, then removal of the passed pawn. Castling shows the king and rook sequentially, explicitly explaining that they form one move. Replay repeats the preview; Try now restores the original exercise. Watch remains available on completed lessons.

Preview positions never enter saves or award completion. Replay, leaving the screen and changing missions cancel pending animation steps. Reduced-motion mode retains timed instructional poses without movement. Existing voice files remain unchanged.

## Fantasy guide and tactical previews (v11.17.9)

Promotion, knight underpromotion, knight/rook/queen forks, bishop pin, and rook/queen skewers now use the same Watch → Replay / Try now flow. Forks show two attack arrows; pins connect the attacker, pinned piece and king; skewers animate a legal king escape followed by capture of the rear piece. Preview moves never count as player completion. Story introductions lead into the preview before practice.

The guide, kingdom map, vocabulary cards, settings and modal pages share raised parchment, brass corners, gold trim and teal buttons. The existing magic-book character accompanies the guide and settings. Settings adapt to wide and portrait screens and separate preferences, cosmetic rewards and progress reset.

Settings → progress reset requires explicit confirmation. It clears completion, learning records, rewards and the active position while retaining sound, Korean guidance and motion preferences. Locked cosmetics return to defaults. Both the active save and recovery copy are reset, preventing erased progress from reappearing after recovery. Tests use isolated save files/browser profiles and do not reset the player's existing data.
