# FHE-Privacy — RAG 없는 전체 아키텍처 흐름

전체 보안 결정 인덱스: [`1-0. security-architecture-index.md`](1-0.%20security-architecture-index.md)

비개발자용 용어 설명: [`glossary.md`](glossary.md)

## 핵심 불변식

- Secure Gateway만 사용자 원문을 수신한다.
- Hermes Agent 전체와 Agent MCP Bridge는 OpenShell sandbox 안에서 실행한다.
- Agent/LLM에는 masked envelope와 opaque handle만 전달한다.
- Session-scoped Privacy Core만 handle/ciphertext 상태를 소유한다.
- Agent MCP Bridge는 stateless이며 secret key, Vault와 plaintext를 보유하지 않는다.
- Hermes와 Bridge는 하나의 비신뢰 principal이며 Bridge capability의 기밀성에 의존하지 않는다.
- Agent-safe, host-only, reveal channel을 분리한다.
- Agent-safe channel은 제한된 HTTPS/mTLS endpoint이고 host-only/reveal channel은 서로 다른 local UDS다.
- secure mode는 직접 connect/exec/sync/forward와 Agent 입력을 차단한 sealed sandbox만 사용한다.
- FHE secret은 PC와 스마트폰의 2-of-2 share로만 존재하고 완성된 secret key를 만들지 않는다.
- Plaintext는 두 장치가 참여한 뒤 승인된 PC 또는 phone Fusion Sink에서만 생성한다.
- 실패하거나 불확실하면 전송, 연산 또는 reveal을 중단한다.

## 전체 컴포넌트 흐름

```text
Trusted host                              OpenShell sealed sandbox
  Secure Gateway                           Hermes + untrusted MCP adapter
    -> host-only Core UDS          <---->     -> HTTPS/mTLS agent-safe Core
    -> Reveal Coordinator                    -> approved inference route
    -> PC Partial Authority (sk_pc)

Smartphone
  Phone Partial Authority (sk_phone)
  Phone Fusion Sink
```

draw.io 원본: [`1. architecture-component-flow.drawio`](1.%20architecture-component-flow.drawio)

## 프로세스 경계

draw.io의 `PROCESS` 점선 상자는 OS process를, 바깥의 큰 색상 점선 영역은 trust/runtime boundary를
뜻한다. 같은 trust boundary 안에 있어도 process와 권한 채널은 분리한다.

| Process | 내부 구성요소·상태 | 배치 |
|---|---|---|
| Secure Gateway | ingress/egress controller, PII Engine, Crypto Ingress | trusted host ingress |
| Hermes Agent | conversation과 LLM/tool loop | OpenShell sealed sandbox |
| Agent MCP Bridge | stdio MCP ↔ agent-safe HTTPS 변환 | OpenShell sealed sandbox |
| Privacy Core | session, policy, handle 검증과 dispatch | trusted PC host |
| Vault Coordinator | handle metadata와 ciphertext store | trusted PC host |
| Public FHE Worker | public context 기반 secret-free 동형연산 | trusted PC host의 분리 process |
| Reveal Coordinator | reveal policy, destination, nonce와 transcript | trusted PC host의 분리 process |
| PC Partial Authority | `sk_pc`를 이용한 partial decrypt/unwrap | PC의 격리 process |
| Phone Partial Authority | `sk_phone`을 이용한 partial decrypt/unwrap | enrolled phone app process |
| Approved Fusion Sink | 두 partial 결합과 최종 plaintext 생성 | 승인된 PC terminal 또는 phone display process |
| External LLM Provider | masked prompt 추론 | 외부 비신뢰 service |

- PII Engine과 Crypto Ingress는 Secure Gateway process 내부 module이다.
- Hermes와 MCP Bridge는 별도 process지만 같은 OpenShell sandbox principal이므로 서로를 신뢰 경계로
  사용하지 않는다.
- Vault는 단순 파일 경로가 아니라 Privacy Core와 분리된 Vault Coordinator process가 독점하는
  ciphertext store다.
- 완성된 secret key를 가지는 process는 없으며 PC와 phone share는 각 Partial Authority에만 존재한다.

상세 결정:

- [`1-1. pre-llm-ingress.md`](1-1.%20pre-llm-ingress.md)
- [`1-2. mcp-privacy-core-boundary.md`](1-2.%20mcp-privacy-core-boundary.md)
- [`1-3. authority-channel-separation.md`](1-3.%20authority-channel-separation.md)
- [`1-4. handle-vault-contract.md`](1-4.%20handle-vault-contract.md)
- [`1-5. post-llm-reveal-egress.md`](1-5.%20post-llm-reveal-egress.md)

## 단계별 데이터 상태

| 단계 | 위치 | 입력 | 출력 | 평문 접근 |
|---|---|---|---|---|
| 1 | User → Gateway | UTF-8 원문 | raw message | User, Gateway ingress |
| 2 | PII/Crypto ingress | 원문 | scheme별 FHE ciphertext 또는 threshold-envelope AEAD record | trusted host ingress |
| 3 | Session Vault | ciphertext/AEAD secret + metadata | opaque input handle | 평문 없음 |
| 4 | Gateway → OpenShell Hermes Agent | masked envelope | masked conversation | 평문 없음 |
| 5 | Agent → LLM | masked prompt | tool plan/response | 평문 없음 |
| 6 | Agent → MCP Bridge → agent-safe HTTPS | handle operation | Core request | 평문 없음 |
| 7 | Public Compute | handle-bound ciphertext | stored result ciphertext | 평문 없음 |
| 8 | Core → Agent | result handle | unresolved response | 평문 없음 |
| 9 | Agent → Gateway egress | response + result handle | reveal request candidate | 평문 없음 |
| 10 | PC + phone partial authorities → Fusion Sink | 승인된 ciphertext | plaintext | 승인된 PC/phone sink만 |

## 정상 sequence

정상 sequence는 아래 단계와 draw.io 원본을 기준으로 한다. Approximate numeric은 CKKS, exact integer는
검증된 BFV/BGV, exact predicate는 검증된 Boolean FHE를 사용한다. 계산하지 않는 exact secret은
record별 AEAD와 2-of-2 threshold envelope로 저장한다.

draw.io 원본: [`architecture-normal-sequence.drawio`](architecture-normal-sequence.drawio)

정상 흐름:

1. Gateway가 Core session을 시작한다.
2. 사용자의 raw text를 검출·마스킹한다. 데이터 정책에 따라 scheme별 joint public key로 FHE
   암호화하거나 record별 AEAD + threshold envelope record를 Vault에 저장한다.
3. masked envelope만 OpenShell Hermes Agent에 전달한다.
4. LLM이 opaque handle을 이용한 공개 연산을 계획한다.
5. Agent가 stdio MCP Bridge에 handle operation을 요청한다.
6. Core가 session/type/context/provenance를 검증하고 결과 handle을 만든다.
7. Agent가 unresolved result handle을 포함한 응답을 Gateway에 반환한다.
8. Gateway egress와 Reveal Coordinator가 승인한 결과에 대해 PC와 스마트폰이 partial decrypt 또는
   unwrap share를 만든다.
9. 두 partial share는 승인된 PC 또는 phone Fusion Sink에서만 결합한다.

## Interface 경계

| Interface | 호출자 | 허용 기능 |
|---|---|---|
| Gateway host-only Core UDS | Secure Gateway | session, masking, scheme 선택, 암호화와 Vault registration |
| Agent-safe HTTPS/mTLS | sandbox 전체 | handle 기반 공개 FHE operation |
| Reveal Coordinator UDS | Gateway egress | policy, destination, nonce와 partial protocol 조정 |
| PC Partial UDS | Reveal Coordinator | `sk_pc`/PC unwrap share로 partial 결과 생성 |
| Authenticated phone channel | Reveal Coordinator | 사용자 승인과 `sk_phone`/phone unwrap share 요청 |
| PC/Phone Fusion Sink | Coordinator가 승인한 request | 두 partial 결과 결합과 최종 출력 |

`role` argument나 하나의 공용 MCP tool registry로 이 권한을 구분하지 않는다. Agent-facing MCP에는
mask, encrypt, decrypt, resolve, key export와 Vault access tool을 등록하지 않는다.

## 실패/거부 경로

| 상황 | 처리 |
|---|---|
| PII ambiguity/detector/암호화/Vault 실패 | Agent 호출 없음 |
| OpenShell 격리 실패 | secure-gateway 시작 거부 |
| sealed sandbox/connect 차단 확인 실패 | secure-gateway 시작 거부 |
| supervisor heartbeat, lease 또는 policy revision 불일치 | capability 폐기, Core operation 거부 |
| PC/phone share 누락 또는 key-set/context 불일치 | reveal 거부, single-key fallback 없음 |
| phone offline/분실 | reveal 거부; 2-of-3 recovery 구현 전 복구 불가 |
| Core 연결 또는 session 실패 | MCP 오류, fallback 없음 |
| raw plaintext/ciphertext operation 인자 | 거부 |
| unknown/cross-session/context mismatch handle | 거부 |
| 입력 secret 직접 reveal | 거부 |
| Agent/LLM/tool로 plaintext 반환 | 거부 |
| unsupported attachment/memory/tool plaintext | secure mode에서 거부 |
| quota/depth/timeout 초과 | 거부 |

## 보안 주장 범위

- 지원되는 secure-gateway 입력의 등록된 secret을 Agent/LLM에 평문으로 보내지 않는다.
- Agent process가 key/Vault/reveal channel에 접근하지 못하도록 OpenShell과 authority channel 분리를 사용한다.
- Hermes가 Bridge의 capability를 복제해도 agent-safe operation 외 권한을 얻지 못한다.
- FHE public computation은 secret key 없이 수행한다.
- PC 또는 스마트폰 한쪽만으로 FHE ciphertext와 threshold-envelope DEK를 열 수 없다.
- 보안 주장은 OS/kernel 완전 침해, 화면 캡처, 키로거 또는 모든 PII의 완전한 자동 검출을 포함하지 않는다.
- Marker type, 횟수, message length, operation pattern과 주변 문맥의 metadata leakage는 남는다.
