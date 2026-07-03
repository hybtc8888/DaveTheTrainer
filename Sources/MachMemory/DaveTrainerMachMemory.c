#include "DaveTrainerMachMemory.h"

#include <limits.h>
#include <libproc.h>

mach_port_name_t dt_mach_task_self(void) {
    return mach_task_self();
}

kern_return_t dt_task_for_pid(pid_t pid, mach_port_name_t *task) {
    if (task == NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    *task = MACH_PORT_NULL;
    return task_for_pid(mach_task_self(), pid, task);
}

kern_return_t dt_mach_port_deallocate(mach_port_name_t task) {
    if (task == MACH_PORT_NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    return mach_port_deallocate(mach_task_self(), task);
}

kern_return_t dt_mach_vm_read(mach_port_name_t task, uint64_t address, void *buffer, size_t length, size_t *bytes_read) {
    if (buffer == NULL || bytes_read == NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    *bytes_read = 0;
    mach_vm_size_t local_size = 0;
    kern_return_t result = mach_vm_read_overwrite(
        task,
        (mach_vm_address_t)address,
        (mach_vm_size_t)length,
        (mach_vm_address_t)buffer,
        &local_size
    );

    if (result != KERN_SUCCESS) {
        return result;
    }

    *bytes_read = (size_t)local_size;
    return KERN_SUCCESS;
}

kern_return_t dt_mach_vm_write(mach_port_name_t task, uint64_t address, const void *buffer, size_t length) {
    if (buffer == NULL || length > UINT_MAX) {
        return KERN_INVALID_ARGUMENT;
    }

    return mach_vm_write(
        task,
        (mach_vm_address_t)address,
        (vm_offset_t)buffer,
        (mach_msg_type_number_t)length
    );
}

kern_return_t dt_mach_vm_allocate(mach_port_name_t task, uint64_t *address, uint64_t size, int flags) {
    if (address == NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    mach_vm_address_t local_address = (mach_vm_address_t)*address;
    kern_return_t result = mach_vm_allocate(
        task,
        &local_address,
        (mach_vm_size_t)size,
        flags
    );

    if (result != KERN_SUCCESS) {
        return result;
    }

    *address = (uint64_t)local_address;
    return KERN_SUCCESS;
}

kern_return_t dt_mach_vm_deallocate(mach_port_name_t task, uint64_t address, uint64_t size) {
    return mach_vm_deallocate(
        task,
        (mach_vm_address_t)address,
        (mach_vm_size_t)size
    );
}

kern_return_t dt_mach_vm_protect(mach_port_name_t task, uint64_t address, uint64_t size, int set_maximum, int new_protection) {
    return mach_vm_protect(
        task,
        (mach_vm_address_t)address,
        (mach_vm_size_t)size,
        (boolean_t)set_maximum,
        (vm_prot_t)new_protection
    );
}

kern_return_t dt_mach_vm_flush_instruction_cache(mach_port_name_t task, uint64_t address, uint64_t size) {
    vm_machine_attribute_val_t value = MATTR_VAL_ICACHE_FLUSH;
    return mach_vm_machine_attribute(
        task,
        (mach_vm_address_t)address,
        (mach_vm_size_t)size,
        MATTR_CACHE,
        &value
    );
}

kern_return_t dt_mach_vm_region_recurse(mach_port_name_t task, uint64_t *address, uint32_t *depth, DTMemoryRegion *region) {
    if (address == NULL || depth == NULL || region == NULL) {
        return KERN_INVALID_ARGUMENT;
    }

    mach_vm_address_t local_address = (mach_vm_address_t)*address;
    mach_vm_size_t local_size = 0;
    natural_t local_depth = (natural_t)*depth;
    vm_region_submap_info_data_64_t info;
    mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;

    kern_return_t result = mach_vm_region_recurse(
        task,
        &local_address,
        &local_size,
        &local_depth,
        (vm_region_recurse_info_t)&info,
        &count
    );

    if (result != KERN_SUCCESS) {
        return result;
    }

    region->address = (uint64_t)local_address;
    region->size = (uint64_t)local_size;
    region->protection = info.protection;
    region->max_protection = info.max_protection;
    region->is_submap = info.is_submap;
    region->user_tag = info.user_tag;

    *address = (uint64_t)local_address;
    *depth = (uint32_t)local_depth;
    return KERN_SUCCESS;
}

int dt_pid_list_byte_count(void) {
    return proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
}

int dt_list_pids(pid_t *buffer, int capacity) {
    if (buffer == NULL || capacity <= 0) {
        return -1;
    }

    int bytes = proc_listpids(PROC_ALL_PIDS, 0, buffer, capacity * (int)sizeof(pid_t));
    if (bytes < 0) {
        return -1;
    }

    return bytes / (int)sizeof(pid_t);
}

int dt_pid_path(pid_t pid, char *buffer, int capacity) {
    if (buffer == NULL || capacity <= 0) {
        return -1;
    }

    return proc_pidpath(pid, buffer, (uint32_t)capacity);
}

int dt_pid_name(pid_t pid, char *buffer, int capacity) {
    if (buffer == NULL || capacity <= 0) {
        return -1;
    }

    return proc_name(pid, buffer, (uint32_t)capacity);
}
