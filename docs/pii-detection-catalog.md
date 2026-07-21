# PII Detection Catalog

이 문서는 Secure Gateway의 PII Engine이 UTF-8 텍스트에서 탐지할 대상과 기본 처리 방식을 정의한다.
법률상 개인정보의 전체 정의가 아니라 FHE-Privacy가 지원하고 검증할 제품 보안 범위다.

## 쉽게 말하면

PII Engine은 전화번호, 주민등록번호, 계좌번호와 같은 보호 대상을 찾아 원문 대신 안전한 표시를
Agent에 보낸다. 이름은 이 프로젝트에서 탐지하거나 가리지 않는다. 단순한 숫자 모양만 보지 않고
번호 형식, 오류 검사용 숫자와 주변 문장을 함께 확인한다.

용어 설명: [`glossary.md`](glossary.md)

## 분류 원칙

- 이름은 이 프로젝트의 PII 탐지 대상이 아니다. 사람 이름만으로 marker를 만들거나 masking하지 않는다.
- 숫자처럼 보이는 identifier도 산술 의미가 없으면 exact secret으로 분류한다.
- 계산하지 않는 exact secret은 record별 AEAD와 2-of-2 threshold envelope로 저장한다.
- CKKS는 허용 오차가 있는 수치, BFV/BGV는 범위가 정의된 exact integer, Boolean FHE는 검증된
  exact predicate에만 사용한다.
- 단일 정규식 일치만으로 확정하지 않는다. 형식, checksum, 주변 문맥과 등록된 locale을 함께 검증한다.
- 탐지 실패, detector timeout 또는 고위험 ambiguity에서는 Agent를 호출하지 않는다.

## 탐지 방식

| 코드 | 방식 | 설명 |
|---|---|---|
| `D` | Deterministic | 정규화, 형식, 길이와 checksum으로 높은 신뢰 판정 |
| `C` | Contextual | 주변 키워드, 문장 구조와 값의 조합이 있어야 판정 |
| `R` | Registered | 사용자가 사전에 등록한 값, prefix 또는 조직별 규칙으로 판정 |
| `H` | Heuristic | 오탐 가능성이 높아 confidence와 사용자 확인 필요 |
| `U` | Unsupported | message text 또는 검증된 file text projection에서 안전하게 탐지할 수 없어 입력 자체를 거부 |

## 한국 개인 식별정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `kr_rrn` | 주민등록번호 | `D+C` | 13자리, 날짜/세기/성별 코드, checksum, 구분자 변형 | exact envelope, 기본 phone-fusion only |
| `kr_foreigner_registration` | 외국인등록번호 | `D+C` | 13자리, 날짜/등록 코드, checksum, 문맥 | exact envelope, 기본 phone-fusion only |
| `kr_domestic_residence_card` | 국내거소신고번호 | `D+C` | 형식, checksum과 거소/동포 문맥 | exact envelope, 기본 phone-fusion only |
| `kr_passport_number` | 대한민국 여권번호 | `D+C` | 허용 문자·길이와 여권 문맥 | exact envelope, phone-fusion 우선 |
| `kr_driver_license` | 운전면허번호 | `D+C` | 지역/발급 형식과 면허 문맥 | exact envelope |
| `kr_health_insurance_id` | 건강보험증·가입자 식별번호 | `C+R` | 보험/가입자 문맥과 등록 형식 | exact envelope |
| `kr_military_service_id` | 군번 | `C+R` | 군번 문맥과 조직별 형식 | exact envelope |
| `kr_public_employee_id` | 공무원·기관 개인 식별번호 | `C+R` | 기관 문맥과 등록 형식 | exact envelope |
| `kr_disability_registration_id` | 장애인 등록 관련 식별번호 | `C+R` | 등록증 문맥과 형식 | exact envelope, phone-fusion 우선 |
| `kr_immigration_id` | 비자·체류허가·출입국 식별번호 | `C+R` | 비자/체류 문맥과 문서별 형식 | exact envelope |

주민등록번호는 숫자형 FHE 입력으로 취급하지 않는다. 생년월일, 연령 조건 또는 성별 코드가 필요한
경우 trusted ingress에서 형식과 checksum을 검증한 뒤 필요한 최소 파생 속성을 별도 typed handle로
만든다. 원본 주민등록번호 handle과 파생 속성 handle을 동일한 reveal 권한으로 취급하지 않는다.

## 국제 정부 식별정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `national_id` | 국가별 주민·국민 식별번호 | `D+C+R` | locale별 형식/checksum과 국가 문맥 | exact envelope |
| `social_security_id` | SSN, SIN 등 사회보장번호 | `D+C` | 국가별 금지 범위와 형식 검증 | exact envelope, phone-fusion 우선 |
| `taxpayer_id_personal` | 개인 납세자번호 | `D+C+R` | 개인용 세금 식별자 형식 | exact envelope |
| `passport_number` | 외국 여권번호 | `C+R` | 발급국별 형식과 여권 문맥 | exact envelope |
| `visa_number` | 비자번호 | `C+R` | 발급국/비자 종류별 형식 | exact envelope |
| `residence_permit_id` | 영주권·체류허가번호 | `C+R` | 국가별 카드/허가 문맥 | exact envelope |
| `driver_license_id` | 국가별 운전면허번호 | `C+R` | 발급지별 형식과 면허 문맥 | exact envelope |
| `voter_id` | 유권자 식별번호 | `C+R` | 국가별 문맥과 형식 | exact envelope |
| `benefit_recipient_id` | 연금·복지 수급자번호 | `C+R` | 제도명과 수급자 문맥 | exact envelope |

## 연락처와 주소

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `phone_number` | 휴대전화·유선전화·팩스 번호 | `D+C` | 국가번호, 지역번호, 허용 길이 | exact envelope |
| `email_address` | 개인 이메일 주소 | `D` | local/domain 문법, 길이, IDN 정규화 | exact envelope |
| `postal_address` | 도로명·지번·해외 우편 주소 | `C+H` | 주소 구성요소 조합과 locale parser | exact envelope |
| `address_detail` | 동·호수, 건물 내부 위치 | `C` | 주소 문맥과 상세주소 패턴 | exact envelope |
| `postal_code_with_address` | 주소와 결합된 우편번호 | `C` | 우편번호 단독은 제외, 주소 span과 결합 | 주소 marker에 포함 |
| `messenger_handle` | 메신저·SNS 개인 연락 ID | `C+R` | 서비스명 또는 `@` 문맥 | exact envelope |
| `emergency_contact` | 비상 연락처 값 | `C` | 비상연락 문맥 + 전화/계정 값 | exact envelope |

## 금융과 결제 정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `bank_account` | 국내외 은행 계좌번호 | `C+R` | 금융기관/계좌 문맥과 기관별 형식 | exact envelope |
| `iban` | IBAN | `D` | 국가코드, 길이, mod-97 checksum | exact envelope |
| `payment_card_pan` | 신용·체크카드 PAN | `D+C` | 길이, issuer prefix, Luhn checksum | exact envelope, phone-fusion 우선 |
| `payment_card_cvv` | CVV/CVC/CID | `C` | 카드 보안코드 문맥과 3~4자리 | 저장 기본 금지 |
| `payment_card_pin` | 카드 PIN | `C` | PIN 문맥과 짧은 숫자 | 저장·reveal 기본 금지 |
| `payment_card_expiry` | 카드 만료일 | `C` | PAN 또는 카드 문맥과 월/년 조합 | 카드 record에 결합 |
| `securities_account` | 증권·연금·투자 계좌번호 | `C+R` | 금융기관 문맥과 등록 형식 | exact envelope |
| `insurance_policy_number` | 개인 보험계약·증권번호 | `C+R` | 보험사/계약 문맥 | exact envelope |
| `loan_account` | 대출·모기지 계정번호 | `C+R` | 대출 문맥과 기관별 형식 | exact envelope |
| `crypto_wallet_address` | 개인 가상자산 wallet 주소 | `D+C` | network별 encoding/checksum과 wallet 문맥 | exact envelope |
| `transaction_reference` | 개인 거래 추적·승인번호 | `C+R` | 거래 문맥과 기관별 형식 | exact envelope |

금액 자체는 개인정보 marker가 아니다. 암호문 연산이 필요하면 정확성 요구에 따라 CKKS 또는
BFV/BGV typed value로 별도 분류한다. 카드번호, 계좌번호와 같은 identifier에는 산술 연산을 허용하지
않는다.

## 인증정보와 보안 비밀

법률상 개인정보 여부와 관계없이 Agent/LLM 노출 시 계정 탈취로 이어질 수 있으므로 동일한 ingress
차단 대상에 포함한다.

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `password` | 비밀번호·passphrase | `C+R` | password 문맥, 등록 secret과 exact match | 저장·reveal 기본 금지 |
| `pin` | 개인 PIN·잠금번호 | `C` | PIN 문맥 없이는 짧은 숫자를 탐지하지 않음 | 저장·reveal 기본 금지 |
| `otp` | OTP·TOTP·SMS 인증코드 | `C` | 인증 문맥, 짧은 TTL | 저장 금지, 필요 시 phone display only |
| `recovery_code` | 계정 복구코드·backup code | `C+R` | recovery 문맥과 provider별 형식 | 저장·reveal 기본 금지 |
| `api_key` | API key·access key | `D+C+R` | provider prefix 또는 등록 pattern | exact envelope, Agent 전달 금지 |
| `oauth_token` | OAuth access/refresh token | `D+C` | token 문맥/JWT 구조/provider prefix | 저장·reveal 기본 금지 |
| `session_token` | session ID·cookie·CSRF secret | `C+R` | cookie/header 문맥과 entropy | 저장·reveal 기본 금지 |
| `private_key` | PEM/SSH/PGP private key | `D` | header/footer와 encoding 구조 | 입력 거부 우선 |
| `seed_phrase` | 가상자산 mnemonic/seed phrase | `C+R` | wallet 문맥과 word-list 검증 | 입력·저장·reveal 기본 금지 |
| `certificate_secret` | PKCS#12 password, keystore secret | `C+R` | 인증서/keystore 문맥 | 저장·reveal 기본 금지 |
| `database_connection_secret` | DB URL의 password/token | `D+C` | URI parser로 userinfo/query secret 추출 | secret 부분만 차단 |
| `signed_url_secret` | 서명 URL의 signature/token | `D+C` | 알려진 query parameter와 expiry 문맥 | query secret 차단 |

## 디지털·통신·장치 식별정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `ip_address` | IPv4/IPv6 주소 | `D+C` | 유효 주소; loopback/example 범위는 문맥 평가 | exact envelope 또는 정책상 공개 |
| `mac_address` | MAC/BSSID | `D+C` | 48/64-bit 형식과 장치 문맥 | exact envelope |
| `imei` | IMEI | `D+C` | 15자리와 Luhn checksum | exact envelope |
| `imsi` | IMSI | `D+C` | MCC/MNC 길이와 SIM 문맥 | exact envelope |
| `iccid` | SIM ICCID | `D+C` | 길이, issuer prefix와 Luhn 검증 | exact envelope |
| `meid` | MEID/ESN | `D+C` | 허용 hex/decimal 형식과 장치 문맥 | exact envelope |
| `device_serial` | 휴대전화·PC·IoT serial number | `C+R` | vendor/device 문맥 | exact envelope |
| `advertising_id` | IDFA, GAID 등 광고 식별자 | `D+C` | UUID 형식과 서비스 문맥 | exact envelope |
| `device_uuid` | 사용자 연결 장치 UUID | `C+R` | generic UUID 단독은 제외, 장치 문맥 필요 | exact envelope |
| `subscriber_account` | 통신사 가입자·회선번호 | `C+R` | 통신사/회선 문맥 | exact envelope |
| `personal_domain` | 개인 계정과 연결된 domain/host | `C+R` | 사용자 등록 또는 소유 문맥 | exact envelope 또는 공개 정책 |

## 위치와 이동 정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `precise_coordinates` | 위도·경도 | `D+C` | 범위, 좌표쌍과 위치 문맥 | exact envelope |
| `geohash` | geohash, plus code, grid code | `C+R` | encoding과 위치 문맥 | exact envelope |
| `frequent_location` | 집·직장·학교의 반복 위치 | `C+H` | 관계 표현과 주소/좌표 결합 | exact envelope |
| `travel_itinerary` | 개인 항공·철도·숙박 일정 | `C+H` | 예약번호, 날짜, 장소 조합 | exact envelope |
| `boarding_pass_id` | PNR·e-ticket·탑승권 번호 | `C+R` | 운송사 문맥과 형식 | exact envelope |
| `vehicle_location` | 차량 실시간·이력 위치 | `C+H` | 차량 식별자와 좌표/시간 결합 | exact envelope |

## 차량과 자산 식별정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `vehicle_registration_plate` | 차량 번호판 | `D+C` | locale별 형식과 차량 문맥 | exact envelope |
| `vin` | 차량 VIN | `D+C` | 17자, 금지 문자, checksum 지원 locale | exact envelope |
| `vehicle_registration_id` | 차량 등록·소유 문서번호 | `C+R` | 등록 문맥과 기관별 형식 | exact envelope |
| `property_registration_id` | 부동산 등기·필지·계약 식별번호 | `C+R` | 소유/계약 문맥 | exact envelope |
| `utility_account` | 전기·가스·수도 고객번호 | `C+R` | 공급자/요금 문맥 | exact envelope |

## 의료·건강·생체 정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `patient_id` | 환자번호·진료카드번호 | `C+R` | 의료기관 문맥과 등록 형식 | exact envelope |
| `medical_record_id` | 의무기록·검사·처방 식별번호 | `C+R` | 의료 문맥과 문서 종류 | exact envelope |
| `health_insurance_member_id` | 건강보험 회원·청구번호 | `C+R` | 보험/청구 문맥 | exact envelope |
| `prescription_id` | 처방전·조제 식별번호 | `C+R` | 처방 문맥 | exact envelope |
| `diagnosis_or_condition` | 진단명, 질환, 장애, 정신건강 정보 | `C+H` | 의료 문맥과 임상 용어 사전 | exact envelope 또는 입력 거부 |
| `medication` | 개인의 복용약·투약 정보 | `C+H` | 복용 주체와 약물/용량 조합 | exact envelope |
| `genetic_identifier` | 유전검사 sample/variant/profile ID | `C+R` | 유전/검체 문맥 | exact envelope, phone-fusion 우선 |
| `biometric_template` | 지문·얼굴·홍채·음성 template text encoding | `C+R` | template/vendor 문맥 | 입력 거부 우선 |
| `biometric_media` | 얼굴 이미지, 지문 이미지, 음성 원본 | `U` | OCR/이미지·음성 분석 범위 밖 | secure mode 입력 거부 |

## 교육·고용·조직 식별정보

| Kind | 탐지 대상 | 방식 | 검증 조건 | 기본 처리 |
|---|---|---|---|---|
| `student_id` | 학번·수험번호 | `C+R` | 학교/시험 문맥과 기관별 형식 | exact envelope |
| `employee_id` | 사번·인사번호 | `C+R` | 회사/인사 문맥과 등록 형식 | exact envelope |
| `payroll_id` | 급여·원천징수 개인 식별번호 | `C+R` | 급여/세무 문맥 | exact envelope |
| `professional_license_id` | 의사·변호사·기사 등 자격번호 | `C+R` | 자격 종류와 발급기관 문맥 | exact envelope 또는 공개 정책 |
| `applicant_id` | 채용 지원자·입학 지원번호 | `C+R` | 채용/입학 문맥 | exact envelope |
| `membership_number` | 개인 회원·고객·로열티 번호 | `C+R` | 서비스/회원 문맥 | exact envelope |
| `case_or_client_id` | 법률·상담·복지 개인 사건/고객번호 | `C+R` | 기관 문맥과 등록 형식 | exact envelope |

## 사용자 등록 식별정보

정규 detector가 알 수 없는 조직 내부 식별자와 새 credential은 사용자 또는 adapter가 등록할 수 있다.

- exact secret 값의 keyed fingerprint
- 허용 prefix와 전체 길이
- locale/issuer와 checksum callback
- 주변 문맥 keyword
- marker kind와 risk class
- 기본 fusion destination
- TTL과 rotation version

등록 API는 raw secret 목록을 Agent-facing process에 노출하지 않는다. 등록값 비교는 trusted ingress에서
수행하고 log에는 일치 여부와 kind만 기록한다.

## 명시적 제외

다음 값은 단독으로는 PII marker를 만들지 않는다.

- 사람 이름, 별명, 이니셜
- 일반 회사명, 기관명, 상호
- 나이, 성별, 국적, 직업 같은 일반 속성
- 국가·도시 수준의 넓은 위치
- 우편번호 단독
- 날짜와 시간 단독
- 일반 금액, 수량, 백분율
- 공개 제품번호, 공용 전화번호, 대표 이메일
- generic UUID, 짧은 숫자와 무작위 hex 문자열

제외 값이 주소, 계정번호, 연락처 또는 등록 secret과 결합되면 복합 detector가 전체 span을 민감정보로
판정할 수 있다. 이름을 다른 민감정보와 함께 입력해도 이름 span 자체는 masking하지 않는다.

## 우선 구현 순서

### P0: Deterministic high-risk

- 한국 주민등록번호·외국인등록번호·국내거소신고번호
- 여권번호와 운전면허번호
- 전화번호와 이메일 주소
- 결제카드 PAN, IBAN, IMEI, ICCID
- API key, OAuth/session token, private key, OTP와 recovery code
- 사용자 등록 exact secret

### P1: Locale and issuer aware

- 은행·증권·보험 계정번호
- 국제 national ID, tax ID, passport, residence permit
- 차량번호·VIN, 학생번호·사번·환자번호
- crypto wallet, device/subscriber identifiers
- 정밀 좌표와 travel identifiers

### P2: Contextual sensitive content

- 우편 주소와 상세주소
- 진단·투약·유전 정보
- 자산·고용·교육·법률 사건 정보
- 조직별 등록 detector와 복합 span 판정

P2 detector는 언어와 domain별 평가 corpus 없이 `passing`으로 표시하지 않는다.

## 필수 검증

- 구분자, 공백, Unicode digit, zero-width character와 line break 변형
- checksum positive/negative 및 금지 범위
- placeholder, 문서 예시, test number와 실제 값의 구분
- 같은 숫자 형식 간 충돌과 span overlap
- 이름이 단독 또는 다른 marker 인접 시 masking되지 않음
- 주민등록번호가 CKKS/BFV 산술 handle로 자동 변환되지 않음
- exact identifier의 BFV/BGV/Boolean FHE 사용은 명시적 operation contract 없이는 거부
- marker 이후 원문 잔존 검사와 log/exception redaction
- detector timeout, model failure와 ambiguity에서 Agent 호출 0회
- 언어·locale·issuer별 precision/recall과 false-positive budget

## 보안 주장 제한

이 목록은 탐지 가능한 목표 범위다. Pattern과 문맥을 의도적으로 난독화한 값, 새 identifier 형식,
지원하지 않는 언어, 허용 profile 밖의 attachment와 이미지·음성 내용은 놓칠 수 있다. Secure mode는
지원하지 않는 입력 형식을 거부하며 모든 개인정보를 자동 탐지한다고 주장하지 않는다. 지원 파일의
text는 format별 완전성 검사를 마친 Canonical Document IR projection만 detector에 전달한다.
