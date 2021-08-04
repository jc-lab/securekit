# TPM MITM Attack Protection

## 시나리오

1. 정상 상태에서 첫번째 부팅을 하여 DISK를 현재 TPM PCR으로 암호화.
2. 이후 부팅 시 TPM을 통한 DISK복호화
3. 해커가 PC 탈취 후 TPM MITM 공격
  * PC는 Session 생성 후 persistent handle로 TPM에 Sealed Key복호화 요청
  * 공격자는 Session 생성 당시부터 MITM공격을 통해 PC와는 자신의 Session Key 사용
  * TPM은 Sealing 당시의 PCR과 현재 PCR이 다르지 않음을 확인하고 Unsealed Key를 PC에 세션키로 암호화하여 전송
  * TPM이 주는 세션은 공격자의 세션이기 때문에 공격자가 Unsealed Key 탈취 가능함


