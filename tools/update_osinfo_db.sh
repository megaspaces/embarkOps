# 다운로드 최신  데이터베이스
wget https://releases.pagure.org/libosinfo/osinfo-db-20240523.tar.xz
# 업데이트
sudo osinfo-db-import --system osinfo-db-20240523.tar.xz
# 정보 조회
osinfo-query os | grep -i rocky
 rocky-unknown        | Rocky Linux Unknown                                | unknown  | http://rockylinux.org/rocky/unknown
 rocky8               | Rocky Linux 8                                      | 8        | http://rockylinux.org/rocky/8
 rocky8-unknown       | Rocky Linux 8 Unknown                              | 8-unknown | http://rockylinux.org/rocky/8-unknown
 rocky8.4             | Rocky Linux 8.4                                    | 8.4      | http://rockylinux.org/rocky/8.4
 rocky8.5             | Rocky Linux 8.5                                    | 8.5      | http://rockylinux.org/rocky/8.5
 rocky8.6             | Rocky Linux 8.6                                    | 8.6      | http://rockylinux.org/rocky/8.6
 rocky9               | Rocky Linux 9                                      | 9        | http://rockylinux.org/rocky/9
 rocky9-unknown       | Rocky Linux 9 Unknown                              | 9-unknown | http://rockylinux.org/rocky/9-unknown
 rocky9.0             | Rocky Linux 9.0                                    | 9.0      | http://rockylinux.org/rocky/9.0

