// Header file for semaphore

// Generic Counting Semaphore
struct semaphore {
  int value;
  struct spinlock lk;
};

// Prototype of the three semaphore functions in semaphore.c
void initsema(struct semaphore*, int);
int downsema(struct semaphore*);
int upsema(struct semaphore*);


// Read/Write Semaphore
struct rwsemaphore {
   struct semaphore mutex; // To protect readers
   struct semaphore roomEmpty; // To ensure mutex of writers
   int readers;
};

void initrwsema(struct rwsemaphore *);
int downreadsema(struct rwsemaphore *);
int upreadsema(struct rwsemaphore *);
void downwritesema(struct rwsemaphore *);
void upwritesema(struct rwsemaphore *);
