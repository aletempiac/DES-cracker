#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

/* Macro that defines informations about the kernel module*/
// The device file
#define DES_DEVICE  "/dev/uio0"
// The size of the address space of our hardware peripheral
#define DES_SIZE     0x1000

int main(int argc, char **argv) {
  int status = 0; // return status
  int fd;         // file descriptor for device file
  // the interface registers of the hardware peripheral, memory-mapped in
  // virtual address space
  volatile uint32_t *regs;

  uint32_t plaintext_h, cyphertext_h, k0_h;
  uint32_t plaintext_l, cyphertext_l, k0_l;
  uint32_t k_h, k_l, k1_h, k1_l;

  if (argc!=7) {
  	fprintf(stderr, "ARGS error: plaintext, cyphertext, k0\n");
	return -1;
  }

  plaintext_h = strtol(argv[1], NULL, 16);
  plaintext_l = strtol(argv[2], NULL, 16);
  cyphertext_h = strtol(argv[3], NULL, 16);
  cyphertext_l = strtol(argv[4], NULL, 16);
  k0_h = strtol(argv[5], NULL, 16);
  k0_l = strtol(argv[6], NULL, 16);

  // Open device
  fd = open(DES_DEVICE, O_RDWR);
  if(fd == -1) {
    fprintf(stderr, "Cannot open device file %s: %s\n", DES_DEVICE, strerror(errno));
    return -1;
  }

  // Map device file in memory, read-only, shared with other processes mapping
  // the same memory region
  regs = mmap(NULL, DES_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if(regs == MAP_FAILED) {
    fprintf(stderr, "Mapping error: %s\n", strerror(errno));
    close(fd);
    return -1;
  }

  printf("executing for:\n\tplaintext: " "0x%08" PRIx32, plaintext_h);
  printf("%08" PRIx32 "\n", plaintext_l);
  printf("\tcyphertext: " "0x%08" PRIx32, cyphertext_h);
  printf("%08" PRIx32 "\n", cyphertext_l);
  printf("\tk0: " "0x%06" PRIx32, k0_h);
  printf("%08" PRIx32 "\n", k0_l);

  // Infinite loop waiting for interrupts
  while(1) {
    uint32_t interrupts; // interrupts counter

    // Enable interrupts
    interrupts = 1;
    if(write(fd, &interrupts, sizeof(interrupts)) < 0) {
      fprintf(stderr, "Cannot enable interrupts: %s\n", strerror(errno));
      status = -1;
      break;
    }

	regs[0]=(uint32_t) (plaintext_l);
	regs[1]=(uint32_t) (plaintext_h);
	regs[2]=(uint32_t) (cyphertext_l);
	regs[3]=(uint32_t) (cyphertext_h);
	regs[4]=(uint32_t) (k0_l);
	regs[5]=(uint32_t) (k0_h);

    // Wait for interrupt
    if(read(fd, &interrupts, sizeof(interrupts)) < 0) {
      fprintf(stderr, "Cannot read device file: %s\n", strerror(errno));
      status = -1;
      break;
    }

    printf("Received %u interrupts\n", interrupts);\
	k1_h=regs[9];
	k1_l=regs[8];
    // Read and display content of interface registers
    printf("\tK1: " "0x%06"PRIx32, k1_h);
    printf("%08"PRIx32 "\n", k1_l);
  }

  // Unmap
  munmap((void*)regs, DES_SIZE);
  // Close device file
  close(fd);

  return status;
}
