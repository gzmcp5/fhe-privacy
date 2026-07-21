# FHE-Privacy — RAG 없는 전체 아키텍처 흐름

전체 보안 결정 인덱스: [`1-0. security-architecture-index.md`](1-0.%20security-architecture-index.md)

비개발자용 용어 설명: [`glossary.md`](glossary.md)

## 핵심 불변식

- Secure Gateway만 사용자 원문을 수신한다.
- 파일 원본은 Gateway의 Secure File Ingress만 수신하고 masked document projection만 sandbox로 전달한다.
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
- 파일 결과는 승인된 Isolated Document Renderer/local file Fusion Sink가 새 파일로만 생성한다.
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

다이어그램의 번호는 다음 흐름을 뜻한다.

1. Secure Gateway가 사용자의 message text 또는 지원 파일 원본을 직접 수신한다.
2. Message는 PII/Crypto Ingress로 보내고, 파일은 암호화 보관·격리 parsing·Document IR 변환 후
   PII/Crypto Ingress에서 검출·마스킹·암호화한다.
3. Masked message 또는 document projection만 Hermes/LLM에 전달하고 unresolved 응답만 회수한다.
4. Agent의 handle-only 요청은 MCP Bridge를 거쳐 Privacy Core와 Public FHE Worker에서 처리한다.
5. 출력 요청은 Gateway 검증과 PC·스마트폰 2-of-2 reveal 승인을 거친다.
6. 승인된 local sink에서 화면에 표시하거나 Isolated Document Renderer가 새 파일을 생성한다.

상세 결정:

- [`1-1. pre-llm-ingress.md`](1-1.%20pre-llm-ingress.md)
- [`1-2. mcp-privacy-core-boundary.md`](1-2.%20mcp-privacy-core-boundary.md)
- [`1-3. authority-channel-separation.md`](1-3.%20authority-channel-separation.md)
- [`1-4. handle-vault-contract.md`](1-4.%20handle-vault-contract.md)
- [`1-5. post-llm-reveal-egress.md`](1-5.%20post-llm-reveal-egress.md)
- [`1-9. secure-file-ingress.md`](1-9.%20secure-file-ingress.md)
- [`1-10. secure-file-egress.md`](1-10.%20secure-file-egress.md)

## 단계별 데이터 상태

| 단계 | 위치 | 입력 | 출력 | 평문 접근 |
|---|---|---|---|---|
| 1 | User → Gateway | UTF-8 message 또는 지원 파일 bytes | raw message 또는 encrypted original object | User, Gateway ingress |
| 2 | Text/File ingress | message 또는 parser가 만든 Canonical Document IR | masked text/document projection + 보호 record | trusted host ingress/parser |
| 3 | Session Vault | ciphertext/AEAD secret + metadata | opaque input handle | 평문 없음 |
| 4 | Gateway → OpenShell Hermes Agent | masked envelope | masked conversation | 평문 없음 |
| 5 | Agent → LLM | masked prompt | tool plan/response | 평문 없음 |
| 6 | Agent → MCP Bridge → agent-safe HTTPS | handle operation | Core request | 평문 없음 |
| 7 | Public Compute | handle-bound ciphertext | stored result ciphertext | 평문 없음 |
| 8 | Core → Agent | result handle | unresolved response | 평문 없음 |
| 9 | Agent → Gateway egress | response + result handle | reveal request candidate | 평문 없음 |
| 10 | PC + phone partial authorities → Fusion Sink | 승인된 ciphertext | plaintext | 승인된 PC/phone sink만 |
| 11 | File Renderer/Fusion Sink → User | 검증된 Output Document IR + 승인된 partial | 새 local output file | 승인된 renderer와 User |

## 정상 sequence

정상 sequence는 아래 단계와 draw.io 원본을 기준으로 한다. Approximate numeric은 CKKS, exact integer는
검증된 BFV/BGV, exact predicate는 검증된 Boolean FHE를 사용한다. 계산하지 않는 exact secret은
record별 AEAD와 2-of-2 threshold envelope로 저장한다.

draw.io 원본: [`architecture-normal-sequence.drawio`](architecture-normal-sequence.drawio)

정상 흐름:

1. Gateway가 Core session을 시작한다.
2. 사용자의 raw text를 검출·마스킹한다. 파일이면 원본을 chunked AEAD object로 저장하고 격리
   parser가 만든 complete Canonical Document IR을 검출·마스킹한다. 데이터 정책에 따라 scheme별 joint
   public key로 FHE 암호화하거나 record별 AEAD + threshold envelope record를 Vault에 저장한다.
3. masked envelope만 OpenShell Hermes Agent에 전달한다.
4. LLM이 opaque handle을 이용한 공개 연산을 계획한다.
5. Agent가 stdio MCP Bridge에 handle operation을 요청한다.
6. Core가 session/type/context/provenance를 검증하고 결과 handle을 만든다.
7. Agent가 unresolved result handle을 포함한 응답을 Gateway에 반환한다.
8. Gateway egress와 Reveal Coordinator가 승인한 결과에 대해 PC와 스마트폰이 partial decrypt 또는
   unwrap share를 만든다.
9. 두 partial share는 승인된 PC 또는 phone Fusion Sink에서만 결합한다.
10. 파일 출력이면 Gateway가 masked result를 Output Document IR로 검증하고, 승인된 Isolated Document
    Renderer/local file Fusion Sink가 destination-bound plaintext를 결합해 새 파일을 원자적으로 생성한다.

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
| unsupported/unverified file profile, OCR 필요 content, memory/tool plaintext | secure mode에서 거부 |
| quota/depth/timeout 초과 | 거부 |

## 보안 주장 범위

- 지원되는 secure-gateway 입력의 등록된 secret을 Agent/LLM에 평문으로 보내지 않는다.
- Agent process가 key/Vault/reveal channel에 접근하지 못하도록 OpenShell과 authority channel 분리를 사용한다.
- Hermes가 Bridge의 capability를 복제해도 agent-safe operation 외 권한을 얻지 못한다.
- FHE public computation은 secret key 없이 수행한다.
- PC 또는 스마트폰 한쪽만으로 FHE ciphertext와 threshold-envelope DEK를 열 수 없다.
- 보안 주장은 OS/kernel 완전 침해, 화면 캡처, 키로거 또는 모든 PII의 완전한 자동 검출을 포함하지 않는다.
- Marker type, 횟수, message length, operation pattern과 주변 문맥의 metadata leakage는 남는다.
