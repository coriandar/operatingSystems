#include <stdio.h>
#include "prog4.h"

int insert_last(struct List_item *head, struct List_item *item)
{
  if (head == null)
  {
    return 0;
  }

  struct List_item *current = head;

  // iterate to end of linked list.
  while (current->next != null)
  {
    current = current->next;
  }

  if (current->next == null)
  {
    current->next = item;
    printf("Inserted at end of list.\n");
    return 1;
  }
}


