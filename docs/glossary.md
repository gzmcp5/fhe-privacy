# FHE-Privacy Glossary

이 문서는 FHE-Privacy 설계 문서에 반복해서 나오는 전문 용어를 비개발자 관점에서 설명한다.
정확한 구현 규격보다 전체 구조를 이해하기 위한 쉬운 설명을 우선한다.

## 가장 중요한 용어

| 용어 | 쉽게 말하면 |
|---|---|
| 평문, `plaintext` | 암호화되지 않아 사람이 그대로 읽을 수 있는 원래 정보 |
| 암호문, `ciphertext` | 열쇠 없이는 읽기 어렵게 변환한 정보 |
| PII | 이 프로젝트가 외부 Agent나 LLM에 보내지 않기로 정한 개인 식별·연락·금융·계정 정보 |
| 마스킹, `masking` | 민감정보를 `{{rrn:...}}` 같은 안전한 표시로 바꾸는 작업 |
| 복호화, `decrypt` | 암호문을 원래 정보로 되돌리는 작업 |
| Reveal | 정책과 승인을 확인한 뒤 최종 사용자에게 원래 값을 보여주는 전체 과정 |
| Gateway | 사용자 입력을 먼저 검사하고 안전한 내용만 Agent에 전달하는 관문 |
| Document IR | Document Intermediate Representation. PDF, DOCX, Markdown 등 서로 다른 파일을 문단·표·셀·위치·segment의 공통 구조로 바꾼 표준 문서 중간 표현 |
| Agent | LLM과 도구를 사용해 작업하는 프로그램. 이 설계에서는 믿지 않는 대상으로 간주 |
| LLM | 외부 언어 모델. 마스킹된 내용만 받아야 함 |
| Sandbox | Agent가 파일·프로세스·네트워크 경계를 벗어나지 못하게 가두는 실행 공간 |
| Fail-closed | 문제가 생기면 원문을 통과시키지 않고 작업을 중단하는 방식 |

## 신뢰와 경계

| 용어 | 쉽게 말하면 |
|---|---|
| 신뢰, `trusted` | 이 구성요소가 약속을 지킨다고 설계가 의존한다는 뜻. 안전성이 자동 증명됐다는 뜻은 아님 |
| 비신뢰, `untrusted` | 악의적이거나 고장 날 수 있다고 가정하고 중요한 열쇠와 평문을 주지 않는 대상 |
| 신뢰 경계 | 정보나 권한이 서로 다른 영역 사이를 넘어가는 지점 |
| Ingress | 정보가 시스템 안으로 들어오는 입구 |
| Egress | 정보가 사용자나 외부로 나가는 출구 |
| Authority | 특정 민감 작업을 수행할 권한을 가진 구성요소 |
| 최소 권한 | 각 구성요소에 꼭 필요한 권한만 주는 원칙 |
| 위협 모델 | 누가 무엇을 공격할 수 있다고 가정하는지 정한 기준 |
| 잔여 위험 | 보호 조치를 적용한 뒤에도 남는 위험 |

## Session, Handle과 Vault

| 용어 | 쉽게 말하면 |
|---|---|
| Session | 한 번의 대화나 작업을 구분하는 범위 |
| Marker | 원문에서 민감정보를 치환한 표시 문자열 |
| Handle | Vault 안의 암호문을 가리키는 추측하기 어려운 보관증 |
| Opaque handle | 내부 정보나 저장 위치를 드러내지 않는 handle |
| Vault | 암호문과 handle의 관계를 보관하는 금고 역할의 저장소 |
| Provenance | 결과가 어떤 입력과 연산을 거쳐 만들어졌는지에 대한 이력 |
| Capability | 특정 세션에서 허용된 작업만 요청할 수 있는 제한된 이용권 |
| Lease | 일정 시간이 지나거나 상태가 바뀌면 자동 만료되는 짧은 이용권 |
| Policy revision | 현재 적용 중인 보안 정책의 버전 |
| Replay | 과거 승인이나 요청을 복사해 다시 사용하는 공격 |
| Nonce | 같은 요청을 재사용하지 못하게 매번 새로 넣는 일회성 값 |

## 암호 기술

| 용어 | 쉽게 말하면 |
|---|---|
| 공개키 | 공개해도 되는 잠금용 열쇠. 이것만으로 암호문을 열 수 없음 |
| 비밀키 | 암호문을 여는 데 필요한 비밀 열쇠 |
| FHE | 정보를 암호화한 채로 계산하는 기술 |
| 동형 연산 | 암호문을 풀지 않고 수행하는 계산 |
| Scheme | 암호화와 계산 규칙의 종류 |
| CKKS | 약간의 오차를 허용하는 평균·통계 같은 수치 계산용 FHE 방식 |
| BFV/BGV | 정해진 범위 안에서 오차 없는 정수 계산을 하는 FHE 방식 |
| Boolean FHE | 참/거짓, 같음, 비트 조건 같은 정확한 판정을 계산하는 FHE 방식 |
| Approximate | 결과에 작고 통제된 오차가 있을 수 있다는 뜻 |
| Exact | 약속한 조건 안에서 오차 없이 같은 값을 얻는다는 뜻 |
| Modular arithmetic | 일정 숫자를 넘으면 처음으로 돌아가는 시계 같은 계산 방식 |
| Overflow | 계산 결과가 약속한 범위를 넘어 의도와 다른 값이 되는 문제 |
| Parameter set | 안전성, 정확도와 가능한 계산 횟수를 정하는 설정 묶음 |
| Context | scheme과 parameter set을 포함한 암호문 계산 환경 |
| Evaluation key | 비밀키 없이 특정 암호문 계산을 가능하게 하는 공개 연산 자료 |
| AEAD | 데이터를 정확히 암호화하면서 위조 여부도 확인하는 일반 암호화 방식 |
| DEK | 한 record를 암호화하는 데만 사용하는 임시 데이터 암호화 열쇠 |
| Envelope encryption | 실제 데이터용 DEK를 다시 다른 키 구조로 감싸 보호하는 방식 |
| Key wrapping | DEK 같은 열쇠를 다른 열쇠로 잠그는 작업 |

## PC·스마트폰 2-of-2

| 용어 | 쉽게 말하면 |
|---|---|
| Multiparty FHE | 여러 장치가 함께 키를 만들고 결과를 여는 FHE 방식 |
| Threshold FHE | 정해진 수 이상의 참여자가 모여야 결과를 열 수 있는 FHE 방식 |
| 2-of-2 | PC와 스마트폰 두 장치가 모두 참여해야 열 수 있다는 뜻 |
| Secret share | 각 장치가 가진 비밀 조각. 한 조각만으로는 열 수 없어야 함 |
| Joint public key | PC와 스마트폰이 함께 만든 공개 암호화 키 |
| Joint evaluation keys | 공동 secret에 맞게 함께 만든 공개 연산 자료 |
| Partial decrypt | 각 장치가 자기 share로 만드는 불완전한 복호 결과 |
| Fusion | 두 partial decrypt를 합쳐 최종 평문을 만드는 단계 |
| PC fusion | 최종 평문을 PC에서 만드는 방식 |
| Phone fusion | 최종 평문을 스마트폰에서만 만드는 방식 |
| Threshold envelope | exact secret의 DEK도 두 장치가 함께해야 열리도록 감싼 구조 |
| 2-of-3 recovery | PC, 스마트폰, 복구 장치 중 두 개로 복구하는 후속 구조 |

2-of-2는 완성된 비밀키 파일을 반으로 자르는 방식이 아니다. PC와 스마트폰이 처음부터 공동 키
생성에 참여하고, 어느 장치도 완성된 FHE secret key를 갖지 않는 구조다.

## 시스템 컴포넌트

| 용어 | 쉽게 말하면 |
|---|---|
| Secure Gateway | 원문을 받고 PII를 탐지·마스킹하며 최종 출력을 관리하는 관문 |
| PII Engine | 텍스트에서 보호 대상 정보를 찾는 탐지기 |
| Privacy Core | 세션, handle, 정책과 허용 연산을 검사하는 중앙 조정자 |
| Session Handle Vault | handle이 어떤 암호문을 가리키는지 보관하는 저장소 |
| Public FHE Worker | 비밀키 없이 암호문 계산만 수행하는 작업자 |
| MCP Bridge | Agent 요청을 Core 요청으로 바꾸는 중계기. 별도 보안 권한은 없음 |
| Reveal Coordinator | reveal 목적지, 승인과 nonce를 검사하고 두 장치 참여를 조정하는 구성요소 |
| PC Partial Decrypt Authority | PC share로 partial decrypt를 만드는 최소 권한 프로세스 |
| Phone Partial Decrypt Authority | 스마트폰 share로 partial decrypt를 만드는 앱 영역 |
| Fusion Sink | 두 partial 결과를 합쳐 승인된 장치에 평문을 만드는 최종 위치 |
| Terminal Egress | PC 터미널에 최종 결과를 표시하는 출구 |

## 통신과 실행

| 용어 | 쉽게 말하면 |
|---|---|
| UDS | 같은 PC 안의 프로세스끼리 사용하는 로컬 전용 통로 |
| HTTPS | 네트워크 메시지를 암호화해 전달하는 통신 방식 |
| TLS | 상대방 확인과 통신 암호화에 사용하는 보안 규칙 |
| mTLS | 서버와 요청자 양쪽이 인증서를 보여 신원을 확인하는 TLS |
| Endpoint | 프로그램이 요청을 받을 주소와 기능 |
| Stdio | 프로그램의 표준 입력과 출력을 이용한 통신 방식 |
| MCP | Agent가 외부 도구를 일정한 형식으로 호출하는 protocol |
| Sealed sandbox | 일반 connect, exec, 파일 전송과 port forwarding을 차단한 sandbox |
| Heartbeat | 구성요소가 정상 동작 중임을 주기적으로 알리는 신호 |

## PII 탐지와 평가

| 용어 | 쉽게 말하면 |
|---|---|
| Detector | 텍스트에서 특정 형태나 의미를 찾아내는 탐지기 |
| Deterministic detector | 길이, 형식과 checksum처럼 명확한 규칙으로 찾는 탐지기 |
| Contextual detector | 주변 단어와 문장의 의미까지 보고 판단하는 탐지기 |
| Heuristic | 완벽하지 않은 경험 규칙으로 가능성을 추정하는 방식 |
| 정규식 | 전화번호처럼 일정한 문자 모양을 찾는 pattern 규칙 |
| Checksum | 번호 일부를 계산해 오타나 가짜 형식을 걸러내는 검증 숫자 |
| Locale | 국가·언어·지역에 따라 다른 번호와 주소 형식 |
| Issuer | 여권, 카드, 계정번호 등을 발급한 국가나 기관 |
| False positive, 오탐 | 민감정보가 아닌데 민감정보라고 잘못 판단한 경우 |
| False negative, 미탐 | 실제 민감정보를 찾아내지 못한 경우 |
| Precision | 탐지했다고 판단한 것 중 실제로 맞은 비율 |
| Recall | 실제 탐지 대상 중 빠뜨리지 않고 찾아낸 비율 |
| Ambiguity | 민감정보인지 확실히 판정하기 어려운 상태 |

## 권장 읽기 순서

1. `security-architecture-index.md`: 누가 무엇을 신뢰하는지 확인
2. `architecture-flow.md`: 정보가 이동하는 순서 확인
3. `pii-detection-catalog.md`: 어떤 정보를 찾아 보호하는지 확인
4. `cryptography-data-policy.md`: 데이터별 암호 방식 확인
5. `reveal-device-policy.md`: PC와 스마트폰이 결과를 여는 방식 확인

이해가 어려운 용어가 새로 추가되면 해당 문서에만 설명을 두지 말고 이 용어집에도 함께 추가한다.
