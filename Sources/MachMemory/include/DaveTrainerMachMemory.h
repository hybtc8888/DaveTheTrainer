#ifndef DAVE_TRAINER_MACH_MEMORY_H
#define DAVE_TRAINER_MACH_MEMORY_H

#include <mach/mach.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#define DT_PROCESS_PATH_BUFFER_SIZE 4096

typedef struct {
    uint64_t address;
    uint64_t size;
    int protection;
    int max_protection;
    int is_submap;
    uint32_t user_tag;
} DTMemoryRegion;

mach_port_name_t dt_mach_task_self(void);
kern_return_t dt_task_for_pid(pid_t pid, mach_port_name_t *task);
kern_return_t dt_mach_port_deallocate(mach_port_name_t task);
kern_return_t dt_mach_vm_read(mach_port_name_t task, uint64_t address, void *buffer, size_t length, size_t *bytes_read);
kern_return_t dt_mach_vm_write(mach_port_name_t task, uint64_t address, const void *buffer, size_t length);
kern_return_t dt_mach_vm_allocate(mach_port_name_t task, uint64_t *address, uint64_t size, int flags);
kern_return_t dt_mach_vm_deallocate(mach_port_name_t task, uint64_t address, uint64_t size);
kern_return_t dt_mach_vm_protect(mach_port_name_t task, uint64_t address, uint64_t size, int set_maximum, int new_protection);
kern_return_t dt_mach_vm_flush_instruction_cache(mach_port_name_t task, uint64_t address, uint64_t size);
kern_return_t dt_mach_vm_region_recurse(mach_port_name_t task, uint64_t *address, uint32_t *depth, DTMemoryRegion *region);

int dt_pid_list_byte_count(void);
int dt_list_pids(pid_t *buffer, int capacity);
int dt_pid_path(pid_t pid, char *buffer, int capacity);
int dt_pid_name(pid_t pid, char *buffer, int capacity);

#endif
