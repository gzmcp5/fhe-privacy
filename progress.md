# 진행 상황

> 아래에는 삭제된 과거 구현과 당시 결정을 기록한 항목도 있다. 현재 설계는
> `session-handoff.md`와 `docs/1-0. security-architecture-index.md`가 우선한다. 특히 단일 Reveal
> Authority, 완성 secret key와 선택적 smartphone step-up 기록은 PC·스마트폰 2-of-2 설계로
> 대체되었다.

## 현재 상태

- **최종 업데이트:** 2026-07-15
- **OpenShell 로컬 바이너리:** 공식 `v0.0.80` Linux x86-64 musl artifact를 Linux와 Windows WSL 2
  경로의 `artifacts/openshell/0.0.80/bin/openshell`에 설치하고 `artifacts/bin/openshell`로 연결했다.
  공식 archive SHA-256과 실행 버전을 확인했으며 `versions.lock`에 release commit과 checksum을
  고정했다. Windows에서는 `tools/openshell/openshell.ps1`로 WSL 바이너리를 호출한다. WSL의 전체
  OpenShell 호환성, 다른 플랫폼, container, chart는 아직 검증하지 않았다.
- **OpenFHE wheel:** OpenFHE 1.5.1/OpenFHE-Python 1.5.1.0을 CPython 3.13용으로 source build한
  Ubuntu 24.04 x86-64 wheel을 `vendor/wheels/`에 설치하고 checksum을 `versions.lock`에 고정했다.
  Windows x86-64의 Ubuntu 26.04 WSL 2 wheel도 source build와 scheme smoke test를 통과해 checksum을
  고정했다. macOS 14 arm64는 별도 build workflow를 준비했지만 runner 검증 전이라 `UNVALIDATED`다.
- **새 clone runtime bootstrap:** `./tools/bootstrap-dev-runtime.sh`가 `versions.lock`의 플랫폼별
  OpenShell asset을 다운로드·checksum·버전 검증하고, 현재 플랫폼용 OpenFHE wheel이 없으면 고정
  commit에서 빌드한 뒤 scheme smoke test를 실행한다. Linux x86-64에서 전체 bootstrap을 확인했으며
  macOS arm64 호환성은 실제 Mac 검증 전까지 unvalidated다.
  Windows는 `tools/bootstrap-dev-runtime.ps1`가 Ubuntu 26.04 WSL 2에 같은 검증을 연결한다.
- **테스트:** 현재 제품 코드(`fhe/`), 테스트(`tests/`), 제품 스크립트(`scripts/`)를 제거한 상태라 `./init.sh` 검증 기준은 더 이상 통과하지 않는다.
- **상태:** 독립 FHE-Privacy 제품 저장소로 분리 완료. 제품 코드는 없고 루트 harness와 설계 문서,
  OpenShell/Hermes/deploy scaffolding만 있는 구현 전 상태.
- **명칭:** 시스템 대표 명칭 = **FHE-Privacy 프라이버시 게이트웨이** (Python 패키지로 배포).
- **범위:** 외부 에이전트용 로컬 프라이버시 게이트웨이(MCP/secure gateway) 시스템.
- **비범위:** 웹서버, 채팅 UI, 자체 LLM provider loop, DB viewer, web_search.
- **다음 시작점:** 확정 설계의 구현 가능성 spike와 P0 문서/검증 하네스 재구축.

## 2026-07-14 macOS arm64 native runtime 생성

- macOS arm64에서 `./tools/bootstrap-dev-runtime.sh`를 실행해 OpenShell v0.0.80 공식
  `openshell-aarch64-apple-darwin.tar.gz` artifact를 다운로드하고 archive checksum과
  `openshell --version`을 확인했다.
- gitignore된 `artifacts/openshell/0.0.80/bin/openshell`에 34MB 바이너리를 설치하고
  `artifacts/bin/openshell` symlink를 갱신했다. 설치된 바이너리 SHA-256은
  `3db26ebe766020133ad70f7a021bb0fea012bdf1141455a878ea97de2da3b103`이다.
- 같은 bootstrap에서 OpenFHE core `1306d14f8c26bb6150d3e6ad54f28dfe1007689e`,
  OpenFHE-Python `4f13e2c3a7e35f73f4816904dabd3a3db47b6e51`, packager
  `099b8bddd045e941fb8a91f48214da800d9bc27c` 기준으로 CPython 3.13 macOS 14 arm64 wheel을
  source build했다.
- 생성된 wheel은 gitignore된
  `vendor/wheels/openfhe-1.5.1.0.14.0-cp313-cp313-macosx_14_0_arm64.whl`이며 SHA-256은
  `1c99f50a6203cb71f9a2f083dde40c7375e9ebac58d36f85ddf46fcf16edfc2c`이다.
- 격리 venv 설치 후 `tools/openfhe/smoke.py`가 BFV, BGV, CKKS, Boolean FHE와 BGV 2-of-2 partial
  decrypt/fusion smoke test를 통과했다. 제품 구현과 E2E 보안 경로 검증은 아직 없으므로
  `feature_list.json` 상태는 변경하지 않았다.

## 2026-07-14 독립 제품 저장소 전환 및 세션 종료

- OpenShell fork 내부의 `fhe-privacy/` 설계 snapshot을 `git subtree split`로 독립 저장소에 분리해
  기존 설계 커밋 3개의 이력을 보존했다.
- 독립 저장소 위치를 `/home/gildellmint/Workspace/AGENTS/FHE-Privacy`로 정하고
  `https://github.com/gzmcp5/fhe-privacy.git`의 `main`을 새 이력으로 초기화했다.
- FHE-Privacy를 최상위 제품, OpenShell을 pinned sandbox runtime dependency, Hermes를 OpenShell이
  실행하는 workload image로 확정했다.
- `adapters/openshell/`, `images/hermes/`, `deploy/`, `versions.lock`를 추가해 source/build/deploy
  소유 경계를 표시했다. 현재는 문서 scaffolding이며 구현이나 검증 완료를 뜻하지 않는다.
- Agent harness 파일을 루트로 이동했다. 현재 시작 파일은 `AGENTS.md`, `CLAUDE.md`,
  `feature_list.json`, `progress.md`, `session-handoff.md`이며 `harness/` directory는 없다.
- OpenShell fork의 `main`은 FHE-Privacy snapshot 복사 전 `94cdd697`로 되돌려 원격에도
  force-with-lease로 반영했다. FHE-Privacy 전용 구현은 OpenShell 저장소에 남아 있지 않다.
- 확정된 배포 원칙:
  - 사용자는 FHE-Privacy만 설치하고 실행한다.
  - 로컬 설치는 검증된 OpenShell host binary/package를 내부 dependency로 설치한다.
  - Kubernetes는 OpenShell Gateway/Supervisor와 FHE-Privacy component를 별도 workload로 배포한다.
  - Secure Gateway와 OpenShell Gateway는 하나의 제품 경험을 제공하지만 별도 프로세스와 권한을 유지한다.
  - 필요한 OpenShell 변경은 범용 sealed sandbox capability로 제한하고, 미반영 기간에는 fork commit과
    release artifact checksum/digest를 FHE-Privacy가 고정한다.
- 이번 세션에서는 제품 코드를 구현하지 않았고 `feature_list.json`의 모든 기능은 `not_started`다.
- 검증 결과: `feature_list.json` JSON, `versions.lock` TOML, draw.io XML과 핵심 문서 링크가 유효하다.
  기존 RAG 문서의 누락 SVG 링크 두 개는 RAG 비범위의 선행 문제로 남아 있다.
- 다음 세션은 P0 package/test/CLI skeleton과 `init.sh` 복구에서 시작한다.

## 2026-07-14 Windows WSL 2 runtime 산출물

- OpenShell v0.0.80에는 native Windows release asset이 없고 공식 Windows host 경로가 WSL 2임을
  확인해 지원 경계를 Windows x86-64 + Ubuntu 26.04 WSL 2로 명시했다.
- `tools/bootstrap-dev-runtime.ps1`를 추가해 PowerShell에서 WSL 경로 매핑, 고정 target 선택,
  WSL filesystem의 OpenFHE build cache와 기존 checksum/smoke 검증을 한 번에 실행한다.
- 공식 `openshell-x86_64-unknown-linux-musl.tar.gz`를 checksum 검증 후 설치했다. 설치 binary는
  39,285,672 bytes, SHA-256 `0bbd03564f68bc04d9e74c0798c9b0c288eb0f7d817b7272e87c8e9c7ffc651c`이며
  `tools/openshell/openshell.ps1 --version`에서 `openshell 0.0.80`을 확인했다.
- OpenFHE 1.5.1/OpenFHE-Python 1.5.1.0을 Ubuntu 26.04 WSL 2의 CPython 3.13.3으로 source build해
  `vendor/wheels/openfhe-1.5.1.0.26.4-cp313-cp313-linux_x86_64.whl`을 생성했다. 크기는
  3,902,560 bytes, SHA-256은 `f979a017cdbe09a048e393a3611fedac0247788467ecb98d67de5b536d091ac3`이다.
- 격리 venv에서 BFV, BGV, CKKS, Boolean FHE와 BGV 2-party partial decrypt/fusion smoke test가
  모두 통과했다. 이는 WSL backend 호환성 근거이며 제품의 device-separated protocol 완료 근거는 아니다.
- Windows Git의 CRLF checkout으로 bash가 깨지는 문제를 막기 위해 `.gitattributes`에서 `*.sh`를
  LF로 고정했다. uv-managed Python symlink의 venv prefix 문제는 canonical interpreter로 packager
  venv를 먼저 생성하도록 build script를 보강했다.
- OpenShell은 다운로드/version 확인만 수행했으므로 filesystem/network/channel/sealed-management
  negative test 전까지 `compatibility = "unvalidated"`를 유지한다.
- 제품 `./init.sh`는 여전히 존재하지 않아 실행하지 못했고 기능 상태를 `passing`으로 바꾸지 않았다.

## 2026-07-15 Hermes · LLM tool loop 명시

- `docs/1. architecture-component-flow.drawio`를 trust boundary만 표시하던 구조에서 OS process 경계까지
  보이도록 세분화했다. Secure Gateway process 안에는 PII Engine과 Crypto Ingress module을 묶고,
  Hermes, MCP Bridge, Privacy Core, Vault Coordinator, Public FHE Worker, Reveal Coordinator,
  PC/Phone Partial Authority, Fusion Sink와 외부 LLM을 각각 별도 process/service로 표시했다.
- 사용자 재배치본을 기준으로 큰 process container는 제거하고 기존 좌표와 화살표를 유지했다.
  `PROCESS ·`, `MODULE ·`, `EXTERNAL SERVICE ·` 제목과 선 스타일로 같은 프로세스 정보를 다시 반영했다.
- `docs/architecture-flow.md`에 process별 내부 책임과 배치 표를 추가했다. Hermes와 Bridge는 별도
  process지만 동일한 비신뢰 principal이고, secret share authority는 각각 독립 process라는 구분을
  명시했다.
- `docs/0-1. product-command-comparison.md`를 추가해 Hermes 단독 실행, OpenShell sandbox 실행,
  FHE-Privacy secure gateway 실행의 사용자 커맨드를 초기화·실행·상태·로그·종료 작업별로 비교했다.
  FHE-Privacy 커맨드는 구현 전 목표 인터페이스임을 명시했다.
- `docs/0. product-runtime-relationship.md`의 정상 흐름에 Hermes와 LLM 사이의 provider 요청, tool call,
  result handle 반환과 최종 unresolved response 단계를 명시했다.
- Gateway가 Hermes에 보내는 masked envelope 전체가 LLM provider payload로 그대로 전달되는 것은 아니다.
  Hermes adapter가 `maskedText`, 허용된 tool 설명과 최소 공개 context만 골라 LLM 요청을 구성한다.
- LLM이 handle 기반 공개 연산을 요청하면 Hermes → MCP Bridge → Privacy Core → Public Compute Worker를
  거쳐 result handle이 발급되고, Hermes가 이를 LLM에 돌려주는 tool loop가 필요에 따라 반복된다.

## 2026-07-14 FHE-Privacy · OpenShell · Hermes 제품 관계 다이어그램

- `docs/0. product-runtime-relationship.drawio`를 추가해 세 제품의 소유·실행 관계를 상위 수준에서
  분리해 표현했다.
- FHE-Privacy는 최상위 제품, 설치/실행 진입점과 신뢰 프라이버시 경계로 표시했다. Secure Gateway,
  Privacy Core, Local Reveal 영역은 FHE-Privacy가 소유한다.
- OpenShell은 FHE-Privacy가 버전과 무결성을 고정하고 orchestration하는 별도 sandbox runtime
  dependency로 표시했으며, FHE-Privacy와 같은 프로세스나 권한 경계로 합치지 않았다.
- Hermes Agent와 stateless MCP Bridge는 sealed OpenShell sandbox 안의 동일한 비신뢰 principal로
  표시했다. 데이터 경로는 masked envelope, handle-only HTTPS/mTLS와 unresolved response만 허용한다.
- README와 `docs/distribution-guide.md`에서 새 draw.io 원본을 연결했다.
- draw.io XML 구조, cell ID uniqueness, edge source/target와 문서 링크를 확인했다. 제품 `./init.sh`는
  여전히 존재하지 않아 실행하지 않았고 기능 상태는 변경하지 않았다.
- 후속 시각 검토에서 중앙 통로의 화살표가 교차할 수 있어 Gateway/Hermes와 Core/Bridge를 같은 행에
  재배치했다. orchestration, masked input, unresolved response, handle-only MCP가 서로 다른 수평 lane을
  사용하고 Hermes→Bridge만 sandbox 내부 수직 lane을 사용하도록 모든 waypoint를 제거했다.
- `docs/0. product-runtime-relationship.md`를 개조식 핵심 문서로 추가해 제품 소유 관계, 구성요소,
  신뢰 경계, 데이터 경로, 정상 흐름, 금지 경로, 실패 처리와 현재 상태를 요약했다. README와 배포
  문서는 설명 문서를 우선 진입점으로, draw.io를 편집 원본으로 연결한다.
- 같은 문서에 MCP 통신 규격, 일반 MCP Server와 FHE-Privacy의 무상태 MCP Bridge 차이 및 실제
  권한 검증이 Privacy Core에 있다는 점을 비교표로 추가했다.

## 2026-07-14 제품 관계 검토 종료 지점

- Masked envelope는 `sessionId`, `messageId`, `maskedText`, `policyVersion` 등의 구조화된 데이터이며,
  `maskedText`가 Hermes를 거쳐 LLM에 전달되는 보호된 본문이다.
- `{{phone:h_81bc...}}` 전체는 marker, `phone`은 marker type, `h_81bc...`는 opaque handle이다.
  Handle 자체에서 plaintext, Vault 위치, key나 record metadata를 추론할 수 없어야 하며 실제 유효성은
  Privacy Core의 session/type/context/provenance/TTL/operation 검증으로 결정한다.
- MCP는 protocol이고 Stateless MCP Bridge는 그 protocol을 처리하는 비신뢰 stdio MCP Server다.
  기존 MCP Server에 함께 있을 수 있던 상태·정책·연산 기능은 Privacy Core와 별도 Worker로 분리한다.
- Privacy Core는 모든 암·복호 연산을 직접 수행하지 않는다. Crypto ingress가 입력 암호화,
  Public Compute Worker가 secret-free 동형연산, PC/Phone Partial Authority와 Fusion Sink가 partial
  decrypt와 최종 plaintext 생성을 담당한다. Core는 검증, 상태, dispatch와 결과 handle 발급을 담당한다.
- 다음 세션은 사용자 편집 상태로 남은 `docs/0. product-runtime-relationship.drawio`와
  `docs/1. architecture-component-flow.drawio`를 열어 위 책임 분리가 시각적으로 정확한지 확인하는
  것부터 시작한다.

## 2026-07-14 clone 후 native runtime 재현 경로

- `AGENTS.md`의 빠른 시작을 현재 존재하지 않는 과거 `./init.sh setup`에서
  `./tools/bootstrap-dev-runtime.sh`로 교체했다.
- `versions.lock`에 OpenShell v0.0.80 공식 release URL, checksum manifest와 Linux x86-64,
  Linux arm64, macOS arm64의 정확한 asset 이름 및 공식 SHA-256을 기록했다. 공식 checksum과 제품
  호환성 상태를 분리해 Linux x86-64만 validated로 유지했다.
- `tools/openshell/install.sh`는 OS/CPU에 맞는 고정 asset만 다운로드하고 SHA-256 및
  `openshell --version`을 검증한 뒤 gitignore된 `artifacts/`에 설치한다.
- `tools/openfhe/build-wheel.sh`의 고정 source build를 clone bootstrap에 연결하고, 만들어진 wheel을
  격리 환경에 설치해 BFV/BGV/CKKS/Boolean/2-party fusion smoke test를 실행하도록 했다.
- Linux x86-64에서 bootstrap 전체를 실행해 OpenShell 0.0.80과 기존 고정 OpenFHE wheel checksum,
  모든 smoke test 통과를 확인했다. `./init.sh`는 아직 복구 전이라 실행할 수 없다.

## 2026-07-14 OpenShell 0.0.80 로컬 바이너리 설치

- NVIDIA/OpenShell 공식 `v0.0.80` release의 `openshell-x86_64-unknown-linux-musl.tar.gz`를 사용했다.
- 공식 checksum 파일과 내려받은 archive의 SHA-256
  `e06ac01e7527b4aadeed549265850a197f3d7ed9347f8ba476a062f10d274611`이 일치함을 확인했다.
- gitignore된 `artifacts/openshell/0.0.80/bin/openshell`에 설치하고
  `artifacts/bin/openshell` symlink를 만들었다.
- `artifacts/bin/openshell --version` 결과는 `openshell 0.0.80`이다.
- `versions.lock`에 release version, tag commit과 Linux amd64 archive checksum을 기록했다.
- 제품 검증 entrypoint인 `./init.sh`는 현재 저장소에 없어 실행하지 못했으며 기능 상태를
  `passing`으로 변경하지 않았다.

## 2026-07-14 OpenFHE 1.5.1 플랫폼 wheel 준비

- 공식 Ubuntu 24.04 wheel이 `py3-none-any`로 표시되지만 내부에는 CPython 3.12 native module만
  포함해 Python 3.13 import가 실패함을 확인했다.
- OpenFHE core `v1.5.1`, OpenFHE-Python `v1.5.1.0`과 공식 packager commit을 고정하고
  `tools/openfhe/build-wheel.sh`로 CPython 3.13 native wheel을 source build했다.
- Linux wheel을 `vendor/wheels/openfhe-1.5.1.0.24.4-cp313-cp313-linux_x86_64.whl`에 두고
  ABI/platform tag와 `Root-Is-Purelib: false` metadata를 바로잡았다. wheel은 gitignore 대상이다.
- 격리된 `.venv`에 wheel을 설치해 BFV, BGV, CKKS, Boolean FHE와 BGV 2-party partial
  decrypt/fusion smoke test를 통과했다.
- `.github/workflows/openfhe-wheels.yml`에 Ubuntu 24.04 x86-64와 macOS 14 arm64 별도 wheel build,
  smoke test와 artifact upload를 구성했다. macOS job은 아직 실행하지 않아 checksum을 확정하지 않았다.
- 이 smoke test는 backend API 호환성 근거이며 장치 분리, missing-share 거부와 secret lifecycle까지
  구현·검증됐다는 근거가 아니므로 `feature_list.json` 상태는 변경하지 않았다.
- 제품 검증 entrypoint인 `./init.sh`는 현재 저장소에 없어 실행하지 못했다.

## 2026-07-13 보안 아키텍처 전체 기준 정리

- RAG를 제외한 아키텍처 문서를 새 설계 기준으로 정합화했다.
- 첫 외부 Agent 구현 대상을 Hermes로 확정했다. 지원 완료 표시는 adapter와 OpenShell E2E 검증 후로 유보한다.
- 채택한 핵심 경계:
  - Secure Gateway만 사용자 원문을 수신하고, 불확실하거나 실패하면 Agent 호출 전에 중단한다.
  - Hermes Agent 전체와 stateless Agent MCP Bridge를 OpenShell sandbox 안에 둔다.
  - Agent는 opaque, typed, session-bound handle과 허용된 공개 연산만 사용한다.
  - Privacy Core, Public Compute Worker, Reveal Coordinator, PC/phone partial authority와 Fusion Sink를
    서로 다른 권한 채널로 분리한다.
  - FHE secret은 PC와 스마트폰의 2-of-2 share로만 보관하고 완성된 secret key를 만들지 않는다.
  - plaintext는 두 장치가 참여한 뒤 승인된 PC terminal 또는 phone display Fusion Sink에서만 만든다.
  - reveal은 post-LLM terminal egress에서만 수행하며 Agent/history/tool로 되돌리지 않는다.
  - CKKS는 근사 수치, BFV/BGV는 exact integer, Boolean FHE는 exact predicate에 사용한다.
  - 주민등록번호 같은 exact identifier는 record별 AEAD와 2-of-2 threshold envelope로 보호한다.
  - 이름은 현재 제품의 PII 탐지·masking 대상에서 제외한다.
  - 초기 Vault는 메모리 기반이며 후속 영속화 기본안은 SQLite metadata + binary BLOB이다.
  - 초기 입력 범위는 text-only이며 attachment/OCR/audio/memory/tool plaintext는 차단한다.
- 기능 목록과 개발 계획은 전 항목 `not_started`인 재구축 기준으로 다시 작성했다.
- draw.io 원본을 2-of-2 구조에 맞췄고 내용이 오래된 SVG 산출물 3개는 삭제했다.
- 비개발자도 읽을 수 있도록 `docs/glossary.md`를 추가하고 주요 문서에 쉬운 설명을 넣었다.
- `docs/pii-detection-catalog.md`에 이름을 제외한 92개 탐지 후보를 정리했다.
- 문서 변경 30개를 `4da1145d` (`docs(fhe-privacy): revise privacy architecture`)로 커밋해
  `origin/main`에 푸시했다.
- 설계 상태이므로 구현 완료나 `./init.sh` 통과를 주장하지 않는다.

## 2026-07-13 개발 환경 상태

- `mise` 2026.7.5를 `~/.local/bin/mise`에 설치했다.
- `~/.zshrc`에 mise zsh activation을 추가하고 OpenShell `mise.toml`을 trust했다.
- 전체 15개 도구 설치를 시작했으나 사용자 요청으로 중단했다. 상태 기록 전 실행한
  `mise run pre-commit`이 누락 도구 설치를 자동으로 재개해 Rust와 Skaffold 설치까지 완료한 뒤
  다시 중단했다.
- 설치 완료: Python, Node, uv, kubectl, protoc, Helm, helm-docs, Syft, cargo-about,
  cargo-zigbuild, sccache, markdownlint-cli2.
- 추가 설치 완료: Rust 1.95.0, Skaffold 2.20.0.
- 미설치: Zig 0.14.1.
- 설치 프로세스가 종료됐음을 확인했다. `mise run pre-commit`의 실제 검사 단계는 완료되지 않았다.
  재개 시 Zig만 설치한 뒤 `mise doctor`와 pre-commit을 실행한다.

## 2026-07-13 Pre-LLM ingress 경계 확정

- 기존 기능 목록과 개발 계획을 구현 근거로 사용하지 않고 아키텍처를 문제별로 다시 검토하기 시작.
- 외부 Agent와 LLM을 비신뢰 영역으로 확정하고, 외부 Agent 전체를 OpenShell sandbox에서 실행하는
  방향을 채택.
- 첫 번째 문제인 pre-LLM Gateway 강제 경계를 확정:
  - Secure Gateway만 사용자 원문을 수신.
  - OpenShell Hermes Agent와 LLM에는 masked envelope만 전달.
  - PII 검출, 암호화, Vault 저장, masking 검증이 실패하거나 불확실하면 Agent를 호출하지 않음.
  - Gateway를 강제할 수 없는 Agent 연결은 secure-gateway 모드로 표시하지 않음.
- `docs/1-1. pre-llm-ingress.md`에 신뢰 경계, 정상 흐름, envelope 최소 계약, fail-closed 규칙,
  초기 지원 범위, OpenShell 조건, 완료 검증을 기록.
- `docs/1. architecture-component-flow.drawio`에 trusted host ingress와 OpenShell untrusted 영역,
  sole raw-input owner, masked-envelope-only 경로, fail-closed 중단 경로를 반영.
- `docs/1. architecture-component-flow.svg`를 최신 draw.io 원본에서 생성하고
  `docs/architecture-flow.md`의 깨진 링크를 새 파일명으로 수정.
- 다음 아키텍처 문제: stdio MCP bridge와 stateful Privacy Core의 프로세스/상태 배치.

## 2026-07-13 코드베이스 초기화

- 사용자 요청에 따라 제품 코드와 테스트를 제거.
- 유지:
  - `AGENTS.md`
  - `CLAUDE.md`
  - `README.md`
  - `docs/`
  - `feature_list.json`
  - `init.sh`
  - `progress.md`
  - `pyproject.toml`
  - `session-handoff.md`
  - `uv.lock`
  - `vendor/`
- 삭제:
  - `fhe/`
  - `tests/`
  - `scripts/`
- 결과:
  - 문서와 하네스는 남아 있음
  - 구현 코드 기준의 feature state는 초기화 필요
  - 다음 구현 전까지 검증 상태를 `passing`으로 주장할 수 없음

## 2026-07-03 프로젝트 재정의

- 새 프로젝트 위치: `/Users/giljong-in/Workspace/AGENTS/AgentOrigin/FHE-Privacy`
- 기존 FHE-Agent PoC에서 FHE/PII 핵심만 분리:
  - `fhe/client/`: FHEClient, profile store, bytes/base64 유틸
  - `fhe/engine/`: OpenFHE backend, subprocess backend, wire protocol
  - `fhe/server/fhe_ops.py`: 공개 컨텍스트 동형 연산 파사드
  - `fhe/server/masking.py`: 금액/수량/전화/이름 마스킹, SecretVault, RevealVault
  - FHE/PII 관련 테스트
- 제거/비포함:
  - FastAPI/uvicorn 서버
  - 자체 agent loop
  - Anthropic/OpenRouter provider 코드
  - WebSocket/프런트엔드
  - SQLite ledger/demo seed

## 2026-07-03 하네스/문서 갱신

- `AGENTS.md`, `CLAUDE.md`, `progress.md`, `session-handoff.md`, `init.sh`, `pyproject.toml`
  기준을 배포형 FHE-Privacy 런타임으로 갱신.
- 기존 docs 내용 제거.
- 새 문서 생성:
  - `docs/fhe-features.md`
  - `docs/fhe-development-plan.md`
  - `docs/architecture-flow.md`
  - `docs/distribution-guide.md`

## 2026-07-03 draw.io 다이어그램 전환

- `README.md` 목표 구조를 draw.io 원본 + SVG 표시로 전환.
- `docs/architecture-flow.md`의 전체 컴포넌트 흐름도와 정상 질의 sequence를 draw.io 원본 + SVG
  표시로 전환.
- `./init.sh` 통과로 문서 변경 후 baseline 유지 확인.

## 2026-07-03 README 목표 구조 화살표/라벨 정리

- `docs/readme-target-structure.drawio`의 반환 화살표 경로를 분리해 입력/마스킹 화살표와 겹치지 않도록 조정.
- draw.io edge label이 흰 배경으로 화살표를 가리지 않도록 라벨을 독립 텍스트 셀로 분리.
- `docs/readme-target-structure.svg`도 같은 경로와 라벨 배치로 갱신.
- `./init.sh` 통과로 문서 변경 후 baseline 유지 확인.

## 2026-07-03 정상 질의 sequence 화살표/라벨 정리

- `docs/architecture-normal-sequence.drawio`의 메시지 라벨을 화면 기준으로 모두 화살표 위쪽에 배치.
- 왼쪽/오른쪽 방향 화살표의 draw.io offset 차이를 보정해 텍스트가 화살표를 가리지 않도록 조정.
- `docs/architecture-normal-sequence.svg`를 갱신.
- `./init.sh` 통과로 문서 변경 후 baseline 유지 확인.

## 2026-07-03 MCP stdio 서버 최소 구현

- `docs/mcp-tool-contract.md`에 MCP tool 이름, 입출력, 권한 경계를 정리.
- `fhe-privacy mcp serve --role agent|gateway|local-egress` CLI와 `fhe.mcp.server` stdio
  JSON-RPC 서버를 추가.
- `agent-safe`, `gateway-internal`, `local-egress` role 기반 tool 권한 분리 구현.
- `tests/test_mcp_server.py`에 initialize/tools list round-trip, 권한 거부, PII mask, FHE op
  검증을 추가.
- `./init.sh` 통과로 ruff, format, mypy, pytest 107개 확인.

## 2026-07-03 Secure Gateway 최소 pipeline 구현

- `fhe/gateway/runtime.py`에 `SecureGateway`를 추가.
- ingress는 MCP `gateway` role의 `pii.mask_text` 경로로 사용자 입력을 Agent/LLM 전에 마스킹.
- egress는 MCP `local-egress` role의 `pii.resolve_markers` 경로로 최종 응답을 로컬에서 해결.
- `tests/test_gateway.py`에 LLM-facing payload 평문 누출 방지, reveal marker 로컬 해결,
  unknown marker fail-closed 회귀 테스트 추가.
- `./init.sh` 통과로 ruff, format, mypy, pytest 110개 확인.

## 2026-07-03 범용 Agent adapter 계약 정리

- `docs/agent-adapter-contract.md` 추가.
- OpenClaw/Hermes를 핵심 런타임에 하드코딩하지 않고 reference adapter로 다루는 방향으로 정리.
- Agent capability model, `tool-only`/`secure-gateway` 모드 조건, adapter doctor 출력 계약,
  adapter profile 기반 설치 흐름을 정의.

## 2026-07-03 범용 Agent adapter 코드화

- `fhe/adapter/profiles.py` 추가.
- adapter capability model, `tool-only`/`secure-gateway` mode 판정, doctor 결과, install plan 생성
  로직 구현.
- `fhe-privacy adapter list`, `adapter doctor`, `adapter install` plan CLI 추가.
- `tests/test_adapter_profiles.py`로 tool-only 경고와 secure-gateway fail-closed 동작 검증.

## 2026-07-03 Agent adapter safe config writer

- `fhe/adapter/installer.py` 추가.
- `adapter install`을 기본 dry-run으로 유지하고 `--apply`일 때만 JSON 설정 파일을 쓰도록 변경.
- 기존 Agent 설정 파일이 있으면 쓰기 전에 `.bak`, `.bak.1` 형태로 백업.
- MCP stdio 등록과 secure-gateway metadata를 기존 JSON 설정에 병합.

## 2026-07-03 OpenClaw/Hermes reference adapter profile

- `openclaw`, `hermes` builtin adapter profile 추가.
- 두 profile 모두 현재는 MCP server 등록만 검증된 `tool-only`로 둠.
- OpenClaw는 JSON `mcp.servers`, Hermes는 YAML `mcp_servers` 경로로 MCP server 설정을 렌더링.
- pre-LLM/post-LLM wrapper 지점이 확인되기 전까지 LLM 평문 0을 주장하지 않음.

## 2026-07-03 Reference adapter smoke test

- OpenClaw/Hermes `adapter doctor` CLI가 `tool-only`와 `llm_plaintext_zero_claim: no`를 출력하는지 검증.
- OpenClaw `adapter install --apply`가 JSON `mcp.servers.fhe-privacy`를 병합하고 `.bak` 백업을 생성하는지 검증.
- Hermes `adapter install --apply`가 빈 YAML target에 `mcp_servers.fhe-privacy`를 생성하는지 검증.

## 2026-07-03 Secure gateway wrapper 조사

- `docs/secure-gateway-wrapper-investigation.md`에 OpenClaw/Hermes의 MCP 연결점, plugin/hook 후보,
  secure-gateway 승격 조건을 정리.
- 두 reference profile은 MCP 등록만 검증된 `tool-only`로 유지.
- `adapter doctor --mode secure-gateway`가 wrapper, pre-LLM 입력 경계, post-LLM egress 경계
  미검증 blocker를 출력하도록 추가.

## 2026-07-06 아키텍처 다이어그램 정리 (프라이버시 게이트웨이)

- `docs/architecture-component-flow.drawio`를 개념 설명용으로 대폭 개선:
  - MCP Server를 허브로 두고 Gateway·Agent가 role 단위로 호출하는 구조를 명시(MCP 경유 명시).
  - 세 흐름을 색으로 분리: ① 프롬프트→LLM(마스킹, 파랑) ② Tool Calling·동형 연산(주황) ③ 결과 복호·출력(초록).
  - 런타임 구성요소(PII·FHE Client·FHE Ops·Local Vault)를 에메랄드로 통일하고 `MCP tool runtime` 영역으로 묶음. Secure Gateway·MCP Server는 런타임 밖(호출자 / access layer).
  - `Vault → FHE Ops (ciphertext inputs)`, `FHE Client → MCP (decrypt → plaintext)` 화살표 추가로 데이터 경로 완결.
  - 코드 식별자 라벨(`fhe.op_*` 등)을 개념어(encrypted computation 등)로 교체.
- `docs/rag-fhe-flow.drawio`(신규, 암호문 RAG 검색 파이프라인)와 `docs/architecture-rag-combined.drawio`(신규, 두 다이어그램 무손실 병합) 추가.
  - 병합 seam: `Selected Chunks → Prompt Builder → Secure Gateway(mask) → Agent → LLM`.
  - 정합성 수정: Decrypt+Rank를 로컬(sk) 영역으로, RAG 출력은 Gateway 마스킹 경유. 외부 LLM 1개로 통합.
- **주의:** `architecture-component-flow.svg`는 최신 drawio와 어긋남(구 레이아웃). diagrams.net에서 재export 필요.

## 2026-07-06 용어 정리

- 시스템 대표 명칭 = **프라이버시 게이트웨이**(별도 로컬 보안 서비스). 산출물 = **패키지/툴킷**. **런타임**은 내부 실행 객체 `MCPToolRuntime`에만 사용.
- `docs/fhe-features.md`에 용어(Terminology) 정의 블록 추가, RTE-01 `로컬 런타임 패키지`→`로컬 패키지`, 섹션 `런타임 코어`→`패키지 · 하네스`.
- `AGENTS.md`·`README.md`·`feature_list.json`의 제품 설명 `런타임`→`시스템(패키지로 배포)`.
- 설계 논의: 권장 타깃 = pre-LLM 강제 마스킹 어댑터(프록시) + 비밀키 단독 소유 로컬 런타임 데몬. tool-only는 '프라이버시 모드' 포장에서 격하 예정(코드 제거는 secure-gateway 러너 확보 이후).

## 2026-07-08 Reveal 장치 / 신뢰 경계 설계 노트

- `docs/reveal-device-policy.md` 추가.
- 로컬 전체를 신뢰영역으로 두기보다 `reveal authority` / `decrypt authority`를 최소화하는 방향으로 정리.
- TPM-backed Local Reveal을 기본 권장 모드로 정의하고, FHE secret key는 TPM/Intel PTT wrapping key로 저장 중 보호하는 방향으로 정리.
- 스마트폰은 기본 메시징 채널이나 기본 reveal 장치가 아니라 고위험 reveal의 step-up 장치로 재정의.
- 기본 모드(TPM-backed Local Reveal), 선택적 강화 모드(Smartphone Step-up Reveal), 고보증 모드(High-Assurance Reveal)를 구분.
- 생체인증은 기본 UX가 아니라 step-up reveal의 세션 승인, batch approval, 고위험 매건 인증 조합으로 정리.
- risk-based reveal policy와 향후 `RevealRequest` / `RevealPolicy` / `RevealAuthority` 추상화 방향을 기록.
- TPM-backed local reveal과 스마트폰 step-up 구조를 하나의 end-to-end 흐름으로 통합.
- `docs/reveal-device-flow.drawio` / `.svg`를 TPM-backed local reveal + smartphone step-up 구조로 갱신.
- 커밋 기록:
  - `2cc9f07 docs: add reveal device policy`
  - `1101f7f docs: merge reveal device flow`
  - `95187b4 docs: add reveal device flow diagram`
  - `0c79a59 docs: make TPM-backed reveal the default`
- 세션 종료 시점에 reveal policy 관련 변경은 모두 커밋 완료. 별도 다이어그램 rename/delete로 보이는 작업트리 변경은 기존 작업으로 남겨둠.

## 2026-07-09 Threshold FHE Reveal 설계 노트

- `docs/threshold-fhe-reveal.md` 추가.
- `docs/reveal-device-policy.md`를 Threshold FHE 중심 정책으로 재정리.
- `docs/reveal-device-policy.md`의 신뢰/비신뢰 경계를 추상 개념 대신 `SecureGateway`,
  local-egress, reveal policy, threshold authorities, PC/phone OS, external Agent/LLM 등
  구체 구성요소별 표로 명시.
- `docs/reveal-device-flow.drawio` / `.svg`를 Local Convenience Reveal, Smartphone Step-up Approval,
  Threshold PC Fusion, Threshold Phone Fusion + Display Only 라우팅 구조로 갱신.
- Multiparty FHE와 Threshold FHE의 용어 범위를 구분하고, 설계 용어는 `Threshold FHE Reveal`,
  구현/API 용어는 OpenFHE `Multiparty*` 계열로 분리.
- PC와 스마트폰의 `2-of-2` secret share, `pk_joint`, `eval_keys_joint`, partial decrypt,
  fusion 위치(PC vs phone)별 보안 성질을 정리.
- 고보증 reveal의 권장 경로를 `phone fusion + phone display only`로 정의.
- TPM/Intel PTT/TEE는 threshold FHE의 필수 전제가 아니라 local reveal 또는 secret share
  저장 보호를 위한 optional hardening으로 정리.
- OpenFHE Python 바인딩에서 `MultipartyKeyGen`, `MultipartyDecryptLead/Main/Fusion`,
  `Multi*Eval*` API가 노출되는 것을 확인하고, 후속 구현은 bundle v5/별도 backend spike로
  분리하는 방향을 기록.
- 이후 `docs/reveal-device-policy.md`는 세부 정책/구현 계획을 덜어내고 전체 동작 흐름,
  reveal 모델, threshold FHE 개념, Gateway 경계를 설명하는 개념 설계 문서로 축약.
- `docs/reveal-device-policy.md`에서 `핵심 결론`, `문서화해야 할 보안 주장`, `구현 방향`
  섹션 제거.
- 문장 표현을 서술형에서 개조식 명사구 중심으로 정리하고, 코드블록 없이 표와 bullet만 사용.
- `docs/reveal-device-flow.drawio`의 겹치던 화살표를 정리.
  - `Phone Fusion -> PC output` status 반환선 제거.
  - `PC/phone partial -> PC Fusion` 긴 역방향 dashed 선 제거.
  - `Reveal Policy -> PC Fusion -> PC output` 개념 분기로 단순화.
  - `docs/reveal-device-flow.svg` 재생성.

## 검증

- `./init.sh` 통과 (2026-07-03): ruff, ruff format, mypy, pytest 129개.
- 2026-07-06: 문서/다이어그램(.drawio/.md/.json)만 변경, 코드 무변경 — `./init.sh` 재실행 안 함.
- 2026-07-08: `./init.sh` 통과 (ruff, ruff format, mypy, pytest 129개).
- 2026-07-09: `./init.sh` 통과 (ruff, ruff format, mypy, pytest 129개).
