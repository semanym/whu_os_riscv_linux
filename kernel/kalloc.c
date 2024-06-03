// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define HEAP_SIZE 16*1024*1024

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
    void *heap_start = (void*)(PHYSTOP - HEAP_SIZE);
    freerange(end, heap_start);
    // Initialize the new heap
    heap_init(heap_start, HEAP_SIZE);
  //freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}



struct heap_block {
    int size;
    int free;
    struct heap_block *next;

};

struct {
    struct spinlock lock;
    struct heap_block *free_list;
} heap;

void heap_init(void *heap_start, int size) {
    initlock(&heap.lock, "heap");
    heap.free_list = (struct heap_block*)heap_start;
    heap.free_list->size = size - sizeof(struct heap_block);
    heap.free_list->next = 0;
    heap.free_list->free = 1;
}


void *malloc(int size) {
    struct heap_block *curr;
    void *result = 0;

    acquire(&heap.lock);

    for (curr = heap.free_list; curr != 0; curr = curr->next) {
        if (curr->free && curr->size >= size + sizeof(struct heap_block)) {

                if(curr->size - size - sizeof(struct heap_block) != 0){
                  struct heap_block *new_block = (struct heap_block*)((char*)curr + sizeof(struct heap_block) + size);
                  new_block->size = curr->size - size - sizeof(struct heap_block);
                  new_block->next = curr->next;
                  new_block->free = 1;
                  curr->next = new_block;
                }
                
            curr->size = size;
            curr->free = 0;
            result = (void*)((char*)curr + sizeof(struct heap_block));
            break;
        }
    }
    release(&heap.lock);
    return result;
}

void free(void *ptr) {
    if(!ptr)
        return;

    struct heap_block *block = (struct heap_block*)((char*)ptr - sizeof(struct heap_block));
    acquire(&heap.lock);
    block->free = 1;
    block->size += sizeof(struct heap_block);

    struct heap_block *curr = heap.free_list;
    while (curr != 0){
        if (curr->free && curr->next && curr->next->free) {
            curr->size += curr->next->size + sizeof(struct heap_block);
            curr->next = curr->next->next;
        }else{
            curr = curr->next;
        }
    }
    release(&heap.lock);
}

void printheap(){
    acquire(&heap.lock);

    for (struct heap_block *curr = heap.free_list; curr != 0; curr = curr->next) {
        printf("the heap is  at  %p ,free state is %d,size is %d\n", curr,curr->free,curr->size);

    }

    release(&heap.lock);
};
