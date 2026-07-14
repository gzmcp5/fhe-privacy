# AGENTS.md — FHE-Privacy Runtime 라우팅 파일

> 이 파일은 상세 설계서가 아니라 다음에 무엇을 읽고 어떻게 검증할지 알려주는 지도다.

## 프로젝트 개요

FHE-Privacy는 OpenClaw, Hermes 같은 외부 AI 에이전트에 붙일 수 있는 **로컬 개인정보 보호 시스템**이다(하나의 Python **패키지**로 배포; 용어 구분은 `docs/fhe-features.md`). 기존 FHE-Agent PoC의 웹앱/채팅 서버/자체 LLM loop를 버리고, FHE 엔진과
PII 마스킹 엔진을 배포 가능한 MCP/secure gateway 형태로 재구성한다.

- 언어/런타임: Python 3.13 (`uv`, `.python-version`)
- 암호 방식: CKKS(근사 수치), BFV/BGV(exact integer), Boolean FHE(exact predicate),
  record별 AEAD + threshold envelope(exact secret). backend와 모바일 지원은 구현 전에 검증한다.
- 핵심 범위: FHE 엔진, PII 검출/마스킹, local-only reveal, MCP stdio 서버, secure gateway/adapters
- 제외 범위: 자체 LLM agent loop, FastAPI 채팅 서버, WebSocket, 프런트엔드, Tavily/web_search

## 빠른 시작

새 clone에서 코드·통합 테스트를 수행하기 전에 플랫폼별 native runtime을 준비한다. 이 명령은
`versions.lock`에 고정된 OpenShell release asset을 내려받아 검증하고, 고정된 OpenFHE source
commit에서 현재 플랫폼용 wheel을 빌드한 뒤 smoke test를 실행한다. 생성물은 gitignore된
`artifacts/`와 `vendor/wheels/`에 둔다.

```bash
./tools/bootstrap-dev-runtime.sh
```

Windows x86-64 uses OpenShell's supported WSL 2 path. From PowerShell, with Ubuntu 26.04 installed:

```powershell
.\tools\bootstrap-dev-runtime.ps1 -Distro Ubuntu-26.04
```

- Linux x86-64, macOS Apple Silicon, Windows x86-64 + Ubuntu 26.04 WSL 2가 현재 OpenFHE build target이다.
- macOS의 OpenShell/OpenFHE는 bootstrap과 checksum 확인이 가능하지만 플랫폼 호환성 상태는 테스트
  근거가 기록되기 전까지 `unvalidated`/`UNVALIDATED`로 유지한다.
- Windows는 native `.exe`가 아니라 Ubuntu 26.04 WSL 2 경로를 지원한다. OpenFHE wheel smoke test는
  검증됐지만 OpenShell 호환성은 sealed/negative test 전까지 `unvalidated`로 유지한다.
- 문서만 수정하는 작업에는 native runtime bootstrap이 필요하지 않다.
- 세부 재현·검증 절차: `tools/openshell/README.md`, `tools/openfhe/README.md`, `versions.lock`.
- 제품 package와 `./init.sh`는 현재 재구축 전이므로 존재한다고 가정하지 않는다.

## HARD 제약

- **MUST**: FHE secret은 PC와 스마트폰의 2-of-2 share로만 보관한다. 완성된 secret key를 생성,
  저장, 전송하거나 single-key fallback으로 복구하지 않는다.
- **MUST**: 비신뢰 LLM에 평문 민감값을 보내지 않는다. 입력은 LLM 전에 secure gateway에서 마스킹한다.
- **MUST**: decrypt/unmask/reveal resolve는 local-only egress 경로로만 실행한다.
- **MUST**: MCP tool-only 모드와 secure gateway 모드를 구분한다. LLM 평문 0 주장은 secure gateway에서만 한다.
- **MUST**: 동형 연산은 공개 컨텍스트로 수행하고, reveal은 PC·스마트폰 partial decrypt와 승인된
  Fusion Sink에서만 수행한다.
- **MUST**: CKKS를 주민등록번호 같은 exact identifier에 사용하지 않는다. 계산하지 않는 exact
  secret은 record별 AEAD와 2-of-2 threshold envelope로 보호한다.
- **MUST**: 이름은 현재 제품 정책상 PII detector와 masking 대상에서 제외한다.
- **MUST**: 모든 변경은 `./init.sh`를 통과해야 한다.
- **MUST NOT**: `local_keys/`, `profile.json`, `*.db`, `vendor/wheels/*.whl`를 커밋하지 않는다.
- **MUST NOT**: 웹앱/채팅 UI/LLM provider 코드를 이 프로젝트에 다시 끌어오지 않는다.

## 작업 규칙

- WIP는 한 번에 하나만 둔다.
- `feature_list.json` 상태는 검증 명령 성공 근거가 있을 때만 `passing`으로 둔다.
- 새 기능은 `docs/fhe-features.md`와 `docs/fhe-development-plan.md`의 범위 안에서 진행한다.
- 보류된 결정과 다음 시작점은 `session-handoff.md`에 남긴다.

## 완료의 정의

완료 = 코드 작성이 아니라 검증 통과다.

- L1: `ruff check`, `ruff format --check`, `mypy fhe`
- L2: `pytest`
- MCP 서버 도입 후: stdio round-trip + 권한 거부 테스트 필수

## 코드 지도

| 영역 | 파일 | 책임 |
|---|---|---|
| Crypto ingress | `fhe/client/fhe_engine.py` | scheme별 암호화와 공개 bundle; secret share는 별도 authority가 소유 |
| 직렬화 | `fhe/client/utils.py` | Base64 ↔ 암호문 bytes |
| 프로필 | `fhe/client/local_profile.py` | 공개 암호 설정 profile 저장/로드; Vault 본체가 아님 |
| 백엔드 | `fhe/engine/` | OpenFHE 격리, in-process/subprocess backend |
| 동형 연산 | `fhe/server/fhe_ops.py` | 공개 컨텍스트 기반 FHEOps |
| PII 엔진 | `fhe/server/masking.py` | 민감정보 검출/마스킹/vault/reveal |
| 스크립트 | `fhe/scripts/` | 키/프로필 생성, 로컬 복호 진단 |

## 주제 문서

- 기능 목록: `docs/fhe-features.md`
- 개발 계획: `docs/fhe-development-plan.md`
- 전체 동작 흐름도: `docs/architecture-flow.md`
- 배포 방식: `docs/distribution-guide.md`

## 세션 루틴

- 시작: `progress.md`, `session-handoff.md`, `feature_list.json` 확인.
- 새 clone에서 native runtime이 필요한 작업: `./tools/bootstrap-dev-runtime.sh` 실행.
- 변경 전: 관련 코드와 테스트를 먼저 읽는다.
- 변경 후: `./init.sh`가 복구된 뒤에는 반드시 통과 확인. 복구 전에는 변경 범위의 검증 명령과
  `./init.sh` 부재를 명시한다.
- 종료: 상태 파일 갱신 후 원자적 커밋.
