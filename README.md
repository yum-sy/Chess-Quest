# Chess Quest: The Lost Crown

Godot 4 Compatibility + GDScript로 만든 터치 중심 체스·영어 모험 게임입니다. 기존 SDGO-like와 Mew's Escape 프로젝트와 독립적으로 실행됩니다.

## 실행

- Godot 4.7.2에서 `project.godot`를 열어 실행합니다.
- 웹 빌드: `npm ci` 후 `python3 tools/build_web.py`.
- 로컬 웹 실행: `python3 -m http.server 8765 --directory dist`, 브라우저에서 `http://localhost:8765` 접속.
- `file://`로 열면 WebAssembly와 저장 기능이 동작하지 않습니다.

빌드 스크립트는 상위 폴더의 `.tools/Godot.app/Contents/MacOS/Godot`를 사용합니다. 다른 환경에서는 스크립트의 Godot 경로를 변경하세요. Godot 웹 내보내기 템플릿도 필요합니다.

## 구성

- 7개 챕터, 챕터별 일반 미션 5개와 보스 미션 3개, 총 56개 슬롯.
- 4×4 / 6×6 훈련, 8×8 정식 체스. 9가지 퍼즐 목표, 복수 해답 판정.
- Chapter 6의 마지막 3개는 진행된 배치에서 시작하는 자유로운 AI 대국. Chapter 7의 8개는 기본 배치에서 시작하는 매우 쉬운 AI 정식 대국.
- 폰·나이트·룩·비숍·퀸·킹 캐릭터와 마법책은 프로젝트 전용 벡터 그림으로 실시간 렌더링됩니다. 외부 캐릭터 이미지를 사용하지 않습니다.
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

- `scripts/game.gd`: 장면, 입력, 원본 벡터 아트, 스토리, 음성, 대국 흐름
- `scripts/rules.gd`: 훈련/네이티브 규칙, 체크와 무승부, 쉬운 AI
- `scripts/objectives.gd`: 퍼즐 목표와 복수 해답 판정
- `scripts/learning.gd`: 별도 학습 기록, 복습 우선순위, 버전 저장
- `data/`: 콘텐츠와 영어 표현 JSON
- `assets/audio/`: 포함된 WAV 음성
- `web/bridge.js`: chess.js 연결
- `tools/build_web.py`: 웹 내보내기, PWA, 오프라인 캐시, 소스 ZIP
- `tests/`, `evidence/`: 자동 검사와 확인 화면

콘텐츠 재생성: `python3 tools/content.py`. 이후 headless 검사를 실행하면 각 퍼즐의 `acceptedSolutions`를 현재 규칙으로 다시 계산합니다. 음성은 이미 포함되어 있습니다. macOS에서만 `python3 tools/audio.py`로 재생성할 수 있습니다.

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

실제 iPad·Galaxy Z Fold 하드웨어에서 터치, 홈 화면 설치, 음성 출력, 30/60FPS 성능은 별도 실기기 검증이 필요합니다. 데스크톱 Chrome의 화면 크기 시뮬레이션은 실기기 검증을 대체하지 않습니다. 이전에 확정했다는 두 번째 콘셉트 이미지는 이번 첨부에 없었으므로 그 이미지와의 시각적 일치 여부는 확인할 수 없습니다. 그래픽은 실시간 3D 모델이 아닌 원본 2.5D 벡터 캐릭터입니다.

라이선스와 출처는 `CREDITS.txt`, `LICENSE`, `assets/OFL.txt`, `vendor/chess.js.LICENSE`를 참고하세요.
