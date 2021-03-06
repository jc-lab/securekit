# SecureKit

SecureKit은 [LinuxKit](https://github.com/linuxkit/linuxkit)으로 만들어지는 이미지에 대해 TPM을 통해 이미지 자체의 무결성을 자체 검증하고, 데이터를 암호화하여 LinuxKit OS외부에서 내부의 데이터에 접근하지 못하게 도와줍니다.

# DO NOT USE YET!

아직 TPM MITM에 취약합니다.

* See [docs/tpm-mitm-protection.md](docs/tpm-mitm-protection.md)
* See also [How can I prevent MITM attacks for unsealing?](https://lists.01.org/hyperkitty/list/tpm2@lists.01.org/thread/ETZM6ECYGPWBNZGTPQJVUGJJ5U5YZJCV/)

# 빠른 시작

See [docs/quick-start.md](docs/quick-start.md)

# 목적

- (LinuxKit을 사용함으로써) 기본적으로 원격 및 로컬 콘솔을 통한 접근은 금지합니다.
- (무결성 확인) TPM을 통한 전체 이미지 무결성 확인
- (데이터 접근) (IPMI등을 통해) 부팅 과정 변경을 통한 해킹 방지
    - 부팅 과정 중 init script을 변경하거나 다른 OS를 통한 로그인 우회
    - HDD 복제를 통한 데이터 접근

### 콘손 접근 금지

 리눅스 배포판을 설치한 후 서버 소프트웨어를 설치하는 과정과 이후 관리하는 과정에 원격/로컬 Shell 연결이 필요합니다. 하지만 LinuxKit으로 부팅 후 바로 동작할 수 있는 이미지를 만들어 추가 유지 보수가 불필요하기에 원격 및 로컬 콘솔 접근을 금지합니다.

### LinuxKit의 보안성

 추가적으로 LinuxKit은 containerd를 통해 각 서비스가 동작됩니다. 이는 각 어플리케이션의 네임스페이스가 격리되어 서로의 간섭할 수 없다는 것입니다. 이러한 LinuxKit의 특성들은 Attack Surface를 줄입니다.

### 무결성 확인

리눅스에는 IMA(lntegrity Measurement Architecture)를 통해 시스템의 파일들의 무결성을 확인하여 변조된 파일은 로드되지 않게 할 수 있는 기능이 있습니다. 하지만 방대한 리눅스 배포판의 시스템의 모든 부분들을 무결성 체크를 하기에는 어려움이 따르며 이는 곧 공격의 가능성을 발생시킵니다. (특정 설정 파일이 IMA에 포함되지 않았는데 이를 통해 데이터 디렉터리에 있는 악성 코드를 실행시킨다는 등)

 LinuxKit은 시스템 전체를 불변 이미지로 만들 수 있습니다. 불변 이미지의 무결성을 확인하는 것은 매우 쉽습니다. 그냥 전체 영역을 해시하면 됩니다! 이러한 LinuxKit의 특성을 통해 SecureKit에서는 이미지 자체의 무결성을 서명 키로 부터 검증하고, TPM을 통해 부팅 과정부터의 무결성을 확인합니다.

이 과정은 아래와 같습니다.

[이미지 생성]

- systemd-boot의 [linux efi stub](https://github.com/jc-lab/systemd-boot-efi)을 통해 linuxkit 이미지를 단일 efi 실행 파일로 만듭니다.
- grub 등을 사용하여 efi와 initrd를 분리할 수도 있지만 Kernel과 initrd를 하나의 efi 파일로 만들면 상위 부트로더(Motherboard's UEFI Firmware)가 자동으로 PCR에 extend하여 손쉽게 kernel, cmdline, initrd에 대해 measured boot가 가능합니다.
- (직접 해야 함) secure boot 인증서로 efi를 서명 합니다.

[이미지 검증]

- secure boot 과정을 통해 UEFI Firmware가 서명을 확인합니다. 이것은 securekit이 아닌 메인보드의 펌웨어에서 동작합니다.
- initrd.img 에서 TPM을 통해 현재 PCR값으로 봉인된 암호키를 추출 해 데이터 디스크를 마운트 합니다.

### 부팅 과정 변경을 통한 해킹 방지

 서버의 보안이 강하여도 IPMI/iLO 등을 통해 원격 서버 관리가 가능한 경우 이를 통해서 부팅 과정 개입이 가능합니다. 혹은 잘못된 구성으로 인해 서버가 재부팅 하면서 PXE로 부팅할 수도 있습니다. 예상치 못한 부팅 과정에 대한 공격이 있을 수 있습니다.

 이러한 부팅 과정 변화는 TPM을 통해 보호할 수 있습니다. TPM을 통해 부팅 과정을 측정함으로써 안전한 상태로 부팅 되었을 때에만 암호화된 데이터에 접근할 수 있습니다.

# 약점

 Hypervisor 위에서 동작할 경우 보안이 약화됩니다. 약한 권한을 가져서 Hypervisor를 통한 콘솔 접근만 가능한 경우 부팅 과정을 통한 공격 완화는 여전히 동작합니다. 하지만 Hypervisor의 권한이 탈취 당한 경우에는 보호가 불가 합니다. 같은 이유로써 Hypervisor를 사용하지 않는다 하더라고 하드웨어 자체를 제어할 수 있는 경우에도 동일하게 보호가 불가능해 집니다.

### 디버깅

 VM Monitor를 통한 디버깅 혹은 물리적 하드웨어 디버깅을 통해 키가 노출될 수 있습니다. 이는 정상적인 부팅 과정 중 Break Point를 걸게 된다면 그 상태의 메모리를 볼 수 있기 때문입니다.


하지만 Hardware에 대해 잘 모르는 초보 해커의 공격은 아마도 막을 수 있을 것입니다.😎



# 동작 방식

## Protector Keys

보호 및 백업을 위한 3 가지 키가 있습니다. SecureKit에서 직접적으로 사용하는 것은 2 가지 뿐 입니다.

### FS_PROTECTOR_KEY

= FileSystem Protector Key

PGP 키 형식이며, 파일 시스템 복구용 키 입니다. 이미지 업데이트 혹은 예기치 못한 이유로 정상 동작이 어려울 때 암호화된 파일시스템을 복구하기 위해 사용할 수 있습니다.

### INTEGRITY_PROTECTOR_KEY

= Integrity Protector Key

PGP 키 형식이며, GRUB에서 kernel과 initrd의 무결성을 검증하기 위해 사용합니다.

## 부팅 과정

1. (공통사항) Grub 이미지에서 kernel과 initrd의 무결성을 검증한 뒤 리눅스 커널로 부팅합니다. Grub 이미지 내에 INTEGRITY_PROTECTOR_KEY 가 내장되어야 하며 Grub 이미지는 UEFI 디지털 서명해야 합니다. (SecureKit에서 강제하는 것은 아니지만 권장합니다.)

### 첫번째 부팅

첫 번째 부팅에서는 디스크에 아무것이 있지 않습니다. (어떠한 파티션도 존재하지 않아야 합니다) 따라서 디스크를 초기화 합니다.

2. 파티션을 2개 생성합니다. 첫 번째는 암호화된 키 및 TPM 사용을 위한 암호화된 데이터들이 저장됩니다. 두 번째는 암호화된 데이터 저장소로 사용됩니다.

3. 현재 PCR로 보호된 TPM 으로 Seal되는 키와 복구 키로 두 번째 파티션을 luks로 포멧합니다.

4. 복구 키는 FS_PROTECTOR_KEY(공개 키)로 암호화되어 첫 번째 파티션에 저장됩니다. 이렇게 저장된 암호화된 키는 부팅 후 SSH로 접근하여 따로 보관해 놓으십시오. (생성된 파일을 지우지는 마십시오!)

### 이후의 부팅

2. TPM으로 Unseal된 키를 통해 파일시스템을 Open 합니다.

### 이미지 업데이트 시

이미지를 업데이트 하면 TPM PCR값이 달라져 파일시스템 복구에 실패하게 됩니다. 따라서 업데이트 된 PCR을 통해 키를 다시 Seal해야 합니다.

2. 모든 드라이브에서 "fs_protector_key.private.asc", 즉 암호화된 개인 키 파일을 찾은 뒤, 해당 키로 [첫번째 부팅](#첫번째 부팅)때 생성 된 암호화된 키를 복호화하여 파일시스템을 Open 합니다. (FAT로 포멧 된 USB 드라이브를 사용할 수 있습니다.)

3. 다시 현재의 PCR로 보호된 TPM 으로 Seal하여 기존의 키를 교체합니다.

# License 

Apache License 2.0
