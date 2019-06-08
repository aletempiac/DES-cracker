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

  uint64_t plaintext, cyphertext, k0;
  uint64_t k, k1;

  if (argc!=4) {
  	fprintf(stderr, "ARGS error: plaintext, cyphertext, k0\n");
	return -1;
  }

  plaintext = strtol(argv[1], NULL, 16);
  cyphertext = strtol(argv[2], NULL, 16);
  k0 = strtol(argv[3], NULL, 16);

  // Open device
  fd = open(DES_DEVICE, O_RDWR);
  if(fd == -1) {
    fprintf(stderr, "Cannot open device file %s: %s\n", DES_DEVICE, strerror(errno));
    return -1;
  }

  // Map device file in memory, read-only, shared with other processes mapping
  // the same memory region
  regs = mmap(NULL, DES_SIZE, PROT_READ, MAP_SHARED, fd, 0);
  if(regs == MAP_FAILED) {
    fprintf(stderr, "Mapping error: %s\n", strerror(errno));
    close(fd);
    return -1;
  }

  printf("executing for:\n\tplaintext: " "0x%016" PRIx64 "\n", plaintext);
  printf("\tcyphertext: " "0x%016" PRIx64 "\n", cyphertext);
  printf("\tk0: " "0x%012" PRIx64 "\n", k0);

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

	regs[0]=(uint32_t) (plaintext);
	regs[1]=(uint32_t) (plaintext >> 32);
	regs[2]=(uint32_t) (cyphertext);
	regs[3]=(uint32_t) (cyphertext >> 32);
	regs[4]=(uint32_t) (k0);
	regs[5]=(uint32_t) (k0 >> 32);

    // Wait for interrupt
    if(read(fd, &interrupts, sizeof(interrupts)) < 0) {
      fprintf(stderr, "Cannot read device file: %s\n", strerror(errno));
      status = -1;
      break;
    }

    printf("Received %u interrupts\n", interrupts);

    // Read and display content of interface registers
	k=(((uint64_t) regs[9]) << 32) | ((uint64_t) regs[8]);
    printf("\tK: " "0x%012"PRIx64 "\n", k);
  }

  // Unmap
  munmap((void*)regs, DES_SIZE);
  // Close device file
  close(fd);

  return status;
}
