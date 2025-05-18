FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    cpu-checker \
    qemu-kvm \
    kmod \
    && apt-get clean

# Verifica se /dev/kvm existe
CMD ["/bin/bash", "-c", "\
    echo 'Verificando suporte a KVM...'; \
    if [ -e /dev/kvm ]; then \
        echo '✅ KVM está disponível neste ambiente!'; \
    else \
        echo '❌ KVM não está disponível (sem /dev/kvm).'; \
    fi && \
    echo 'Resultado de kvm-ok:' && \
    kvm-ok || true \
"]
