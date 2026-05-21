#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>

int main() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("socket");
        return 1;
    }

    /* Force multicast out from QNX Ethernet IP */
    struct in_addr local_if;
    local_if.s_addr = inet_addr("192.168.50.1");

    if (setsockopt(sock, IPPROTO_IP, IP_MULTICAST_IF, &local_if, sizeof(local_if)) < 0) {
        perror("setsockopt IP_MULTICAST_IF");
    }

    unsigned char ttl = 3;
    setsockopt(sock, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl));

    struct sockaddr_in dst;
    memset(&dst, 0, sizeof(dst));
    dst.sin_family = AF_INET;
    dst.sin_port = htons(30490);
    dst.sin_addr.s_addr = inet_addr("224.244.224.245");

    const char *msg = "qnx multicast test";

    int ret = sendto(sock, msg, strlen(msg), 0, (struct sockaddr *)&dst, sizeof(dst));
    if (ret < 0) {
        perror("sendto");
        close(sock);
        return 1;
    }

    printf("sent %d bytes to 224.244.224.245:30490\n", ret);
    close(sock);
    return 0;
}
